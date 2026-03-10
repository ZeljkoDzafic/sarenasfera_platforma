-- Local Supabase bootstrap for plain Postgres-based docker-compose development.
-- This file ensures auth schema, helper functions, and core roles exist before
-- application migrations that reference auth.users and Supabase roles.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
    CREATE ROLE anon NOLOGIN NOINHERIT;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
    CREATE ROLE authenticated NOLOGIN NOINHERIT;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'service_role') THEN
    CREATE ROLE service_role NOLOGIN NOINHERIT BYPASSRLS;
  END IF;
END
$$;

CREATE SCHEMA IF NOT EXISTS auth;

ALTER ROLE postgres IN DATABASE postgres SET search_path = auth, public;

CREATE TABLE IF NOT EXISTS auth.users (
  instance_id uuid NULL,
  id uuid NOT NULL UNIQUE,
  aud varchar(255) NULL,
  role varchar(255) NULL,
  email varchar(255) NULL UNIQUE,
  encrypted_password varchar(255) NULL,
  confirmed_at timestamptz NULL,
  invited_at timestamptz NULL,
  confirmation_token varchar(255) NULL,
  confirmation_sent_at timestamptz NULL,
  recovery_token varchar(255) NULL,
  recovery_sent_at timestamptz NULL,
  email_change_token varchar(255) NULL,
  email_change varchar(255) NULL,
  email_change_sent_at timestamptz NULL,
  last_sign_in_at timestamptz NULL,
  raw_app_meta_data jsonb NULL,
  raw_user_meta_data jsonb NULL,
  is_super_admin bool NULL,
  created_at timestamptz NULL DEFAULT now(),
  updated_at timestamptz NULL DEFAULT now(),
  CONSTRAINT users_pkey PRIMARY KEY (id)
);

CREATE INDEX IF NOT EXISTS users_instance_id_email_idx ON auth.users USING btree (instance_id, email);
CREATE INDEX IF NOT EXISTS users_instance_id_idx ON auth.users USING btree (instance_id);

CREATE TABLE IF NOT EXISTS auth.refresh_tokens (
  instance_id uuid NULL,
  id bigserial NOT NULL,
  token varchar(255) NULL,
  user_id varchar(255) NULL,
  revoked bool NULL,
  created_at timestamptz NULL DEFAULT now(),
  updated_at timestamptz NULL DEFAULT now(),
  CONSTRAINT refresh_tokens_pkey PRIMARY KEY (id)
);

CREATE INDEX IF NOT EXISTS refresh_tokens_instance_id_idx ON auth.refresh_tokens USING btree (instance_id);
CREATE INDEX IF NOT EXISTS refresh_tokens_instance_id_user_id_idx ON auth.refresh_tokens USING btree (instance_id, user_id);
CREATE INDEX IF NOT EXISTS refresh_tokens_token_idx ON auth.refresh_tokens USING btree (token);

CREATE TABLE IF NOT EXISTS auth.instances (
  id uuid NOT NULL,
  uuid uuid NULL,
  raw_base_config text NULL,
  created_at timestamptz NULL DEFAULT now(),
  updated_at timestamptz NULL DEFAULT now(),
  CONSTRAINT instances_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS auth.audit_log_entries (
  instance_id uuid NULL,
  id uuid NOT NULL,
  payload json NULL,
  created_at timestamptz NULL DEFAULT now(),
  CONSTRAINT audit_log_entries_pkey PRIMARY KEY (id)
);

CREATE INDEX IF NOT EXISTS audit_logs_instance_id_idx ON auth.audit_log_entries USING btree (instance_id);

CREATE TABLE IF NOT EXISTS auth.schema_migrations (
  version varchar(255) NOT NULL,
  CONSTRAINT auth_schema_migrations_pkey PRIMARY KEY (version)
);

CREATE OR REPLACE FUNCTION auth.uid()
RETURNS uuid AS $$
  SELECT NULLIF(current_setting('request.jwt.claim.sub', true), '')::uuid;
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION auth.role()
RETURNS text AS $$
  SELECT NULLIF(current_setting('request.jwt.claim.role', true), '')::text;
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION auth.jwt()
RETURNS jsonb AS $$
  SELECT COALESCE(NULLIF(current_setting('request.jwt.claims', true), ''), '{}')::jsonb;
$$ LANGUAGE sql STABLE;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_type t
    JOIN pg_namespace n ON n.oid = t.typnamespace
    WHERE n.nspname = 'auth' AND t.typname = 'aal_level'
  ) THEN
    CREATE TYPE auth.aal_level AS ENUM ('aal1', 'aal2', 'aal3');
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_type t
    JOIN pg_namespace n ON n.oid = t.typnamespace
    WHERE n.nspname = 'auth' AND t.typname = 'factor_type'
  ) THEN
    CREATE TYPE auth.factor_type AS ENUM ('totp');
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_type t
    JOIN pg_namespace n ON n.oid = t.typnamespace
    WHERE n.nspname = 'auth' AND t.typname = 'factor_status'
  ) THEN
    CREATE TYPE auth.factor_status AS ENUM ('unverified', 'verified');
  END IF;
END
$$;
