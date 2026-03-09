-- Migration: Quiz Responses
-- T-900: Development Quiz (Lead Generation)

-- Quiz responses table (saves answers + computed results for analytics)
CREATE TABLE IF NOT EXISTS public.quiz_responses (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  session_id      TEXT NOT NULL,              -- anonymous session identifier
  email           TEXT,                       -- captured at end (optional)
  name            TEXT,
  answers         JSONB NOT NULL DEFAULT '{}', -- {q1: 'a', q2: 'b', ...}
  results         JSONB NOT NULL DEFAULT '{}', -- {emotional: 3, social: 4, ...}
  recommendations JSONB DEFAULT '[]',          -- [{domain, text, workshop_slug}]
  age_group       TEXT,                        -- '2-3', '3-4', '4-5', '5-6'
  completed       BOOLEAN NOT NULL DEFAULT false,
  shared          BOOLEAN NOT NULL DEFAULT false,
  share_token     TEXT UNIQUE,                 -- for shareable result link
  referral_code   TEXT,
  user_id         UUID REFERENCES auth.users(id),
  created_at      TIMESTAMPTZ DEFAULT now(),
  updated_at      TIMESTAMPTZ DEFAULT now()
);

-- Indexes
CREATE INDEX IF NOT EXISTS quiz_responses_email_idx    ON public.quiz_responses(email);
CREATE INDEX IF NOT EXISTS quiz_responses_session_idx  ON public.quiz_responses(session_id);
CREATE INDEX IF NOT EXISTS quiz_responses_completed_idx ON public.quiz_responses(completed);
CREATE INDEX IF NOT EXISTS quiz_responses_share_idx    ON public.quiz_responses(share_token) WHERE share_token IS NOT NULL;

-- Updated_at trigger
CREATE TRIGGER quiz_responses_updated_at
  BEFORE UPDATE ON public.quiz_responses
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- RLS
ALTER TABLE public.quiz_responses ENABLE ROW LEVEL SECURITY;

-- Anyone can insert (no auth required)
CREATE POLICY "quiz_responses_public_insert" ON public.quiz_responses
  FOR INSERT WITH CHECK (true);

-- Session owner can update (email capture, completion)
CREATE POLICY "quiz_responses_session_update" ON public.quiz_responses
  FOR UPDATE USING (
    session_id = current_setting('request.headers', true)::jsonb->>'x-quiz-session'
    OR user_id = auth.uid()
    OR auth.jwt()->'app_metadata'->>'role' IN ('admin', 'staff')
  );

-- Public read for shared results (via share_token)
CREATE POLICY "quiz_responses_shared_read" ON public.quiz_responses
  FOR SELECT USING (
    shared = true
    OR user_id = auth.uid()
    OR auth.jwt()->'app_metadata'->>'role' = 'admin'
  );

-- Admin can read all
CREATE POLICY "quiz_responses_admin_read" ON public.quiz_responses
  FOR SELECT USING (
    auth.jwt()->'app_metadata'->>'role' = 'admin'
  );
