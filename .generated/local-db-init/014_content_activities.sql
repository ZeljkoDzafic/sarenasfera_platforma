-- ─── Content: Home Activities, Blog, Resources ───────────────────────────────
-- T-102: Database Migrations
-- Migration: 014_content_activities.sql

-- ─── Home Activities ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.home_activities (
  id                UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  session_id        UUID REFERENCES public.sessions(id),
  workshop_id       UUID REFERENCES public.workshops(id),
  child_id          UUID REFERENCES public.children(id) ON DELETE CASCADE NOT NULL,
  parent_id         UUID REFERENCES public.profiles(id) NOT NULL,
  assigned_at       TIMESTAMPTZ DEFAULT now(),
  completed         BOOLEAN DEFAULT false,
  completed_at      TIMESTAMPTZ,
  difficulty_rating INTEGER CHECK (difficulty_rating BETWEEN 1 AND 5),
  enjoyment_rating  INTEGER CHECK (enjoyment_rating BETWEEN 1 AND 5),
  parent_comment    TEXT,
  photo_urls        TEXT[],
  created_at        TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_home_activities_child  ON public.home_activities(child_id);
CREATE INDEX IF NOT EXISTS idx_home_activities_parent ON public.home_activities(parent_id);

-- ─── Blog Posts ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.blog_posts (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  slug            TEXT NOT NULL UNIQUE,
  title           TEXT NOT NULL,
  excerpt         TEXT,
  content         TEXT,                       -- rich text / MDX
  cover_image_url TEXT,
  author_id       UUID REFERENCES public.profiles(id),
  author_name     TEXT,                       -- display name override
  category        TEXT,
  tags            TEXT[],
  skill_area_id   UUID REFERENCES public.skill_areas(id),
  read_time_minutes INTEGER,
  is_published    BOOLEAN DEFAULT false,
  is_featured     BOOLEAN DEFAULT false,
  seo_title       TEXT,
  seo_description TEXT,
  og_image_url    TEXT,
  view_count      INTEGER DEFAULT 0,
  published_at    TIMESTAMPTZ,
  created_at      TIMESTAMPTZ DEFAULT now(),
  updated_at      TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_blog_posts_slug      ON public.blog_posts(slug);
CREATE INDEX IF NOT EXISTS idx_blog_posts_published ON public.blog_posts(is_published, published_at DESC);
CREATE INDEX IF NOT EXISTS idx_blog_posts_category  ON public.blog_posts(category);
CREATE INDEX IF NOT EXISTS idx_blog_posts_area      ON public.blog_posts(skill_area_id);

DROP TRIGGER IF EXISTS blog_posts_updated_at ON public.blog_posts;
CREATE TRIGGER blog_posts_updated_at
  BEFORE UPDATE ON public.blog_posts
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ─── Resources (free downloads / lead magnets) ────────────────────────────────
CREATE TABLE IF NOT EXISTS public.resources (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title           TEXT NOT NULL,
  description     TEXT,
  file_url        TEXT,
  cover_image_url TEXT,
  resource_type   TEXT NOT NULL DEFAULT 'pdf'
                    CHECK (resource_type IN ('pdf', 'video', 'audio', 'guide', 'worksheet', 'other')),
  category        TEXT,
  skill_area_id   UUID REFERENCES public.skill_areas(id),
  age_group       TEXT,
  requires_email  BOOLEAN DEFAULT true,       -- lead magnet: email required to download
  requires_auth   BOOLEAN DEFAULT false,
  min_tier        TEXT DEFAULT 'free'
                    CHECK (min_tier IN ('free', 'paid', 'premium')),
  download_count  INTEGER DEFAULT 0,
  is_published    BOOLEAN DEFAULT true,
  created_at      TIMESTAMPTZ DEFAULT now(),
  updated_at      TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_resources_type      ON public.resources(resource_type);
CREATE INDEX IF NOT EXISTS idx_resources_area      ON public.resources(skill_area_id);
CREATE INDEX IF NOT EXISTS idx_resources_published ON public.resources(is_published);

DROP TRIGGER IF EXISTS resources_updated_at ON public.resources;
CREATE TRIGGER resources_updated_at
  BEFORE UPDATE ON public.resources
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ─── Weekly Challenges ────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.weekly_challenges (
  id           UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title        TEXT NOT NULL,
  description  TEXT NOT NULL,
  instructions TEXT,
  skill_area_id UUID REFERENCES public.skill_areas(id),
  age_group    TEXT,
  week_number  INTEGER,
  year         INTEGER,
  is_active    BOOLEAN DEFAULT true,
  created_at   TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.challenge_submissions (
  id               UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  challenge_id     UUID REFERENCES public.weekly_challenges(id) ON DELETE CASCADE,
  family_id        UUID REFERENCES public.profiles(id),         -- parent's profile
  child_id         UUID REFERENCES public.children(id),
  content          TEXT,
  photo_url        TEXT,
  is_approved      BOOLEAN DEFAULT false,
  created_at       TIMESTAMPTZ DEFAULT now()
);

-- ─── Workshop Feedback ────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.workshop_feedback (
  id             UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  session_id     UUID REFERENCES public.sessions(id),
  parent_id      UUID REFERENCES public.profiles(id) NOT NULL,
  child_id       UUID REFERENCES public.children(id),
  rating         INTEGER CHECK (rating BETWEEN 1 AND 5),
  comment        TEXT,
  is_public      BOOLEAN DEFAULT false,
  created_at     TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_feedback_session ON public.workshop_feedback(session_id);

-- ─── RLS ──────────────────────────────────────────────────────────────────────
ALTER TABLE public.home_activities      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.blog_posts           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.resources            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.weekly_challenges    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.challenge_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workshop_feedback    ENABLE ROW LEVEL SECURITY;

-- Home activities: parent sees own; staff sees all
DROP POLICY IF EXISTS "home_activities_parent" ON public.home_activities;
CREATE POLICY "home_activities_parent" ON public.home_activities
  FOR SELECT USING (parent_id = auth.uid() OR auth.jwt()->'app_metadata'->>'role' IN ('admin', 'staff'));
DROP POLICY IF EXISTS "home_activities_parent_write" ON public.home_activities;
CREATE POLICY "home_activities_parent_write" ON public.home_activities
  FOR INSERT WITH CHECK (parent_id = auth.uid());
DROP POLICY IF EXISTS "home_activities_parent_update" ON public.home_activities;
CREATE POLICY "home_activities_parent_update" ON public.home_activities
  FOR UPDATE USING (parent_id = auth.uid());
DROP POLICY IF EXISTS "home_activities_staff" ON public.home_activities;
CREATE POLICY "home_activities_staff" ON public.home_activities
  FOR ALL USING (auth.jwt()->'app_metadata'->>'role' IN ('admin', 'staff'));

-- Blog: public read published; admin manages
DROP POLICY IF EXISTS "blog_public_read" ON public.blog_posts;
CREATE POLICY "blog_public_read" ON public.blog_posts FOR SELECT USING (is_published = true);
DROP POLICY IF EXISTS "blog_admin_all" ON public.blog_posts;
CREATE POLICY "blog_admin_all" ON public.blog_posts FOR ALL    USING (auth.jwt()->'app_metadata'->>'role' IN ('admin', 'staff'));

-- Resources: public read published/free; paid requires auth+tier
DROP POLICY IF EXISTS "resources_public_read" ON public.resources;
CREATE POLICY "resources_public_read" ON public.resources FOR SELECT USING (is_published = true AND requires_auth = false);
DROP POLICY IF EXISTS "resources_auth_read" ON public.resources;
CREATE POLICY "resources_auth_read" ON public.resources FOR SELECT USING (is_published = true AND auth.uid() IS NOT NULL);
DROP POLICY IF EXISTS "resources_admin_all" ON public.resources;
CREATE POLICY "resources_admin_all" ON public.resources FOR ALL    USING (auth.jwt()->'app_metadata'->>'role' IN ('admin', 'staff'));

-- Weekly challenges: public read
DROP POLICY IF EXISTS "challenges_public_read" ON public.weekly_challenges;
CREATE POLICY "challenges_public_read" ON public.weekly_challenges FOR SELECT USING (is_active = true);
DROP POLICY IF EXISTS "challenges_admin" ON public.weekly_challenges;
CREATE POLICY "challenges_admin" ON public.weekly_challenges FOR ALL    USING (auth.jwt()->'app_metadata'->>'role' = 'admin');

-- Challenge submissions: parent writes own; admin manages
DROP POLICY IF EXISTS "submissions_parent_write" ON public.challenge_submissions;
CREATE POLICY "submissions_parent_write" ON public.challenge_submissions FOR INSERT WITH CHECK (family_id = auth.uid());
DROP POLICY IF EXISTS "submissions_approved_read" ON public.challenge_submissions;
CREATE POLICY "submissions_approved_read" ON public.challenge_submissions FOR SELECT USING (is_approved = true OR family_id = auth.uid());
DROP POLICY IF EXISTS "submissions_admin" ON public.challenge_submissions;
CREATE POLICY "submissions_admin" ON public.challenge_submissions FOR ALL    USING (auth.jwt()->'app_metadata'->>'role' = 'admin');

-- Feedback: parent writes own; staff reads
DROP POLICY IF EXISTS "feedback_parent_write" ON public.workshop_feedback;
CREATE POLICY "feedback_parent_write" ON public.workshop_feedback FOR INSERT WITH CHECK (parent_id = auth.uid());
DROP POLICY IF EXISTS "feedback_parent_read" ON public.workshop_feedback;
CREATE POLICY "feedback_parent_read" ON public.workshop_feedback FOR SELECT USING (parent_id = auth.uid() OR auth.jwt()->'app_metadata'->>'role' IN ('admin', 'staff'));
