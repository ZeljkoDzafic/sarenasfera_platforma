-- ─── Groups, Staff, Child-Group Memberships ───────────────────────────────────
-- T-102: Database Migrations
-- Migration: 011_groups.sql

CREATE TABLE IF NOT EXISTS public.groups (
  id             UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name           TEXT NOT NULL,               -- e.g. "Pčelice (3-4 god)"
  description    TEXT,
  age_range_min  INTEGER,                     -- min age in months
  age_range_max  INTEGER,                     -- max age in months
  max_capacity   INTEGER DEFAULT 12,
  schedule       JSONB,                       -- {"days": ["tue","thu"], "time_start": "10:00", "time_end": "11:30"}
  location_id    UUID REFERENCES public.locations(id),
  is_active      BOOLEAN DEFAULT true,
  created_at     TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_groups_location ON public.groups(location_id);

-- group_staff: multiple teachers per group
CREATE TABLE IF NOT EXISTS public.group_staff (
  group_id    UUID REFERENCES public.groups(id) ON DELETE CASCADE,
  staff_id    UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  role        TEXT DEFAULT 'lead'
                CHECK (role IN ('lead', 'assistant', 'volunteer', 'substitute')),
  assigned_at DATE DEFAULT CURRENT_DATE,
  PRIMARY KEY (group_id, staff_id)
);

CREATE INDEX IF NOT EXISTS idx_group_staff_staff ON public.group_staff(staff_id);

-- child_groups: children enrolled in groups
CREATE TABLE IF NOT EXISTS public.child_groups (
  child_id  UUID REFERENCES public.children(id) ON DELETE CASCADE,
  group_id  UUID REFERENCES public.groups(id) ON DELETE CASCADE,
  joined_at DATE DEFAULT CURRENT_DATE,
  left_at   DATE,                             -- null = still active
  PRIMARY KEY (child_id, group_id)
);

CREATE INDEX IF NOT EXISTS idx_child_groups_group ON public.child_groups(group_id);
CREATE INDEX IF NOT EXISTS idx_child_groups_child ON public.child_groups(child_id);

-- ─── RLS ──────────────────────────────────────────────────────────────────────
ALTER TABLE public.groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.group_staff ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.child_groups ENABLE ROW LEVEL SECURITY;

-- Groups: any authenticated user can read active groups; admin manages
CREATE POLICY IF NOT EXISTS "groups_auth_read" ON public.groups
  FOR SELECT USING (is_active = true AND auth.uid() IS NOT NULL);

CREATE POLICY IF NOT EXISTS "groups_admin_all" ON public.groups
  FOR ALL USING (auth.jwt()->'app_metadata'->>'role' IN ('admin', 'staff'));

-- Group staff: staff sees own assignments; admin sees all
CREATE POLICY IF NOT EXISTS "group_staff_own" ON public.group_staff
  FOR SELECT USING (
    staff_id = auth.uid()
    OR auth.jwt()->'app_metadata'->>'role' IN ('admin', 'staff')
  );

CREATE POLICY IF NOT EXISTS "group_staff_admin" ON public.group_staff
  FOR ALL USING (auth.jwt()->'app_metadata'->>'role' = 'admin');

-- Child groups: parent sees their children's groups; staff sees all
CREATE POLICY IF NOT EXISTS "child_groups_parent" ON public.child_groups
  FOR SELECT USING (
    child_id IN (SELECT child_id FROM public.parent_children WHERE parent_id = auth.uid())
    OR auth.jwt()->'app_metadata'->>'role' IN ('admin', 'staff')
  );

CREATE POLICY IF NOT EXISTS "child_groups_admin" ON public.child_groups
  FOR ALL USING (auth.jwt()->'app_metadata'->>'role' IN ('admin', 'staff'));

-- ─── Seed: Default groups ─────────────────────────────────────────────────────
INSERT INTO public.groups (name, description, age_range_min, age_range_max, max_capacity)
VALUES
  ('Leptirići (2–3 god)', 'Najmlađi polaznici programa. Fokus: senzorni razvoj i adaptacija.', 24, 36, 10),
  ('Pčelice (3–4 god)',   'Srednja grupa. Fokus: socijalni razvoj i kreativnost.', 36, 48, 12),
  ('Vjeverice (4–6 god)', 'Starija grupa. Fokus: kognitivni razvoj i školska priprema.', 48, 72, 12)
ON CONFLICT DO NOTHING;
