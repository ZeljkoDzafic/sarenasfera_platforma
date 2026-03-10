-- ─── CRM: Leads, Referrals, Pioneer Wall, Forum ──────────────────────────────
-- T-102: Database Migrations
-- Migration: 017_crm_referrals.sql

-- NOTE: The 'leads' table was created in 001_events.sql
-- This file extends the CRM layer

-- ─── Lead Activities (CRM funnel tracking) ────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.lead_activities (
  id         UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  lead_id    UUID REFERENCES public.leads(id) ON DELETE CASCADE,
  email      TEXT,                            -- denormalized for easy lookup
  type       TEXT NOT NULL,                   -- 'email_open', 'page_view', 'quiz_complete', 'registration', 'subscription'
  data       JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_lead_activities_lead  ON public.lead_activities(lead_id);
CREATE INDEX IF NOT EXISTS idx_lead_activities_email ON public.lead_activities(email);
CREATE INDEX IF NOT EXISTS idx_lead_activities_type  ON public.lead_activities(type);

-- ─── Referrals ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.referrals (
  id               UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  referrer_id      UUID REFERENCES public.profiles(id) NOT NULL,
  referral_code    TEXT NOT NULL UNIQUE,
  referred_email   TEXT,
  referred_user_id UUID REFERENCES public.profiles(id),
  status           TEXT NOT NULL DEFAULT 'pending'
                     CHECK (status IN ('pending', 'registered', 'paid', 'reward_granted', 'expired')),
  reward_granted   BOOLEAN DEFAULT false,
  reward_type      TEXT,                      -- 'free_month', 'discount'
  created_at       TIMESTAMPTZ DEFAULT now(),
  converted_at     TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_referrals_referrer ON public.referrals(referrer_id);
CREATE INDEX IF NOT EXISTS idx_referrals_code     ON public.referrals(referral_code);
CREATE INDEX IF NOT EXISTS idx_referrals_email    ON public.referrals(referred_email);

-- ─── Pioneer Wall ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.pioneer_wall (
  id           UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id      UUID REFERENCES public.profiles(id) NOT NULL,
  display_name TEXT NOT NULL,                 -- name shown on pioneer wall (can be custom)
  city         TEXT,
  joined_at    TIMESTAMPTZ DEFAULT now(),
  slot_number  INTEGER,                       -- 1..50
  is_visible   BOOLEAN DEFAULT true
);

CREATE INDEX IF NOT EXISTS idx_pioneer_wall_user ON public.pioneer_wall(user_id);

-- ─── Forum Topics & Posts ─────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.forum_topics (
  id             UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title          TEXT NOT NULL,
  slug           TEXT UNIQUE NOT NULL,
  content        TEXT,
  author_id      UUID REFERENCES public.profiles(id) NOT NULL,
  category       TEXT,
  skill_area_id  UUID REFERENCES public.skill_areas(id),
  age_group      TEXT,
  is_pinned      BOOLEAN DEFAULT false,
  is_locked      BOOLEAN DEFAULT false,
  is_published   BOOLEAN DEFAULT true,
  view_count     INTEGER DEFAULT 0,
  reply_count    INTEGER DEFAULT 0,
  created_at     TIMESTAMPTZ DEFAULT now(),
  updated_at     TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_forum_topics_category ON public.forum_topics(category);
CREATE INDEX IF NOT EXISTS idx_forum_topics_author   ON public.forum_topics(author_id);

CREATE TABLE IF NOT EXISTS public.forum_posts (
  id         UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  topic_id   UUID REFERENCES public.forum_topics(id) ON DELETE CASCADE NOT NULL,
  author_id  UUID REFERENCES public.profiles(id) NOT NULL,
  content    TEXT NOT NULL,
  is_answer  BOOLEAN DEFAULT false,           -- marked as "best answer"
  parent_id  UUID REFERENCES public.forum_posts(id), -- nested replies
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_forum_posts_topic  ON public.forum_posts(topic_id, created_at);
CREATE INDEX IF NOT EXISTS idx_forum_posts_author ON public.forum_posts(author_id);

DROP TRIGGER IF EXISTS forum_topics_updated_at ON public.forum_topics;
CREATE TRIGGER forum_topics_updated_at
  BEFORE UPDATE ON public.forum_topics
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ─── RLS ──────────────────────────────────────────────────────────────────────
ALTER TABLE public.lead_activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.referrals       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pioneer_wall    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.forum_topics    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.forum_posts     ENABLE ROW LEVEL SECURITY;

-- Lead activities: admin only
DROP POLICY IF EXISTS "lead_activities_admin" ON public.lead_activities;
CREATE POLICY "lead_activities_admin" ON public.lead_activities FOR ALL USING (auth.jwt()->'app_metadata'->>'role' = 'admin');

-- Referrals: user sees own; admin sees all
DROP POLICY IF EXISTS "referrals_own" ON public.referrals;
CREATE POLICY "referrals_own" ON public.referrals FOR SELECT USING (referrer_id = auth.uid() OR auth.jwt()->'app_metadata'->>'role' = 'admin');
DROP POLICY IF EXISTS "referrals_insert" ON public.referrals;
CREATE POLICY "referrals_insert" ON public.referrals FOR INSERT WITH CHECK (referrer_id = auth.uid());
DROP POLICY IF EXISTS "referrals_admin" ON public.referrals;
CREATE POLICY "referrals_admin" ON public.referrals FOR ALL    USING (auth.jwt()->'app_metadata'->>'role' = 'admin');

-- Pioneer wall: public read
DROP POLICY IF EXISTS "pioneer_wall_public" ON public.pioneer_wall;
CREATE POLICY "pioneer_wall_public" ON public.pioneer_wall FOR SELECT USING (is_visible = true);
DROP POLICY IF EXISTS "pioneer_wall_admin" ON public.pioneer_wall;
CREATE POLICY "pioneer_wall_admin" ON public.pioneer_wall FOR ALL    USING (auth.jwt()->'app_metadata'->>'role' = 'admin');

-- Forum: authenticated read published
DROP POLICY IF EXISTS "forum_topics_read" ON public.forum_topics;
CREATE POLICY "forum_topics_read" ON public.forum_topics FOR SELECT USING (is_published = true AND auth.uid() IS NOT NULL);
DROP POLICY IF EXISTS "forum_topics_write" ON public.forum_topics;
CREATE POLICY "forum_topics_write" ON public.forum_topics FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
DROP POLICY IF EXISTS "forum_topics_admin" ON public.forum_topics;
CREATE POLICY "forum_topics_admin" ON public.forum_topics FOR ALL    USING (auth.jwt()->'app_metadata'->>'role' IN ('admin', 'staff'));
DROP POLICY IF EXISTS "forum_posts_read" ON public.forum_posts;
CREATE POLICY "forum_posts_read" ON public.forum_posts  FOR SELECT USING (auth.uid() IS NOT NULL);
DROP POLICY IF EXISTS "forum_posts_write" ON public.forum_posts;
CREATE POLICY "forum_posts_write" ON public.forum_posts  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
DROP POLICY IF EXISTS "forum_posts_own" ON public.forum_posts;
CREATE POLICY "forum_posts_own" ON public.forum_posts  FOR UPDATE USING (author_id = auth.uid());
DROP POLICY IF EXISTS "forum_posts_admin" ON public.forum_posts;
CREATE POLICY "forum_posts_admin" ON public.forum_posts  FOR ALL    USING (auth.jwt()->'app_metadata'->>'role' IN ('admin', 'staff'));
