-- Seed demo accounts for development and testing
-- These accounts will be created on every fresh database initialization

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Function to create a demo user with profile
CREATE OR REPLACE FUNCTION create_demo_user(
  p_email TEXT,
  p_password TEXT,
  p_full_name TEXT,
  p_role TEXT,
  p_tier TEXT
) RETURNS UUID AS $$
DECLARE
  v_user_id UUID;
  v_encrypted_password TEXT;
BEGIN
  -- Generate bcrypt hash for password
  v_encrypted_password := crypt(p_password, gen_salt('bf'));

  -- Insert into auth.users
  INSERT INTO auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    recovery_sent_at,
    last_sign_in_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at,
    confirmation_token,
    email_change,
    email_change_token_new,
    recovery_token
  ) VALUES (
    '00000000-0000-0000-0000-000000000000',
    gen_random_uuid(),
    'authenticated',
    'authenticated',
    p_email,
    v_encrypted_password,
    NOW(),
    NOW(),
    NOW(),
    jsonb_build_object('provider', 'email', 'providers', ARRAY['email']),
    jsonb_build_object('full_name', p_full_name),
    NOW(),
    NOW(),
    '',
    '',
    '',
    ''
  ) RETURNING id INTO v_user_id;

  -- Update the profile with correct role and tier
  UPDATE public.profiles
  SET
    role = p_role,
    subscription_tier = p_tier,
    full_name = p_full_name,
    onboarding_completed = TRUE,
    updated_at = NOW()
  WHERE id = v_user_id;

  RETURN v_user_id;
END;
$$ LANGUAGE plpgsql;

-- Delete existing demo accounts if they exist (for re-running the seed)
DELETE FROM auth.users WHERE email IN (
  'admin@sarenasfera.com',
  'demo-admin@sarenasfera.com',
  'demo-staff@sarenasfera.com',
  'demo-parent-free@sarenasfera.com',
  'demo-parent-paid@sarenasfera.com',
  'demo-parent-premium@sarenasfera.com'
);

-- Create demo accounts
DO $$
DECLARE
  v_admin_id UUID;
  v_demo_admin_id UUID;
  v_staff_id UUID;
  v_parent_free_id UUID;
  v_parent_paid_id UUID;
  v_parent_premium_id UUID;
BEGIN
  -- Main admin account
  v_admin_id := create_demo_user(
    'admin@sarenasfera.com',
    'admin123',
    'Admin User',
    'admin',
    'premium'
  );
  RAISE NOTICE 'Created admin account: admin@sarenasfera.com (password: admin123)';

  -- Demo admin account
  v_demo_admin_id := create_demo_user(
    'demo-admin@sarenasfera.com',
    'demo123',
    'Demo Admin',
    'admin',
    'premium'
  );
  RAISE NOTICE 'Created demo admin: demo-admin@sarenasfera.com (password: demo123)';

  -- Demo staff/educator account
  v_staff_id := create_demo_user(
    'demo-staff@sarenasfera.com',
    'demo123',
    'Demo Edukator',
    'staff',
    'free'
  );
  RAISE NOTICE 'Created demo staff: demo-staff@sarenasfera.com (password: demo123)';

  -- Demo parent - free tier
  v_parent_free_id := create_demo_user(
    'demo-parent-free@sarenasfera.com',
    'demo123',
    'Demo Roditelj (Free)',
    'parent',
    'free'
  );
  RAISE NOTICE 'Created demo parent (free): demo-parent-free@sarenasfera.com (password: demo123)';

  -- Demo parent - paid tier
  v_parent_paid_id := create_demo_user(
    'demo-parent-paid@sarenasfera.com',
    'demo123',
    'Demo Roditelj (Paid)',
    'parent',
    'paid'
  );
  RAISE NOTICE 'Created demo parent (paid): demo-parent-paid@sarenasfera.com (password: demo123)';

  -- Demo parent - premium tier
  v_parent_premium_id := create_demo_user(
    'demo-parent-premium@sarenasfera.com',
    'demo123',
    'Demo Roditelj (Premium)',
    'parent',
    'premium'
  );
  RAISE NOTICE 'Created demo parent (premium): demo-parent-premium@sarenasfera.com (password: demo123)';

  RAISE NOTICE '✅ All demo accounts created successfully!';
END $$;

-- Drop the helper function (cleanup)
DROP FUNCTION IF EXISTS create_demo_user(TEXT, TEXT, TEXT, TEXT, TEXT);

-- Display created accounts summary
DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '═══════════════════════════════════════════════════════════════';
  RAISE NOTICE '📝 DEMO ACCOUNTS SUMMARY';
  RAISE NOTICE '═══════════════════════════════════════════════════════════════';
  RAISE NOTICE 'Admin Account:';
  RAISE NOTICE '  • admin@sarenasfera.com / admin123 (admin, premium)';
  RAISE NOTICE '';
  RAISE NOTICE 'Demo Accounts (all use password: demo123):';
  RAISE NOTICE '  • demo-admin@sarenasfera.com (admin, premium)';
  RAISE NOTICE '  • demo-staff@sarenasfera.com (staff, free)';
  RAISE NOTICE '  • demo-parent-free@sarenasfera.com (parent, free)';
  RAISE NOTICE '  • demo-parent-paid@sarenasfera.com (parent, paid)';
  RAISE NOTICE '  • demo-parent-premium@sarenasfera.com (parent, premium)';
  RAISE NOTICE '═══════════════════════════════════════════════════════════════';
END $$;
