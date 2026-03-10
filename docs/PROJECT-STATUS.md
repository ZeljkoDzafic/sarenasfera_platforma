# Project Status

Last updated: 2026-03-09

This document describes the current repository state, not the ideal target state.

## Executive Summary

The project has a strong product direction, a credible Supabase-first architecture, and a meaningful amount of frontend and schema work already present. It is still not yet production-ready. This pass improved deploy packaging, local bootstrap, education seed data, email API protection, and portal HTML sanitization, but launch is still blocked by unverified RLS, unverified auth flows, missing real production infra inputs, and incomplete automated verification.

## Current Stack

- Frontend: Nuxt 4, Vue 3, TypeScript, Tailwind CSS
- Data/Auth: Self-hosted Supabase
- Custom backend: Python FastAPI
- DevOps: Docker Compose, GitHub Actions

## Implemented In Repo

### Frontend foundation

- Nuxt app scaffolded and configured
- Public pages exist for `/`, `program`, `blog`, `resources`, `contact`, `pricing`, `referrals`, `events`, `quiz`
- Parent portal pages exist under `frontend/pages/portal/`
- Admin pages exist under `frontend/pages/admin/`
- Core composables exist:
  - `useSupabase`
  - `useAuth`
  - `useFeatures`
  - `useTier`
- Core route middleware exists:
  - `auth`
  - `guest`
  - `role`

### Data model and migrations

- Large Supabase migration set exists in `supabase/migrations/`
- Feature flags, referrals, education, milestones, content, and events are represented in schema planning and migrations
- Seed file exists
- Fresh local stack validation is in progress and has already exposed real historical migration conflicts between:
  - `012_curriculum.sql` and `020_developmental_milestones.sql`
  - `016_billing_features.sql` and `022_phase8_features_tiers.sql`
  - `017_crm_referrals.sql` and `024_forum_partners.sql`
- Local compatibility fixes now exist for clean-boot validation, but the migration chain is still not fully proven end-to-end

### CI/CD baseline

- GitHub Actions run frontend type/build checks
- GitHub Actions run Python syntax validation
- Local frontend verification now passes from an installed environment:
  - `cd frontend && npm run typecheck`
  - `cd frontend && npm run build`

## Partially Implemented

### Authentication

- Auth composable and middleware exist
- Auth pages now exist in `frontend/pages/auth/`
- End-to-end auth flow still needs verification against a running local Supabase stack
- Public layout and multiple public pages link to `/auth/login` and `/auth/register`

### FastAPI

- Service now includes health checks, transactional email endpoints, internal API protection, structured error handling, and environment validation
- Broader PDF/reporting and deeper business workflows are still incomplete

### Production deployment

- Root `package.json` now includes local install/dev and production build/publish entry points
- Production Dockerfiles now exist for frontend and API
- Production Kong declarative config now exists and matches production service names
- Real host rollout is still unverified because certificates, real secrets, and target infra remain external to the repo

### Frontend data fidelity

- Some pages are backed by live Supabase queries
- Some pages still contain placeholder or demo data

### Route integrity

- Several critical route mismatches have been corrected
- Remaining route integrity work should focus on full navigation verification under real usage

## Missing Or Unverified

- End-to-end auth flow
- Verified RLS coverage for all tables
- Fully clean database bootstrap through the entire migration chain
- Generated database types
- Test coverage beyond type/build checks
- Observability and alerting
- Backup/restore runbook
- Secrets rotation procedure
- Full rate limiting and abuse controls across all public write paths
- Error budgets and incident response process

## Highest-Leverage Next Steps

1. Verify auth and role flows end-to-end against a running local Supabase stack.
2. Validate migrations and RLS against a fresh local Supabase instance.
3. Replace placeholder frontend data with real queries or explicit mock boundaries.
4. Continue route integrity checks under real navigation and edge cases.
5. Expand FastAPI to the first real production use case:
   PDF reports or transactional email.
6. Turn deployment docs into executable infrastructure and release steps.
7. Add monitoring, backups, and operational runbooks before production traffic.

## Status Semantics

Use these meanings when updating docs:

- `implemented`
  - Exists in code and is locally testable.
- `partial`
  - Some code exists, but major acceptance criteria are missing or unverified.
- `planned`
  - Designed in docs, not delivered.
- `historical`
  - Useful context, but not an active guide for implementation.
