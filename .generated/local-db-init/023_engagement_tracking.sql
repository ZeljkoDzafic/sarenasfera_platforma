-- ─── Parent Engagement Tracking & Gamification ────────────────────────────────
-- T-905 + T-906: Engagement tracking, badges, and certificates
-- Migration: 022_engagement_tracking.sql

-- ─── Badges System ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.badges (
  id               UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  key              TEXT UNIQUE NOT NULL,           -- 'pioneer', 'active_parent', 'ambassador'
  name             TEXT NOT NULL,
  description      TEXT,
  icon_url         TEXT,                            -- emoji or icon name
  badge_type       TEXT NOT NULL CHECK (badge_type IN ('parent', 'child', 'milestone')),
  tier_required    TEXT CHECK (tier_required IN ('free', 'paid', 'premium')),
  criteria_json    JSONB DEFAULT '{}',              -- achievement criteria
  requirement_type  TEXT,                            -- e.g., 'workshops', 'activities', 'forum_posts'
  requirement_count INTEGER,                         -- e.g., 10, 25, 50
  sort_order       INTEGER DEFAULT 0,
  is_active        BOOLEAN DEFAULT true,
  created_at       TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.badges
ADD COLUMN IF NOT EXISTS tier_required TEXT,
ADD COLUMN IF NOT EXISTS criteria_json JSONB DEFAULT '{}',
ADD COLUMN IF NOT EXISTS requirement_type TEXT,
ADD COLUMN IF NOT EXISTS requirement_count INTEGER,
ADD COLUMN IF NOT EXISTS sort_order INTEGER DEFAULT 0;

ALTER TABLE public.badges DROP CONSTRAINT IF EXISTS badges_badge_type_check;
ALTER TABLE public.badges
ADD CONSTRAINT badges_badge_type_check
CHECK (
  badge_type IN (
    'parent', 'child', 'milestone',
    'pioneer', 'activity', 'referral', 'attendance', 'special'
  )
);

-- User-earned badges
CREATE TABLE IF NOT EXISTS public.user_badges (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id         UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  badge_id        UUID REFERENCES public.badges(id) NOT NULL,
  earned_at       TIMESTAMPTZ DEFAULT now(),
  progress        INTEGER DEFAULT 0,               -- for progressive badges
  UNIQUE(user_id, badge_id)
);

ALTER TABLE public.user_badges
ADD COLUMN IF NOT EXISTS progress INTEGER DEFAULT 0;

CREATE INDEX IF NOT EXISTS idx_user_badges_user ON public.user_badges(user_id);
CREATE INDEX IF NOT EXISTS idx_user_badges_earned ON public.user_badges(earned_at);

-- ─── Certificates System ───────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.certificates (
  id               UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  child_id         UUID REFERENCES public.children(id) ON DELETE CASCADE,
  user_id          UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  certificate_type TEXT NOT NULL CHECK (certificate_type IN (
                     'program_completion', 'domain_mastery', 'attendance_milestone',
                     'parent_achievement', 'custom'
                   )),
  title            TEXT NOT NULL,
  description      TEXT,
  domain           TEXT CHECK (domain IN ('emotional','social','creative','cognitive','motor','language')),
  milestone_value  INTEGER,                         -- e.g., 25, 50, 75, 96 workshops
  issued_date      TIMESTAMPTZ DEFAULT now(),
  pdf_url          TEXT,                            -- generated PDF link
  is_published     BOOLEAN DEFAULT true,
  created_at       TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.certificates
ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
ADD COLUMN IF NOT EXISTS is_published BOOLEAN DEFAULT true;

ALTER TABLE public.certificates DROP CONSTRAINT IF EXISTS certificates_certificate_type_check;
ALTER TABLE public.certificates
ADD CONSTRAINT certificates_certificate_type_check
CHECK (
  certificate_type IN (
    'program_completion', 'domain_mastery', 'attendance_milestone',
    'parent_achievement', 'custom'
  )
);

CREATE INDEX IF NOT EXISTS idx_certificates_child ON public.certificates(child_id);
CREATE INDEX IF NOT EXISTS idx_certificates_user ON public.certificates(user_id);
CREATE INDEX IF NOT EXISTS idx_certificates_type ON public.certificates(certificate_type);

-- ─── Engagement Tracking ───────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.engagement_events (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id         UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  event_type      TEXT NOT NULL CHECK (event_type IN (
                    'workshop_attended', 'home_activity_completed', 'forum_post',
                    'forum_reply', 'referral_made', 'login', 'profile_updated',
                    'resource_downloaded', 'certificate_earned'
                  )),
  event_date      DATE NOT NULL DEFAULT CURRENT_DATE,
  points          INTEGER DEFAULT 1,
  metadata        JSONB DEFAULT '{}',
  created_at      TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_engagement_user ON public.engagement_events(user_id);
CREATE INDEX IF NOT EXISTS idx_engagement_date ON public.engagement_events(event_date);
CREATE INDEX IF NOT EXISTS idx_engagement_type ON public.engagement_events(event_type);

-- ─── Engagement Scores (Materialized View) ────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.user_engagement_scores (
  user_id         UUID REFERENCES public.profiles(id) ON DELETE CASCADE PRIMARY KEY,
  total_points    INTEGER DEFAULT 0,
  workshops_attended INTEGER DEFAULT 0,
  activities_completed INTEGER DEFAULT 0,
  forum_posts     INTEGER DEFAULT 0,
  referrals_made  INTEGER DEFAULT 0,
  current_streak  INTEGER DEFAULT 0,              -- consecutive weeks with activity
  longest_streak  INTEGER DEFAULT 0,
  last_activity   TIMESTAMPTZ,
  updated_at      TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_engagement_scores_points ON public.user_engagement_scores(total_points);
CREATE INDEX IF NOT EXISTS idx_engagement_scores_streak ON public.user_engagement_scores(current_streak);

-- ─── Seed: Default Badges ──────────────────────────────────────────────────────
INSERT INTO public.badges (key, name, description, icon_url, badge_type, tier_required, criteria_json, sort_order) VALUES
-- Parent Badges
('pioneer', 'Roditelj Pionir', 'Jedan od prvih 50 roditelja na platformi', '🎖️', 'parent', 'free', '{"is_pioneer": true}', 1),
('active_parent', 'Aktivni Roditelj', 'Završeno 10+ kućnih aktivnosti', '⭐', 'parent', 'paid', '{"home_activities": 10}', 2),
('super_active', 'Super Aktivni', 'Završeno 25+ kućnih aktivnosti', '🌟', 'parent', 'paid', '{"home_activities": 25}', 3),
('ambassador', 'Ambasador', 'Preporučeno 3+ prijatelja', '🎯', 'parent', 'free', '{"referrals": 3}', 4),
('super_ambassador', 'Super Ambasador', 'Preporučeno 10+ prijatelja', '🏆', 'parent', 'free', '{"referrals": 10}', 5),
('regular', 'Redovan', 'Prisustvovano 8+ radionica u mjesecu', '📅', 'parent', 'paid', '{"monthly_workshops": 8}', 6),
('engaged', 'Angažovan', 'Aktivan na forumu (10+ postova)', '💬', 'parent', 'premium', '{"forum_posts": 10}', 7),
('community_leader', 'Lider Zajednice', 'Aktivan na forumu (50+ postova)', '👑', 'parent', 'premium', '{"forum_posts": 50}', 8),
('streak_7', 'Nedeljni Redovnik', '7 uzastopnih sedmica aktivnosti', '🔥', 'parent', 'paid', '{"streak": 7}', 9),
('streak_30', 'Mjesečni Redovnik', '30 uzastopnih sedmica aktivnosti', '🔥🔥', 'parent', 'paid', '{"streak": 30}', 10),

-- Child Milestones
('attendance_25', '25 Radionica', 'Prisustvovano 25 radionica', '🎨', 'milestone', 'paid', '{"workshops": 25}', 11),
('attendance_50', '50 Radionica', 'Prisustvovano 50 radionica', '🎨🎨', 'milestone', 'paid', '{"workshops": 50}', 12),
('attendance_75', '75 Radionica', 'Prisustvovano 75 radionica', '🎨🎨🎨', 'milestone', 'paid', '{"workshops": 75}', 13),
('attendance_96', 'Program Završen', 'Prisustvovano svim radionicama (96)', '🎓', 'milestone', 'paid', '{"workshops": 96}', 14),

-- Domain Mastery
('creative_master', 'Kreativni Istraživač', 'Majstorstvo u kreativnom razvoju', '🎨', 'child', 'premium', '{"domain": "creative", "score": 4.5}', 15),
('language_master', 'Mali Govornik', 'Majstorstvo u jezičkom razvoju', '💬', 'child', 'premium', '{"domain": "language", "score": 4.5}', 16),
('cognitive_master', 'Mali Naučnik', 'Majstorstvo u kognitivnom razvoju', '🧠', 'child', 'premium', '{"domain": "cognitive", "score": 4.5}', 17),
('motor_master', 'Mali Sportista', 'Majstorstvo u motoričkom razvoju', '🏃', 'child', 'premium', '{"domain": "motor", "score": 4.5}', 18),
('emotional_master', 'Emocionalni Guru', 'Majstorstvo u emocionalnom razvoju', '❤️', 'child', 'premium', '{"domain": "emotional", "score": 4.5}', 19),
('social_master', 'Društvena Leptir', 'Majstorstvo u socijalnom razvoju', '🤝', 'child', 'premium', '{"domain": "social", "score": 4.5}', 20)
ON CONFLICT (key) DO NOTHING;

-- ─── RLS Policies ──────────────────────────────────────────────────────────────
ALTER TABLE public.badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.certificates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.engagement_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_engagement_scores ENABLE ROW LEVEL SECURITY;

-- Badges: public read
DROP POLICY IF EXISTS "badges_public_read" ON public.badges;
CREATE POLICY "badges_public_read" ON public.badges
  FOR SELECT USING (is_active = true);

-- User badges: users see own, admin sees all
DROP POLICY IF EXISTS "user_badges_own" ON public.user_badges;
CREATE POLICY "user_badges_own" ON public.user_badges
  FOR SELECT USING (user_id = auth.uid() OR auth.jwt()->'app_metadata'->>'role' = 'admin');
DROP POLICY IF EXISTS "user_badges_admin_all" ON public.user_badges;
CREATE POLICY "user_badges_admin_all" ON public.user_badges
  FOR ALL USING (auth.jwt()->'app_metadata'->>'role' = 'admin');

-- Certificates: users see own children's, admin manages
DROP POLICY IF EXISTS "certificates_own_children" ON public.certificates;
CREATE POLICY "certificates_own_children" ON public.certificates
  FOR SELECT USING (
    user_id = auth.uid() OR
    (child_id IS NOT NULL AND EXISTS (
      SELECT 1 FROM public.parent_children pc
      WHERE pc.child_id = certificates.child_id
        AND pc.parent_id = auth.uid()
    )) OR
    auth.jwt()->'app_metadata'->>'role' IN ('staff', 'admin')
  );
DROP POLICY IF EXISTS "certificates_admin_all" ON public.certificates;
CREATE POLICY "certificates_admin_all" ON public.certificates
  FOR ALL USING (auth.jwt()->'app_metadata'->>'role' = 'admin');

-- Engagement events: users see own, admin sees all
DROP POLICY IF EXISTS "engagement_own" ON public.engagement_events;
CREATE POLICY "engagement_own" ON public.engagement_events
  FOR SELECT USING (user_id = auth.uid() OR auth.jwt()->'app_metadata'->>'role' = 'admin');
DROP POLICY IF EXISTS "engagement_insert_own" ON public.engagement_events;
CREATE POLICY "engagement_insert_own" ON public.engagement_events
  FOR INSERT WITH CHECK (user_id = auth.uid() OR auth.jwt()->'app_metadata'->>'role' IN ('staff', 'admin'));

-- Engagement scores: users see own, admin sees all
DROP POLICY IF EXISTS "scores_own" ON public.user_engagement_scores;
CREATE POLICY "scores_own" ON public.user_engagement_scores
  FOR SELECT USING (user_id = auth.uid() OR auth.jwt()->'app_metadata'->>'role' = 'admin');
DROP POLICY IF EXISTS "scores_admin_all" ON public.user_engagement_scores;
CREATE POLICY "scores_admin_all" ON public.user_engagement_scores
  FOR ALL USING (auth.jwt()->'app_metadata'->>'role' = 'admin');

-- ─── Functions: Update Engagement Score ────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.update_engagement_score(p_user_id UUID)
RETURNS void AS $$
BEGIN
  INSERT INTO public.user_engagement_scores (user_id, total_points, workshops_attended, activities_completed, forum_posts, referrals_made, last_activity, updated_at)
  SELECT
    p_user_id,
    COALESCE(SUM(points), 0) as total_points,
    COALESCE(SUM(CASE WHEN event_type = 'workshop_attended' THEN 1 ELSE 0 END), 0) as workshops_attended,
    COALESCE(SUM(CASE WHEN event_type = 'home_activity_completed' THEN 1 ELSE 0 END), 0) as activities_completed,
    COALESCE(SUM(CASE WHEN event_type IN ('forum_post', 'forum_reply') THEN 1 ELSE 0 END), 0) as forum_posts,
    COALESCE(SUM(CASE WHEN event_type = 'referral_made' THEN 1 ELSE 0 END), 0) as referrals_made,
    MAX(created_at) as last_activity,
    now() as updated_at
  FROM public.engagement_events
  WHERE user_id = p_user_id
  ON CONFLICT (user_id) DO UPDATE SET
    total_points = EXCLUDED.total_points,
    workshops_attended = EXCLUDED.workshops_attended,
    activities_completed = EXCLUDED.activities_completed,
    forum_posts = EXCLUDED.forum_posts,
    referrals_made = EXCLUDED.referrals_made,
    last_activity = EXCLUDED.last_activity,
    updated_at = now();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ─── End of Migration ──────────────────────────────────────────────────────────
