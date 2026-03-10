-- Migration 019: Advanced tables — daily logs, check-ins, learning stories,
-- enrollment pipeline, staff scheduling, helper RLS functions

-- ============================================================
-- HELPER RLS FUNCTIONS
-- ============================================================

CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS text LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT COALESCE(auth.jwt()->'app_metadata'->>'role', 'parent')
$$;

CREATE OR REPLACE FUNCTION public.is_staff_or_admin()
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT public.get_my_role() IN ('staff', 'admin')
$$;

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT public.get_my_role() = 'admin'
$$;

CREATE OR REPLACE FUNCTION public.my_children_ids()
RETURNS uuid[] LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT ARRAY(
    SELECT child_id FROM public.parent_children WHERE parent_id = auth.uid()
  )
$$;

-- ============================================================
-- HOME ACTIVITY MEDIA
-- ============================================================

CREATE TABLE IF NOT EXISTS public.home_activity_media (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  activity_id   uuid NOT NULL REFERENCES public.home_activities(id) ON DELETE CASCADE,
  file_url      text NOT NULL,
  file_type     text NOT NULL CHECK (file_type IN ('photo', 'video')),
  caption       text,
  created_at    timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.home_activity_media ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "parent_view_own_activity_media" ON public.home_activity_media;
CREATE POLICY "parent_view_own_activity_media" ON public.home_activity_media FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.home_activities ha
      WHERE ha.id = home_activity_media.activity_id
        AND ha.parent_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "staff_admin_all_activity_media" ON public.home_activity_media;
CREATE POLICY "staff_admin_all_activity_media" ON public.home_activity_media FOR ALL USING (public.is_staff_or_admin());

-- ============================================================
-- DAILY LOGS (childcare daily log book)
-- ============================================================

CREATE TABLE IF NOT EXISTS public.daily_logs (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  child_id    uuid NOT NULL REFERENCES public.children(id) ON DELETE CASCADE,
  log_date    date NOT NULL DEFAULT CURRENT_DATE,
  notes       text,
  mood        text CHECK (mood IN ('happy', 'neutral', 'sad', 'tired', 'sick')),
  logged_by   uuid REFERENCES public.profiles(id),
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now(),
  UNIQUE(child_id, log_date)
);

CREATE TRIGGER handle_daily_logs_updated_at BEFORE UPDATE ON public.daily_logs
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

ALTER TABLE public.daily_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "parent_view_own_daily_logs" ON public.daily_logs;
CREATE POLICY "parent_view_own_daily_logs" ON public.daily_logs FOR SELECT USING (
    child_id = ANY(public.my_children_ids())
  );

DROP POLICY IF EXISTS "staff_admin_all_daily_logs" ON public.daily_logs;
CREATE POLICY "staff_admin_all_daily_logs" ON public.daily_logs FOR ALL USING (public.is_staff_or_admin());

-- Meals sub-log
CREATE TABLE IF NOT EXISTS public.daily_log_meals (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  log_id      uuid NOT NULL REFERENCES public.daily_logs(id) ON DELETE CASCADE,
  meal_type   text NOT NULL CHECK (meal_type IN ('breakfast', 'snack_am', 'lunch', 'snack_pm')),
  amount      text CHECK (amount IN ('all', 'most', 'half', 'little', 'none')),
  notes       text
);

ALTER TABLE public.daily_log_meals ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "parent_view_own_meals" ON public.daily_log_meals;
CREATE POLICY "parent_view_own_meals" ON public.daily_log_meals FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.daily_logs dl WHERE dl.id = log_id AND dl.child_id = ANY(public.my_children_ids()))
  );

DROP POLICY IF EXISTS "staff_admin_all_meals" ON public.daily_log_meals;
CREATE POLICY "staff_admin_all_meals" ON public.daily_log_meals FOR ALL USING (public.is_staff_or_admin());

-- Naps sub-log
CREATE TABLE IF NOT EXISTS public.daily_log_naps (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  log_id      uuid NOT NULL REFERENCES public.daily_logs(id) ON DELETE CASCADE,
  nap_start   time,
  nap_end     time,
  quality     text CHECK (quality IN ('good', 'restless', 'no_nap'))
);

ALTER TABLE public.daily_log_naps ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "parent_view_own_naps" ON public.daily_log_naps;
CREATE POLICY "parent_view_own_naps" ON public.daily_log_naps FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.daily_logs dl WHERE dl.id = log_id AND dl.child_id = ANY(public.my_children_ids()))
  );

DROP POLICY IF EXISTS "staff_admin_all_naps" ON public.daily_log_naps;
CREATE POLICY "staff_admin_all_naps" ON public.daily_log_naps FOR ALL USING (public.is_staff_or_admin());

-- ============================================================
-- CHECK-INS
-- ============================================================

CREATE TABLE IF NOT EXISTS public.check_ins (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  child_id        uuid NOT NULL REFERENCES public.children(id) ON DELETE CASCADE,
  session_id      uuid REFERENCES public.sessions(id),
  check_in_time   timestamptz,
  check_out_time  timestamptz,
  checked_in_by   uuid REFERENCES public.profiles(id),
  checked_out_by  uuid REFERENCES public.profiles(id),
  pickup_person   text,
  notes           text,
  created_at      timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.check_ins ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "parent_view_own_checkins" ON public.check_ins;
CREATE POLICY "parent_view_own_checkins" ON public.check_ins FOR SELECT USING (
    child_id = ANY(public.my_children_ids())
  );

DROP POLICY IF EXISTS "staff_admin_all_checkins" ON public.check_ins;
CREATE POLICY "staff_admin_all_checkins" ON public.check_ins FOR ALL USING (public.is_staff_or_admin());

-- ============================================================
-- AUTHORIZED PICKUPS
-- ============================================================

CREATE TABLE IF NOT EXISTS public.authorized_pickups (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  child_id    uuid NOT NULL REFERENCES public.children(id) ON DELETE CASCADE,
  full_name   text NOT NULL,
  relationship text NOT NULL,
  phone       text,
  id_document text,
  photo_url   text,
  is_active   boolean NOT NULL DEFAULT true,
  created_at  timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.authorized_pickups ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "parent_manage_own_pickups" ON public.authorized_pickups;
CREATE POLICY "parent_manage_own_pickups" ON public.authorized_pickups FOR ALL USING (
    child_id = ANY(public.my_children_ids())
  );

DROP POLICY IF EXISTS "staff_admin_view_pickups" ON public.authorized_pickups;
CREATE POLICY "staff_admin_view_pickups" ON public.authorized_pickups FOR SELECT USING (public.is_staff_or_admin());

-- ============================================================
-- INCIDENT REPORTS
-- ============================================================

CREATE TABLE IF NOT EXISTS public.incident_reports (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  child_id        uuid NOT NULL REFERENCES public.children(id) ON DELETE CASCADE,
  reported_by     uuid REFERENCES public.profiles(id),
  incident_date   date NOT NULL DEFAULT CURRENT_DATE,
  incident_time   time,
  description     text NOT NULL,
  action_taken    text,
  parent_notified boolean NOT NULL DEFAULT false,
  severity        text NOT NULL CHECK (severity IN ('minor', 'moderate', 'serious')),
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now()
);

CREATE TRIGGER handle_incident_updated_at BEFORE UPDATE ON public.incident_reports
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

ALTER TABLE public.incident_reports ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "parent_view_own_incidents" ON public.incident_reports;
CREATE POLICY "parent_view_own_incidents" ON public.incident_reports FOR SELECT USING (
    child_id = ANY(public.my_children_ids())
  );

DROP POLICY IF EXISTS "staff_admin_all_incidents" ON public.incident_reports;
CREATE POLICY "staff_admin_all_incidents" ON public.incident_reports FOR ALL USING (public.is_staff_or_admin());

-- ============================================================
-- EMERGENCY CONTACTS
-- ============================================================

CREATE TABLE IF NOT EXISTS public.emergency_contacts (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  child_id    uuid NOT NULL REFERENCES public.children(id) ON DELETE CASCADE,
  full_name   text NOT NULL,
  relationship text NOT NULL,
  phone       text NOT NULL,
  phone_alt   text,
  priority    integer NOT NULL DEFAULT 1,
  created_at  timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.emergency_contacts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "parent_manage_own_emergency_contacts" ON public.emergency_contacts;
CREATE POLICY "parent_manage_own_emergency_contacts" ON public.emergency_contacts FOR ALL USING (
    child_id = ANY(public.my_children_ids())
  );

DROP POLICY IF EXISTS "staff_admin_view_emergency_contacts" ON public.emergency_contacts;
CREATE POLICY "staff_admin_view_emergency_contacts" ON public.emergency_contacts FOR SELECT USING (public.is_staff_or_admin());

-- ============================================================
-- LEARNING STORIES
-- ============================================================

CREATE TABLE IF NOT EXISTS public.learning_stories (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  child_id      uuid NOT NULL REFERENCES public.children(id) ON DELETE CASCADE,
  author_id     uuid REFERENCES public.profiles(id),
  title         text NOT NULL,
  story         text NOT NULL,
  domains       text[] DEFAULT '{}',
  is_shared     boolean NOT NULL DEFAULT false,
  published_at  timestamptz,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now()
);

CREATE TRIGGER handle_learning_stories_updated_at BEFORE UPDATE ON public.learning_stories
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

ALTER TABLE public.learning_stories ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "parent_view_own_stories" ON public.learning_stories;
CREATE POLICY "parent_view_own_stories" ON public.learning_stories FOR SELECT USING (
    child_id = ANY(public.my_children_ids()) AND is_shared = true
  );

DROP POLICY IF EXISTS "staff_admin_all_stories" ON public.learning_stories;
CREATE POLICY "staff_admin_all_stories" ON public.learning_stories FOR ALL USING (public.is_staff_or_admin());

CREATE TABLE IF NOT EXISTS public.learning_story_media (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  story_id    uuid NOT NULL REFERENCES public.learning_stories(id) ON DELETE CASCADE,
  file_url    text NOT NULL,
  file_type   text NOT NULL CHECK (file_type IN ('photo', 'video', 'audio')),
  caption     text,
  sort_order  integer NOT NULL DEFAULT 0,
  created_at  timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.learning_story_media ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "parent_view_own_story_media" ON public.learning_story_media;
CREATE POLICY "parent_view_own_story_media" ON public.learning_story_media FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.learning_stories ls
      WHERE ls.id = story_id
        AND ls.child_id = ANY(public.my_children_ids())
        AND ls.is_shared = true
    )
  );

DROP POLICY IF EXISTS "staff_admin_all_story_media" ON public.learning_story_media;
CREATE POLICY "staff_admin_all_story_media" ON public.learning_story_media FOR ALL USING (public.is_staff_or_admin());

-- Child portfolio settings
CREATE TABLE IF NOT EXISTS public.child_portfolio_settings (
  child_id          uuid PRIMARY KEY REFERENCES public.children(id) ON DELETE CASCADE,
  share_observations boolean NOT NULL DEFAULT false,
  share_assessments  boolean NOT NULL DEFAULT false,
  share_photos       boolean NOT NULL DEFAULT true,
  share_stories      boolean NOT NULL DEFAULT true,
  updated_at         timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.child_portfolio_settings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "parent_manage_portfolio_settings" ON public.child_portfolio_settings;
CREATE POLICY "parent_manage_portfolio_settings" ON public.child_portfolio_settings FOR ALL USING (
    child_id = ANY(public.my_children_ids())
  );

DROP POLICY IF EXISTS "staff_admin_view_portfolio_settings" ON public.child_portfolio_settings;
CREATE POLICY "staff_admin_view_portfolio_settings" ON public.child_portfolio_settings FOR SELECT USING (public.is_staff_or_admin());

-- ============================================================
-- ENROLLMENT PIPELINE
-- ============================================================

CREATE TABLE IF NOT EXISTS public.enrollment_inquiries (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  lead_id         uuid REFERENCES public.leads(id),
  parent_name     text NOT NULL,
  parent_email    text NOT NULL,
  parent_phone    text,
  child_name      text NOT NULL,
  child_dob       date,
  message         text,
  status          text NOT NULL DEFAULT 'new' CHECK (status IN ('new', 'contacted', 'scheduled', 'enrolled', 'rejected')),
  assigned_to     uuid REFERENCES public.profiles(id),
  notes           text,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now()
);

CREATE TRIGGER handle_inquiries_updated_at BEFORE UPDATE ON public.enrollment_inquiries
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

ALTER TABLE public.enrollment_inquiries ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "admin_all_inquiries" ON public.enrollment_inquiries;
CREATE POLICY "admin_all_inquiries" ON public.enrollment_inquiries FOR ALL USING (public.is_admin());

DROP POLICY IF EXISTS "staff_view_inquiries" ON public.enrollment_inquiries;
CREATE POLICY "staff_view_inquiries" ON public.enrollment_inquiries FOR SELECT USING (public.is_staff_or_admin());

-- Waitlist
CREATE TABLE IF NOT EXISTS public.waitlist (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  inquiry_id    uuid REFERENCES public.enrollment_inquiries(id),
  group_id      uuid REFERENCES public.groups(id),
  position      integer,
  notes         text,
  notified_at   timestamptz,
  created_at    timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.waitlist ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "staff_admin_all_waitlist" ON public.waitlist;
CREATE POLICY "staff_admin_all_waitlist" ON public.waitlist FOR ALL USING (public.is_staff_or_admin());

-- ============================================================
-- STAFF SCHEDULING
-- ============================================================

CREATE TABLE IF NOT EXISTS public.staff_schedules (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  staff_id    uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  work_date   date NOT NULL,
  start_time  time NOT NULL,
  end_time    time NOT NULL,
  location_id uuid REFERENCES public.locations(id),
  notes       text,
  created_at  timestamptz NOT NULL DEFAULT now(),
  UNIQUE(staff_id, work_date)
);

ALTER TABLE public.staff_schedules ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "staff_view_own_schedule" ON public.staff_schedules;
CREATE POLICY "staff_view_own_schedule" ON public.staff_schedules FOR SELECT USING (staff_id = auth.uid());

DROP POLICY IF EXISTS "admin_all_schedules" ON public.staff_schedules;
CREATE POLICY "admin_all_schedules" ON public.staff_schedules FOR ALL USING (public.is_admin());

-- Staff time entries
CREATE TABLE IF NOT EXISTS public.staff_time_entries (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  staff_id    uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  clock_in    timestamptz NOT NULL DEFAULT now(),
  clock_out   timestamptz,
  notes       text,
  approved    boolean DEFAULT false,
  created_at  timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.staff_time_entries ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "staff_manage_own_time" ON public.staff_time_entries;
CREATE POLICY "staff_manage_own_time" ON public.staff_time_entries FOR ALL USING (staff_id = auth.uid());

DROP POLICY IF EXISTS "admin_all_time_entries" ON public.staff_time_entries;
CREATE POLICY "admin_all_time_entries" ON public.staff_time_entries FOR ALL USING (public.is_admin());

-- ============================================================
-- EDUCATOR GOALS
-- ============================================================

CREATE TABLE IF NOT EXISTS public.educator_goals (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  staff_id    uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  period      text NOT NULL,
  goal        text NOT NULL,
  progress    text,
  status      text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'completed', 'abandoned')),
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TRIGGER handle_goals_updated_at BEFORE UPDATE ON public.educator_goals
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

ALTER TABLE public.educator_goals ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "staff_manage_own_goals" ON public.educator_goals;
CREATE POLICY "staff_manage_own_goals" ON public.educator_goals FOR ALL USING (staff_id = auth.uid());

DROP POLICY IF EXISTS "admin_all_goals" ON public.educator_goals;
CREATE POLICY "admin_all_goals" ON public.educator_goals FOR ALL USING (public.is_admin());

-- ============================================================
-- FORUM CATEGORIES (extends forum_topics in 017)
-- ============================================================

CREATE TABLE IF NOT EXISTS public.forum_categories (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name        text NOT NULL,
  slug        text NOT NULL UNIQUE,
  description text,
  icon        text DEFAULT '💬',
  sort_order  integer NOT NULL DEFAULT 0,
  is_active   boolean NOT NULL DEFAULT true,
  created_at  timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.forum_categories ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "all_read_forum_categories" ON public.forum_categories;
CREATE POLICY "all_read_forum_categories" ON public.forum_categories FOR SELECT USING (true);

DROP POLICY IF EXISTS "admin_manage_forum_categories" ON public.forum_categories;
CREATE POLICY "admin_manage_forum_categories" ON public.forum_categories FOR ALL USING (public.is_admin());

-- Seed forum categories
INSERT INTO public.forum_categories (name, slug, description, icon, sort_order) VALUES
  ('Razvoj i odgoj',     'razvoj-i-odgoj',    'Pitanja o dječijem razvoju i odgojnim praksama', '🌱', 1),
  ('Kućne aktivnosti',   'kucne-aktivnosti',  'Dijeljenje iskustava s kućnim aktivnostima',      '🏠', 2),
  ('Radionice',          'radionice',         'Pitanja i utisci s radionica',                    '🎨', 3),
  ('Preporuke',          'preporuke',         'Preporuke knjiga, igračaka, sadržaja',             '📚', 4),
  ('Najave',             'najave',            'Najave i vijesti od tima',                        '📢', 5)
ON CONFLICT (slug) DO NOTHING;

-- ============================================================
-- ACTIVITY LOG (audit log)
-- ============================================================

CREATE TABLE IF NOT EXISTS public.activity_log (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid REFERENCES public.profiles(id),
  action      text NOT NULL,
  entity_type text,
  entity_id   uuid,
  metadata    jsonb DEFAULT '{}',
  ip_address  inet,
  created_at  timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.activity_log ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "admin_all_activity_log" ON public.activity_log;
CREATE POLICY "admin_all_activity_log" ON public.activity_log FOR ALL USING (public.is_admin());

DROP POLICY IF EXISTS "staff_view_activity_log" ON public.activity_log;
CREATE POLICY "staff_view_activity_log" ON public.activity_log FOR SELECT USING (public.is_staff_or_admin());

-- Auto-log trigger helper
CREATE OR REPLACE FUNCTION public.log_activity(
  p_action text,
  p_entity_type text DEFAULT NULL,
  p_entity_id uuid DEFAULT NULL,
  p_metadata jsonb DEFAULT '{}'
) RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO public.activity_log (user_id, action, entity_type, entity_id, metadata)
  VALUES (auth.uid(), p_action, p_entity_type, p_entity_id, p_metadata);
END;
$$;

-- ============================================================
-- ROOM RATIOS (childcare compliance)
-- ============================================================

CREATE TABLE IF NOT EXISTS public.room_ratios (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  age_group_min   integer NOT NULL,
  age_group_max   integer NOT NULL,
  max_children    integer NOT NULL,
  min_staff       integer NOT NULL,
  notes           text,
  created_at      timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.room_ratios ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "admin_all_ratios" ON public.room_ratios;
CREATE POLICY "admin_all_ratios" ON public.room_ratios FOR ALL USING (public.is_admin());

DROP POLICY IF EXISTS "staff_view_ratios" ON public.room_ratios;
CREATE POLICY "staff_view_ratios" ON public.room_ratios FOR SELECT USING (public.is_staff_or_admin());

-- Seed default ratios (Bosnia childcare regulations)
INSERT INTO public.room_ratios (age_group_min, age_group_max, max_children, min_staff) VALUES
  (2, 3, 8,  2),
  (3, 4, 12, 2),
  (4, 6, 15, 2)
ON CONFLICT DO NOTHING;
