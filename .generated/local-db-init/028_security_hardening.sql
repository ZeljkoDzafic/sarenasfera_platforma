-- Migration 026: Security Hardening & Production Prep
-- CRITICAL: Security improvements for production launch

-- ============================================================
-- 1. AUDIT LOGGING
-- ============================================================

-- Audit log table for tracking important actions
CREATE TABLE IF NOT EXISTS public.audit_logs (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id         UUID REFERENCES public.profiles(id),
  action          TEXT NOT NULL, -- 'login', 'logout', 'data_export', 'admin_action', etc.
  resource_type   TEXT, -- 'child', 'observation', 'workshop', etc.
  resource_id     UUID,
  ip_address      INET,
  user_agent      TEXT,
  metadata        JSONB DEFAULT '{}',
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_audit_logs_user ON public.audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_action ON public.audit_logs(action);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created ON public.audit_logs(created_at);
CREATE INDEX IF NOT EXISTS idx_audit_logs_resource ON public.audit_logs(resource_type, resource_id);

-- Function to log audit events
CREATE OR REPLACE FUNCTION public.log_audit_event(
  p_action TEXT,
  p_resource_type TEXT DEFAULT NULL,
  p_resource_id UUID DEFAULT NULL,
  p_metadata JSONB DEFAULT '{}'
) RETURNS UUID AS $$
DECLARE
  v_log_id UUID;
BEGIN
  INSERT INTO public.audit_logs (user_id, action, resource_type, resource_id, ip_address, user_agent, metadata)
  VALUES (
    auth.uid(),
    p_action,
    p_resource_type,
    p_resource_id,
    COALESCE(current_setting('app.ip_address', true)::inet, NULL),
    current_setting('app.user_agent', true),
    p_metadata
  )
  RETURNING id INTO v_log_id;
  
  RETURN v_log_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- 2. RATE LIMITING HELPERS
-- ============================================================

-- Rate limit tracking table
CREATE TABLE IF NOT EXISTS public.rate_limit_tracker (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  identifier      TEXT NOT NULL, -- IP address or user_id
  action          TEXT NOT NULL,
  count           INTEGER NOT NULL DEFAULT 1,
  window_start    TIMESTAMPTZ NOT NULL DEFAULT now(),
  window_end      TIMESTAMPTZ NOT NULL,
  UNIQUE(identifier, action, window_start)
);

CREATE INDEX IF NOT EXISTS idx_rate_limit_identifier ON public.rate_limit_tracker(identifier);
CREATE INDEX IF NOT EXISTS idx_rate_limit_window ON public.rate_limit_tracker(window_end);

-- Function to check and update rate limit
CREATE OR REPLACE FUNCTION public.check_rate_limit(
  p_identifier TEXT,
  p_action TEXT,
  p_max_count INTEGER,
  p_window_minutes INTEGER
) RETURNS BOOLEAN AS $$
DECLARE
  v_window_start TIMESTAMPTZ;
  v_count INTEGER;
BEGIN
  v_window_start := now() - (p_window_minutes || ' minutes')::interval;
  
  -- Get current count in window
  SELECT COALESCE(SUM(count), 0) INTO v_count
  FROM public.rate_limit_tracker
  WHERE identifier = p_identifier
    AND action = p_action
    AND window_start >= v_window_start;
  
  -- Check if limit exceeded
  IF v_count >= p_max_count THEN
    RETURN FALSE; -- Rate limit exceeded
  END IF;
  
  -- Update or insert counter
  INSERT INTO public.rate_limit_tracker (identifier, action, count, window_start, window_end)
  VALUES (p_identifier, p_action, 1, now(), now() + (p_window_minutes || ' minutes')::interval)
  ON CONFLICT (identifier, action, window_start)
  DO UPDATE SET count = rate_limit_tracker.count + 1;
  
  RETURN TRUE; -- Within limit
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- 3. SESSION MANAGEMENT
-- ============================================================

-- Active sessions tracking
CREATE TABLE IF NOT EXISTS public.user_sessions (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id         UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  session_id      TEXT NOT NULL UNIQUE,
  ip_address      INET,
  user_agent      TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_active_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at      TIMESTAMPTZ NOT NULL,
  is_active       BOOLEAN DEFAULT true
);

CREATE INDEX IF NOT EXISTS idx_user_sessions_user ON public.user_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_sessions_session ON public.user_sessions(session_id);
CREATE INDEX IF NOT EXISTS idx_user_sessions_active ON public.user_sessions(is_active);

-- Function to track session activity
CREATE OR REPLACE FUNCTION public.track_session_activity(
  p_session_id TEXT,
  p_ip_address INET DEFAULT NULL,
  p_user_agent TEXT DEFAULT NULL
) RETURNS VOID AS $$
BEGIN
  UPDATE public.user_sessions
  SET
    last_active_at = now(),
    ip_address = COALESCE(p_ip_address, ip_address),
    user_agent = COALESCE(p_user_agent, user_agent)
  WHERE session_id = p_session_id
    AND is_active = true
    AND expires_at > now();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to cleanup expired sessions
CREATE OR REPLACE FUNCTION public.cleanup_expired_sessions()
RETURNS INTEGER AS $$
DECLARE
  v_count INTEGER;
BEGIN
  DELETE FROM public.user_sessions
  WHERE expires_at < now() OR is_active = false;
  
  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- 4. SENSITIVE DATA PROTECTION
-- ============================================================

-- Function to mask sensitive data
CREATE OR REPLACE FUNCTION public.mask_email(email TEXT)
RETURNS TEXT AS $$
DECLARE
  parts TEXT[];
  local_part TEXT;
  domain_part TEXT;
BEGIN
  IF email IS NULL THEN
    RETURN NULL;
  END IF;
  
  parts := string_to_array(email, '@');
  local_part := parts[1];
  domain_part := parts[2];
  
  -- Mask local part: show first 2 chars, mask rest
  IF length(local_part) > 2 THEN
    local_part := substring(local_part from 1 for 2) || repeat('*', length(local_part) - 2);
  END IF;
  
  -- Mask domain: show first 2 chars and TLD
  IF position('.' in domain_part) > 0 THEN
    domain_part := substring(domain_part from 1 for 2) || '***' || 
                   substring(domain_part from position('.' in domain_part));
  END IF;
  
  RETURN local_part || '@' || domain_part;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Function to mask phone number
CREATE OR REPLACE FUNCTION public.mask_phone(phone TEXT)
RETURNS TEXT AS $$
BEGIN
  IF phone IS NULL THEN
    RETURN NULL;
  END IF;
  
  -- Remove all non-digits
  phone := regexp_replace(phone, '[^0-9]', '', 'g');
  
  -- Show last 4 digits, mask rest
  IF length(phone) >= 4 THEN
    RETURN repeat('*', length(phone) - 4) || substring(phone from length(phone) - 3);
  ELSE
    RETURN repeat('*', length(phone));
  END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================================
-- 5. DATA EXPORT TRACKING (for GDPR compliance)
-- ============================================================

CREATE TABLE IF NOT EXISTS public.data_exports (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id         UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  export_type     TEXT NOT NULL CHECK (export_type IN ('personal_data', 'children_data', 'full_export')),
  status          TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
  file_url        TEXT,
  expires_at      TIMESTAMPTZ,
  requested_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  completed_at    TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_data_exports_user ON public.data_exports(user_id);
CREATE INDEX IF NOT EXISTS idx_data_exports_status ON public.data_exports(status);

-- ============================================================
-- 6. FAILED LOGIN TRACKING
-- ============================================================

CREATE TABLE IF NOT EXISTS public.failed_login_attempts (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  email           TEXT NOT NULL,
  ip_address      INET,
  user_agent      TEXT,
  attempted_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_failed_login_email ON public.failed_login_attempts(email);
CREATE INDEX IF NOT EXISTS idx_failed_login_ip ON public.failed_login_attempts(ip_address);
CREATE INDEX IF NOT EXISTS idx_failed_login_time ON public.failed_login_attempts(attempted_at);

-- Function to check if account should be locked
CREATE OR REPLACE FUNCTION public.is_account_locked(p_email TEXT)
RETURNS BOOLEAN AS $$
DECLARE
  v_attempt_count INTEGER;
  v_window_start TIMESTAMPTZ;
BEGIN
  v_window_start := now() - interval '15 minutes';
  
  SELECT COUNT(*) INTO v_attempt_count
  FROM public.failed_login_attempts
  WHERE email = p_email
    AND attempted_at >= v_window_start;
  
  -- Lock after 5 failed attempts in 15 minutes
  RETURN v_attempt_count >= 5;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to track failed login
CREATE OR REPLACE FUNCTION public.track_failed_login(p_email TEXT, p_ip_address INET DEFAULT NULL)
RETURNS VOID AS $$
BEGIN
  INSERT INTO public.failed_login_attempts (email, ip_address)
  VALUES (p_email, p_ip_address);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- 7. RLS ENHANCEMENTS
-- ============================================================

-- Ensure all new tables have RLS enabled
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rate_limit_tracker ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.data_exports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.failed_login_attempts ENABLE ROW LEVEL SECURITY;

-- Audit logs: users can only see their own, admin sees all
DROP POLICY IF EXISTS "audit_logs_own_read" ON public.audit_logs;
CREATE POLICY "audit_logs_own_read" ON public.audit_logs FOR SELECT
  USING (user_id = auth.uid() OR auth.jwt()->'app_metadata'->>'role' = 'admin');

DROP POLICY IF EXISTS "audit_logs_admin_insert" ON public.audit_logs;
CREATE POLICY "audit_logs_admin_insert" ON public.audit_logs FOR INSERT
  WITH CHECK (auth.jwt()->'app_metadata'->>'role' = 'admin');

-- Rate limit tracker: internal use only, no direct access
DROP POLICY IF EXISTS "rate_limit_tracker_no_access" ON public.rate_limit_tracker;
CREATE POLICY "rate_limit_tracker_no_access" ON public.rate_limit_tracker FOR ALL
  USING (false);

-- User sessions: users see own sessions
DROP POLICY IF EXISTS "user_sessions_own" ON public.user_sessions;
CREATE POLICY "user_sessions_own" ON public.user_sessions FOR ALL
  USING (user_id = auth.uid());

-- Data exports: users see own exports
DROP POLICY IF EXISTS "data_exports_own" ON public.data_exports;
CREATE POLICY "data_exports_own" ON public.data_exports FOR ALL
  USING (user_id = auth.uid());

-- Failed login attempts: no direct access (used via functions)
DROP POLICY IF EXISTS "failed_login_attempts_no_access" ON public.failed_login_attempts;
CREATE POLICY "failed_login_attempts_no_access" ON public.failed_login_attempts FOR ALL
  USING (false);

-- ============================================================
-- 8. SECURITY VIEWS
-- ============================================================

-- View for active users count (for monitoring)
CREATE OR REPLACE VIEW public.v_active_users_count AS
SELECT 
  COUNT(DISTINCT user_id) as active_users_last_hour,
  COUNT(DISTINCT CASE WHEN last_active_at > now() - interval '24 hours' THEN user_id END) as active_users_last_day,
  COUNT(DISTINCT CASE WHEN last_active_at > now() - interval '7 days' THEN user_id END) as active_users_last_week
FROM public.user_sessions
WHERE is_active = true;

-- View for security metrics
CREATE OR REPLACE VIEW public.v_security_metrics AS
SELECT
  (SELECT COUNT(*) FROM public.failed_login_attempts WHERE attempted_at > now() - interval '1 hour') as failed_logins_last_hour,
  (SELECT COUNT(*) FROM public.audit_logs WHERE created_at > now() - interval '1 hour') as audit_events_last_hour,
  (SELECT COUNT(*) FROM public.data_exports WHERE status = 'pending') as pending_exports,
  (SELECT COUNT(*) FROM public.user_sessions WHERE is_active = true) as active_sessions;

-- ============================================================
-- 9. CLEANUP FUNCTIONS (for pg_cron or external scheduler)
-- ============================================================

-- Cleanup old audit logs (keep 90 days)
CREATE OR REPLACE FUNCTION public.cleanup_old_audit_logs()
RETURNS INTEGER AS $$
DECLARE
  v_count INTEGER;
BEGIN
  DELETE FROM public.audit_logs
  WHERE created_at < now() - interval '90 days';
  
  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$ LANGUAGE plpgsql;

-- Cleanup old rate limit entries
CREATE OR REPLACE FUNCTION public.cleanup_old_rate_limits()
RETURNS INTEGER AS $$
DECLARE
  v_count INTEGER;
BEGIN
  DELETE FROM public.rate_limit_tracker
  WHERE window_end < now();
  
  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$ LANGUAGE plpgsql;

-- Cleanup old failed login attempts
CREATE OR REPLACE FUNCTION public.cleanup_old_failed_logins()
RETURNS INTEGER AS $$
DECLARE
  v_count INTEGER;
BEGIN
  DELETE FROM public.failed_login_attempts
  WHERE attempted_at < now() - interval '24 hours';
  
  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- 10. COMMENTS
-- ============================================================

COMMENT ON TABLE public.audit_logs IS 'Security audit trail for important actions';
COMMENT ON TABLE public.rate_limit_tracker IS 'Rate limiting tracking table';
COMMENT ON TABLE public.user_sessions IS 'Active user session tracking';
COMMENT ON TABLE public.data_exports IS 'GDPR data export requests';
COMMENT ON TABLE public.failed_login_attempts IS 'Failed login attempt tracking for brute force protection';
COMMENT ON FUNCTION public.log_audit_event IS 'Log an audit event';
COMMENT ON FUNCTION public.check_rate_limit IS 'Check and update rate limit counter';
COMMENT ON FUNCTION public.mask_email IS 'Mask email for display (privacy)';
COMMENT ON FUNCTION public.mask_phone IS 'Mask phone number for display (privacy)';
COMMENT ON FUNCTION public.is_account_locked IS 'Check if account should be locked due to failed logins';
COMMENT ON FUNCTION public.track_failed_login IS 'Track a failed login attempt';

-- ============================================================
-- GRANTS (restrict access to security functions)
-- ============================================================

-- Only allow service role to execute security functions directly
REVOKE ALL ON FUNCTION public.log_audit_event(TEXT, TEXT, UUID, JSONB) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.check_rate_limit(TEXT, TEXT, INTEGER, INTEGER) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.is_account_locked(TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.track_failed_login(TEXT, INET) FROM PUBLIC;

-- Grant to service role
GRANT ALL ON FUNCTION public.log_audit_event(TEXT, TEXT, UUID, JSONB) TO service_role;
GRANT ALL ON FUNCTION public.check_rate_limit(TEXT, TEXT, INTEGER, INTEGER) TO service_role;
GRANT ALL ON FUNCTION public.is_account_locked(TEXT) TO service_role;
GRANT ALL ON FUNCTION public.track_failed_login(TEXT, INET) TO service_role;
GRANT ALL ON FUNCTION public.cleanup_expired_sessions() TO service_role;
GRANT ALL ON FUNCTION public.cleanup_old_audit_logs() TO service_role;
GRANT ALL ON FUNCTION public.cleanup_old_rate_limits() TO service_role;
GRANT ALL ON FUNCTION public.cleanup_old_failed_logins() TO service_role;
