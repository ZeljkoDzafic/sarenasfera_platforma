-- ─── Curriculum: Skill Areas, Skills, Milestones ─────────────────────────────
-- T-102: Database Migrations
-- Migration: 012_curriculum.sql

-- ─── Skill Areas (6 developmental domains) ───────────────────────────────────
CREATE TABLE IF NOT EXISTS public.skill_areas (
  id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  key         TEXT UNIQUE NOT NULL,           -- 'emotional', 'social', etc.
  name        TEXT NOT NULL,                  -- 'Emotional Development'
  name_local  TEXT NOT NULL,                  -- 'Emocionalni razvoj'
  description TEXT,
  icon        TEXT,                           -- emoji
  color       TEXT,                           -- hex color
  sort_order  INTEGER DEFAULT 0,
  methodology TEXT CHECK (methodology IN ('montessori', 'ntc', 'custom', 'both')),
  created_at  TIMESTAMPTZ DEFAULT now()
);

INSERT INTO public.skill_areas (key, name, name_local, icon, color, sort_order, methodology)
VALUES
  ('emotional', 'Emotional Development',  'Emocionalni razvoj', '❤️', '#cf2e2e', 1, 'both'),
  ('social',    'Social Development',     'Socijalni razvoj',   '🤝', '#fcb900', 2, 'both'),
  ('creative',  'Creative Development',   'Kreativni razvoj',   '🎨', '#9b51e0', 3, 'both'),
  ('cognitive', 'Cognitive Development',  'Kognitivni razvoj',  '🧠', '#0693e3', 4, 'both'),
  ('motor',     'Motor Development',      'Motorički razvoj',   '🏃', '#00d084', 5, 'both'),
  ('language',  'Language Development',   'Jezički razvoj',     '💬', '#f78da7', 6, 'both')
ON CONFLICT (key) DO UPDATE SET color = EXCLUDED.color, icon = EXCLUDED.icon;

-- ─── Skills (sub-skills under each domain) ────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.skills (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  skill_area_id   UUID REFERENCES public.skill_areas(id) NOT NULL,
  parent_skill_id UUID REFERENCES public.skills(id),
  name            TEXT NOT NULL,
  name_local      TEXT NOT NULL,
  description     TEXT,
  age_range_min   INTEGER,                    -- expected age in months
  age_range_max   INTEGER,
  sort_order      INTEGER DEFAULT 0,
  is_active       BOOLEAN DEFAULT true,
  created_at      TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_skills_area   ON public.skills(skill_area_id);
CREATE INDEX IF NOT EXISTS idx_skills_parent ON public.skills(parent_skill_id);
CREATE INDEX IF NOT EXISTS idx_skills_age    ON public.skills(age_range_min, age_range_max);

-- ─── Curriculum Lessons (Montessori Compass pattern) ─────────────────────────
CREATE TABLE IF NOT EXISTS public.curriculum_lessons (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  skill_id        UUID REFERENCES public.skills(id) NOT NULL,
  title           TEXT NOT NULL,
  title_local     TEXT NOT NULL,
  description     TEXT,
  methodology     TEXT NOT NULL
                    CHECK (methodology IN ('montessori', 'ntc', 'custom')),
  materials       TEXT[],
  age_range_min   INTEGER,
  age_range_max   INTEGER,
  duration_minutes INTEGER,
  instructions    TEXT,
  success_criteria TEXT,
  sort_order      INTEGER DEFAULT 0,
  is_active       BOOLEAN DEFAULT true,
  created_at      TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_curriculum_skill  ON public.curriculum_lessons(skill_id);
CREATE INDEX IF NOT EXISTS idx_curriculum_method ON public.curriculum_lessons(methodology);

-- ─── Child Lesson Records (per-child progress) ───────────────────────────────
CREATE TABLE IF NOT EXISTS public.child_lesson_records (
  id           UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  child_id     UUID REFERENCES public.children(id) ON DELETE CASCADE NOT NULL,
  lesson_id    UUID REFERENCES public.curriculum_lessons(id) NOT NULL,
  status       TEXT NOT NULL DEFAULT 'not_presented'
                 CHECK (status IN ('not_presented', 'presented', 'practicing', 'mastered')),
  presented_at TIMESTAMPTZ,
  mastered_at  TIMESTAMPTZ,
  presented_by UUID REFERENCES public.profiles(id),
  attempts     INTEGER DEFAULT 0,
  notes        TEXT,
  created_at   TIMESTAMPTZ DEFAULT now(),
  updated_at   TIMESTAMPTZ DEFAULT now(),
  UNIQUE(child_id, lesson_id)
);

CREATE INDEX IF NOT EXISTS idx_lesson_records_child  ON public.child_lesson_records(child_id);
CREATE INDEX IF NOT EXISTS idx_lesson_records_lesson ON public.child_lesson_records(lesson_id);
CREATE INDEX IF NOT EXISTS idx_lesson_records_status ON public.child_lesson_records(status);

DROP TRIGGER IF EXISTS lesson_records_updated_at ON public.child_lesson_records;
CREATE TRIGGER lesson_records_updated_at
  BEFORE UPDATE ON public.child_lesson_records
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ─── Child Milestones (Transparent Classroom pattern) ────────────────────────
CREATE TABLE IF NOT EXISTS public.child_milestones (
  id            UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  child_id      UUID REFERENCES public.children(id) ON DELETE CASCADE NOT NULL,
  skill_id      UUID REFERENCES public.skills(id) NOT NULL,
  status        TEXT NOT NULL DEFAULT 'not_introduced'
                  CHECK (status IN ('not_introduced', 'introduced', 'developing', 'practicing', 'mastered')),
  assessed_by   UUID REFERENCES public.profiles(id),
  assessed_at   TIMESTAMPTZ DEFAULT now(),
  notes         TEXT,
  evidence_observation_id UUID,              -- FK added after observations table
  created_at    TIMESTAMPTZ DEFAULT now(),
  updated_at    TIMESTAMPTZ DEFAULT now(),
  UNIQUE(child_id, skill_id)
);

CREATE INDEX IF NOT EXISTS idx_child_milestones_child ON public.child_milestones(child_id);
CREATE INDEX IF NOT EXISTS idx_child_milestones_skill ON public.child_milestones(skill_id);

DROP TRIGGER IF EXISTS child_milestones_updated_at ON public.child_milestones;
CREATE TRIGGER child_milestones_updated_at
  BEFORE UPDATE ON public.child_milestones
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ─── Milestone History ────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.milestone_history (
  id         UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  child_id   UUID REFERENCES public.children(id) ON DELETE CASCADE NOT NULL,
  skill_id   UUID REFERENCES public.skills(id) NOT NULL,
  old_status TEXT,
  new_status TEXT NOT NULL,
  changed_by UUID REFERENCES public.profiles(id),
  changed_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_milestone_history_child ON public.milestone_history(child_id, changed_at DESC);

-- ─── RLS ──────────────────────────────────────────────────────────────────────
ALTER TABLE public.skill_areas         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.skills              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.curriculum_lessons  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.child_lesson_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.child_milestones    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.milestone_history   ENABLE ROW LEVEL SECURITY;

-- Skill areas & skills: public read
DROP POLICY IF EXISTS "skill_areas_public_read" ON public.skill_areas;
CREATE POLICY "skill_areas_public_read" ON public.skill_areas FOR SELECT USING (true);
DROP POLICY IF EXISTS "skills_public_read" ON public.skills;
CREATE POLICY "skills_public_read" ON public.skills      FOR SELECT USING (true);
DROP POLICY IF EXISTS "curriculum_auth_read" ON public.curriculum_lessons;
CREATE POLICY "curriculum_auth_read" ON public.curriculum_lessons FOR SELECT USING (auth.uid() IS NOT NULL);

-- Admin/staff manage curriculum
DROP POLICY IF EXISTS "skill_areas_admin" ON public.skill_areas;
CREATE POLICY "skill_areas_admin" ON public.skill_areas      FOR ALL USING (auth.jwt()->'app_metadata'->>'role' IN ('admin', 'staff'));
DROP POLICY IF EXISTS "skills_admin" ON public.skills;
CREATE POLICY "skills_admin" ON public.skills            FOR ALL USING (auth.jwt()->'app_metadata'->>'role' IN ('admin', 'staff'));
DROP POLICY IF EXISTS "curriculum_admin" ON public.curriculum_lessons;
CREATE POLICY "curriculum_admin" ON public.curriculum_lessons FOR ALL USING (auth.jwt()->'app_metadata'->>'role' IN ('admin', 'staff'));

-- Child milestones: parent sees own children; staff sees all
DROP POLICY IF EXISTS "milestones_parent_read" ON public.child_milestones;
CREATE POLICY "milestones_parent_read" ON public.child_milestones
  FOR SELECT USING (
    child_id IN (SELECT child_id FROM public.parent_children WHERE parent_id = auth.uid())
    OR auth.jwt()->'app_metadata'->>'role' IN ('admin', 'staff')
  );

DROP POLICY IF EXISTS "milestones_staff_write" ON public.child_milestones;
CREATE POLICY "milestones_staff_write" ON public.child_milestones
  FOR ALL USING (auth.jwt()->'app_metadata'->>'role' IN ('admin', 'staff'));

DROP POLICY IF EXISTS "lesson_records_parent" ON public.child_lesson_records;
CREATE POLICY "lesson_records_parent" ON public.child_lesson_records
  FOR SELECT USING (
    child_id IN (SELECT child_id FROM public.parent_children WHERE parent_id = auth.uid())
    OR auth.jwt()->'app_metadata'->>'role' IN ('admin', 'staff')
  );

DROP POLICY IF EXISTS "lesson_records_staff" ON public.child_lesson_records;
CREATE POLICY "lesson_records_staff" ON public.child_lesson_records
  FOR ALL USING (auth.jwt()->'app_metadata'->>'role' IN ('admin', 'staff'));
