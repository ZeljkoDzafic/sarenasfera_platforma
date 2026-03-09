-- ─── Communication: Messages, Notifications, Email Campaigns ────────────────
-- T-102: Database Migrations
-- Migration: 015_communication.sql

-- ─── Messages (parent-staff direct messages) ──────────────────────────────────
CREATE TABLE IF NOT EXISTS public.messages (
  id           UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  sender_id    UUID REFERENCES public.profiles(id) NOT NULL,
  recipient_id UUID REFERENCES public.profiles(id) NOT NULL,
  child_id     UUID REFERENCES public.children(id),     -- if about a specific child
  subject      TEXT,
  content      TEXT NOT NULL,
  read_at      TIMESTAMPTZ,
  is_archived  BOOLEAN DEFAULT false,
  parent_message_id UUID REFERENCES public.messages(id), -- thread support
  created_at   TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_messages_sender    ON public.messages(sender_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_recipient ON public.messages(recipient_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_unread    ON public.messages(recipient_id, read_at) WHERE read_at IS NULL;

-- ─── Notifications ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.notifications (
  id           UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id      UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  type         TEXT NOT NULL
                 CHECK (type IN ('message', 'report', 'session', 'milestone', 'activity', 'system', 'payment')),
  title        TEXT NOT NULL,
  body         TEXT,
  action_url   TEXT,
  data         JSONB DEFAULT '{}',
  read_at      TIMESTAMPTZ,
  created_at   TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_notifications_user   ON public.notifications(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_unread ON public.notifications(user_id, read_at) WHERE read_at IS NULL;

-- ─── Email Campaigns ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.email_campaigns (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name            TEXT NOT NULL,
  subject         TEXT NOT NULL,
  body_html       TEXT,
  body_text       TEXT,
  target_audience TEXT NOT NULL DEFAULT 'all'
                    CHECK (target_audience IN ('all', 'parents', 'paid', 'premium', 'staff', 'leads')),
  status          TEXT DEFAULT 'draft'
                    CHECK (status IN ('draft', 'scheduled', 'sending', 'sent', 'cancelled')),
  scheduled_at    TIMESTAMPTZ,
  sent_at         TIMESTAMPTZ,
  sent_count      INTEGER DEFAULT 0,
  open_count      INTEGER DEFAULT 0,
  click_count     INTEGER DEFAULT 0,
  created_by      UUID REFERENCES public.profiles(id),
  created_at      TIMESTAMPTZ DEFAULT now(),
  updated_at      TIMESTAMPTZ DEFAULT now()
);

DROP TRIGGER IF EXISTS email_campaigns_updated_at ON public.email_campaigns;
CREATE TRIGGER email_campaigns_updated_at
  BEFORE UPDATE ON public.email_campaigns
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ─── Email Recipients ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.email_recipients (
  id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  campaign_id UUID REFERENCES public.email_campaigns(id) ON DELETE CASCADE NOT NULL,
  email       TEXT NOT NULL,
  user_id     UUID REFERENCES public.profiles(id),
  status      TEXT DEFAULT 'pending'
                CHECK (status IN ('pending', 'sent', 'opened', 'clicked', 'bounced', 'unsubscribed')),
  sent_at     TIMESTAMPTZ,
  opened_at   TIMESTAMPTZ,
  created_at  TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_email_recipients_campaign ON public.email_recipients(campaign_id);
CREATE INDEX IF NOT EXISTS idx_email_recipients_status   ON public.email_recipients(status);

-- ─── RLS ──────────────────────────────────────────────────────────────────────
ALTER TABLE public.messages         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.email_campaigns  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.email_recipients ENABLE ROW LEVEL SECURITY;

-- Messages: participants can read; admin sees all
CREATE POLICY IF NOT EXISTS "messages_own_read" ON public.messages
  FOR SELECT USING (sender_id = auth.uid() OR recipient_id = auth.uid() OR auth.jwt()->'app_metadata'->>'role' = 'admin');
CREATE POLICY IF NOT EXISTS "messages_own_insert" ON public.messages
  FOR INSERT WITH CHECK (sender_id = auth.uid());
CREATE POLICY IF NOT EXISTS "messages_own_update" ON public.messages
  FOR UPDATE USING (recipient_id = auth.uid()); -- only recipient can mark as read

-- Notifications: user sees own
CREATE POLICY IF NOT EXISTS "notifications_own" ON public.notifications
  FOR SELECT USING (user_id = auth.uid());
CREATE POLICY IF NOT EXISTS "notifications_own_update" ON public.notifications
  FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY IF NOT EXISTS "notifications_admin" ON public.notifications
  FOR ALL USING (auth.jwt()->'app_metadata'->>'role' = 'admin');

-- Email campaigns: admin only
CREATE POLICY IF NOT EXISTS "campaigns_admin" ON public.email_campaigns FOR ALL USING (auth.jwt()->'app_metadata'->>'role' = 'admin');
CREATE POLICY IF NOT EXISTS "recipients_admin" ON public.email_recipients FOR ALL USING (auth.jwt()->'app_metadata'->>'role' = 'admin');
