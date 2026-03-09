-- Migration 020: Education & LMS System
-- T-1010: Education DB Migration
-- Full spec: docs/arhitektura/17-child-tracking-and-education.md

-- ============================================================
-- EDUCATIONAL CONTENT (Master table for all content types)
-- ============================================================

CREATE TABLE IF NOT EXISTS public.educational_content (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title           TEXT NOT NULL,
  slug            TEXT UNIQUE NOT NULL,
  description     TEXT,
  cover_image_url TEXT,
  
  -- Content type: 'course', 'event', 'resource', 'webinar'
  content_type    TEXT NOT NULL CHECK (content_type IN ('course', 'event', 'resource', 'webinar')),
  
  -- Categorization
  domain          TEXT CHECK (domain IN ('emotional', 'social', 'creative', 'cognitive', 'motor', 'language')),
  age_min         INTEGER,
  age_max         INTEGER,
  
  -- Tier access
  required_tier   TEXT NOT NULL DEFAULT 'free' CHECK (required_tier IN ('free', 'paid', 'premium')),
  
  -- Status
  status          TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'archived')),
  
  -- Metadata
  duration_minutes INTEGER,
  difficulty_level TEXT CHECK (difficulty_level IN ('beginner', 'intermediate', 'advanced')),
  
  -- SEO
  meta_title      TEXT,
  meta_description TEXT,
  
  -- Stats (denormalized for performance)
  view_count      INTEGER DEFAULT 0,
  enrollment_count INTEGER DEFAULT 0,
  completion_count INTEGER DEFAULT 0,
  average_rating  NUMERIC(3,2) DEFAULT 0,
  
  -- Timestamps
  published_at    TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by      UUID REFERENCES public.profiles(id)
);

CREATE INDEX IF NOT EXISTS idx_educational_content_type ON public.educational_content(content_type);
CREATE INDEX IF NOT EXISTS idx_educational_content_domain ON public.educational_content(domain);
CREATE INDEX IF NOT EXISTS idx_educational_content_status ON public.educational_content(status);
CREATE INDEX IF NOT EXISTS idx_educational_content_tier ON public.educational_content(required_tier);
CREATE INDEX IF NOT EXISTS idx_educational_content_slug ON public.educational_content(slug);

-- ============================================================
-- COURSE MODULES (grouping lessons within courses)
-- ============================================================

CREATE TABLE IF NOT EXISTS public.course_modules (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  course_id       UUID NOT NULL REFERENCES public.educational_content(id) ON DELETE CASCADE,
  title           TEXT NOT NULL,
  description     TEXT,
  sort_order      INTEGER NOT NULL DEFAULT 0,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_course_modules_course ON public.course_modules(course_id);
CREATE INDEX IF NOT EXISTS idx_course_modules_order ON public.course_modules(sort_order);

-- ============================================================
-- COURSE LESSONS (individual lessons within modules)
-- ============================================================

CREATE TABLE IF NOT EXISTS public.course_lessons (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  module_id       UUID NOT NULL REFERENCES public.course_modules(id) ON DELETE CASCADE,
  title           TEXT NOT NULL,
  slug            TEXT NOT NULL,
  description     TEXT,
  
  -- Content
  content_html    TEXT,
  video_url       TEXT,
  video_duration  INTEGER, -- seconds
  
  -- Attachments
  attachment_urls TEXT[], -- Array of file URLs
  
  -- Lesson type
  lesson_type     TEXT NOT NULL DEFAULT 'content' CHECK (lesson_type IN ('content', 'quiz', 'assignment', 'discussion')),
  
  -- Settings
  is_preview      BOOLEAN DEFAULT false, -- Can be viewed without enrollment
  is_required     BOOLEAN DEFAULT true,
  
  -- Ordering
  sort_order      INTEGER NOT NULL DEFAULT 0,
  
  -- Stats
  view_count      INTEGER DEFAULT 0,
  completion_count INTEGER DEFAULT 0,
  
  -- Timestamps
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_course_lessons_module ON public.course_lessons(module_id);
CREATE INDEX IF NOT EXISTS idx_course_lessons_order ON public.course_lessons(sort_order);
CREATE UNIQUE INDEX IF NOT EXISTS idx_course_lessons_unique ON public.course_lessons(module_id, slug);

-- ============================================================
-- COURSE ENROLLMENTS (user enrollment tracking)
-- ============================================================

CREATE TABLE IF NOT EXISTS public.course_enrollments (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id         UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  course_id       UUID NOT NULL REFERENCES public.educational_content(id) ON DELETE CASCADE,
  
  -- Progress
  progress_percent NUMERIC(5,2) DEFAULT 0,
  completed_lessons UUID[], -- Array of completed lesson IDs
  
  -- Status
  status          TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'completed', 'dropped')),
  
  -- Timestamps
  enrolled_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  completed_at    TIMESTAMPTZ,
  last_accessed_at TIMESTAMPTZ,
  
  UNIQUE(user_id, course_id)
);

CREATE INDEX IF NOT EXISTS idx_course_enrollments_user ON public.course_enrollments(user_id);
CREATE INDEX IF NOT EXISTS idx_course_enrollments_course ON public.course_enrollments(course_id);
CREATE INDEX IF NOT EXISTS idx_course_enrollments_status ON public.course_enrollments(status);

-- ============================================================
-- LESSON PROGRESS (per-lesson completion tracking)
-- ============================================================

CREATE TABLE IF NOT EXISTS public.lesson_progress (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id         UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  lesson_id       UUID NOT NULL REFERENCES public.course_lessons(id) ON DELETE CASCADE,
  enrollment_id   UUID NOT NULL REFERENCES public.course_enrollments(id) ON DELETE CASCADE,
  
  -- Status
  status          TEXT NOT NULL DEFAULT 'not_started' CHECK (status IN ('not_started', 'in_progress', 'completed')),
  
  -- Progress tracking
  progress_percent NUMERIC(5,2) DEFAULT 0,
  time_spent_seconds INTEGER DEFAULT 0,
  
  -- Timestamps
  started_at      TIMESTAMPTZ DEFAULT now(),
  completed_at    TIMESTAMPTZ,
  last_watched_at TIMESTAMPTZ,
  last_position   INTEGER DEFAULT 0, -- Video position in seconds
  
  UNIQUE(user_id, lesson_id)
);

CREATE INDEX IF NOT EXISTS idx_lesson_progress_user ON public.lesson_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_lesson_progress_lesson ON public.lesson_progress(lesson_id);
CREATE INDEX IF NOT EXISTS idx_lesson_progress_enrollment ON public.lesson_progress(enrollment_id);

-- ============================================================
-- CONTENT REGISTRATIONS (event/webinar registration)
-- ============================================================

CREATE TABLE IF NOT EXISTS public.content_registrations (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id         UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  content_id      UUID NOT NULL REFERENCES public.educational_content(id) ON DELETE CASCADE,
  
  -- Child link (optional, for parent registrations)
  child_id        UUID REFERENCES public.children(id),
  
  -- Registration details
  status          TEXT NOT NULL DEFAULT 'registered' CHECK (status IN ('registered', 'confirmed', 'waitlist', 'cancelled', 'attended')),
  
  -- Meeting info (for online events)
  meeting_link    TEXT,
  meeting_id      TEXT,
  
  -- Timestamps
  registered_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  attended_at     TIMESTAMPTZ,
  
  UNIQUE(user_id, content_id)
);

CREATE INDEX IF NOT EXISTS idx_content_registrations_user ON public.content_registrations(user_id);
CREATE INDEX IF NOT EXISTS idx_content_registrations_content ON public.content_registrations(content_id);
CREATE INDEX IF NOT EXISTS idx_content_registrations_status ON public.content_registrations(status);

-- ============================================================
-- RESOURCE MATERIALS (attachments for resources)
-- ============================================================

CREATE TABLE IF NOT EXISTS public.resource_materials (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  content_id      UUID NOT NULL REFERENCES public.educational_content(id) ON DELETE CASCADE,
  
  -- File info
  file_url        TEXT NOT NULL,
  file_type       TEXT NOT NULL CHECK (file_type IN ('pdf', 'image', 'video', 'audio', 'document', 'worksheet')),
  file_size_bytes INTEGER,
  
  -- Metadata
  title           TEXT NOT NULL,
  description     TEXT,
  download_count  INTEGER DEFAULT 0,
  
  -- Access control
  is_downloadable BOOLEAN DEFAULT true,
  
  -- Timestamps
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_resource_materials_content ON public.resource_materials(content_id);
CREATE INDEX IF NOT EXISTS idx_resource_materials_type ON public.resource_materials(file_type);

-- ============================================================
-- CONTENT RATINGS & REVIEWS
-- ============================================================

CREATE TABLE IF NOT EXISTS public.content_ratings (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id         UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  content_id      UUID NOT NULL REFERENCES public.educational_content(id) ON DELETE CASCADE,
  
  rating          INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  review_text     TEXT,
  
  -- Helpful count (other users can mark reviews as helpful)
  helpful_count   INTEGER DEFAULT 0,
  
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  UNIQUE(user_id, content_id)
);

CREATE INDEX IF NOT EXISTS idx_content_ratings_content ON public.content_ratings(content_id);
CREATE INDEX IF NOT EXISTS idx_content_ratings_user ON public.content_ratings(user_id);

-- ============================================================
-- TRIGGERS
-- ============================================================

-- Updated_at triggers
DROP TRIGGER IF EXISTS educational_content_updated_at ON public.educational_content;
CREATE TRIGGER educational_content_updated_at
  BEFORE UPDATE ON public.educational_content
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS course_modules_updated_at ON public.course_modules;
CREATE TRIGGER course_modules_updated_at
  BEFORE UPDATE ON public.course_modules
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS course_lessons_updated_at ON public.course_lessons;
CREATE TRIGGER course_lessons_updated_at
  BEFORE UPDATE ON public.course_lessons
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS content_ratings_updated_at ON public.content_ratings;
CREATE TRIGGER content_ratings_updated_at
  BEFORE UPDATE ON public.content_ratings
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================

ALTER TABLE public.educational_content    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.course_modules         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.course_lessons         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.course_enrollments     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lesson_progress        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.content_registrations  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.resource_materials     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.content_ratings        ENABLE ROW LEVEL SECURITY;

-- Educational content: public can read published, authenticated can read all published
CREATE POLICY "educational_content_public_read"
  ON public.educational_content FOR SELECT
  USING (status = 'published');

-- Only staff/admin can insert/update/delete
CREATE POLICY "educational_content_staff_write"
  ON public.educational_content FOR ALL
  USING (public.is_staff_or_admin())
  WITH CHECK (public.is_staff_or_admin());

-- Course modules: same as content
CREATE POLICY "course_modules_public_read"
  ON public.course_modules FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.educational_content ec
      WHERE ec.id = course_modules.course_id AND ec.status = 'published'
    )
  );

CREATE POLICY "course_modules_staff_write"
  ON public.course_modules FOR ALL
  USING (public.is_staff_or_admin())
  WITH CHECK (public.is_staff_or_admin());

-- Course lessons: same as content
CREATE POLICY "course_lessons_public_read"
  ON public.course_lessons FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.course_modules cm
      JOIN public.educational_content ec ON ec.id = cm.course_id
      WHERE cm.id = course_lessons.module_id AND ec.status = 'published'
    )
  );

CREATE POLICY "course_lessons_staff_write"
  ON public.course_lessons FOR ALL
  USING (public.is_staff_or_admin())
  WITH CHECK (public.is_staff_or_admin());

-- Course enrollments: users see own, staff/admin see all
CREATE POLICY "course_enrollments_own"
  ON public.course_enrollments FOR SELECT
  USING (user_id = auth.uid() OR public.is_staff_or_admin());

CREATE POLICY "course_enrollments_insert"
  ON public.course_enrollments FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "course_enrollments_update"
  ON public.course_enrollments FOR UPDATE
  USING (user_id = auth.uid() OR public.is_staff_or_admin());

-- Lesson progress: users see own
CREATE POLICY "lesson_progress_own"
  ON public.lesson_progress FOR ALL
  USING (user_id = auth.uid());

-- Content registrations: users see own, staff/admin see all
CREATE POLICY "content_registrations_own"
  ON public.content_registrations FOR SELECT
  USING (user_id = auth.uid() OR public.is_staff_or_admin());

CREATE POLICY "content_registrations_insert"
  ON public.content_registrations FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "content_registrations_update"
  ON public.content_registrations FOR UPDATE
  USING (user_id = auth.uid() OR public.is_staff_or_admin());

-- Resource materials: public read for published content
CREATE POLICY "resource_materials_public_read"
  ON public.resource_materials FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.educational_content ec
      WHERE ec.id = resource_materials.content_id AND ec.status = 'published'
    )
  );

CREATE POLICY "resource_materials_staff_write"
  ON public.resource_materials FOR ALL
  USING (public.is_staff_or_admin())
  WITH CHECK (public.is_staff_or_admin());

-- Content ratings: authenticated can read, users can manage own
CREATE POLICY "content_ratings_authenticated_read"
  ON public.content_ratings FOR SELECT
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "content_ratings_own"
  ON public.content_ratings FOR ALL
  USING (user_id = auth.uid());

-- ============================================================
-- HELPER FUNCTIONS
-- ============================================================

-- Function to update course enrollment progress
CREATE OR REPLACE FUNCTION public.update_enrollment_progress()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF TG_TABLE_NAME = 'lesson_progress' THEN
    -- Update enrollment progress when lesson progress changes
    UPDATE public.course_enrollments
    SET
      progress_percent = (
        SELECT AVG(progress_percent)
        FROM public.lesson_progress lp
        JOIN public.course_lessons cl ON cl.id = lp.lesson_id
        JOIN public.course_modules cm ON cm.id = cl.module_id
        WHERE cm.course_id = (
          SELECT course_id FROM public.course_enrollments WHERE id = NEW.enrollment_id
        )
      ),
      last_accessed_at = now()
    WHERE id = NEW.enrollment_id;
  END IF;
  
  RETURN NEW;
END;
$$;

-- Trigger to auto-update enrollment progress
DROP TRIGGER IF EXISTS trigger_update_enrollment_progress ON public.lesson_progress;
CREATE TRIGGER trigger_update_enrollment_progress
  AFTER INSERT OR UPDATE ON public.lesson_progress
  FOR EACH ROW EXECUTE FUNCTION public.update_enrollment_progress();

-- Function to check if user has access to content based on tier
CREATE OR REPLACE FUNCTION public.can_access_content(content_id UUID)
RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  content_tier TEXT;
  user_tier TEXT;
  tier_hierarchy CONSTANT TEXT[] := ARRAY['free', 'paid', 'premium'];
  content_rank INTEGER;
  user_rank INTEGER;
BEGIN
  -- Get content required tier
  SELECT required_tier INTO content_tier
  FROM public.educational_content
  WHERE id = content_id;
  
  IF NOT FOUND THEN
    RETURN FALSE;
  END IF;
  
  -- Get user's tier
  SELECT COALESCE(subscription_tier, 'free') INTO user_tier
  FROM public.profiles
  WHERE id = auth.uid();
  
  -- Compare tiers
  content_rank := array_position(tier_hierarchy, content_tier);
  user_rank := array_position(tier_hierarchy, user_tier);
  
  RETURN user_rank >= content_rank;
END;
$$;

-- ============================================================
-- COMMENTS
-- ============================================================

COMMENT ON TABLE public.educational_content IS 'Master table for all educational content: courses, events, resources, webinars';
COMMENT ON TABLE public.course_modules IS 'Module grouping within courses';
COMMENT ON TABLE public.course_lessons IS 'Individual lessons within modules';
COMMENT ON TABLE public.course_enrollments IS 'User enrollment tracking for courses';
COMMENT ON TABLE public.lesson_progress IS 'Per-lesson completion tracking';
COMMENT ON TABLE public.content_registrations IS 'Event/webinar registration tracking';
COMMENT ON TABLE public.resource_materials IS 'Downloadable attachments for resources';
COMMENT ON TABLE public.content_ratings IS 'User ratings and reviews for content';
COMMENT ON FUNCTION public.can_access_content IS 'Check if current user has tier access to content';
