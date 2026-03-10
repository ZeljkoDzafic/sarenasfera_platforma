-- Migration 022: Community Forum & Partner Program
-- T-907: Community Forum
-- T-908: Partner/Affiliate Program

-- ============================================================
-- COMMUNITY FORUM (T-907)
-- ============================================================

-- Forum categories
CREATE TABLE IF NOT EXISTS public.forum_categories (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name            TEXT NOT NULL,
  slug            TEXT UNIQUE NOT NULL,
  description     TEXT,
  icon            TEXT,
  color           TEXT DEFAULT '#9b51e0',
  
  -- Ordering & visibility
  sort_order      INTEGER DEFAULT 0,
  is_active       BOOLEAN DEFAULT true,
  is_locked       BOOLEAN DEFAULT false, -- Lock entire category
  
  -- Stats (denormalized)
  topic_count     INTEGER DEFAULT 0,
  post_count      INTEGER DEFAULT 0,
  last_activity_at TIMESTAMPTZ,
  
  -- Moderation
  moderators      UUID[], -- Array of user IDs
  
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_forum_categories_slug ON public.forum_categories(slug);
CREATE INDEX IF NOT EXISTS idx_forum_categories_order ON public.forum_categories(sort_order);

ALTER TABLE public.forum_categories
ADD COLUMN IF NOT EXISTS color TEXT DEFAULT '#9b51e0',
ADD COLUMN IF NOT EXISTS is_locked BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS topic_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS post_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS last_activity_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS moderators UUID[],
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT now();

-- Forum topics
CREATE TABLE IF NOT EXISTS public.forum_topics (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title           TEXT NOT NULL,
  slug            TEXT UNIQUE NOT NULL,
  content         TEXT NOT NULL,
  
  -- Author & category
  author_id       UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  category_id     UUID NOT NULL REFERENCES public.forum_categories(id) ON DELETE CASCADE,
  
  -- Child context (optional - for child-specific discussions)
  child_id        UUID REFERENCES public.children(id) ON DELETE SET NULL,
  
  -- Status & visibility
  status          TEXT NOT NULL DEFAULT 'published'
                  CHECK (status IN ('draft', 'published', 'hidden', 'archived')),
  
  -- Moderation
  is_pinned       BOOLEAN DEFAULT false,
  is_locked       BOOLEAN DEFAULT false, -- No more replies allowed
  is_featured     BOOLEAN DEFAULT false,
  
  -- Stats (denormalized)
  view_count      INTEGER DEFAULT 0,
  reply_count     INTEGER DEFAULT 0,
  like_count      INTEGER DEFAULT 0,
  last_reply_at   TIMESTAMPTZ,
  last_reply_by   UUID REFERENCES public.profiles(id),
  
  -- Tags
  tags            TEXT[],
  
  -- Timestamps
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.forum_topics
ADD COLUMN IF NOT EXISTS category_id UUID REFERENCES public.forum_categories(id) ON DELETE CASCADE,
ADD COLUMN IF NOT EXISTS child_id UUID REFERENCES public.children(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'published',
ADD COLUMN IF NOT EXISTS is_featured BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS last_reply_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS last_reply_by UUID REFERENCES public.profiles(id),
ADD COLUMN IF NOT EXISTS tags TEXT[];

ALTER TABLE public.forum_topics DROP CONSTRAINT IF EXISTS forum_topics_status_check;
ALTER TABLE public.forum_topics
ADD CONSTRAINT forum_topics_status_check
CHECK (status IN ('draft', 'published', 'hidden', 'archived'));

CREATE INDEX IF NOT EXISTS idx_forum_topics_category ON public.forum_topics(category_id);
CREATE INDEX IF NOT EXISTS idx_forum_topics_author ON public.forum_topics(author_id);
CREATE INDEX IF NOT EXISTS idx_forum_topics_status ON public.forum_topics(status);
CREATE INDEX IF NOT EXISTS idx_forum_topics_created ON public.forum_topics(created_at);
CREATE INDEX IF NOT EXISTS idx_forum_topics_slug ON public.forum_topics(slug);

-- Forum posts (replies)
CREATE TABLE IF NOT EXISTS public.forum_posts (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  topic_id        UUID NOT NULL REFERENCES public.forum_topics(id) ON DELETE CASCADE,
  author_id       UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  content         TEXT NOT NULL,
  
  -- Parent post (for nested replies)
  parent_id       UUID REFERENCES public.forum_posts(id) ON DELETE CASCADE,
  
  -- Moderation
  is_answer       BOOLEAN DEFAULT false, -- Marked as best answer by OP
  is_edited       BOOLEAN DEFAULT false,
  edited_at       TIMESTAMPTZ,
  
  -- Stats
  like_count      INTEGER DEFAULT 0,
  
  -- Timestamps
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.forum_posts
ADD COLUMN IF NOT EXISTS is_edited BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS edited_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS like_count INTEGER DEFAULT 0;

CREATE INDEX IF NOT EXISTS idx_forum_posts_topic ON public.forum_posts(topic_id, created_at);
CREATE INDEX IF NOT EXISTS idx_forum_posts_author ON public.forum_posts(author_id);
CREATE INDEX IF NOT EXISTS idx_forum_posts_parent ON public.forum_posts(parent_id);

-- Forum likes
CREATE TABLE IF NOT EXISTS public.forum_likes (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id         UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  topic_id        UUID REFERENCES public.forum_topics(id) ON DELETE CASCADE,
  post_id         UUID REFERENCES public.forum_posts(id) ON DELETE CASCADE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  UNIQUE(user_id, topic_id, post_id),
  CHECK (topic_id IS NOT NULL OR post_id IS NOT NULL)
);

CREATE INDEX IF NOT EXISTS idx_forum_likes_user ON public.forum_likes(user_id);
CREATE INDEX IF NOT EXISTS idx_forum_likes_topic ON public.forum_likes(topic_id);
CREATE INDEX IF NOT EXISTS idx_forum_likes_post ON public.forum_likes(post_id);

-- Forum bookmarks
CREATE TABLE IF NOT EXISTS public.forum_bookmarks (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id         UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  topic_id        UUID NOT NULL REFERENCES public.forum_topics(id) ON DELETE CASCADE,
  post_id         UUID REFERENCES public.forum_posts(id) ON DELETE CASCADE,
  notes           TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  UNIQUE(user_id, topic_id, post_id)
);

CREATE INDEX IF NOT EXISTS idx_forum_bookmarks_user ON public.forum_bookmarks(user_id);
CREATE INDEX IF NOT EXISTS idx_forum_bookmarks_topic ON public.forum_bookmarks(topic_id);

-- Forum reports (for moderation)
CREATE TABLE IF NOT EXISTS public.forum_reports (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  reporter_id     UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  topic_id        UUID REFERENCES public.forum_topics(id) ON DELETE CASCADE,
  post_id         UUID REFERENCES public.forum_posts(id) ON DELETE CASCADE,
  
  reason          TEXT NOT NULL,
  reason_other    TEXT,
  
  status          TEXT NOT NULL DEFAULT 'pending'
                  CHECK (status IN ('pending', 'reviewed', 'resolved', 'dismissed')),
  
  moderator_id    UUID REFERENCES public.profiles(id),
  moderator_notes TEXT,
  resolved_at     TIMESTAMPTZ,
  
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_forum_reports_status ON public.forum_reports(status);
CREATE INDEX IF NOT EXISTS idx_forum_reports_created ON public.forum_reports(created_at);

-- User reputation/badges for forum activity
CREATE TABLE IF NOT EXISTS public.forum_reputation (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id         UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  
  -- Stats
  topic_count     INTEGER DEFAULT 0,
  post_count      INTEGER DEFAULT 0,
  like_count      INTEGER DEFAULT 0,
  best_answer_count INTEGER DEFAULT 0,
  
  -- Level
  level           TEXT NOT NULL DEFAULT 'newcomer'
                  CHECK (level IN ('newcomer', 'contributor', 'active', 'expert', 'legend')),
  
  points          INTEGER DEFAULT 0,
  
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  UNIQUE(user_id)
);

CREATE INDEX IF NOT EXISTS idx_forum_reputation_user ON public.forum_reputation(user_id);
CREATE INDEX IF NOT EXISTS idx_forum_reputation_level ON public.forum_reputation(level);

-- ============================================================
-- PARTNER/AFFILIATE PROGRAM (T-908)
-- ============================================================

-- Partner types
CREATE TYPE partner_type AS ENUM ('kindergarten', 'school', 'pediatrician', 'organization', 'influencer', 'other');

-- Partners table
CREATE TABLE IF NOT EXISTS public.partners (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name            TEXT NOT NULL,
  slug            TEXT UNIQUE NOT NULL,
  
  -- Partner info
  partner_type    partner_type NOT NULL,
  description     TEXT,
  website_url     TEXT,
  logo_url        TEXT,
  contact_email   TEXT,
  contact_phone   TEXT,
  
  -- Location
  address         TEXT,
  city            TEXT,
  canton          TEXT,
  country         TEXT DEFAULT 'Bosnia and Herzegovina',
  
  -- Affiliate
  affiliate_code  TEXT UNIQUE NOT NULL,
  commission_rate NUMERIC(5,2) DEFAULT 20, -- Percentage
  
  -- Status
  is_active       BOOLEAN DEFAULT true,
  is_verified     BOOLEAN DEFAULT false,
  
  -- Stats (denormalized)
  referral_count  INTEGER DEFAULT 0,
  conversion_count INTEGER DEFAULT 0,
  total_commission NUMERIC(10,2) DEFAULT 0,
  
  -- Metadata
  metadata        JSONB DEFAULT '{}',
  
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_partners_slug ON public.partners(slug);
CREATE INDEX IF NOT EXISTS idx_partners_type ON public.partners(partner_type);
CREATE INDEX IF NOT EXISTS idx_partners_code ON public.partners(affiliate_code);

-- Partner referrals (tracking)
CREATE TABLE IF NOT EXISTS public.partner_referrals (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  partner_id      UUID NOT NULL REFERENCES public.partners(id) ON DELETE CASCADE,
  
  -- Referred user
  user_id         UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  user_email      TEXT,
  
  -- Conversion tracking
  status          TEXT NOT NULL DEFAULT 'registered'
                  CHECK (status IN ('registered', 'trial', 'paid', 'expired')),
  
  -- Commission
  commission_earned NUMERIC(10,2) DEFAULT 0,
  commission_paid   BOOLEAN DEFAULT false,
  paid_at           TIMESTAMPTZ,
  
  -- Metadata
  source          TEXT,
  campaign        TEXT,
  metadata        JSONB DEFAULT '{}',
  
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  converted_at    TIMESTAMPTZ,
  
  UNIQUE(user_id)
);

CREATE INDEX IF NOT EXISTS idx_partner_referrals_partner ON public.partner_referrals(partner_id);
CREATE INDEX IF NOT EXISTS idx_partner_referrals_user ON public.partner_referrals(user_id);
CREATE INDEX IF NOT EXISTS idx_partner_referrals_status ON public.partner_referrals(status);

-- Partner payouts
CREATE TABLE IF NOT EXISTS public.partner_payouts (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  partner_id      UUID NOT NULL REFERENCES public.partners(id) ON DELETE CASCADE,
  
  -- Amount
  amount          NUMERIC(10,2) NOT NULL,
  currency        TEXT NOT NULL DEFAULT 'BAM',
  
  -- Period
  period_start    DATE NOT NULL,
  period_end      DATE NOT NULL,
  
  -- Payment
  payment_method  TEXT CHECK (payment_method IN ('bank', 'paypal', 'cash')),
  payment_ref     TEXT,
  payment_date    DATE,
  
  -- Status
  status          TEXT NOT NULL DEFAULT 'pending'
                  CHECK (status IN ('pending', 'processing', 'paid', 'cancelled')),
  
  -- Notes
  notes           TEXT,
  
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_partner_payouts_partner ON public.partner_payouts(partner_id);
CREATE INDEX IF NOT EXISTS idx_partner_payouts_status ON public.partner_payouts(status);

-- ============================================================
-- TRIGGERS & FUNCTIONS
-- ============================================================

-- Update forum stats on new post
CREATE OR REPLACE FUNCTION public.update_forum_topic_stats()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF TG_TABLE_NAME = 'forum_posts' THEN
    -- Update topic reply count
    UPDATE public.forum_topics
    SET
      reply_count = (SELECT COUNT(*) FROM public.forum_posts WHERE topic_id = NEW.topic_id),
      last_reply_at = NEW.created_at,
      last_reply_by = NEW.author_id,
      updated_at = now()
    WHERE id = NEW.topic_id;
    
    -- Update category stats
    UPDATE public.forum_categories
    SET
      post_count = post_count + 1,
      last_activity_at = NEW.created_at
    WHERE id = (SELECT category_id FROM public.forum_topics WHERE id = NEW.topic_id);
  END IF;
  
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_update_forum_topic_stats ON public.forum_posts;
CREATE TRIGGER trigger_update_forum_topic_stats
  AFTER INSERT ON public.forum_posts
  FOR EACH ROW EXECUTE FUNCTION public.update_forum_topic_stats();

-- Update forum reputation on activity
CREATE OR REPLACE FUNCTION public.update_forum_reputation()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  new_level TEXT;
  new_points INTEGER;
BEGIN
  IF TG_TABLE_NAME = 'forum_topics' THEN
    -- Topic created
    INSERT INTO public.forum_reputation (user_id, topic_count, points)
    VALUES (NEW.author_id, 1, 10)
    ON CONFLICT (user_id) DO UPDATE
    SET
      topic_count = forum_reputation.topic_count + 1,
      points = forum_reputation.points + 10,
      updated_at = now();
  END IF;
  
  IF TG_TABLE_NAME = 'forum_posts' THEN
    -- Post created
    INSERT INTO public.forum_reputation (user_id, post_count, points)
    VALUES (NEW.author_id, 1, 5)
    ON CONFLICT (user_id) DO UPDATE
    SET
      post_count = forum_reputation.post_count + 1,
      points = forum_reputation.points + 5,
      updated_at = now();
  END IF;
  
  IF TG_TABLE_NAME = 'forum_likes' THEN
    -- Like received (give points to content creator)
    IF NEW.post_id IS NOT NULL THEN
      UPDATE public.forum_reputation
      SET
        like_count = like_count + 1,
        points = points + 1,
        updated_at = now()
      WHERE user_id = (SELECT author_id FROM public.forum_posts WHERE id = NEW.post_id);
    END IF;
  END IF;
  
  -- Calculate level based on points
  SELECT points INTO new_points FROM public.forum_reputation WHERE user_id = NEW.author_id;
  
  IF new_points >= 1000 THEN
    new_level := 'legend';
  ELSIF new_points >= 500 THEN
    new_level := 'expert';
  ELSIF new_points >= 200 THEN
    new_level := 'active';
  ELSIF new_points >= 50 THEN
    new_level := 'contributor';
  ELSE
    new_level := 'newcomer';
  END IF;
  
  UPDATE public.forum_reputation SET level = new_level WHERE user_id = NEW.author_id;
  
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_update_forum_reputation_topics ON public.forum_topics;
CREATE TRIGGER trigger_update_forum_reputation_topics
  AFTER INSERT ON public.forum_topics
  FOR EACH ROW EXECUTE FUNCTION public.update_forum_reputation();

DROP TRIGGER IF EXISTS trigger_update_forum_reputation_posts ON public.forum_posts;
CREATE TRIGGER trigger_update_forum_reputation_posts
  AFTER INSERT ON public.forum_posts
  FOR EACH ROW EXECUTE FUNCTION public.update_forum_reputation();

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

ALTER TABLE public.forum_categories      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.forum_topics          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.forum_posts           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.forum_likes           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.forum_bookmarks       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.forum_reports         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.forum_reputation      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.partners              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.partner_referrals     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.partner_payouts       ENABLE ROW LEVEL SECURITY;

-- Forum categories: public read, admin/staff write
CREATE POLICY IF NOT EXISTS "forum_categories_public_read"
  ON public.forum_categories FOR SELECT
  USING (is_active = true);

CREATE POLICY IF NOT EXISTS "forum_categories_staff_write"
  ON public.forum_categories FOR ALL
  USING (auth.jwt()->'app_metadata'->>'role' IN ('admin', 'staff'));

-- Forum topics: authenticated read published, users can create
CREATE POLICY IF NOT EXISTS "forum_topics_authenticated_read"
  ON public.forum_topics FOR SELECT
  USING (
    (status = 'published' AND auth.uid() IS NOT NULL)
    OR auth.jwt()->'app_metadata'->>'role' IN ('admin', 'staff')
  );

CREATE POLICY IF NOT EXISTS "forum_topics_users_insert"
  ON public.forum_topics FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY IF NOT EXISTS "forum_topics_users_update"
  ON public.forum_topics FOR UPDATE
  USING (author_id = auth.uid() OR auth.jwt()->'app_metadata'->>'role' IN ('admin', 'staff'));

CREATE POLICY IF NOT EXISTS "forum_topics_admin_delete"
  ON public.forum_topics FOR DELETE
  USING (auth.jwt()->'app_metadata'->>'role' IN ('admin', 'staff'));

-- Forum posts: authenticated read, users can create
CREATE POLICY IF NOT EXISTS "forum_posts_authenticated_read"
  ON public.forum_posts FOR SELECT
  USING (auth.uid() IS NOT NULL);

CREATE POLICY IF NOT EXISTS "forum_posts_users_insert"
  ON public.forum_posts FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY IF NOT EXISTS "forum_posts_users_update"
  ON public.forum_posts FOR UPDATE
  USING (author_id = auth.uid() OR auth.jwt()->'app_metadata'->>'role' IN ('admin', 'staff'));

CREATE POLICY IF NOT EXISTS "forum_posts_admin_delete"
  ON public.forum_posts FOR DELETE
  USING (auth.jwt()->'app_metadata'->>'role' IN ('admin', 'staff'));

-- Forum likes: authenticated users can like
CREATE POLICY IF NOT EXISTS "forum_likes_authenticated"
  ON public.forum_likes FOR ALL
  USING (auth.uid() IS NOT NULL)
  WITH CHECK (auth.uid() IS NOT NULL);

-- Forum bookmarks: users manage own
CREATE POLICY IF NOT EXISTS "forum_bookmarks_own"
  ON public.forum_bookmarks FOR ALL
  USING (user_id = auth.uid());

-- Forum reports: users can report, admin can manage
CREATE POLICY IF NOT EXISTS "forum_reports_insert"
  ON public.forum_reports FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY IF NOT EXISTS "forum_reports_admin"
  ON public.forum_reports FOR ALL
  USING (auth.jwt()->'app_metadata'->>'role' IN ('admin', 'staff'));

-- Forum reputation: public read
CREATE POLICY IF NOT EXISTS "forum_reputation_public"
  ON public.forum_reputation FOR SELECT
  USING (true);

-- Partners: public read active, admin write
CREATE POLICY IF NOT EXISTS "partners_public_read"
  ON public.partners FOR SELECT
  USING (is_active = true);

CREATE POLICY IF NOT EXISTS "partners_admin_write"
  ON public.partners FOR ALL
  USING (auth.jwt()->'app_metadata'->>'role' = 'admin');

-- Partner referrals: partner sees own, admin sees all
CREATE POLICY IF NOT EXISTS "partner_referrals_partner_read"
  ON public.partner_referrals FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.partners p
      WHERE p.id = partner_referrals.partner_id
        AND p.affiliate_code = current_setting('app.current_partner_code', true)
    )
    OR auth.jwt()->'app_metadata'->>'role' = 'admin'
  );

CREATE POLICY IF NOT EXISTS "partner_referrals_admin"
  ON public.partner_referrals FOR ALL
  USING (auth.jwt()->'app_metadata'->>'role' = 'admin');

-- Partner payouts: partner sees own, admin sees all
CREATE POLICY IF NOT EXISTS "partner_payouts_partner_read"
  ON public.partner_payouts FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.partners p
      WHERE p.id = partner_payouts.partner_id
        AND p.affiliate_code = current_setting('app.current_partner_code', true)
    )
    OR auth.jwt()->'app_metadata'->>'role' = 'admin'
  );

CREATE POLICY IF NOT EXISTS "partner_payouts_admin"
  ON public.partner_payouts FOR ALL
  USING (auth.jwt()->'app_metadata'->>'role' = 'admin');

-- ============================================================
-- SEED DATA
-- ============================================================

-- Seed forum categories
INSERT INTO public.forum_categories (name, slug, description, icon, color, sort_order) VALUES
  ('Opšte', 'opste', 'Opšte diskusije o roditeljstvu i Šarenoj Sferi', '💬', '#9b51e0', 1),
  ('Po uzrastu', 'po-uzrastu', 'Diskusije po uzrasnim grupama', '👶', '#cf2e2e', 2),
  ('Po domenu', 'po-domenu', 'Razvojne domene i aktivnosti', '🎨', '#fcb900', 3),
  ('Aktivnosti', 'aktivnosti', 'Dijeljenje iskustava o kućnim aktivnostima', '🏠', '#0693e3', 4),
  ('Pitaj stručnjaka', 'pitaj-strucnjaka', 'Pitanja za naše stručnjake', '👨‍⚕️', '#00d084', 5),
  ('Upoznavanje', 'upoznavanje', 'Predstavite se drugim roditeljima', '👋', '#f78da7', 6)
ON CONFLICT (slug) DO NOTHING;

-- Seed forum reputation levels
INSERT INTO public.forum_reputation (user_id, level, points)
SELECT id, 'newcomer', 0 FROM public.profiles
ON CONFLICT (user_id) DO NOTHING;

-- ============================================================
-- COMMENTS
-- ============================================================

COMMENT ON TABLE public.forum_categories IS 'Forum discussion categories';
COMMENT ON TABLE public.forum_topics IS 'Forum discussion topics';
COMMENT ON TABLE public.forum_posts IS 'Forum replies/posts';
COMMENT ON TABLE public.forum_likes IS 'Forum content likes';
COMMENT ON TABLE public.forum_bookmarks IS 'User bookmarked topics/posts';
COMMENT ON TABLE public.forum_reports IS 'Content reports for moderation';
COMMENT ON TABLE public.forum_reputation IS 'User forum reputation and levels';
COMMENT ON TABLE public.partners IS 'Partner/affiliate organizations';
COMMENT ON TABLE public.partner_referrals IS 'Partner referral tracking';
COMMENT ON TABLE public.partner_payouts IS 'Partner commission payouts';
