-- Migration 021: Feature Flags, Subscription Tiers & Growth Features
-- PHASE 8: Feature Flags, Tiers & Event Registration (HIGH PRIORITY)
-- T-810, T-820, T-901, T-902, T-906

-- ============================================================
-- FEATURE FLAGS SYSTEM (T-810)
-- ============================================================

CREATE TABLE IF NOT EXISTS public.feature_flags (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  key             TEXT NOT NULL UNIQUE,
  name            TEXT NOT NULL,
  description     TEXT,
  status          TEXT NOT NULL DEFAULT 'active'
                  CHECK (status IN ('active', 'coming_soon', 'hidden', 'beta')),
  min_tier        TEXT NOT NULL DEFAULT 'free'
                  CHECK (min_tier IN ('free', 'paid', 'premium')),
  location_id     UUID REFERENCES public.locations(id),
  updated_by      UUID REFERENCES public.profiles(id),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_feature_flags_key ON public.feature_flags(key);
CREATE INDEX IF NOT EXISTS idx_feature_flags_status ON public.feature_flags(status);
CREATE INDEX IF NOT EXISTS idx_feature_flags_tier ON public.feature_flags(min_tier);

-- Feature interests tracking (users interested in coming soon features)
CREATE TABLE IF NOT EXISTS public.feature_interests (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id         UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  feature_key     TEXT NOT NULL REFERENCES public.feature_flags(key) ON DELETE CASCADE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  notified_at     TIMESTAMPTZ,
  UNIQUE(user_id, feature_key)
);

CREATE INDEX IF NOT EXISTS idx_feature_interests_user ON public.feature_interests(user_id);
CREATE INDEX IF NOT EXISTS idx_feature_interests_feature ON public.feature_interests(feature_key);

ALTER TABLE public.feature_interests
ADD COLUMN IF NOT EXISTS notified_at TIMESTAMPTZ;

-- ============================================================
-- SUBSCRIPTION TIERS SYSTEM (T-820)
-- ============================================================

-- Subscription plans
CREATE TABLE IF NOT EXISTS public.subscription_plans (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name            TEXT NOT NULL UNIQUE,
  key             TEXT NOT NULL UNIQUE CHECK (key IN ('free', 'paid', 'premium')),
  description     TEXT,
  price_km        NUMERIC(10,2) NOT NULL DEFAULT 0,
  tier_level      INTEGER NOT NULL DEFAULT 0,
  
  -- Features included
  max_children    INTEGER DEFAULT 1,
  max_activities  INTEGER DEFAULT 10,
  max_observations INTEGER DEFAULT 3,
  includes_reports BOOLEAN DEFAULT false,
  includes_video   BOOLEAN DEFAULT false,
  includes_forum   BOOLEAN DEFAULT false,
  includes_expert  BOOLEAN DEFAULT false,
  
  is_active       BOOLEAN DEFAULT true,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_subscription_plans_key ON public.subscription_plans(key);

ALTER TABLE public.subscription_plans
ADD COLUMN IF NOT EXISTS description TEXT,
ADD COLUMN IF NOT EXISTS tier_level INTEGER NOT NULL DEFAULT 0,
ADD COLUMN IF NOT EXISTS max_activities INTEGER DEFAULT 10,
ADD COLUMN IF NOT EXISTS max_observations INTEGER DEFAULT 3,
ADD COLUMN IF NOT EXISTS includes_reports BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS includes_video BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS includes_forum BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS includes_expert BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT now();

-- User subscriptions
CREATE TABLE IF NOT EXISTS public.subscriptions (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id         UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  plan_id         UUID NOT NULL REFERENCES public.subscription_plans(id),
  
  status          TEXT NOT NULL DEFAULT 'active'
                  CHECK (status IN ('active', 'cancelled', 'expired', 'trial')),
  
  -- Billing
  start_date      DATE NOT NULL DEFAULT CURRENT_DATE,
  end_date        DATE,
  cancelled_at    TIMESTAMPTZ,
  
  -- Payment info
  payment_method  TEXT CHECK (payment_method IN ('cash', 'bank', 'card', 'paypal')),
  payment_ref     TEXT,
  
  -- Trial
  is_trial        BOOLEAN DEFAULT false,
  trial_end_date  DATE,
  
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.subscriptions
ADD COLUMN IF NOT EXISTS plan_id UUID REFERENCES public.subscription_plans(id),
ADD COLUMN IF NOT EXISTS start_date DATE NOT NULL DEFAULT CURRENT_DATE,
ADD COLUMN IF NOT EXISTS end_date DATE,
ADD COLUMN IF NOT EXISTS payment_method TEXT,
ADD COLUMN IF NOT EXISTS payment_ref TEXT,
ADD COLUMN IF NOT EXISTS is_trial BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS trial_end_date DATE;

UPDATE public.subscriptions s
SET plan_id = sp.id
FROM public.subscription_plans sp
WHERE s.plan_id IS NULL
  AND sp.key = s.plan_key;

CREATE INDEX IF NOT EXISTS idx_subscriptions_user ON public.subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_plan ON public.subscriptions(plan_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_status ON public.subscriptions(status);
CREATE UNIQUE INDEX IF NOT EXISTS idx_subscriptions_active ON public.subscriptions(user_id) WHERE status = 'active';

-- Payment history
CREATE TABLE IF NOT EXISTS public.payments (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id         UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  subscription_id UUID REFERENCES public.subscriptions(id),
  
  amount_km       NUMERIC(10,2) NOT NULL,
  currency        TEXT NOT NULL DEFAULT 'BAM',
  
  payment_method  TEXT NOT NULL CHECK (payment_method IN ('cash', 'bank', 'card', 'paypal')),
  payment_ref     TEXT,
  payment_date    TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  -- Period covered
  period_start    DATE NOT NULL,
  period_end      DATE NOT NULL,
  
  notes           TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_payments_user ON public.payments(user_id);
CREATE INDEX IF NOT EXISTS idx_payments_subscription ON public.payments(subscription_id);

ALTER TABLE public.payments
ADD COLUMN IF NOT EXISTS currency TEXT DEFAULT 'BAM',
ADD COLUMN IF NOT EXISTS payment_date TIMESTAMPTZ DEFAULT now(),
ADD COLUMN IF NOT EXISTS period_start DATE,
ADD COLUMN IF NOT EXISTS period_end DATE;

CREATE INDEX IF NOT EXISTS idx_payments_date ON public.payments(payment_date);

-- Add subscription_tier to profiles (denormalized for performance)
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS subscription_tier TEXT NOT NULL DEFAULT 'free'
CHECK (subscription_tier IN ('free', 'paid', 'premium'));

CREATE INDEX IF NOT EXISTS idx_profiles_tier ON public.profiles(subscription_tier);

-- ============================================================
-- REFERRAL SYSTEM (T-901)
-- ============================================================

-- Already exists in 017_crm_referrals.sql, adding reward tracking
ALTER TABLE public.referrals 
ADD COLUMN IF NOT EXISTS reward_months INTEGER DEFAULT 1;

-- ============================================================
-- PIONEER PROGRAM (T-902)
-- ============================================================

-- Pioneer slots configuration
CREATE TABLE IF NOT EXISTS public.pioneer_config (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  max_slots       INTEGER NOT NULL DEFAULT 50,
  paid_price_km   NUMERIC(10,2) NOT NULL DEFAULT 10,
  premium_price_km NUMERIC(10,2) NOT NULL DEFAULT 20,
  is_active       BOOLEAN DEFAULT true,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Insert default config
INSERT INTO public.pioneer_config (max_slots, paid_price_km, premium_price_km)
VALUES (50, 10, 20)
ON CONFLICT DO NOTHING;

-- Pioneer wall already exists in 017_crm_referrals.sql

-- ============================================================
-- CERTIFICATES & ACHIEVEMENTS (T-906)
-- ============================================================

-- Certificates for children
CREATE TABLE IF NOT EXISTS public.certificates (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  child_id        UUID NOT NULL REFERENCES public.children(id) ON DELETE CASCADE,
  
  certificate_type TEXT NOT NULL CHECK (certificate_type IN ('program_completion', 'domain_mastery', 'attendance_milestone')),
  
  -- Domain mastery specific
  domain          TEXT CHECK (domain IN ('emotional', 'social', 'creative', 'cognitive', 'motor', 'language')),
  
  -- Attendance milestone specific
  attendance_count INTEGER,
  
  -- Certificate details
  title           TEXT NOT NULL,
  description     TEXT,
  issued_date     DATE NOT NULL DEFAULT CURRENT_DATE,
  valid_until     DATE,
  
  -- PDF generation
  pdf_url         TEXT,
  template_id     TEXT,
  
  -- Metadata
  metadata        JSONB DEFAULT '{}',
  
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by      UUID REFERENCES public.profiles(id)
);

CREATE INDEX IF NOT EXISTS idx_certificates_child ON public.certificates(child_id);
CREATE INDEX IF NOT EXISTS idx_certificates_type ON public.certificates(certificate_type);
CREATE INDEX IF NOT EXISTS idx_certificates_domain ON public.certificates(domain);

-- Badges for parents
CREATE TABLE IF NOT EXISTS public.badges (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  key             TEXT NOT NULL UNIQUE,
  name            TEXT NOT NULL,
  description     TEXT,
  icon_url        TEXT,
  badge_type      TEXT NOT NULL CHECK (badge_type IN ('pioneer', 'activity', 'referral', 'attendance', 'special')),
  
  -- Requirements
  requirement_type TEXT,
  requirement_count INTEGER,
  
  is_active       BOOLEAN DEFAULT true,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_badges_key ON public.badges(key);
CREATE INDEX IF NOT EXISTS idx_badges_type ON public.badges(badge_type);

-- User badges (earned badges)
CREATE TABLE IF NOT EXISTS public.user_badges (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id         UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  badge_id        UUID NOT NULL REFERENCES public.badges(id),
  
  earned_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  context         TEXT, -- Why they earned it
  context_id      UUID, -- Related entity (e.g., referral id, activity id)
  
  is_displayed    BOOLEAN DEFAULT true,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  UNIQUE(user_id, badge_id)
);

CREATE INDEX IF NOT EXISTS idx_user_badges_user ON public.user_badges(user_id);
CREATE INDEX IF NOT EXISTS idx_user_badges_badge ON public.user_badges(badge_id);

-- ============================================================
-- TRIGGERS
-- ============================================================

-- Update profiles.subscription_tier when subscription changes
CREATE OR REPLACE FUNCTION public.update_profile_tier()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF TG_TABLE_NAME = 'subscriptions' THEN
    -- Get the tier from the plan
    UPDATE public.profiles p
    SET subscription_tier = sp.key
    FROM public.subscriptions s
    JOIN public.subscription_plans sp ON sp.id = s.plan_id
    WHERE p.id = NEW.user_id
      AND s.id = NEW.id
      AND s.status = 'active';
  END IF;
  
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_update_profile_tier ON public.subscriptions;
CREATE TRIGGER trigger_update_profile_tier
  AFTER INSERT OR UPDATE ON public.subscriptions
  FOR EACH ROW
  WHEN (NEW.status = 'active')
  EXECUTE FUNCTION public.update_profile_tier();

-- Auto-assign free tier on profile creation
CREATE OR REPLACE FUNCTION public.assign_free_tier_on_signup()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  -- Create free subscription
  INSERT INTO public.subscriptions (user_id, plan_id, plan_key, status, is_trial)
  SELECT NEW.id, id, key, 'active', false
  FROM public.subscription_plans
  WHERE key = 'free'
  ON CONFLICT DO NOTHING;
  
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_assign_free_tier ON public.profiles;
CREATE TRIGGER trigger_assign_free_tier
  AFTER INSERT ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.assign_free_tier_on_signup();

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

ALTER TABLE public.feature_flags      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.feature_interests  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscription_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscriptions      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.certificates       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.badges             ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_badges        ENABLE ROW LEVEL SECURITY;

-- Feature flags: anyone can read, only admin can write
CREATE POLICY IF NOT EXISTS "feature_flags_public_read"
  ON public.feature_flags FOR SELECT
  USING (true);

CREATE POLICY IF NOT EXISTS "feature_flags_admin_write"
  ON public.feature_flags FOR ALL
  USING (auth.jwt()->'app_metadata'->>'role' = 'admin');

-- Feature interests: users can insert own, admin can read all
CREATE POLICY IF NOT EXISTS "feature_interests_insert"
  ON public.feature_interests FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY IF NOT EXISTS "feature_interests_read_own"
  ON public.feature_interests FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY IF NOT EXISTS "feature_interests_admin_read"
  ON public.feature_interests FOR SELECT
  USING (auth.jwt()->'app_metadata'->>'role' = 'admin');

-- Subscription plans: anyone can read, admin can write
CREATE POLICY IF NOT EXISTS "subscription_plans_public_read"
  ON public.subscription_plans FOR SELECT
  USING (true);

CREATE POLICY IF NOT EXISTS "subscription_plans_admin_write"
  ON public.subscription_plans FOR ALL
  USING (auth.jwt()->'app_metadata'->>'role' = 'admin');

-- Subscriptions: users see own, admin sees all
CREATE POLICY IF NOT EXISTS "subscriptions_own_read"
  ON public.subscriptions FOR SELECT
  USING (user_id = auth.uid() OR auth.jwt()->'app_metadata'->>'role' = 'admin');

CREATE POLICY IF NOT EXISTS "subscriptions_own_insert"
  ON public.subscriptions FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY IF NOT EXISTS "subscriptions_admin_write"
  ON public.subscriptions FOR ALL
  USING (auth.jwt()->'app_metadata'->>'role' = 'admin');

-- Payments: users see own, admin sees all
CREATE POLICY IF NOT EXISTS "payments_own_read"
  ON public.payments FOR SELECT
  USING (user_id = auth.uid() OR auth.jwt()->'app_metadata'->>'role' = 'admin');

CREATE POLICY IF NOT EXISTS "payments_admin_write"
  ON public.payments FOR ALL
  USING (auth.jwt()->'app_metadata'->>'role' = 'admin');

-- Certificates: parents see own children's, admin/staff see all
CREATE POLICY IF NOT EXISTS "certificates_parents_read"
  ON public.certificates FOR SELECT
  USING (
    child_id = ANY(public.my_children_ids())
    OR auth.jwt()->'app_metadata'->>'role' IN ('admin', 'staff')
  );

CREATE POLICY IF NOT EXISTS "certificates_staff_write"
  ON public.certificates FOR ALL
  USING (auth.jwt()->'app_metadata'->>'role' IN ('admin', 'staff'));

-- Badges: anyone can read badge definitions
CREATE POLICY IF NOT EXISTS "badges_public_read"
  ON public.badges FOR SELECT
  USING (true);

CREATE POLICY IF NOT EXISTS "badges_admin_write"
  ON public.badges FOR ALL
  USING (auth.jwt()->'app_metadata'->>'role' = 'admin');

-- User badges: users see own, admin sees all
CREATE POLICY IF NOT EXISTS "user_badges_own_read"
  ON public.user_badges FOR SELECT
  USING (user_id = auth.uid() OR auth.jwt()->'app_metadata'->>'role' = 'admin');

CREATE POLICY IF NOT EXISTS "user_badges_admin_write"
  ON public.user_badges FOR ALL
  USING (auth.jwt()->'app_metadata'->>'role' = 'admin');

-- ============================================================
-- SEED DATA
-- ============================================================

-- Seed subscription plans
INSERT INTO public.subscription_plans (key, name, description, price_km, tier_level, max_children, max_activities, max_observations, includes_reports, includes_video, includes_forum, includes_expert)
VALUES
  ('free', 'Besplatni', 'Osnovni pristup platformi i zajednici', 0, 0, 1, 10, 3, false, false, true, false),
  ('paid', 'Osnovni', 'Praćenje razvoja djeteta', 15, 1, 3, 50, 100, true, false, true, false),
  ('premium', 'Premium', 'Potpuna podrška sa ekspertnim savjetima', 30, 2, 999, 9999, 9999, true, true, true, true)
ON CONFLICT (key) DO UPDATE SET
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  price_km = EXCLUDED.price_km,
  tier_level = EXCLUDED.tier_level,
  max_children = EXCLUDED.max_children,
  max_activities = EXCLUDED.max_activities,
  max_observations = EXCLUDED.max_observations,
  includes_reports = EXCLUDED.includes_reports,
  includes_video = EXCLUDED.includes_video,
  includes_forum = EXCLUDED.includes_forum,
  includes_expert = EXCLUDED.includes_expert;

-- Seed feature flags
INSERT INTO public.feature_flags (key, name, description, status, min_tier) VALUES
  -- Public features
  ('public.landing', 'Landing Page', 'Početna stranica', 'active', 'free'),
  ('public.program', 'Program', 'Stranica sa programom', 'active', 'free'),
  ('public.blog', 'Blog', 'Blog članci', 'active', 'free'),
  ('public.resources', 'Resursi', 'Besplatni resursi', 'active', 'free'),
  ('public.contact', 'Kontakt', 'Kontakt forma', 'active', 'free'),
  ('public.quiz', 'Kviz', 'Razvojni kviz', 'active', 'free'),
  ('public.pricing', 'Cjenovnik', 'Stranica sa cijenama', 'active', 'free'),
  ('public.events', 'Događaji', 'Javni događaji i radionice', 'active', 'free'),
  ('public.referrals', 'Preporuči', 'Referral landing', 'active', 'free'),
  
  -- Auth features
  ('auth.login', 'Prijava', 'Login stranica', 'active', 'free'),
  ('auth.register', 'Registracija', 'Registracija naloga', 'active', 'free'),
  ('auth.forgot_password', 'Zaboravljena lozinka', 'Reset lozinke', 'active', 'free'),
  
  -- Portal features
  ('portal.dashboard', 'Kontrolna tabla', 'Portal dashboard', 'active', 'free'),
  ('portal.children', 'Moja djeca', 'Lista djece', 'active', 'free'),
  ('portal.passport', 'Dječiji pasoš', 'Razvojni pasoš', 'active', 'paid'),
  ('portal.passport.radar', 'Radar grafikon', '6-domena radar', 'active', 'paid'),
  ('portal.passport.reports', 'PDF izvještaji', 'Kvartalni PDF izvještaji', 'active', 'premium'),
  ('portal.passport.path', 'Razvojna putanja', 'Personalizovani plan razvoja', 'active', 'paid'),
  ('portal.activities', 'Aktivnosti', 'Kućne aktivnosti', 'active', 'paid'),
  ('portal.library', 'Biblioteka aktivnosti', 'Pretraga aktivnosti', 'active', 'paid'),
  ('portal.workshops', 'Radionice', 'Pregled radionica', 'active', 'free'),
  ('portal.gallery', 'Foto galerija', 'Galerija slika djece', 'active', 'paid'),
  ('portal.messages', 'Poruke', 'Direktne poruke voditeljima', 'active', 'paid'),
  ('portal.forum', 'Forum', 'Zajednica roditelja', 'active', 'free'),
  ('portal.progress', 'Moj napredak', 'Parent engagement tracking', 'coming_soon', 'paid'),
  ('portal.certificates', 'Sertifikati', 'Dječiji sertifikati', 'coming_soon', 'premium'),
  ('portal.referrals', 'Preporuči prijatelja', 'Referral dashboard', 'active', 'free'),
  ('portal.pioneer', 'Pioniri', 'Pioneer program', 'active', 'free'),
  ('portal.expert', 'Pitaj stručnjaka', '1× mjesečno pitanje stručnjaku', 'coming_soon', 'premium'),
  ('portal.video', 'Video tutorijali', 'Video vodiči za aktivnosti', 'coming_soon', 'premium'),
  
  -- Admin features
  ('admin.dashboard', 'Admin Dashboard', 'Admin kontrolna tabla', 'active', 'free'),
  ('admin.children', 'Upravljanje djecom', 'Children CRUD', 'active', 'free'),
  ('admin.groups', 'Grupe', 'Group management', 'active', 'free'),
  ('admin.workshops', 'Radionice', 'Workshop management', 'active', 'free'),
  ('admin.observations', 'Opservacije', 'Observation entry', 'active', 'free'),
  ('admin.attendance', 'Prisustvo', 'Attendance tracking', 'active', 'free'),
  ('admin.users', 'Korisnici', 'User management', 'active', 'free'),
  ('admin.messages', 'Poruke', 'Messaging system', 'coming_soon', 'free'),
  ('admin.statistics', 'Statistike', 'Analytics', 'coming_soon', 'free'),
  ('admin.features', 'Feature Manager', 'Feature flag management', 'active', 'free'),
  ('admin.subscriptions', 'Pretplate', 'Subscription management', 'coming_soon', 'free'),
  ('admin.events', 'Događaji', 'Event management', 'active', 'free'),
  ('admin.library', 'Biblioteka', 'Activity library admin', 'coming_soon', 'free')
ON CONFLICT (key) DO UPDATE SET
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  status = EXCLUDED.status,
  min_tier = EXCLUDED.min_tier;

-- Seed badges
INSERT INTO public.badges (key, name, description, badge_type, requirement_type, requirement_count) VALUES
  ('pioneer', 'Roditelj Pionir', 'Jedan od prvih 50 članova', 'pioneer', NULL, NULL),
  ('aktivni_roditelj', 'Aktivni roditelj', '10+ završenih kućnih aktivnosti', 'activity', 'activities_completed', 10),
  ('ambasador', 'Ambasador', '3+ uspješne preporuke', 'referral', 'referrals_converted', 3),
  ('redovan', 'Redovan', '8+ radionica u mjesecu', 'attendance', 'workshops_month', 8),
  ('posvecen', 'Posvećen', '25+ radionica ukupno', 'attendance', 'workshops_total', 25),
  ('super_roditelj', 'Super roditelj', '50+ radionica ukupno', 'attendance', 'workshops_total', 50),
  ('entuzijasta', 'Entuzijasta', '100+ radionica ukupno', 'attendance', 'workshops_total', 100)
ON CONFLICT (key) DO NOTHING;

-- ============================================================
-- COMMENTS
-- ============================================================

COMMENT ON TABLE public.feature_flags IS 'Feature flags for staged rollout';
COMMENT ON TABLE public.feature_interests IS 'Users interested in coming soon features';
COMMENT ON TABLE public.subscription_plans IS 'Available subscription tiers';
COMMENT ON TABLE public.subscriptions IS 'User active subscriptions';
COMMENT ON TABLE public.payments IS 'Payment history';
COMMENT ON TABLE public.certificates IS 'Certificates for children achievements';
COMMENT ON TABLE public.badges IS 'Badge definitions for parent achievements';
COMMENT ON TABLE public.user_badges IS 'Badges earned by users';
COMMENT ON FUNCTION public.update_profile_tier IS 'Updates profile tier when subscription changes';
COMMENT ON FUNCTION public.assign_free_tier_on_signup IS 'Auto-assigns free tier on registration';
