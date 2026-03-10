-- ─── Workshops, Sessions, Attendance, Observations ───────────────────────────
-- T-102: Database Migrations
-- Migration: 013_workshops_sessions.sql

-- ─── Workshop Templates ────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.workshops (
  id                        UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title                     TEXT NOT NULL,
  description               TEXT,
  month_number              INTEGER CHECK (month_number BETWEEN 1 AND 12),
  workshop_number           INTEGER CHECK (workshop_number BETWEEN 1 AND 12),
  domains                   TEXT[] NOT NULL DEFAULT '{}',
  target_skills             UUID[],
  objectives                TEXT[],
  materials_needed          TEXT[],
  preparation_checklist     JSONB,
  duration_minutes          INTEGER DEFAULT 90,
  home_activity_title       TEXT,
  home_activity_description TEXT,
  home_activity_materials   TEXT[],
  home_activity_pdf_url     TEXT,
  methodology               TEXT CHECK (methodology IN ('montessori', 'ntc', 'mixed')),
  methodology_notes         TEXT,
  age_group_recommendation  TEXT,
  difficulty_level          INTEGER DEFAULT 1 CHECK (difficulty_level BETWEEN 1 AND 3),
  cover_image_url           TEXT,
  is_published              BOOLEAN DEFAULT true,
  created_at                TIMESTAMPTZ DEFAULT now(),
  updated_at                TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_workshops_month     ON public.workshops(month_number);
CREATE INDEX IF NOT EXISTS idx_workshops_published ON public.workshops(is_published);

DROP TRIGGER IF EXISTS workshops_updated_at ON public.workshops;
CREATE TRIGGER workshops_updated_at
  BEFORE UPDATE ON public.workshops
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ─── Workshop Materials ────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.workshop_materials (
  id           UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  workshop_id  UUID REFERENCES public.workshops(id) ON DELETE CASCADE NOT NULL,
  title        TEXT NOT NULL,
  description  TEXT,
  file_url     TEXT NOT NULL,
  file_type    TEXT NOT NULL
                 CHECK (file_type IN ('pdf', 'video', 'audio', 'image', 'link', 'document')),
  is_for_parents BOOLEAN DEFAULT false,
  is_for_staff   BOOLEAN DEFAULT true,
  sort_order   INTEGER DEFAULT 0,
  created_at   TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_workshop_materials_workshop ON public.workshop_materials(workshop_id);

-- ─── Sessions (specific delivery of workshop to group) ────────────────────────
CREATE TABLE IF NOT EXISTS public.sessions (
  id                   UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  workshop_id          UUID REFERENCES public.workshops(id) NOT NULL,
  group_id             UUID REFERENCES public.groups(id) NOT NULL,
  location_id          UUID REFERENCES public.locations(id),
  scheduled_date       DATE NOT NULL,
  scheduled_time_start TIME,
  scheduled_time_end   TIME,
  actual_date          DATE,
  staff_id             UUID REFERENCES public.profiles(id),
  status               TEXT DEFAULT 'scheduled'
                         CHECK (status IN ('scheduled', 'in_progress', 'completed', 'cancelled', 'postponed')),
  staff_notes          TEXT,
  summary_for_parents  TEXT,
  summary_sent         BOOLEAN DEFAULT false,
  cancelled_reason     TEXT,
  created_at           TIMESTAMPTZ DEFAULT now(),
  updated_at           TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_sessions_group_date ON public.sessions(group_id, scheduled_date);
CREATE INDEX IF NOT EXISTS idx_sessions_date       ON public.sessions(scheduled_date);
CREATE INDEX IF NOT EXISTS idx_sessions_workshop   ON public.sessions(workshop_id);
CREATE INDEX IF NOT EXISTS idx_sessions_status     ON public.sessions(status);

DROP TRIGGER IF EXISTS sessions_updated_at ON public.sessions;
CREATE TRIGGER sessions_updated_at
  BEFORE UPDATE ON public.sessions
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ─── Attendance ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.attendance (
  id                UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  session_id        UUID REFERENCES public.sessions(id) ON DELETE CASCADE NOT NULL,
  child_id          UUID REFERENCES public.children(id) ON DELETE CASCADE NOT NULL,
  status            TEXT DEFAULT 'present'
                      CHECK (status IN ('present', 'absent', 'late', 'left_early', 'excused')),
  participation_level TEXT CHECK (participation_level IN ('observed', 'partial', 'full', 'exceptional')),
  arrived_at        TIME,
  left_at           TIME,
  recorded_by       UUID REFERENCES public.profiles(id),
  parent_notified   BOOLEAN DEFAULT false,
  created_at        TIMESTAMPTZ DEFAULT now(),
  UNIQUE(session_id, child_id)
);

CREATE INDEX IF NOT EXISTS idx_attendance_child   ON public.attendance(child_id);
CREATE INDEX IF NOT EXISTS idx_attendance_session ON public.attendance(session_id);

-- ─── Observation Templates (fast entry snippets) ──────────────────────────────
CREATE TABLE IF NOT EXISTS public.observation_templates (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  skill_area_id   UUID REFERENCES public.skill_areas(id) NOT NULL,
  content         TEXT NOT NULL,
  has_placeholder BOOLEAN DEFAULT false,
  usage_count     INTEGER DEFAULT 0,
  created_by      UUID REFERENCES public.profiles(id),
  is_system       BOOLEAN DEFAULT true,
  created_at      TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_obs_templates_area ON public.observation_templates(skill_area_id);

-- ─── Observations ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.observations (
  id                 UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  child_id           UUID REFERENCES public.children(id) ON DELETE CASCADE NOT NULL,
  session_id         UUID REFERENCES public.sessions(id),
  staff_id           UUID REFERENCES public.profiles(id) NOT NULL,
  content            TEXT NOT NULL,
  skill_area_id      UUID REFERENCES public.skill_areas(id),
  tagged_skills      UUID[],
  observation_type   TEXT DEFAULT 'workshop'
                       CHECK (observation_type IN ('workshop', 'adhoc', 'milestone', 'concern', 'positive')),
  is_visible_to_parent BOOLEAN DEFAULT true,
  is_highlighted     BOOLEAN DEFAULT false,
  template_id        UUID REFERENCES public.observation_templates(id),
  created_at         TIMESTAMPTZ DEFAULT now(),
  updated_at         TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_observations_child   ON public.observations(child_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_observations_session ON public.observations(session_id);
CREATE INDEX IF NOT EXISTS idx_observations_area    ON public.observations(skill_area_id);
CREATE INDEX IF NOT EXISTS idx_observations_type    ON public.observations(observation_type);

DROP TRIGGER IF EXISTS observations_updated_at ON public.observations;
CREATE TRIGGER observations_updated_at
  BEFORE UPDATE ON public.observations
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ─── Observation Media ────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.observation_media (
  id             UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  observation_id UUID REFERENCES public.observations(id) ON DELETE CASCADE NOT NULL,
  file_url       TEXT NOT NULL,
  file_type      TEXT NOT NULL CHECK (file_type IN ('photo', 'video', 'audio', 'document')),
  caption        TEXT,
  sort_order     INTEGER DEFAULT 0,
  created_at     TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_observation_media_obs ON public.observation_media(observation_id);

-- ─── Assessments (domain scores 1-5 per quarter) ─────────────────────────────
CREATE TABLE IF NOT EXISTS public.assessments (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  child_id        UUID REFERENCES public.children(id) ON DELETE CASCADE NOT NULL,
  staff_id        UUID REFERENCES public.profiles(id) NOT NULL,
  skill_area_id   UUID REFERENCES public.skill_areas(id) NOT NULL,
  score           INTEGER NOT NULL CHECK (score BETWEEN 1 AND 5),
  period          TEXT NOT NULL,              -- "2026-Q1"
  evidence_notes  TEXT,
  observation_ids UUID[],
  created_at      TIMESTAMPTZ DEFAULT now(),
  updated_at      TIMESTAMPTZ DEFAULT now(),
  UNIQUE(child_id, skill_area_id, period)
);

CREATE INDEX IF NOT EXISTS idx_assessments_child_period ON public.assessments(child_id, period);

DROP TRIGGER IF EXISTS assessments_updated_at ON public.assessments;
CREATE TRIGGER assessments_updated_at
  BEFORE UPDATE ON public.assessments
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ─── Quarterly Reports ────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.quarterly_reports (
  id                    UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  child_id              UUID REFERENCES public.children(id) ON DELETE CASCADE NOT NULL,
  period                TEXT NOT NULL,        -- "2026-Q1"
  status                TEXT DEFAULT 'draft'
                          CHECK (status IN ('draft', 'review', 'published', 'archived')),
  pdf_url               TEXT,
  domain_scores         JSONB,               -- {"emotional": 4, "social": 3, ...}
  attendance_total      INTEGER,
  attendance_present    INTEGER,
  attendance_percentage NUMERIC(5,2),
  strengths             TEXT[],
  areas_to_improve      TEXT[],
  recommendations       TEXT,
  staff_narrative       TEXT,
  generated_by          UUID REFERENCES public.profiles(id),
  reviewed_by           UUID REFERENCES public.profiles(id),
  published_by          UUID REFERENCES public.profiles(id),
  published_at          TIMESTAMPTZ,
  parent_viewed_at      TIMESTAMPTZ,
  parent_acknowledged   BOOLEAN DEFAULT false,
  generated_at          TIMESTAMPTZ DEFAULT now(),
  UNIQUE(child_id, period)
);

CREATE INDEX IF NOT EXISTS idx_reports_child  ON public.quarterly_reports(child_id);
CREATE INDEX IF NOT EXISTS idx_reports_status ON public.quarterly_reports(status);

-- ─── RLS ──────────────────────────────────────────────────────────────────────
ALTER TABLE public.workshops           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workshop_materials  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sessions            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.observation_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.observations        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.observation_media   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.assessments         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quarterly_reports   ENABLE ROW LEVEL SECURITY;

-- Workshops: authenticated read
DROP POLICY IF EXISTS "workshops_auth_read" ON public.workshops;
CREATE POLICY "workshops_auth_read" ON public.workshops          FOR SELECT USING (auth.uid() IS NOT NULL AND is_published = true);
DROP POLICY IF EXISTS "workshops_admin_all" ON public.workshops;
CREATE POLICY "workshops_admin_all" ON public.workshops          FOR ALL    USING (auth.jwt()->'app_metadata'->>'role' IN ('admin', 'staff'));
DROP POLICY IF EXISTS "materials_auth_read" ON public.workshop_materials;
CREATE POLICY "materials_auth_read" ON public.workshop_materials FOR SELECT USING (auth.uid() IS NOT NULL);
DROP POLICY IF EXISTS "materials_admin_all" ON public.workshop_materials;
CREATE POLICY "materials_admin_all" ON public.workshop_materials FOR ALL    USING (auth.jwt()->'app_metadata'->>'role' IN ('admin', 'staff'));

-- Sessions: parent reads sessions for their children's groups
DROP POLICY IF EXISTS "sessions_parent_read" ON public.sessions;
CREATE POLICY "sessions_parent_read" ON public.sessions
  FOR SELECT USING (
    group_id IN (
      SELECT cg.group_id FROM public.child_groups cg
      JOIN public.parent_children pc ON pc.child_id = cg.child_id
      WHERE pc.parent_id = auth.uid()
    )
    OR auth.jwt()->'app_metadata'->>'role' IN ('admin', 'staff')
  );
DROP POLICY IF EXISTS "sessions_staff_all" ON public.sessions;
CREATE POLICY "sessions_staff_all" ON public.sessions
  FOR ALL USING (auth.jwt()->'app_metadata'->>'role' IN ('admin', 'staff'));

-- Attendance: parent sees own children; staff sees all
DROP POLICY IF EXISTS "attendance_parent_read" ON public.attendance;
CREATE POLICY "attendance_parent_read" ON public.attendance
  FOR SELECT USING (
    child_id IN (SELECT child_id FROM public.parent_children WHERE parent_id = auth.uid())
    OR auth.jwt()->'app_metadata'->>'role' IN ('admin', 'staff')
  );
DROP POLICY IF EXISTS "attendance_staff_all" ON public.attendance;
CREATE POLICY "attendance_staff_all" ON public.attendance
  FOR ALL USING (auth.jwt()->'app_metadata'->>'role' IN ('admin', 'staff'));

-- Observations: parent sees visible observations of own children
DROP POLICY IF EXISTS "observations_parent_read" ON public.observations;
CREATE POLICY "observations_parent_read" ON public.observations
  FOR SELECT USING (
    (child_id IN (SELECT child_id FROM public.parent_children WHERE parent_id = auth.uid()) AND is_visible_to_parent = true)
    OR auth.jwt()->'app_metadata'->>'role' IN ('admin', 'staff')
  );
DROP POLICY IF EXISTS "observations_staff_all" ON public.observations;
CREATE POLICY "observations_staff_all" ON public.observations
  FOR ALL USING (auth.jwt()->'app_metadata'->>'role' IN ('admin', 'staff'));

-- Observation media follows observation visibility
DROP POLICY IF EXISTS "obs_media_parent_read" ON public.observation_media;
CREATE POLICY "obs_media_parent_read" ON public.observation_media
  FOR SELECT USING (
    observation_id IN (SELECT id FROM public.observations WHERE child_id IN (SELECT child_id FROM public.parent_children WHERE parent_id = auth.uid()) AND is_visible_to_parent = true)
    OR auth.jwt()->'app_metadata'->>'role' IN ('admin', 'staff')
  );
DROP POLICY IF EXISTS "obs_media_staff_all" ON public.observation_media;
CREATE POLICY "obs_media_staff_all" ON public.observation_media
  FOR ALL USING (auth.jwt()->'app_metadata'->>'role' IN ('admin', 'staff'));

-- Assessments: parent reads; staff writes
DROP POLICY IF EXISTS "assessments_parent_read" ON public.assessments;
CREATE POLICY "assessments_parent_read" ON public.assessments
  FOR SELECT USING (
    child_id IN (SELECT child_id FROM public.parent_children WHERE parent_id = auth.uid())
    OR auth.jwt()->'app_metadata'->>'role' IN ('admin', 'staff')
  );
DROP POLICY IF EXISTS "assessments_staff_all" ON public.assessments;
CREATE POLICY "assessments_staff_all" ON public.assessments
  FOR ALL USING (auth.jwt()->'app_metadata'->>'role' IN ('admin', 'staff'));

-- Reports: parent reads published reports for own children; staff manages
DROP POLICY IF EXISTS "reports_parent_read" ON public.quarterly_reports;
CREATE POLICY "reports_parent_read" ON public.quarterly_reports
  FOR SELECT USING (
    (child_id IN (SELECT child_id FROM public.parent_children WHERE parent_id = auth.uid()) AND status = 'published')
    OR auth.jwt()->'app_metadata'->>'role' IN ('admin', 'staff')
  );
DROP POLICY IF EXISTS "reports_staff_all" ON public.quarterly_reports;
CREATE POLICY "reports_staff_all" ON public.quarterly_reports
  FOR ALL USING (auth.jwt()->'app_metadata'->>'role' IN ('admin', 'staff'));

-- Observation templates: authenticated read; admin/staff write
DROP POLICY IF EXISTS "obs_templates_read" ON public.observation_templates;
CREATE POLICY "obs_templates_read" ON public.observation_templates FOR SELECT USING (auth.uid() IS NOT NULL);
DROP POLICY IF EXISTS "obs_templates_staff" ON public.observation_templates;
CREATE POLICY "obs_templates_staff" ON public.observation_templates FOR ALL    USING (auth.jwt()->'app_metadata'->>'role' IN ('admin', 'staff'));
