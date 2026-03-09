# 03 - Database Schema (PostgreSQL via Supabase)

## ER Diagram (high-level)

```
                        ┌─────────────┐
                        │  locations   │ (franchise support)
                        └──────┬──────┘
                               │
profiles ──< parent_children >── children ──< child_groups >── groups
   │                              │    │                         │
   │                              │    │                    group_staff
   │                              │    │
   │         ┌────────────────────┘    └────────────────┐
   │         │                                          │
   │    child_milestones ──> milestones ──> skill_areas  │
   │         │                                          │
   │    observations ──< observation_media              │
   │         │                                          │
   │    assessments                               workshops (template)
   │         │                                     │
   │    quarterly_reports                    sessions (instance)
   │                                           │
   │    home_activities                    attendance
   │
   ├── messages
   ├── notifications
   ├── subscriptions ──> subscription_plans
   ├── payments
   └── email_campaigns ──> email_recipients

blog_posts    forum_topics ──< forum_posts
resources     lead_contacts   contact_submissions
weekly_challenges ──< challenge_submissions
workshop_feedback   observation_templates
```

## TABLES

---

### SECTION 1: Users & Roles

#### 1. profiles

```sql
CREATE TABLE public.profiles (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  full_name TEXT NOT NULL,
  email TEXT,
  phone TEXT,
  role TEXT NOT NULL DEFAULT 'parent'
    CHECK (role IN ('parent', 'staff', 'admin', 'expert')),
  avatar_url TEXT,
  city TEXT,
  bio TEXT,                           -- short bio for staff/experts shown on public site
  specialization TEXT,                -- e.g. "Montessori pedagog", "Djecji psiholog"
  is_active BOOLEAN DEFAULT true,
  onboarding_completed BOOLEAN DEFAULT false,
  last_seen_at TIMESTAMPTZ,
  preferred_language TEXT DEFAULT 'bs', -- 'bs', 'en' (Phase 3 i18n)
  notification_preferences JSONB DEFAULT '{"email": true, "push": true, "sms": false}',
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_profiles_role ON public.profiles(role);

-- Auto-create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, email, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    NEW.email,
    'parent'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
```

---

### SECTION 2: Children & Relationships

#### 2. children

```sql
CREATE TABLE public.children (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  full_name TEXT NOT NULL,
  nickname TEXT,                       -- name child prefers to be called
  date_of_birth DATE NOT NULL,
  gender TEXT CHECK (gender IN ('male', 'female', 'other')),
  photo_url TEXT,
  avatar_character TEXT,               -- Khan-style: child picks mascot (pcelica, leptir, etc.)
  enrollment_date DATE DEFAULT CURRENT_DATE,
  age_group TEXT,                      -- auto-calculated or manual override
  allergies TEXT,                      -- important for workshop safety
  special_needs TEXT,                  -- any accommodations needed
  notes TEXT,                          -- internal staff notes
  is_active BOOLEAN DEFAULT true,
  location_id UUID REFERENCES public.locations(id), -- franchise support
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_children_active ON public.children(is_active) WHERE is_active = true;
CREATE INDEX idx_children_location ON public.children(location_id);
```

#### 3. parent_children (many-to-many: both parents can have access)

```sql
CREATE TABLE public.parent_children (
  parent_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  child_id UUID REFERENCES public.children(id) ON DELETE CASCADE,
  relationship TEXT DEFAULT 'parent'
    CHECK (relationship IN ('mother', 'father', 'guardian', 'grandparent', 'other')),
  is_primary BOOLEAN DEFAULT true,    -- primary contact parent
  can_pickup BOOLEAN DEFAULT true,    -- authorized to pick up child
  created_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (parent_id, child_id)
);

CREATE INDEX idx_parent_children_child ON public.parent_children(child_id);
CREATE INDEX idx_parent_children_parent ON public.parent_children(parent_id);
```

---

### SECTION 3: Locations & Groups (Franchise Support)

#### 4. locations (multi-location / franchise)

```sql
CREATE TABLE public.locations (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,                  -- "Sarena Sfera Sarajevo"
  address TEXT,
  city TEXT,
  phone TEXT,
  email TEXT,
  manager_id UUID REFERENCES public.profiles(id),
  logo_url TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);
```

#### 5. groups

```sql
CREATE TABLE public.groups (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,                  -- e.g. "Pcelice (3-4 god)"
  description TEXT,
  age_range_min INTEGER,               -- min age in months
  age_range_max INTEGER,               -- max age in months
  max_capacity INTEGER DEFAULT 12,
  schedule JSONB,                      -- structured: {"days": ["tue","thu"], "time_start": "10:00", "time_end": "11:30"}
  location_id UUID REFERENCES public.locations(id),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_groups_location ON public.groups(location_id);
```

#### 6. group_staff (many-to-many: multiple teachers per group)

```sql
CREATE TABLE public.group_staff (
  group_id UUID REFERENCES public.groups(id) ON DELETE CASCADE,
  staff_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  role TEXT DEFAULT 'lead'
    CHECK (role IN ('lead', 'assistant', 'volunteer', 'substitute')),
  assigned_at DATE DEFAULT CURRENT_DATE,
  PRIMARY KEY (group_id, staff_id)
);
```

#### 7. child_groups

```sql
CREATE TABLE public.child_groups (
  child_id UUID REFERENCES public.children(id) ON DELETE CASCADE,
  group_id UUID REFERENCES public.groups(id) ON DELETE CASCADE,
  joined_at DATE DEFAULT CURRENT_DATE,
  left_at DATE,                        -- null = still active in group
  PRIMARY KEY (child_id, group_id)
);
```

---

### SECTION 4: Curriculum & Skills (Transparent Classroom Pattern)

#### 8. skill_areas (top-level development domains)

```sql
CREATE TABLE public.skill_areas (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  key TEXT UNIQUE NOT NULL,            -- 'emotional', 'social', etc.
  name TEXT NOT NULL,                  -- 'Emotional Development'
  name_local TEXT NOT NULL,            -- 'Emocionalni razvoj'
  description TEXT,
  icon TEXT,                           -- emoji or icon name
  color TEXT,                          -- hex color for charts
  sort_order INTEGER DEFAULT 0,
  methodology TEXT                     -- 'montessori', 'ntc', 'custom', 'both'
    CHECK (methodology IN ('montessori', 'ntc', 'custom', 'both')),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Seed the 6 core domains
INSERT INTO public.skill_areas (key, name, name_local, icon, color, sort_order, methodology) VALUES
  ('emotional', 'Emotional Development', 'Emocionalni razvoj', '💛', '#F59E0B', 1, 'both'),
  ('social', 'Social Development', 'Socijalni razvoj', '🤝', '#3B82F6', 2, 'both'),
  ('creative', 'Creative Development', 'Kreativni razvoj', '🎨', '#EC4899', 3, 'both'),
  ('cognitive', 'Cognitive Development', 'Kognitivni razvoj', '🧩', '#8B5CF6', 4, 'both'),
  ('motor', 'Motor Development', 'Motoricki razvoj', '🏃', '#10B981', 5, 'both'),
  ('language', 'Language Development', 'Jezicki razvoj', '💬', '#F97316', 6, 'both');
```

#### 9. skills (hierarchical: sub-skills under each area)

```sql
CREATE TABLE public.skills (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  skill_area_id UUID REFERENCES public.skill_areas(id) NOT NULL,
  parent_skill_id UUID REFERENCES public.skills(id), -- allows nesting (sub-sub-skills)
  name TEXT NOT NULL,                  -- 'Names basic emotions'
  name_local TEXT NOT NULL,            -- 'Imenuje osnovne emocije'
  description TEXT,
  age_range_min INTEGER,               -- expected age in months (e.g. 24 = 2 years)
  age_range_max INTEGER,               -- e.g. 48 = 4 years
  sort_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_skills_area ON public.skills(skill_area_id);
CREATE INDEX idx_skills_parent ON public.skills(parent_skill_id);

-- Example skills for Emotional Development
-- INSERT INTO public.skills (skill_area_id, name, name_local, age_range_min, age_range_max) VALUES
-- ((SELECT id FROM skill_areas WHERE key='emotional'), 'Names basic emotions (happy, sad, angry)', 'Imenuje osnovne emocije (sretan, tuzan, ljut)', 24, 48),
-- ((SELECT id FROM skill_areas WHERE key='emotional'), 'Accepts frustration with support', 'Prihvata frustraciju uz podrsku', 30, 54),
-- ((SELECT id FROM skill_areas WHERE key='emotional'), 'Shows empathy towards peers', 'Pokazuje empatiju prema vrsnjacima', 36, 60),
-- etc.
```

#### 10. curriculum_lessons (Montessori Compass pattern: pre-loaded lesson catalog)

Maps specific lessons/activities to skills. A workshop can reference specific lessons.
Allows lesson-level record keeping, not just domain-level.

```sql
CREATE TABLE public.curriculum_lessons (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  skill_id UUID REFERENCES public.skills(id) NOT NULL,  -- which skill this teaches
  title TEXT NOT NULL,                 -- 'Golden Bead Introduction'
  title_local TEXT NOT NULL,           -- 'Uvod u zlatne perlice'
  description TEXT,
  methodology TEXT NOT NULL
    CHECK (methodology IN ('montessori', 'ntc', 'custom')),
  materials TEXT[],                    -- materials needed
  age_range_min INTEGER,               -- in months
  age_range_max INTEGER,
  duration_minutes INTEGER,
  instructions TEXT,                   -- how to present
  success_criteria TEXT,               -- how to know child has mastered it
  sort_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_curriculum_skill ON public.curriculum_lessons(skill_id);
CREATE INDEX idx_curriculum_method ON public.curriculum_lessons(methodology);
```

#### 11. child_lesson_records (per-child lesson status tracking)

```sql
CREATE TABLE public.child_lesson_records (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  child_id UUID REFERENCES public.children(id) ON DELETE CASCADE NOT NULL,
  lesson_id UUID REFERENCES public.curriculum_lessons(id) NOT NULL,
  status TEXT NOT NULL DEFAULT 'not_presented'
    CHECK (status IN ('not_presented', 'presented', 'practicing', 'mastered')),
  presented_at TIMESTAMPTZ,            -- when first introduced
  mastered_at TIMESTAMPTZ,             -- when mastered
  presented_by UUID REFERENCES public.profiles(id),
  attempts INTEGER DEFAULT 0,          -- how many times practiced
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(child_id, lesson_id)
);

CREATE INDEX idx_lesson_records_child ON public.child_lesson_records(child_id);
CREATE INDEX idx_lesson_records_lesson ON public.child_lesson_records(lesson_id);
CREATE INDEX idx_lesson_records_status ON public.child_lesson_records(status);
```

#### 12. child_milestones (Transparent Classroom: skill status tracking per child)

```sql
CREATE TABLE public.child_milestones (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  child_id UUID REFERENCES public.children(id) ON DELETE CASCADE NOT NULL,
  skill_id UUID REFERENCES public.skills(id) NOT NULL,
  status TEXT NOT NULL DEFAULT 'not_introduced'
    CHECK (status IN ('not_introduced', 'introduced', 'developing', 'practicing', 'mastered')),
  assessed_by UUID REFERENCES public.profiles(id),
  assessed_at TIMESTAMPTZ DEFAULT now(),
  notes TEXT,
  evidence_observation_id UUID REFERENCES public.observations(id), -- link to observation that proves this
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(child_id, skill_id)          -- one status per child per skill (latest)
);

CREATE INDEX idx_child_milestones_child ON public.child_milestones(child_id);
CREATE INDEX idx_child_milestones_skill ON public.child_milestones(skill_id);
```

#### 13. milestone_history (track status changes over time)

```sql
CREATE TABLE public.milestone_history (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  child_id UUID REFERENCES public.children(id) ON DELETE CASCADE NOT NULL,
  skill_id UUID REFERENCES public.skills(id) NOT NULL,
  old_status TEXT,
  new_status TEXT NOT NULL,
  changed_by UUID REFERENCES public.profiles(id),
  changed_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_milestone_history_child ON public.milestone_history(child_id, changed_at DESC);
```

---

### SECTION 5: Workshops & Sessions

#### 12. workshops (TEMPLATE - reusable across groups and locations)

```sql
CREATE TABLE public.workshops (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  month_number INTEGER CHECK (month_number BETWEEN 1 AND 12),
  workshop_number INTEGER CHECK (workshop_number BETWEEN 1 AND 12),
  domains TEXT[] NOT NULL,             -- can target multiple domains: ['emotional', 'social']
  target_skills UUID[],                -- specific skills this workshop aims to develop
  objectives TEXT[],                   -- learning objectives
  materials_needed TEXT[],             -- list of materials
  preparation_checklist JSONB,         -- [{"item": "Prepare paint stations", "done": false}, ...]
  duration_minutes INTEGER DEFAULT 90,
  home_activity_title TEXT,
  home_activity_description TEXT,
  home_activity_materials TEXT[],
  home_activity_pdf_url TEXT,
  methodology TEXT                     -- 'montessori', 'ntc', 'mixed'
    CHECK (methodology IN ('montessori', 'ntc', 'mixed')),
  methodology_notes TEXT,
  age_group_recommendation TEXT,       -- e.g. "3-4 years"
  difficulty_level INTEGER DEFAULT 1 CHECK (difficulty_level BETWEEN 1 AND 3),
  cover_image_url TEXT,
  is_published BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_workshops_month ON public.workshops(month_number);
```

#### 13. sessions (INSTANCE - specific delivery of a workshop to a group)

```sql
CREATE TABLE public.sessions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  workshop_id UUID REFERENCES public.workshops(id) NOT NULL,
  group_id UUID REFERENCES public.groups(id) NOT NULL,
  location_id UUID REFERENCES public.locations(id),
  scheduled_date DATE NOT NULL,
  scheduled_time_start TIME,
  scheduled_time_end TIME,
  actual_date DATE,                    -- may differ from scheduled
  staff_id UUID REFERENCES public.profiles(id), -- lead teacher for this session
  status TEXT DEFAULT 'scheduled'
    CHECK (status IN ('scheduled', 'in_progress', 'completed', 'cancelled', 'postponed')),
  staff_notes TEXT,                    -- private notes about how it went
  summary_for_parents TEXT,            -- public summary sent to parents
  summary_sent BOOLEAN DEFAULT false,
  cancelled_reason TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_sessions_group_date ON public.sessions(group_id, scheduled_date);
CREATE INDEX idx_sessions_date ON public.sessions(scheduled_date);
CREATE INDEX idx_sessions_workshop ON public.sessions(workshop_id);
```

#### 14. workshop_materials (files/resources attached to workshops)

```sql
CREATE TABLE public.workshop_materials (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  workshop_id UUID REFERENCES public.workshops(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  file_url TEXT NOT NULL,              -- Supabase Storage path
  file_type TEXT NOT NULL              -- 'pdf', 'video', 'audio', 'image', 'link'
    CHECK (file_type IN ('pdf', 'video', 'audio', 'image', 'link', 'document')),
  is_for_parents BOOLEAN DEFAULT false, -- if true, parents can see it
  is_for_staff BOOLEAN DEFAULT true,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_workshop_materials_workshop ON public.workshop_materials(workshop_id);
```

---

### SECTION 6: Attendance & Observations

#### 15. attendance

```sql
CREATE TABLE public.attendance (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  session_id UUID REFERENCES public.sessions(id) ON DELETE CASCADE NOT NULL,
  child_id UUID REFERENCES public.children(id) ON DELETE CASCADE NOT NULL,
  status TEXT DEFAULT 'present'
    CHECK (status IN ('present', 'absent', 'late', 'left_early', 'excused')),
  participation_level TEXT
    CHECK (participation_level IN ('observed', 'partial', 'full', 'exceptional')),
  arrived_at TIME,
  left_at TIME,
  recorded_by UUID REFERENCES public.profiles(id),
  parent_notified BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(session_id, child_id)
);

CREATE INDEX idx_attendance_child ON public.attendance(child_id);
CREATE INDEX idx_attendance_session ON public.attendance(session_id);
```

#### 16. observations

```sql
CREATE TABLE public.observations (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  child_id UUID REFERENCES public.children(id) ON DELETE CASCADE NOT NULL,
  session_id UUID REFERENCES public.sessions(id),   -- null for ad-hoc observations
  staff_id UUID REFERENCES public.profiles(id) NOT NULL,
  content TEXT NOT NULL,
  skill_area_id UUID REFERENCES public.skill_areas(id), -- primary domain
  tagged_skills UUID[],                -- specific skills this observation relates to
  observation_type TEXT DEFAULT 'workshop'
    CHECK (observation_type IN ('workshop', 'adhoc', 'milestone', 'concern', 'positive')),
  is_visible_to_parent BOOLEAN DEFAULT true,
  is_highlighted BOOLEAN DEFAULT false, -- staff can highlight important observations
  template_id UUID REFERENCES public.observation_templates(id), -- which template was used
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_observations_child ON public.observations(child_id, created_at DESC);
CREATE INDEX idx_observations_session ON public.observations(session_id);
CREATE INDEX idx_observations_area ON public.observations(skill_area_id);
CREATE INDEX idx_observations_type ON public.observations(observation_type);
```

#### 17. observation_media (multiple media per observation)

```sql
CREATE TABLE public.observation_media (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  observation_id UUID REFERENCES public.observations(id) ON DELETE CASCADE NOT NULL,
  file_url TEXT NOT NULL,              -- Supabase Storage path
  file_type TEXT NOT NULL
    CHECK (file_type IN ('photo', 'video', 'audio', 'document')),
  caption TEXT,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_observation_media_obs ON public.observation_media(observation_id);
```

#### 18. observation_templates (pre-built snippets for fast entry)

```sql
CREATE TABLE public.observation_templates (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  skill_area_id UUID REFERENCES public.skill_areas(id) NOT NULL,
  content TEXT NOT NULL,               -- "Named the emotion of {emotion} independently"
  has_placeholder BOOLEAN DEFAULT false, -- if true, contains {placeholders}
  usage_count INTEGER DEFAULT 0,       -- track popularity
  created_by UUID REFERENCES public.profiles(id),
  is_system BOOLEAN DEFAULT true,      -- system-provided vs user-created
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_obs_templates_area ON public.observation_templates(skill_area_id);
```

---

### SECTION 7: Assessments & Reports

#### 19. assessments (domain scores 1-5 per quarter)

```sql
CREATE TABLE public.assessments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  child_id UUID REFERENCES public.children(id) ON DELETE CASCADE NOT NULL,
  staff_id UUID REFERENCES public.profiles(id) NOT NULL,
  skill_area_id UUID REFERENCES public.skill_areas(id) NOT NULL,
  score INTEGER NOT NULL CHECK (score BETWEEN 1 AND 5),
  period TEXT NOT NULL,                -- "2026-Q1"
  evidence_notes TEXT,                 -- justification for the score
  observation_ids UUID[],              -- linked observations that support this score
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(child_id, skill_area_id, period)
);

CREATE INDEX idx_assessments_child_period ON public.assessments(child_id, period);
```

#### 20. quarterly_reports

```sql
CREATE TABLE public.quarterly_reports (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  child_id UUID REFERENCES public.children(id) ON DELETE CASCADE NOT NULL,
  period TEXT NOT NULL,                -- "2026-Q1"
  status TEXT DEFAULT 'draft'
    CHECK (status IN ('draft', 'review', 'published', 'archived')),
  pdf_url TEXT,
  -- Cached/computed data for the report:
  domain_scores JSONB,                 -- {"emotional": 4, "social": 3, ...}
  attendance_total INTEGER,
  attendance_present INTEGER,
  attendance_percentage NUMERIC(5,2),
  strengths TEXT[],
  areas_to_improve TEXT[],
  recommendations TEXT,
  staff_narrative TEXT,                 -- free-form teacher commentary
  -- Report workflow:
  generated_by UUID REFERENCES public.profiles(id),
  reviewed_by UUID REFERENCES public.profiles(id),
  published_by UUID REFERENCES public.profiles(id),
  published_at TIMESTAMPTZ,
  parent_viewed_at TIMESTAMPTZ,        -- track if parent has seen it
  parent_acknowledged BOOLEAN DEFAULT false, -- parent signs off
  generated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(child_id, period)
);

CREATE INDEX idx_reports_child ON public.quarterly_reports(child_id);
CREATE INDEX idx_reports_status ON public.quarterly_reports(status);
```

---

### SECTION 8: Home Activities & Parent Engagement

#### 21. home_activities

```sql
CREATE TABLE public.home_activities (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  session_id UUID REFERENCES public.sessions(id),
  workshop_id UUID REFERENCES public.workshops(id),
  child_id UUID REFERENCES public.children(id) ON DELETE CASCADE NOT NULL,
  parent_id UUID REFERENCES public.profiles(id) NOT NULL,
  assigned_at TIMESTAMPTZ DEFAULT now(),
  completed BOOLEAN DEFAULT false,
  completed_at TIMESTAMPTZ,
  difficulty_rating INTEGER CHECK (difficulty_rating BETWEEN 1 AND 5), -- parent rates
  enjoyment_rating INTEGER CHECK (enjoyment_rating BETWEEN 1 AND 5), -- how much child enjoyed
  parent_comment TEXT,
  time_spent_minutes INTEGER,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_home_activities_child ON public.home_activities(child_id);
CREATE INDEX idx_home_activities_parent ON public.home_activities(parent_id);
```

#### 22. home_activity_media (photos/videos from home activities)

```sql
CREATE TABLE public.home_activity_media (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  home_activity_id UUID REFERENCES public.home_activities(id) ON DELETE CASCADE NOT NULL,
  file_url TEXT NOT NULL,
  file_type TEXT CHECK (file_type IN ('photo', 'video')),
  caption TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);
```

#### 23. weekly_challenges (family challenges)

```sql
CREATE TABLE public.weekly_challenges (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  week_start DATE NOT NULL,
  week_end DATE NOT NULL,
  skill_area_id UUID REFERENCES public.skill_areas(id),
  difficulty TEXT CHECK (difficulty IN ('easy', 'medium', 'hard')),
  cover_image_url TEXT,
  points INTEGER DEFAULT 10,           -- gamification points
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_challenges_active ON public.weekly_challenges(is_active, week_start);
```

#### 24. challenge_submissions

```sql
CREATE TABLE public.challenge_submissions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  challenge_id UUID REFERENCES public.weekly_challenges(id) ON DELETE CASCADE NOT NULL,
  child_id UUID REFERENCES public.children(id) ON DELETE CASCADE NOT NULL,
  parent_id UUID REFERENCES public.profiles(id) NOT NULL,
  comment TEXT,
  photo_url TEXT,
  submitted_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(challenge_id, child_id)
);
```

#### 25. workshop_feedback (parent rates workshops)

```sql
CREATE TABLE public.workshop_feedback (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  session_id UUID REFERENCES public.sessions(id) ON DELETE CASCADE NOT NULL,
  parent_id UUID REFERENCES public.profiles(id) NOT NULL,
  child_id UUID REFERENCES public.children(id),
  overall_rating INTEGER NOT NULL CHECK (overall_rating BETWEEN 1 AND 5),
  child_enjoyed BOOLEAN,
  comment TEXT,
  would_recommend BOOLEAN,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(session_id, parent_id)
);

CREATE INDEX idx_feedback_session ON public.workshop_feedback(session_id);
```

---

### SECTION 9: Communication

#### 26. messages (staff <-> parent, group broadcasts)

```sql
CREATE TABLE public.messages (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  sender_id UUID REFERENCES public.profiles(id) NOT NULL,
  recipient_id UUID REFERENCES public.profiles(id), -- null for group messages
  group_id UUID REFERENCES public.groups(id),        -- if group broadcast
  child_id UUID REFERENCES public.children(id),      -- if about a specific child
  subject TEXT,
  content TEXT NOT NULL,
  message_type TEXT DEFAULT 'direct'
    CHECK (message_type IN ('direct', 'group_broadcast', 'workshop_summary', 'system')),
  is_read BOOLEAN DEFAULT false,
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_messages_recipient ON public.messages(recipient_id, is_read, created_at DESC);
CREATE INDEX idx_messages_group ON public.messages(group_id, created_at DESC);
CREATE INDEX idx_messages_sender ON public.messages(sender_id, created_at DESC);
```

#### 27. notifications

```sql
CREATE TABLE public.notifications (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) NOT NULL,
  title TEXT NOT NULL,
  body TEXT,
  type TEXT NOT NULL
    CHECK (type IN (
      'observation_new', 'report_published', 'workshop_reminder',
      'workshop_summary', 'message_new', 'home_activity_assigned',
      'challenge_new', 'child_milestone', 'attendance_alert',
      'payment_due', 'system', 'welcome'
    )),
  action_url TEXT,                     -- link to relevant page
  data JSONB DEFAULT '{}',             -- extra context data
  is_read BOOLEAN DEFAULT false,
  read_at TIMESTAMPTZ,
  delivered_via TEXT[],                -- ['in_app', 'email', 'push']
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_notifications_user ON public.notifications(user_id, is_read, created_at DESC);
```

---

### SECTION 10: Community & Forum

#### 28. forum_categories

```sql
CREATE TABLE public.forum_categories (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  name_local TEXT NOT NULL,
  description TEXT,
  slug TEXT UNIQUE NOT NULL,
  icon TEXT,
  sort_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Seed categories
-- INSERT INTO forum_categories (name, name_local, slug, sort_order) VALUES
-- ('General Discussion', 'Opsta diskusija', 'general', 1),
-- ('Ages 2-3', 'Uzrast 2-3 godine', 'ages-2-3', 2),
-- ('Ages 3-4', 'Uzrast 3-4 godine', 'ages-3-4', 3),
-- ('Ages 4-5', 'Uzrast 4-5 godina', 'ages-4-5', 4),
-- ('Home Activities', 'Kucne aktivnosti', 'home-activities', 5),
-- ('Ask an Expert', 'Pitaj strucnjaka', 'ask-expert', 6);
```

#### 29. forum_topics

```sql
CREATE TABLE public.forum_topics (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  category_id UUID REFERENCES public.forum_categories(id) NOT NULL,
  author_id UUID REFERENCES public.profiles(id) NOT NULL,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  is_pinned BOOLEAN DEFAULT false,
  is_locked BOOLEAN DEFAULT false,
  view_count INTEGER DEFAULT 0,
  reply_count INTEGER DEFAULT 0,       -- denormalized for performance
  last_reply_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_forum_topics_category ON public.forum_topics(category_id, is_pinned DESC, last_reply_at DESC);
```

#### 30. forum_posts (replies)

```sql
CREATE TABLE public.forum_posts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  topic_id UUID REFERENCES public.forum_topics(id) ON DELETE CASCADE NOT NULL,
  author_id UUID REFERENCES public.profiles(id) NOT NULL,
  content TEXT NOT NULL,
  is_expert_answer BOOLEAN DEFAULT false, -- highlighted if from expert/staff
  parent_post_id UUID REFERENCES public.forum_posts(id), -- threaded replies
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_forum_posts_topic ON public.forum_posts(topic_id, created_at);
```

---

### SECTION 11: Content & Resources

#### 31. resources (media library: videos, PDFs, audio)

```sql
CREATE TABLE public.resources (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  file_url TEXT NOT NULL,
  file_type TEXT NOT NULL
    CHECK (file_type IN ('pdf', 'video', 'audio', 'image', 'link', 'worksheet')),
  thumbnail_url TEXT,
  skill_area_id UUID REFERENCES public.skill_areas(id),
  category TEXT                        -- 'tutorial', 'worksheet', 'story', 'guide', 'visualization'
    CHECK (category IN ('tutorial', 'worksheet', 'story', 'guide', 'visualization', 'song', 'other')),
  age_group TEXT,                      -- recommended age group
  duration_seconds INTEGER,            -- for video/audio
  is_free BOOLEAN DEFAULT false,       -- available without subscription (lead magnet)
  is_published BOOLEAN DEFAULT false,
  download_count INTEGER DEFAULT 0,
  view_count INTEGER DEFAULT 0,
  required_plan TEXT DEFAULT 'free'     -- minimum plan to access
    CHECK (required_plan IN ('free', 'basic', 'premium')),
  tags TEXT[],
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_resources_type ON public.resources(file_type, is_published);
CREATE INDEX idx_resources_free ON public.resources(is_free) WHERE is_free = true;
CREATE INDEX idx_resources_area ON public.resources(skill_area_id);
```

#### 32. blog_posts

```sql
CREATE TABLE public.blog_posts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  content TEXT NOT NULL,
  excerpt TEXT,
  cover_image_url TEXT,
  author_id UUID REFERENCES public.profiles(id),
  category TEXT,
  tags TEXT[],
  skill_area_id UUID REFERENCES public.skill_areas(id), -- related domain
  reading_time_minutes INTEGER,
  is_published BOOLEAN DEFAULT false,
  is_featured BOOLEAN DEFAULT false,
  view_count INTEGER DEFAULT 0,
  published_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_blog_published ON public.blog_posts(is_published, published_at DESC);
CREATE INDEX idx_blog_slug ON public.blog_posts(slug);
```

---

### SECTION 12: Subscriptions & Payments

#### 33. subscription_plans

```sql
CREATE TABLE public.subscription_plans (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  key TEXT UNIQUE NOT NULL,            -- 'free', 'basic', 'premium', 'institution'
  name TEXT NOT NULL,
  name_local TEXT NOT NULL,
  price_km NUMERIC(10,2) NOT NULL,     -- monthly price in KM
  price_yearly_km NUMERIC(10,2),       -- yearly price (discounted)
  features JSONB NOT NULL,             -- {"max_children": 5, "video_access": true, ...}
  max_children INTEGER DEFAULT 1,
  is_active BOOLEAN DEFAULT true,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Seed plans
INSERT INTO public.subscription_plans (key, name, name_local, price_km, features, max_children, sort_order) VALUES
  ('free', 'Free', 'Besplatni', 0, '{"blog": true, "resources_limit": 3, "community": false}', 1, 1),
  ('basic', 'Basic', 'Osnovni', 15, '{"blog": true, "passport": true, "materials": true, "community": false}', 3, 2),
  ('premium', 'Premium', 'Premium', 30, '{"blog": true, "passport": true, "materials": true, "videos": true, "community": true, "expert_access": true}', 5, 3),
  ('institution', 'Institution', 'Institucija', 200, '{"blog": true, "passport": true, "materials": true, "videos": true, "community": true, "expert_access": true, "analytics": true}', 50, 4);
```

#### 34. subscriptions

```sql
CREATE TABLE public.subscriptions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  profile_id UUID REFERENCES public.profiles(id) NOT NULL,
  plan_id UUID REFERENCES public.subscription_plans(id) NOT NULL,
  status TEXT DEFAULT 'active'
    CHECK (status IN ('active', 'cancelled', 'expired', 'trial', 'past_due', 'paused')),
  billing_interval TEXT DEFAULT 'monthly'
    CHECK (billing_interval IN ('monthly', 'yearly')),
  trial_ends_at TIMESTAMPTZ,
  current_period_start TIMESTAMPTZ DEFAULT now(),
  current_period_end TIMESTAMPTZ,
  cancelled_at TIMESTAMPTZ,
  cancel_reason TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_subscriptions_profile ON public.subscriptions(profile_id);
CREATE INDEX idx_subscriptions_status ON public.subscriptions(status);
```

#### 35. payments

```sql
CREATE TABLE public.payments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  profile_id UUID REFERENCES public.profiles(id) NOT NULL,
  subscription_id UUID REFERENCES public.subscriptions(id),
  amount_km NUMERIC(10,2) NOT NULL,
  payment_method TEXT
    CHECK (payment_method IN ('card', 'bank_transfer', 'cash', 'other')),
  status TEXT DEFAULT 'pending'
    CHECK (status IN ('pending', 'completed', 'failed', 'refunded', 'cancelled')),
  description TEXT,                    -- "Premium plan - March 2026"
  invoice_number TEXT,
  receipt_url TEXT,
  external_payment_id TEXT,            -- Stripe or other provider ID
  paid_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_payments_profile ON public.payments(profile_id, created_at DESC);
CREATE INDEX idx_payments_status ON public.payments(status);
```

---

### SECTION 13: Marketing & Lead Generation

#### 36. lead_contacts

```sql
CREATE TABLE public.lead_contacts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  email TEXT NOT NULL,
  full_name TEXT,
  phone TEXT,
  source TEXT NOT NULL                 -- how they found us
    CHECK (source IN ('free_resource', 'newsletter', 'contact_form', 'assessment',
                      'referral', 'social_media', 'blog', 'event', 'other')),
  resource_downloaded TEXT,            -- which lead magnet
  utm_source TEXT,
  utm_medium TEXT,
  utm_campaign TEXT,
  subscribed_to_newsletter BOOLEAN DEFAULT false,
  converted_to_user BOOLEAN DEFAULT false,
  converted_at TIMESTAMPTZ,
  tags TEXT[],
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_leads_email ON public.lead_contacts(email);
CREATE INDEX idx_leads_source ON public.lead_contacts(source);
```

#### 37. contact_submissions (contact form)

```sql
CREATE TABLE public.contact_submissions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT NOT NULL,
  phone TEXT,
  subject TEXT,
  message TEXT NOT NULL,
  status TEXT DEFAULT 'new'
    CHECK (status IN ('new', 'read', 'replied', 'archived')),
  replied_by UUID REFERENCES public.profiles(id),
  replied_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now()
);
```

#### 38. email_campaigns

```sql
CREATE TABLE public.email_campaigns (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  subject TEXT NOT NULL,
  content_html TEXT NOT NULL,
  content_text TEXT,
  sender_name TEXT DEFAULT 'Sarena Sfera',
  target_audience TEXT NOT NULL         -- who receives
    CHECK (target_audience IN ('all_parents', 'all_leads', 'premium_parents',
                               'inactive_parents', 'specific_group', 'custom')),
  target_group_id UUID REFERENCES public.groups(id), -- if specific_group
  status TEXT DEFAULT 'draft'
    CHECK (status IN ('draft', 'scheduled', 'sending', 'sent', 'cancelled')),
  scheduled_at TIMESTAMPTZ,
  sent_at TIMESTAMPTZ,
  total_recipients INTEGER DEFAULT 0,
  total_opened INTEGER DEFAULT 0,
  total_clicked INTEGER DEFAULT 0,
  created_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ DEFAULT now()
);
```

#### 39. email_campaign_recipients

```sql
CREATE TABLE public.email_campaign_recipients (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  campaign_id UUID REFERENCES public.email_campaigns(id) ON DELETE CASCADE NOT NULL,
  email TEXT NOT NULL,
  profile_id UUID REFERENCES public.profiles(id),
  status TEXT DEFAULT 'pending'
    CHECK (status IN ('pending', 'sent', 'delivered', 'opened', 'clicked', 'bounced', 'unsubscribed')),
  sent_at TIMESTAMPTZ,
  opened_at TIMESTAMPTZ,
  clicked_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_campaign_recipients ON public.email_campaign_recipients(campaign_id);
```

---

### SECTION 14: Activity Log

#### 40. activity_log (audit trail)

```sql
CREATE TABLE public.activity_log (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id),
  action TEXT NOT NULL,                -- 'observation.created', 'child.enrolled', etc.
  entity_type TEXT NOT NULL,           -- 'observation', 'child', 'session', etc.
  entity_id UUID,
  metadata JSONB DEFAULT '{}',         -- extra context
  ip_address INET,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_activity_log_user ON public.activity_log(user_id, created_at DESC);
CREATE INDEX idx_activity_log_entity ON public.activity_log(entity_type, entity_id);

-- Auto-cleanup: keep last 90 days
-- (set up as pg_cron job or Python cron)
```

---

### SECTION 15: Daily Routine Tracking (Brightwheel/Tadpoles/Lillio pattern)

All childcare competitors track daily routines. This is what parents check most often.

#### 41. daily_logs (per child per day - staff AND parents can track)

Parents can also create daily logs for home tracking (meals, naps, mood).
This creates a complete picture: workshop days tracked by staff, home days by parents.

```sql
CREATE TABLE public.daily_logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  child_id UUID REFERENCES public.children(id) ON DELETE CASCADE NOT NULL,
  session_id UUID REFERENCES public.sessions(id),  -- optional, links to workshop session
  log_date DATE NOT NULL DEFAULT CURRENT_DATE,
  recorded_by UUID REFERENCES public.profiles(id) NOT NULL,
  log_source TEXT NOT NULL DEFAULT 'staff'
    CHECK (log_source IN ('staff', 'parent')),    -- who created: staff at workshop or parent at home
  general_mood TEXT
    CHECK (general_mood IN ('happy', 'calm', 'tired', 'fussy', 'sick', 'energetic')),
  general_notes TEXT,
  sent_to_parents BOOLEAN DEFAULT false,  -- for staff logs: was it shared?
  sent_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(child_id, log_date, log_source) -- one per source per day (staff + parent can both log)
);

CREATE INDEX idx_daily_logs_child ON public.daily_logs(child_id, log_date DESC);
```

#### 42. daily_log_meals

```sql
CREATE TABLE public.daily_log_meals (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  daily_log_id UUID REFERENCES public.daily_logs(id) ON DELETE CASCADE NOT NULL,
  meal_type TEXT NOT NULL
    CHECK (meal_type IN ('breakfast', 'morning_snack', 'lunch', 'afternoon_snack', 'dinner', 'other')),
  time_at TIME,
  food_items TEXT,                     -- what was offered
  amount_eaten TEXT
    CHECK (amount_eaten IN ('none', 'little', 'half', 'most', 'all')),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_meals_log ON public.daily_log_meals(daily_log_id);
```

#### 43. daily_log_naps

```sql
CREATE TABLE public.daily_log_naps (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  daily_log_id UUID REFERENCES public.daily_logs(id) ON DELETE CASCADE NOT NULL,
  started_at TIME,
  ended_at TIME,
  duration_minutes INTEGER,
  quality TEXT CHECK (quality IN ('restless', 'fair', 'good', 'deep')),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_naps_log ON public.daily_log_naps(daily_log_id);
```

#### 44. daily_log_toileting (diapers/potty for younger children)

```sql
CREATE TABLE public.daily_log_toileting (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  daily_log_id UUID REFERENCES public.daily_logs(id) ON DELETE CASCADE NOT NULL,
  time_at TIME,
  type TEXT NOT NULL
    CHECK (type IN ('wet_diaper', 'soiled_diaper', 'potty_success', 'potty_attempt', 'accident')),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_toileting_log ON public.daily_log_toileting(daily_log_id);
```

#### 45. daily_log_activities (custom trackable items per day)

```sql
CREATE TABLE public.daily_log_activities (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  daily_log_id UUID REFERENCES public.daily_logs(id) ON DELETE CASCADE NOT NULL,
  activity_type TEXT NOT NULL,         -- 'outdoor_play', 'art', 'reading', 'music', 'sensory', 'free_play', custom
  duration_minutes INTEGER,
  engagement_level TEXT
    CHECK (engagement_level IN ('low', 'medium', 'high', 'exceptional')),
  notes TEXT,
  photo_url TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_activities_log ON public.daily_log_activities(daily_log_id);
```

#### 46. daily_log_photos (quick photos during the day, shared with parents)

```sql
CREATE TABLE public.daily_log_photos (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  daily_log_id UUID REFERENCES public.daily_logs(id) ON DELETE CASCADE NOT NULL,
  file_url TEXT NOT NULL,
  caption TEXT,
  taken_at TIME,
  is_shared_with_parent BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_daily_photos_log ON public.daily_log_photos(daily_log_id);
```

---

### SECTION 16: Check-In/Check-Out & Safety (Brightwheel/Procare pattern)

#### 47. check_ins (digital sign-in/sign-out)

```sql
CREATE TABLE public.check_ins (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  child_id UUID REFERENCES public.children(id) ON DELETE CASCADE NOT NULL,
  session_id UUID REFERENCES public.sessions(id),
  check_in_at TIMESTAMPTZ NOT NULL,
  check_in_by UUID REFERENCES public.profiles(id),  -- who dropped off
  check_in_method TEXT DEFAULT 'manual'
    CHECK (check_in_method IN ('manual', 'qr_code', 'pin', 'parent_app')),
  check_out_at TIMESTAMPTZ,
  check_out_by UUID REFERENCES public.profiles(id),  -- who picked up
  check_out_method TEXT
    CHECK (check_out_method IN ('manual', 'qr_code', 'pin', 'parent_app')),
  notes TEXT,                          -- e.g. "Didn't sleep well last night"
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_checkins_child ON public.check_ins(child_id, check_in_at DESC);
CREATE INDEX idx_checkins_date ON public.check_ins(check_in_at::DATE);
```

#### 48. authorized_pickups (who can pick up a child besides parents)

```sql
CREATE TABLE public.authorized_pickups (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  child_id UUID REFERENCES public.children(id) ON DELETE CASCADE NOT NULL,
  full_name TEXT NOT NULL,
  relationship TEXT NOT NULL,          -- 'grandmother', 'uncle', 'nanny', 'family friend'
  phone TEXT NOT NULL,
  photo_url TEXT,                      -- photo ID for verification
  id_document_number TEXT,
  is_permanent BOOLEAN DEFAULT true,   -- false = one-time authorization
  valid_until DATE,                    -- null = permanent
  authorized_by UUID REFERENCES public.profiles(id) NOT NULL, -- which parent authorized
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_authorized_pickups_child ON public.authorized_pickups(child_id);
```

---

### SECTION 17: Safety & Workshop-Relevant Info

We only track health info that's relevant for running workshops safely.
No full medical records - just allergies, dietary needs, and special requirements.

The `children` table already has `allergies` and `special_needs` fields.
This section adds incident reporting and emergency contacts.

#### 49. incident_reports (accidents/injuries during workshops)

```sql
CREATE TABLE public.incident_reports (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  child_id UUID REFERENCES public.children(id) ON DELETE CASCADE NOT NULL,
  session_id UUID REFERENCES public.sessions(id),
  reported_by UUID REFERENCES public.profiles(id) NOT NULL,
  incident_date DATE NOT NULL,
  incident_time TIME,
  incident_type TEXT NOT NULL
    CHECK (incident_type IN ('injury', 'accident', 'illness', 'behavioral', 'allergic_reaction', 'bite', 'fall', 'other')),
  severity TEXT NOT NULL
    CHECK (severity IN ('minor', 'moderate', 'serious', 'emergency')),
  location TEXT,                       -- 'playground', 'classroom', 'bathroom', etc.
  description TEXT NOT NULL,
  action_taken TEXT NOT NULL,
  witnesses TEXT[],                    -- names of witnesses
  first_aid_applied BOOLEAN DEFAULT false,
  first_aid_details TEXT,
  medical_attention_needed BOOLEAN DEFAULT false,
  medical_details TEXT,
  photo_urls TEXT[],
  -- Parent notification workflow
  parent_notified BOOLEAN DEFAULT false,
  parent_notified_at TIMESTAMPTZ,
  parent_notified_by UUID REFERENCES public.profiles(id),
  parent_acknowledged BOOLEAN DEFAULT false,
  parent_acknowledged_at TIMESTAMPTZ,
  parent_signature_url TEXT,           -- digital signature image
  -- Admin review
  reviewed_by UUID REFERENCES public.profiles(id),
  reviewed_at TIMESTAMPTZ,
  follow_up_needed BOOLEAN DEFAULT false,
  follow_up_notes TEXT,
  status TEXT DEFAULT 'open'
    CHECK (status IN ('open', 'parent_notified', 'acknowledged', 'reviewed', 'closed')),
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_incidents_child ON public.incident_reports(child_id, incident_date DESC);
CREATE INDEX idx_incidents_status ON public.incident_reports(status);
CREATE INDEX idx_incidents_severity ON public.incident_reports(severity);
```

#### 50. emergency_contacts (beyond parents)

```sql
CREATE TABLE public.emergency_contacts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  child_id UUID REFERENCES public.children(id) ON DELETE CASCADE NOT NULL,
  full_name TEXT NOT NULL,
  relationship TEXT NOT NULL,          -- 'grandmother', 'uncle', 'neighbor', etc.
  phone_primary TEXT NOT NULL,
  phone_secondary TEXT,
  email TEXT,
  priority_order INTEGER DEFAULT 1,    -- 1 = first to call
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_emergency_contacts_child ON public.emergency_contacts(child_id, priority_order);
```

---

### SECTION 18: Staff Management (Brightwheel/Procare pattern)

#### 51. staff_schedules

```sql
CREATE TABLE public.staff_schedules (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  staff_id UUID REFERENCES public.profiles(id) NOT NULL,
  location_id UUID REFERENCES public.locations(id),
  schedule_date DATE NOT NULL,
  shift_start TIME NOT NULL,
  shift_end TIME NOT NULL,
  group_id UUID REFERENCES public.groups(id),  -- assigned room/group
  role_for_day TEXT DEFAULT 'lead'
    CHECK (role_for_day IN ('lead', 'assistant', 'float', 'substitute', 'admin')),
  status TEXT DEFAULT 'scheduled'
    CHECK (status IN ('scheduled', 'confirmed', 'completed', 'absent', 'cancelled')),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(staff_id, schedule_date)
);

CREATE INDEX idx_staff_schedules_date ON public.staff_schedules(schedule_date);
CREATE INDEX idx_staff_schedules_staff ON public.staff_schedules(staff_id, schedule_date);
```

#### 52. staff_time_entries (actual clock in/out)

```sql
CREATE TABLE public.staff_time_entries (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  staff_id UUID REFERENCES public.profiles(id) NOT NULL,
  location_id UUID REFERENCES public.locations(id),
  clock_in TIMESTAMPTZ NOT NULL,
  clock_out TIMESTAMPTZ,
  total_hours NUMERIC(5,2),            -- auto-calculated
  break_minutes INTEGER DEFAULT 0,
  notes TEXT,
  approved_by UUID REFERENCES public.profiles(id),
  approved_at TIMESTAMPTZ,
  status TEXT DEFAULT 'pending'
    CHECK (status IN ('pending', 'approved', 'rejected', 'adjusted')),
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_time_entries_staff ON public.staff_time_entries(staff_id, clock_in DESC);
```

#### 53. room_ratios (staff-to-child ratio compliance tracking)

```sql
CREATE TABLE public.room_ratios (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  group_id UUID REFERENCES public.groups(id) NOT NULL,
  location_id UUID REFERENCES public.locations(id),
  recorded_at TIMESTAMPTZ DEFAULT now(),
  children_count INTEGER NOT NULL,
  staff_count INTEGER NOT NULL,
  ratio_compliant BOOLEAN NOT NULL,    -- auto-check against age group rules
  required_ratio TEXT,                 -- e.g. "1:4" for infants, "1:8" for 3-4yr
  actual_ratio TEXT,                   -- calculated
  alert_sent BOOLEAN DEFAULT false,
  recorded_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_ratios_group ON public.room_ratios(group_id, recorded_at DESC);
```

---

### SECTION 19: Enrollment Pipeline & CRM (LineLeader/Brightwheel pattern)

#### 54. enrollment_inquiries (lead -> tour -> enroll pipeline)

```sql
CREATE TABLE public.enrollment_inquiries (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  -- Contact info
  parent_name TEXT NOT NULL,
  parent_email TEXT NOT NULL,
  parent_phone TEXT,
  -- Child info
  child_name TEXT,
  child_date_of_birth DATE,
  child_age_at_inquiry TEXT,           -- calculated or entered
  -- Inquiry details
  location_id UUID REFERENCES public.locations(id),
  preferred_start_date DATE,
  preferred_schedule TEXT,             -- 'full_time', 'part_time', 'specific_days'
  how_heard_about_us TEXT,             -- 'google', 'instagram', 'friend', 'event', etc.
  message TEXT,
  -- Pipeline tracking
  stage TEXT DEFAULT 'inquiry'
    CHECK (stage IN ('inquiry', 'tour_scheduled', 'tour_completed', 'application_sent',
                     'application_received', 'waitlisted', 'offered', 'enrolled', 'lost')),
  lead_score INTEGER DEFAULT 0,        -- 0-100 engagement score
  -- Tour scheduling
  tour_scheduled_at TIMESTAMPTZ,
  tour_completed_at TIMESTAMPTZ,
  tour_notes TEXT,
  tour_conducted_by UUID REFERENCES public.profiles(id),
  -- Follow-up
  last_contacted_at TIMESTAMPTZ,
  next_follow_up_at TIMESTAMPTZ,
  follow_up_count INTEGER DEFAULT 0,
  -- Conversion
  lost_reason TEXT,                    -- if stage = 'lost': 'too_expensive', 'chose_other', 'moved', etc.
  converted_child_id UUID REFERENCES public.children(id), -- if enrolled
  assigned_to UUID REFERENCES public.profiles(id), -- staff member managing this lead
  tags TEXT[],
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_inquiries_stage ON public.enrollment_inquiries(stage);
CREATE INDEX idx_inquiries_email ON public.enrollment_inquiries(parent_email);
CREATE INDEX idx_inquiries_followup ON public.enrollment_inquiries(next_follow_up_at)
  WHERE stage NOT IN ('enrolled', 'lost');
```

#### 55. waitlist

```sql
CREATE TABLE public.waitlist (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  inquiry_id UUID REFERENCES public.enrollment_inquiries(id),
  parent_name TEXT NOT NULL,
  parent_email TEXT NOT NULL,
  parent_phone TEXT,
  child_name TEXT NOT NULL,
  child_date_of_birth DATE,
  preferred_group_id UUID REFERENCES public.groups(id),
  location_id UUID REFERENCES public.locations(id),
  preferred_start_date DATE,
  position INTEGER,                    -- position in waitlist queue
  priority TEXT DEFAULT 'normal'
    CHECK (priority IN ('normal', 'sibling', 'staff_child', 'returning', 'high')),
  status TEXT DEFAULT 'waiting'
    CHECK (status IN ('waiting', 'offered', 'accepted', 'declined', 'enrolled', 'expired')),
  offered_at TIMESTAMPTZ,
  response_deadline TIMESTAMPTZ,
  enrolled_at TIMESTAMPTZ,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_waitlist_status ON public.waitlist(status, position);
CREATE INDEX idx_waitlist_location ON public.waitlist(location_id, status);
```

#### 56. enrollment_forms (custom digital forms for registration)

```sql
CREATE TABLE public.enrollment_forms (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,                 -- 'New Family Registration 2026'
  description TEXT,
  location_id UUID REFERENCES public.locations(id),
  form_fields JSONB NOT NULL,          -- dynamic form definition
  -- Example form_fields:
  -- [
  --   {"key": "child_name", "label": "Child's Full Name", "type": "text", "required": true},
  --   {"key": "dob", "label": "Date of Birth", "type": "date", "required": true},
  --   {"key": "allergies", "label": "Known Allergies", "type": "textarea", "required": false},
  --   {"key": "photo_consent", "label": "I consent to photos being taken", "type": "checkbox", "required": true},
  --   {"key": "emergency_contact", "label": "Emergency Contact", "type": "group", "fields": [...]},
  -- ]
  is_active BOOLEAN DEFAULT true,
  created_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ DEFAULT now()
);
```

#### 57. enrollment_submissions (filled-out forms)

```sql
CREATE TABLE public.enrollment_submissions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  form_id UUID REFERENCES public.enrollment_forms(id) NOT NULL,
  inquiry_id UUID REFERENCES public.enrollment_inquiries(id),
  submitted_by_email TEXT NOT NULL,
  form_data JSONB NOT NULL,            -- all submitted field values
  documents JSONB DEFAULT '[]',        -- uploaded documents: [{"name": "immunization_record.pdf", "url": "..."}]
  status TEXT DEFAULT 'submitted'
    CHECK (status IN ('submitted', 'under_review', 'approved', 'incomplete', 'rejected')),
  reviewed_by UUID REFERENCES public.profiles(id),
  reviewed_at TIMESTAMPTZ,
  review_notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_enrollment_subs_form ON public.enrollment_submissions(form_id);
CREATE INDEX idx_enrollment_subs_status ON public.enrollment_submissions(status);
```

---

### SECTION 20: Learning Stories & Portfolio (Storypark pattern)

#### 58. learning_stories (narrative documentation - richer than observations)

```sql
CREATE TABLE public.learning_stories (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  -- Can be about one child, multiple children, or whole group
  child_ids UUID[],                    -- one or more children featured
  group_id UUID REFERENCES public.groups(id),  -- if group story
  author_id UUID REFERENCES public.profiles(id) NOT NULL,
  author_type TEXT DEFAULT 'educator'
    CHECK (author_type IN ('educator', 'parent', 'child_voice')),
  -- Content
  title TEXT NOT NULL,
  content TEXT NOT NULL,               -- rich narrative text (could be markdown/HTML)
  story_type TEXT NOT NULL
    CHECK (story_type IN (
      'learning_moment', 'milestone_celebration', 'daily_diary',
      'project_documentation', 'child_reflection', 'parent_contribution',
      'interest_exploration', 'group_experience'
    )),
  -- Curriculum/framework linking
  skill_area_ids UUID[],               -- linked development domains
  tagged_skills UUID[],                -- specific skills demonstrated
  learning_frameworks TEXT[],          -- ['montessori', 'ntc', 'eyfs', 'te_whariki']
  -- Visibility & publishing
  is_draft BOOLEAN DEFAULT true,
  is_visible_to_parents BOOLEAN DEFAULT true,
  is_featured BOOLEAN DEFAULT false,   -- featured on child's portfolio
  -- Engagement
  parent_comment TEXT,                 -- parent response to the story
  parent_responded_at TIMESTAMPTZ,
  view_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_stories_child ON public.learning_stories USING GIN (child_ids);
CREATE INDEX idx_stories_group ON public.learning_stories(group_id);
CREATE INDEX idx_stories_author ON public.learning_stories(author_id, created_at DESC);
CREATE INDEX idx_stories_type ON public.learning_stories(story_type);
```

#### 59. learning_story_media

```sql
CREATE TABLE public.learning_story_media (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  story_id UUID REFERENCES public.learning_stories(id) ON DELETE CASCADE NOT NULL,
  file_url TEXT NOT NULL,
  file_type TEXT NOT NULL
    CHECK (file_type IN ('photo', 'video', 'audio', 'document')),
  caption TEXT,
  is_cover BOOLEAN DEFAULT false,      -- used as story thumbnail
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_story_media ON public.learning_story_media(story_id);
```

#### 60. child_portfolio_settings (per-child portfolio configuration)

```sql
CREATE TABLE public.child_portfolio_settings (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  child_id UUID REFERENCES public.children(id) ON DELETE CASCADE NOT NULL,
  -- Portfolio is the lifelong collection of stories + observations + assessments
  is_public_to_family BOOLEAN DEFAULT true,  -- extended family can view
  cover_photo_url TEXT,
  portfolio_theme TEXT DEFAULT 'default',
  -- Sharing settings
  share_token TEXT UNIQUE,             -- unique link for sharing portfolio externally
  share_enabled BOOLEAN DEFAULT false,
  share_expires_at TIMESTAMPTZ,
  -- Family members with access (beyond parents)
  extended_family_emails TEXT[],       -- grandparents etc. can view portfolio
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(child_id)
);
```

---

### SECTION 21: Educator Professional Development (Storypark pattern)

#### 61. educator_goals (staff professional development)

```sql
CREATE TABLE public.educator_goals (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  staff_id UUID REFERENCES public.profiles(id) NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  goal_type TEXT DEFAULT 'professional'
    CHECK (goal_type IN ('professional', 'classroom', 'curriculum', 'personal')),
  target_date DATE,
  status TEXT DEFAULT 'active'
    CHECK (status IN ('active', 'in_progress', 'completed', 'deferred')),
  evidence_notes TEXT,                 -- reflection on progress
  completed_at TIMESTAMPTZ,
  reviewed_by UUID REFERENCES public.profiles(id), -- manager review
  review_notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_educator_goals_staff ON public.educator_goals(staff_id, status);
```

---

## Row Level Security (RLS) Policies

```sql
-- ============================================================
-- HELPER FUNCTION: get current user's role without RLS recursion
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS TEXT LANGUAGE sql SECURITY DEFINER STABLE AS $$
  SELECT role FROM public.profiles WHERE id = auth.uid();
$$;

CREATE OR REPLACE FUNCTION public.is_staff_or_admin()
RETURNS BOOLEAN LANGUAGE sql SECURITY DEFINER STABLE AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role IN ('staff', 'admin')
  );
$$;

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN LANGUAGE sql SECURITY DEFINER STABLE AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'admin'
  );
$$;

CREATE OR REPLACE FUNCTION public.my_children_ids()
RETURNS SETOF UUID LANGUAGE sql SECURITY DEFINER STABLE AS $$
  SELECT child_id FROM public.parent_children WHERE parent_id = auth.uid();
$$;

-- ============================================================
-- PROFILES
-- ============================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users view own profile" ON public.profiles
  FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users update own profile" ON public.profiles
  FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Staff view all profiles" ON public.profiles
  FOR SELECT USING (public.is_staff_or_admin());

-- ============================================================
-- CHILDREN
-- ============================================================
ALTER TABLE public.children ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Parents see own children" ON public.children
  FOR SELECT USING (id IN (SELECT public.my_children_ids()));
CREATE POLICY "Parents insert children" ON public.children
  FOR INSERT WITH CHECK (true); -- parent_children link is created separately
CREATE POLICY "Parents update own children" ON public.children
  FOR UPDATE USING (id IN (SELECT public.my_children_ids()));
CREATE POLICY "Staff see all children" ON public.children
  FOR ALL USING (public.is_staff_or_admin());

-- ============================================================
-- PARENT_CHILDREN
-- ============================================================
ALTER TABLE public.parent_children ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Parents see own links" ON public.parent_children
  FOR SELECT USING (parent_id = auth.uid());
CREATE POLICY "Parents insert own links" ON public.parent_children
  FOR INSERT WITH CHECK (parent_id = auth.uid());
CREATE POLICY "Staff manage all links" ON public.parent_children
  FOR ALL USING (public.is_staff_or_admin());

-- ============================================================
-- OBSERVATIONS
-- ============================================================
ALTER TABLE public.observations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Parents see visible observations for own children" ON public.observations
  FOR SELECT USING (
    is_visible_to_parent = true
    AND child_id IN (SELECT public.my_children_ids())
  );
CREATE POLICY "Staff manage observations" ON public.observations
  FOR ALL USING (public.is_staff_or_admin());

-- ============================================================
-- OBSERVATION_MEDIA
-- ============================================================
ALTER TABLE public.observation_media ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Parents see media for visible observations" ON public.observation_media
  FOR SELECT USING (
    observation_id IN (
      SELECT id FROM public.observations
      WHERE is_visible_to_parent = true
      AND child_id IN (SELECT public.my_children_ids())
    )
  );
CREATE POLICY "Staff manage media" ON public.observation_media
  FOR ALL USING (public.is_staff_or_admin());

-- ============================================================
-- ASSESSMENTS, ATTENDANCE, QUARTERLY_REPORTS, HOME_ACTIVITIES
-- Same pattern: parents see own children's, staff see all
-- ============================================================
ALTER TABLE public.assessments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Parents see own" ON public.assessments
  FOR SELECT USING (child_id IN (SELECT public.my_children_ids()));
CREATE POLICY "Staff manage" ON public.assessments
  FOR ALL USING (public.is_staff_or_admin());

ALTER TABLE public.attendance ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Parents see own" ON public.attendance
  FOR SELECT USING (child_id IN (SELECT public.my_children_ids()));
CREATE POLICY "Staff manage" ON public.attendance
  FOR ALL USING (public.is_staff_or_admin());

ALTER TABLE public.quarterly_reports ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Parents see published reports" ON public.quarterly_reports
  FOR SELECT USING (
    status = 'published'
    AND child_id IN (SELECT public.my_children_ids())
  );
CREATE POLICY "Staff manage" ON public.quarterly_reports
  FOR ALL USING (public.is_staff_or_admin());

ALTER TABLE public.home_activities ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Parents manage own" ON public.home_activities
  FOR ALL USING (parent_id = auth.uid());
CREATE POLICY "Staff see all" ON public.home_activities
  FOR SELECT USING (public.is_staff_or_admin());

-- ============================================================
-- CHILD_MILESTONES
-- ============================================================
ALTER TABLE public.child_milestones ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Parents see own children milestones" ON public.child_milestones
  FOR SELECT USING (child_id IN (SELECT public.my_children_ids()));
CREATE POLICY "Staff manage" ON public.child_milestones
  FOR ALL USING (public.is_staff_or_admin());

-- CURRICULUM LESSONS (public read for authenticated users)
ALTER TABLE public.curriculum_lessons ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated read" ON public.curriculum_lessons
  FOR SELECT USING (auth.uid() IS NOT NULL AND is_active = true);
CREATE POLICY "Admin manages" ON public.curriculum_lessons
  FOR ALL USING (public.is_admin());

-- CHILD LESSON RECORDS (parents see own, staff manage)
ALTER TABLE public.child_lesson_records ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Parents see own" ON public.child_lesson_records
  FOR SELECT USING (child_id IN (SELECT public.my_children_ids()));
CREATE POLICY "Staff manage" ON public.child_lesson_records
  FOR ALL USING (public.is_staff_or_admin());

-- ============================================================
-- MESSAGES
-- ============================================================
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users see own messages" ON public.messages
  FOR SELECT USING (
    recipient_id = auth.uid()
    OR sender_id = auth.uid()
    OR (group_id IN (
      SELECT g.group_id FROM public.child_groups g
      WHERE g.child_id IN (SELECT public.my_children_ids())
    ))
  );
CREATE POLICY "Users send messages" ON public.messages
  FOR INSERT WITH CHECK (sender_id = auth.uid());
CREATE POLICY "Staff manage messages" ON public.messages
  FOR ALL USING (public.is_staff_or_admin());

-- ============================================================
-- NOTIFICATIONS
-- ============================================================
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users see own notifications" ON public.notifications
  FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users update own notifications" ON public.notifications
  FOR UPDATE USING (user_id = auth.uid());

-- ============================================================
-- FORUM (authenticated users can read, own posts they can edit)
-- ============================================================
ALTER TABLE public.forum_topics ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated read" ON public.forum_topics
  FOR SELECT USING (auth.uid() IS NOT NULL);
CREATE POLICY "Authors manage own" ON public.forum_topics
  FOR INSERT WITH CHECK (author_id = auth.uid());
CREATE POLICY "Authors update own" ON public.forum_topics
  FOR UPDATE USING (author_id = auth.uid());
CREATE POLICY "Staff manage all" ON public.forum_topics
  FOR ALL USING (public.is_staff_or_admin());

ALTER TABLE public.forum_posts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated read" ON public.forum_posts
  FOR SELECT USING (auth.uid() IS NOT NULL);
CREATE POLICY "Authors create" ON public.forum_posts
  FOR INSERT WITH CHECK (author_id = auth.uid());
CREATE POLICY "Authors update own" ON public.forum_posts
  FOR UPDATE USING (author_id = auth.uid());
CREATE POLICY "Staff manage all" ON public.forum_posts
  FOR ALL USING (public.is_staff_or_admin());

-- ============================================================
-- BLOG, RESOURCES (public read, admin write)
-- ============================================================
ALTER TABLE public.blog_posts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public reads published" ON public.blog_posts
  FOR SELECT USING (is_published = true);
CREATE POLICY "Admin manages" ON public.blog_posts
  FOR ALL USING (public.is_admin());

ALTER TABLE public.resources ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public reads published" ON public.resources
  FOR SELECT USING (is_published = true);
CREATE POLICY "Admin manages" ON public.resources
  FOR ALL USING (public.is_admin());

-- ============================================================
-- SUBSCRIPTIONS, PAYMENTS (users see own, admin sees all)
-- ============================================================
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users see own" ON public.subscriptions
  FOR SELECT USING (profile_id = auth.uid());
CREATE POLICY "Admin manages" ON public.subscriptions
  FOR ALL USING (public.is_admin());

ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users see own" ON public.payments
  FOR SELECT USING (profile_id = auth.uid());
CREATE POLICY "Admin manages" ON public.payments
  FOR ALL USING (public.is_admin());

-- ============================================================
-- WORKSHOP_FEEDBACK (parents create own, staff reads all)
-- ============================================================
ALTER TABLE public.workshop_feedback ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Parents create own" ON public.workshop_feedback
  FOR INSERT WITH CHECK (parent_id = auth.uid());
CREATE POLICY "Parents see own" ON public.workshop_feedback
  FOR SELECT USING (parent_id = auth.uid());
CREATE POLICY "Staff sees all" ON public.workshop_feedback
  FOR SELECT USING (public.is_staff_or_admin());

-- ============================================================
-- ADMIN-ONLY tables (campaigns, contacts, activity_log)
-- ============================================================
ALTER TABLE public.email_campaigns ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Admin manages" ON public.email_campaigns
  FOR ALL USING (public.is_admin());

ALTER TABLE public.contact_submissions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Admin manages" ON public.contact_submissions
  FOR ALL USING (public.is_admin());

ALTER TABLE public.activity_log ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Admin reads" ON public.activity_log
  FOR SELECT USING (public.is_admin());

-- ============================================================
-- DAILY LOGS & SUB-TABLES (parents see own children, staff manage)
-- ============================================================
ALTER TABLE public.daily_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Parents see own" ON public.daily_logs
  FOR SELECT USING (child_id IN (SELECT public.my_children_ids()));
CREATE POLICY "Parents create home logs" ON public.daily_logs
  FOR INSERT WITH CHECK (
    child_id IN (SELECT public.my_children_ids())
    AND log_source = 'parent'
  );
CREATE POLICY "Parents update own home logs" ON public.daily_logs
  FOR UPDATE USING (
    child_id IN (SELECT public.my_children_ids())
    AND log_source = 'parent'
    AND recorded_by = auth.uid()
  );
CREATE POLICY "Staff manage" ON public.daily_logs
  FOR ALL USING (public.is_staff_or_admin());

ALTER TABLE public.daily_log_meals ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Parents see own" ON public.daily_log_meals
  FOR SELECT USING (daily_log_id IN (
    SELECT id FROM public.daily_logs WHERE child_id IN (SELECT public.my_children_ids())
  ));
CREATE POLICY "Staff manage" ON public.daily_log_meals
  FOR ALL USING (public.is_staff_or_admin());

-- Same pattern for daily_log_naps, daily_log_toileting, daily_log_activities, daily_log_photos
ALTER TABLE public.daily_log_naps ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Parents see own" ON public.daily_log_naps
  FOR SELECT USING (daily_log_id IN (SELECT id FROM public.daily_logs WHERE child_id IN (SELECT public.my_children_ids())));
CREATE POLICY "Staff manage" ON public.daily_log_naps
  FOR ALL USING (public.is_staff_or_admin());

ALTER TABLE public.daily_log_toileting ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Parents see own" ON public.daily_log_toileting
  FOR SELECT USING (daily_log_id IN (SELECT id FROM public.daily_logs WHERE child_id IN (SELECT public.my_children_ids())));
CREATE POLICY "Staff manage" ON public.daily_log_toileting
  FOR ALL USING (public.is_staff_or_admin());

ALTER TABLE public.daily_log_activities ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Parents see own" ON public.daily_log_activities
  FOR SELECT USING (daily_log_id IN (SELECT id FROM public.daily_logs WHERE child_id IN (SELECT public.my_children_ids())));
CREATE POLICY "Staff manage" ON public.daily_log_activities
  FOR ALL USING (public.is_staff_or_admin());

ALTER TABLE public.daily_log_photos ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Parents see shared" ON public.daily_log_photos
  FOR SELECT USING (
    is_shared_with_parent = true
    AND daily_log_id IN (SELECT id FROM public.daily_logs WHERE child_id IN (SELECT public.my_children_ids()))
  );
CREATE POLICY "Staff manage" ON public.daily_log_photos
  FOR ALL USING (public.is_staff_or_admin());

-- ============================================================
-- CHECK-INS & SAFETY
-- ============================================================
ALTER TABLE public.check_ins ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Parents see own" ON public.check_ins
  FOR SELECT USING (child_id IN (SELECT public.my_children_ids()));
CREATE POLICY "Parents can check in" ON public.check_ins
  FOR INSERT WITH CHECK (child_id IN (SELECT public.my_children_ids()));
CREATE POLICY "Staff manage" ON public.check_ins
  FOR ALL USING (public.is_staff_or_admin());

ALTER TABLE public.authorized_pickups ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Parents manage own" ON public.authorized_pickups
  FOR ALL USING (child_id IN (SELECT public.my_children_ids()));
CREATE POLICY "Staff see all" ON public.authorized_pickups
  FOR SELECT USING (public.is_staff_or_admin());

-- ============================================================
-- INCIDENT REPORTS & SAFETY
-- ============================================================
ALTER TABLE public.incident_reports ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Parents see own" ON public.incident_reports
  FOR SELECT USING (child_id IN (SELECT public.my_children_ids()));
CREATE POLICY "Staff manage" ON public.incident_reports
  FOR ALL USING (public.is_staff_or_admin());

ALTER TABLE public.emergency_contacts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Parents manage own" ON public.emergency_contacts
  FOR ALL USING (child_id IN (SELECT public.my_children_ids()));
CREATE POLICY "Staff see all" ON public.emergency_contacts
  FOR SELECT USING (public.is_staff_or_admin());

-- ============================================================
-- STAFF MANAGEMENT (admin only)
-- ============================================================
ALTER TABLE public.staff_schedules ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Staff sees own" ON public.staff_schedules
  FOR SELECT USING (staff_id = auth.uid());
CREATE POLICY "Admin manages" ON public.staff_schedules
  FOR ALL USING (public.is_admin());

ALTER TABLE public.staff_time_entries ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Staff sees own" ON public.staff_time_entries
  FOR SELECT USING (staff_id = auth.uid());
CREATE POLICY "Staff creates own" ON public.staff_time_entries
  FOR INSERT WITH CHECK (staff_id = auth.uid());
CREATE POLICY "Admin manages" ON public.staff_time_entries
  FOR ALL USING (public.is_admin());

ALTER TABLE public.room_ratios ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Staff sees own groups" ON public.room_ratios
  FOR SELECT USING (public.is_staff_or_admin());
CREATE POLICY "Staff records" ON public.room_ratios
  FOR INSERT WITH CHECK (public.is_staff_or_admin());
CREATE POLICY "Admin manages" ON public.room_ratios
  FOR ALL USING (public.is_admin());

-- ============================================================
-- ENROLLMENT PIPELINE (admin only, parents see own inquiry)
-- ============================================================
ALTER TABLE public.enrollment_inquiries ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Admin manages" ON public.enrollment_inquiries
  FOR ALL USING (public.is_admin());

ALTER TABLE public.waitlist ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Admin manages" ON public.waitlist
  FOR ALL USING (public.is_admin());

ALTER TABLE public.enrollment_forms ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public reads active" ON public.enrollment_forms
  FOR SELECT USING (is_active = true);
CREATE POLICY "Admin manages" ON public.enrollment_forms
  FOR ALL USING (public.is_admin());

ALTER TABLE public.enrollment_submissions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Admin manages" ON public.enrollment_submissions
  FOR ALL USING (public.is_admin());
-- Allow anonymous/public submission via service role in Python API

-- ============================================================
-- LEARNING STORIES & PORTFOLIO
-- ============================================================
ALTER TABLE public.learning_stories ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Parents see visible stories for own children" ON public.learning_stories
  FOR SELECT USING (
    is_visible_to_parents = true
    AND is_draft = false
    AND child_ids && ARRAY(SELECT public.my_children_ids())::UUID[]
  );
CREATE POLICY "Parents create contributions" ON public.learning_stories
  FOR INSERT WITH CHECK (
    author_id = auth.uid()
    AND author_type = 'parent'
  );
CREATE POLICY "Staff manage" ON public.learning_stories
  FOR ALL USING (public.is_staff_or_admin());

ALTER TABLE public.learning_story_media ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Via story access" ON public.learning_story_media
  FOR SELECT USING (
    story_id IN (SELECT id FROM public.learning_stories WHERE
      is_visible_to_parents = true AND is_draft = false
      AND child_ids && ARRAY(SELECT public.my_children_ids())::UUID[]
    )
  );
CREATE POLICY "Staff manage" ON public.learning_story_media
  FOR ALL USING (public.is_staff_or_admin());

ALTER TABLE public.child_portfolio_settings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Parents manage own" ON public.child_portfolio_settings
  FOR ALL USING (child_id IN (SELECT public.my_children_ids()));
CREATE POLICY "Staff see all" ON public.child_portfolio_settings
  FOR SELECT USING (public.is_staff_or_admin());

-- ============================================================
-- EDUCATOR GOALS (staff sees own, admin sees all)
-- ============================================================
ALTER TABLE public.educator_goals ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Staff sees own" ON public.educator_goals
  FOR ALL USING (staff_id = auth.uid());
CREATE POLICY "Admin sees all" ON public.educator_goals
  FOR SELECT USING (public.is_admin());
```

## Supabase Storage Buckets

```
avatars/              -- user profile photos (public read)
children-photos/      -- child profile photos (private, RLS via parent_children)
observation-media/    -- photos/videos of children's work (private, RLS)
home-activity-media/  -- parent-uploaded photos (private, RLS)
workshop-materials/   -- PDFs, docs for workshops (authenticated)
reports/              -- generated quarterly PDF reports (private, RLS)
resources/            -- media library: videos, PDFs, audio (access by plan level)
blog-images/          -- blog post images (public)
lead-magnets/         -- free downloadable resources (public)
challenge-media/      -- weekly challenge photos (authenticated)
daily-log-photos/     -- daily routine photos sent to parents (private, RLS)
learning-stories/     -- narrative story media (private, RLS)
incident-photos/      -- incident report documentation (private, staff only)
enrollment-docs/      -- uploaded enrollment documents (private, admin only)
pickup-ids/           -- authorized pickup person photos (private, RLS)
```

## Database Views (for common queries)

```sql
-- Child dashboard view (aggregated data for parent dashboard)
CREATE VIEW public.v_child_dashboard AS
SELECT
  c.*,
  (SELECT count(*) FROM public.attendance a
   JOIN public.sessions s ON s.id = a.session_id
   WHERE a.child_id = c.id AND a.status = 'present') AS total_sessions_attended,
  (SELECT count(*) FROM public.observations o
   WHERE o.child_id = c.id) AS total_observations,
  (SELECT jsonb_object_agg(sa.key, a.score)
   FROM public.assessments a
   JOIN public.skill_areas sa ON sa.id = a.skill_area_id
   WHERE a.child_id = c.id
   AND a.period = to_char(now(), 'YYYY') || '-Q' || to_char(now(), 'Q')
  ) AS current_quarter_scores,
  (SELECT count(*) FROM public.child_milestones m
   WHERE m.child_id = c.id AND m.status = 'mastered') AS milestones_mastered
FROM public.children c;

-- Workshop popularity view (for admin analytics)
CREATE VIEW public.v_workshop_stats AS
SELECT
  w.id,
  w.title,
  w.domains,
  count(DISTINCT s.id) AS total_sessions,
  avg(f.overall_rating)::NUMERIC(3,2) AS avg_rating,
  count(DISTINCT f.id) AS total_ratings
FROM public.workshops w
LEFT JOIN public.sessions s ON s.workshop_id = w.id
LEFT JOIN public.workshop_feedback f ON f.session_id = s.id
GROUP BY w.id;
```

## Table Count Summary

| Section | Tables | Purpose |
|---------|--------|---------|
| Users & Roles | 1 | profiles |
| Children & Relationships | 2 | children, parent_children |
| Locations & Groups | 4 | locations, groups, group_staff, child_groups |
| Curriculum & Skills | 6 | skill_areas, skills, curriculum_lessons, child_lesson_records, child_milestones, milestone_history |
| Workshops & Sessions | 3 | workshops, sessions, workshop_materials |
| Attendance & Observations | 4 | attendance, observations, observation_media, observation_templates |
| Assessments & Reports | 2 | assessments, quarterly_reports |
| Home Activities & Engagement | 5 | home_activities, home_activity_media, weekly_challenges, challenge_submissions, workshop_feedback |
| Communication | 2 | messages, notifications |
| Community & Forum | 3 | forum_categories, forum_topics, forum_posts |
| Content & Resources | 2 | resources, blog_posts |
| Subscriptions & Payments | 3 | subscription_plans, subscriptions, payments |
| Marketing & Leads | 4 | lead_contacts, contact_submissions, email_campaigns, email_campaign_recipients |
| Audit | 1 | activity_log |
| Daily Routine Tracking | 6 | daily_logs, daily_log_meals, daily_log_naps, daily_log_toileting, daily_log_activities, daily_log_photos |
| Check-In & Safety | 2 | check_ins, authorized_pickups |
| Safety | 2 | incident_reports, emergency_contacts |
| Staff Management | 3 | staff_schedules, staff_time_entries, room_ratios |
| Enrollment Pipeline | 4 | enrollment_inquiries, waitlist, enrollment_forms, enrollment_submissions |
| Learning Stories & Portfolio | 3 | learning_stories, learning_story_media, child_portfolio_settings |
| Educator Development | 1 | educator_goals |
| **TOTAL** | **61** | |

## Feature Coverage vs Competitors

| Feature | Brightwheel | Procare | Storypark | Transparent Classroom | Montessori Compass | **Sarena Sfera** |
|---------|------------|---------|-----------|----------------------|-------------------|-----------------|
| Check-in/check-out | Yes | Yes | No | No | No | **Yes** |
| Daily routine logs | Yes | Yes | No | No | Yes | **Yes** |
| Meal tracking | Yes | Yes | No | No | Yes | **Yes** |
| Nap tracking | Yes | Yes | No | No | Yes | **Yes** |
| Toileting tracking | Yes | Yes | No | No | Yes | **Yes** |
| Incident reports | Yes | Yes | No | No | No | **Yes** |
| Health/medication | Yes | Yes | No | No | No | **Yes** |
| Staff scheduling | Yes | Yes | No | No | No | **Yes** |
| Ratio compliance | No | Yes | No | No | No | **Yes** |
| Development tracking | Basic | Basic | Yes | Yes | Yes | **Yes (6 domains + skills)** |
| Observations | Basic | Basic | Learning Stories | Yes | Yes | **Yes + Learning Stories** |
| Milestone tracking | No | No | No | Yes | Yes | **Yes (5-stage)** |
| Hierarchical skills | No | No | No | Yes | Yes | **Yes** |
| Quarterly reports | No | No | Yes | Yes | Yes | **Yes (auto PDF)** |
| Parent community | No | No | No | No | No | **Yes (forum)** |
| Home activities | No | No | No | No | No | **Yes** |
| Weekly challenges | No | No | No | No | No | **Yes** |
| Learning stories | No | No | Yes | No | No | **Yes** |
| Child portfolio | No | No | Yes | No | No | **Yes** |
| Parent contributions | No | No | Yes | No | No | **Yes** |
| Educator goals | No | No | Yes | No | No | **Yes** |
| Enrollment CRM | Yes | Yes | No | No | No | **Yes** |
| Waitlist | Yes | Yes | No | No | No | **Yes** |
| Digital enrollment forms | Yes | Yes | No | No | No | **Yes** |
| Blog/content marketing | No | No | No | No | No | **Yes** |
| Lead generation | No | No | No | No | No | **Yes** |
| Email campaigns | No | No | No | No | No | **Yes** |
| Subscription management | N/A | N/A | N/A | N/A | N/A | **Yes** |
| Multi-location/franchise | Yes | Yes | Yes | Yes | Yes | **Yes** |
