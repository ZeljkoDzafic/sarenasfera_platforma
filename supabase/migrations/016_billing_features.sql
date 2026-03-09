-- ─── Billing: Subscription Plans, Subscriptions, Payments, Feature Flags ─────
-- T-102 + T-810 + T-820: Database Migrations
-- Migration: 016_billing_features.sql

-- ─── Subscription Plans ───────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.subscription_plans (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  key             TEXT UNIQUE NOT NULL,       -- 'free', 'paid', 'premium'
  name            TEXT NOT NULL,
  price_km        NUMERIC(8,2) NOT NULL DEFAULT 0,
  billing_period  TEXT DEFAULT 'monthly'
                    CHECK (billing_period IN ('monthly', 'annual')),
  features        JSONB DEFAULT '[]',         -- list of feature strings
  max_children    INTEGER DEFAULT 3,
  is_active       BOOLEAN DEFAULT true,
  sort_order      INTEGER DEFAULT 0,
  created_at      TIMESTAMPTZ DEFAULT now()
);

INSERT INTO public.subscription_plans (key, name, price_km, sort_order, features)
VALUES
  ('free',    'Besplatni',  0.00,  1, '["blog", "resources_3", "trial_workshop"]'),
  ('paid',    'Osnovni',   15.00,  2, '["blog", "resources_all", "child_passport", "workshop_materials", "quarterly_reports", "home_activities"]'),
  ('premium', 'Premium',   30.00,  3, '["blog", "resources_all", "child_passport", "workshop_materials", "quarterly_reports", "home_activities", "videos", "community", "expert_qa", "personalized_path", "certificates"]')
ON CONFLICT (key) DO UPDATE SET price_km = EXCLUDED.price_km;

-- ─── Subscriptions ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.subscriptions (
  id                UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id           UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  plan_key          TEXT NOT NULL REFERENCES public.subscription_plans(key),
  status            TEXT NOT NULL DEFAULT 'active'
                      CHECK (status IN ('active', 'cancelled', 'past_due', 'paused', 'trial')),
  started_at        TIMESTAMPTZ DEFAULT now(),
  ends_at           TIMESTAMPTZ,
  cancelled_at      TIMESTAMPTZ,
  trial_ends_at     TIMESTAMPTZ,
  is_pioneer        BOOLEAN DEFAULT false,    -- "Roditelji Pioniri" locked price
  pioneer_price_km  NUMERIC(8,2),
  referral_code     TEXT,                     -- code used when subscribing
  created_at        TIMESTAMPTZ DEFAULT now(),
  updated_at        TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_subscriptions_user   ON public.subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_status ON public.subscriptions(status);

DROP TRIGGER IF EXISTS subscriptions_updated_at ON public.subscriptions;
CREATE TRIGGER subscriptions_updated_at
  BEFORE UPDATE ON public.subscriptions
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ─── Payments ─────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.payments (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id         UUID REFERENCES public.profiles(id) NOT NULL,
  subscription_id UUID REFERENCES public.subscriptions(id),
  amount_km       NUMERIC(8,2) NOT NULL,
  status          TEXT NOT NULL DEFAULT 'pending'
                    CHECK (status IN ('pending', 'completed', 'failed', 'refunded')),
  payment_method  TEXT,                       -- 'card', 'bank_transfer', 'cash'
  reference       TEXT,
  notes           TEXT,
  paid_at         TIMESTAMPTZ,
  created_at      TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_payments_user   ON public.payments(user_id);
CREATE INDEX IF NOT EXISTS idx_payments_status ON public.payments(status);

-- ─── Feature Flags ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.feature_flags (
  id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  key         TEXT UNIQUE NOT NULL,           -- 'child_passport', 'community', etc.
  name        TEXT NOT NULL,
  description TEXT,
  status      TEXT NOT NULL DEFAULT 'active'
                CHECK (status IN ('active', 'coming_soon', 'hidden', 'beta')),
  min_tier    TEXT DEFAULT 'free'
                CHECK (min_tier IN ('free', 'paid', 'premium')),
  location_id UUID REFERENCES public.locations(id), -- null = global
  updated_by  UUID REFERENCES public.profiles(id),
  created_at  TIMESTAMPTZ DEFAULT now(),
  updated_at  TIMESTAMPTZ DEFAULT now()
);

DROP TRIGGER IF EXISTS feature_flags_updated_at ON public.feature_flags;
CREATE TRIGGER feature_flags_updated_at
  BEFORE UPDATE ON public.feature_flags
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ─── Seed: Core Feature Flags ─────────────────────────────────────────────────
INSERT INTO public.feature_flags (key, name, status, min_tier)
VALUES
  ('child_passport',       'Dječiji pasoš',               'active',      'paid'),
  ('workshop_materials',   'Materijali za radionice',      'active',      'paid'),
  ('home_activities',      'Kućne aktivnosti',             'active',      'paid'),
  ('quarterly_reports',    'Kvartalni izvještaji',         'active',      'paid'),
  ('video_tutorials',      'Video tutorijali',             'active',      'premium'),
  ('community_forum',      'Zajednica roditelja',          'coming_soon', 'premium'),
  ('expert_qa',            'Pitanje stručnjaku',           'coming_soon', 'premium'),
  ('personalized_path',    'Personalizovana putanja',      'coming_soon', 'premium'),
  ('certificates',         'Certifikati i nagrade',        'coming_soon', 'premium'),
  ('referral_system',      'Preporuči prijatelja',         'active',      'free'),
  ('pioneer_program',      'Roditelji Pioniri',            'active',      'free'),
  ('development_quiz',     'Razvojni kviz',                'active',      'free'),
  ('activity_library',     'Biblioteka aktivnosti',        'coming_soon', 'paid')
ON CONFLICT (key) DO NOTHING;

-- ─── Pioneer Slots ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.pioneer_slots (
  id           UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  max_slots    INTEGER NOT NULL DEFAULT 50,
  used_slots   INTEGER NOT NULL DEFAULT 0,
  is_active    BOOLEAN DEFAULT true,
  created_at   TIMESTAMPTZ DEFAULT now(),
  updated_at   TIMESTAMPTZ DEFAULT now()
);

-- Initialize pioneer slots counter
INSERT INTO public.pioneer_slots (max_slots, used_slots) VALUES (50, 0) ON CONFLICT DO NOTHING;

-- ─── Feature Interests (track user interest in coming_soon features) ──────────
CREATE TABLE IF NOT EXISTS public.feature_interests (
  id           UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id      UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  feature_key  TEXT NOT NULL,
  created_at   TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, feature_key)
);

CREATE INDEX IF NOT EXISTS idx_feature_interests_user ON public.feature_interests(user_id);
CREATE INDEX IF NOT EXISTS idx_feature_interests_feature ON public.feature_interests(feature_key);

-- ─── RLS ──────────────────────────────────────────────────────────────────────
ALTER TABLE public.subscription_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscriptions      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.feature_flags      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pioneer_slots      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.feature_interests  ENABLE ROW LEVEL SECURITY;

-- Plans: public read
CREATE POLICY IF NOT EXISTS "plans_public_read" ON public.subscription_plans FOR SELECT USING (is_active = true);
CREATE POLICY IF NOT EXISTS "plans_admin_all"   ON public.subscription_plans FOR ALL    USING (auth.jwt()->'app_metadata'->>'role' = 'admin');

-- Subscriptions: user sees own; admin sees all
CREATE POLICY IF NOT EXISTS "subs_own_read"   ON public.subscriptions FOR SELECT USING (user_id = auth.uid() OR auth.jwt()->'app_metadata'->>'role' = 'admin');
CREATE POLICY IF NOT EXISTS "subs_admin_all"  ON public.subscriptions FOR ALL    USING (auth.jwt()->'app_metadata'->>'role' = 'admin');

-- Payments: user sees own; admin manages
CREATE POLICY IF NOT EXISTS "payments_own"    ON public.payments FOR SELECT USING (user_id = auth.uid() OR auth.jwt()->'app_metadata'->>'role' = 'admin');
CREATE POLICY IF NOT EXISTS "payments_admin"  ON public.payments FOR ALL    USING (auth.jwt()->'app_metadata'->>'role' = 'admin');

-- Feature flags: public read (active/coming_soon visible); admin manages
CREATE POLICY IF NOT EXISTS "flags_public_read" ON public.feature_flags FOR SELECT USING (status IN ('active', 'coming_soon'));
CREATE POLICY IF NOT EXISTS "flags_admin_all"   ON public.feature_flags FOR ALL    USING (auth.jwt()->'app_metadata'->>'role' = 'admin');

-- Pioneer slots: public read; admin updates
CREATE POLICY IF NOT EXISTS "pioneer_public_read" ON public.pioneer_slots FOR SELECT USING (true);
CREATE POLICY IF NOT EXISTS "pioneer_admin"       ON public.pioneer_slots FOR ALL    USING (auth.jwt()->'app_metadata'->>'role' = 'admin');

-- Feature interests: users can insert their own; users see own; admin sees all
CREATE POLICY IF NOT EXISTS "interests_user_insert" ON public.feature_interests FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY IF NOT EXISTS "interests_own_read"    ON public.feature_interests FOR SELECT USING (user_id = auth.uid());
CREATE POLICY IF NOT EXISTS "interests_admin_read"  ON public.feature_interests FOR SELECT USING (auth.jwt()->'app_metadata'->>'role' = 'admin');
