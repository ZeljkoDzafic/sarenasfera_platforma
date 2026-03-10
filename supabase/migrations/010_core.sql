-- ─── Core: Profiles, Children, Locations ─────────────────────────────────────
-- T-102: Database Migrations — Core Tables
-- Migration: 010_core.sql
-- Run after: 001_events.sql, 002_quiz.sql

-- ─── Updated_at helper (shared across all migrations) ─────────────────────────
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ─── SECTION 1: Locations ──────────────────────────────────────────────────────
-- Must be created before children (FK)
CREATE TABLE IF NOT EXISTS public.locations (
  id         UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name       TEXT NOT NULL,                  -- "Sarena Sfera Sarajevo"
  address    TEXT,
  city       TEXT,
  phone      TEXT,
  email      TEXT,
  manager_id UUID,                           -- FK to profiles added later (circular)
  logo_url   TEXT,
  is_active  BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ─── SECTION 2: Profiles ───────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.profiles (
  id                      UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  full_name               TEXT NOT NULL DEFAULT '',
  email                   TEXT,
  phone                   TEXT,
  role                    TEXT NOT NULL DEFAULT 'parent'
                            CHECK (role IN ('parent', 'staff', 'admin', 'expert')),
  avatar_url              TEXT,
  city                    TEXT,
  bio                     TEXT,
  specialization          TEXT,
  is_active               BOOLEAN DEFAULT true,
  onboarding_completed    BOOLEAN DEFAULT false,
  last_seen_at            TIMESTAMPTZ,
  preferred_language      TEXT DEFAULT 'bs',
  notification_preferences JSONB DEFAULT '{"email": true, "push": true, "sms": false}',
  location_id             UUID REFERENCES public.locations(id),
  created_at              TIMESTAMPTZ DEFAULT now(),
  updated_at              TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_location ON public.profiles(location_id);

-- Add manager_id FK to locations (now that profiles exists)
ALTER TABLE public.locations
  ADD COLUMN IF NOT EXISTS manager_id_ref UUID REFERENCES public.profiles(id);

-- Auto-create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, email, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'role', 'parent')
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Updated_at trigger for profiles
DROP TRIGGER IF EXISTS profiles_updated_at ON public.profiles;
CREATE TRIGGER profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ─── SECTION 3: Children ───────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.children (
  id               UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  full_name        TEXT NOT NULL,
  nickname         TEXT,
  date_of_birth    DATE NOT NULL,
  gender           TEXT CHECK (gender IN ('male', 'female', 'other')),
  photo_url        TEXT,
  avatar_character TEXT,                     -- khan-style mascot
  enrollment_date  DATE DEFAULT CURRENT_DATE,
  age_group        TEXT,                     -- auto-calculated or manual override
  allergies        TEXT,
  special_needs    TEXT,
  notes            TEXT,                     -- internal staff notes
  is_active        BOOLEAN DEFAULT true,
  location_id      UUID REFERENCES public.locations(id),
  created_at       TIMESTAMPTZ DEFAULT now(),
  updated_at       TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_children_active   ON public.children(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_children_location ON public.children(location_id);

DROP TRIGGER IF EXISTS children_updated_at ON public.children;
CREATE TRIGGER children_updated_at
  BEFORE UPDATE ON public.children
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ─── SECTION 4: Parent-Children (many-to-many) ────────────────────────────────
CREATE TABLE IF NOT EXISTS public.parent_children (
  parent_id    UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  child_id     UUID REFERENCES public.children(id) ON DELETE CASCADE,
  relationship TEXT DEFAULT 'parent'
                 CHECK (relationship IN ('parent', 'mother', 'father', 'guardian', 'grandparent', 'other')),
  is_primary   BOOLEAN DEFAULT true,
  can_pickup   BOOLEAN DEFAULT true,
  created_at   TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (parent_id, child_id)
);

CREATE INDEX IF NOT EXISTS idx_parent_children_child  ON public.parent_children(child_id);
CREATE INDEX IF NOT EXISTS idx_parent_children_parent ON public.parent_children(parent_id);

-- ─── RLS Policies ─────────────────────────────────────────────────────────────

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.children ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.parent_children ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.locations ENABLE ROW LEVEL SECURITY;

-- Profiles: users see their own; admin/staff see all
CREATE POLICY IF NOT EXISTS "profiles_own_read" ON public.profiles
  FOR SELECT USING (id = auth.uid() OR auth.jwt()->'app_metadata'->>'role' IN ('admin', 'staff'));

CREATE POLICY IF NOT EXISTS "profiles_own_update" ON public.profiles
  FOR UPDATE USING (id = auth.uid());

CREATE POLICY IF NOT EXISTS "profiles_admin_all" ON public.profiles
  FOR ALL USING (auth.jwt()->'app_metadata'->>'role' = 'admin');

-- Children: parent sees their own children; staff sees all active
CREATE POLICY IF NOT EXISTS "children_parent_read" ON public.children
  FOR SELECT USING (
    id IN (SELECT child_id FROM public.parent_children WHERE parent_id = auth.uid())
    OR auth.jwt()->'app_metadata'->>'role' IN ('admin', 'staff')
  );

CREATE POLICY IF NOT EXISTS "children_parent_insert" ON public.children
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY IF NOT EXISTS "children_admin_all" ON public.children
  FOR ALL USING (auth.jwt()->'app_metadata'->>'role' IN ('admin', 'staff'));

-- Parent-children: each parent sees own links; admin sees all
CREATE POLICY IF NOT EXISTS "parent_children_own" ON public.parent_children
  FOR SELECT USING (
    parent_id = auth.uid()
    OR auth.jwt()->'app_metadata'->>'role' IN ('admin', 'staff')
  );

CREATE POLICY IF NOT EXISTS "parent_children_parent_insert" ON public.parent_children
  FOR INSERT WITH CHECK (parent_id = auth.uid());

CREATE POLICY IF NOT EXISTS "parent_children_admin" ON public.parent_children
  FOR ALL USING (auth.jwt()->'app_metadata'->>'role' IN ('admin', 'staff'));

-- Locations: public read; admin manages
CREATE POLICY IF NOT EXISTS "locations_public_read" ON public.locations
  FOR SELECT USING (is_active = true);

CREATE POLICY IF NOT EXISTS "locations_admin_all" ON public.locations
  FOR ALL USING (auth.jwt()->'app_metadata'->>'role' = 'admin');

-- ─── Seed: Default location ───────────────────────────────────────────────────
INSERT INTO public.locations (name, city, email)
VALUES ('Šarena Sfera Sarajevo', 'Sarajevo', 'info@sarenasfera.com')
ON CONFLICT DO NOTHING;
