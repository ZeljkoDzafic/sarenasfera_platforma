# Production Sprint

Last updated: 2026-03-09

This sprint is the fastest credible path from the current repository state to a production-ready MVP.

## Sprint Objective

Ship a stable first production release centered on:

- public acquisition funnel
- working auth
- parent core value
- staff operational basics
- production safety rails

## Release Scope

### Must ship

- Auth pages and role-based redirects
- Public event registration funnel
- Parent portal child and passport flows
- Admin child and observation workflows
- Verified migrations and RLS baseline
- One real FastAPI production service
- Deployment runbook, rollback, backups, monitoring baseline

### Can ship behind feature flags

- community/forum
- premium education library
- expert workflows
- advanced analytics
- referral automation beyond core attribution

## Sprint Phases

### Phase A: Access and funnel

Goal: people can discover the product, register, and enter the correct area.

- A1. Implement `frontend/pages/auth/login.vue`
- A2. Implement `frontend/pages/auth/register.vue`
- A3. Implement `frontend/pages/auth/forgot-password.vue`
- A4. Implement `frontend/pages/auth/reset-password.vue`
- A5. Verify redirects from public layout and middleware
- A6. Verify event registration flow to account creation or lead capture

Exit criteria:

- Public nav links to auth pages work
- Parent can sign up and reach `/portal`
- Staff/admin can sign in and reach `/admin`
- Password reset is functional locally

### Phase B: Data correctness

Goal: the app stops depending on assumptions and starts depending on verified data rules.

- B1. Validate all migrations on a fresh local stack
- B2. Audit duplicate or conflicting migration numbering
- B3. Verify critical RLS for profiles, children, parent_children, groups, observations, events
- B4. Generate or stabilize `frontend/types/database.ts`
- B5. Document verified vs unverified schema areas

Exit criteria:

- Fresh boot succeeds
- Critical tables can be queried with correct role limits
- Frontend compiles against stable database types

### Phase C: Parent core value

Goal: a paying parent gets clear value from the platform immediately.

- C1. Remove or isolate placeholder data in portal dashboard
- C2. Complete child detail/passport data flow
- C3. Ensure workshops and activities pages load real data or clear empty states
- C4. Tier-gate paid and premium areas consistently

Exit criteria:

- Parent dashboard is not demo-only
- Child passport uses real data contracts
- Empty states are intentional, not broken

### Phase D: Staff operations

Goal: staff can do real work without hacks.

- D1. Validate admin children listing and detail flow
- D2. Implement or harden observation entry path
- D3. Validate groups and event/session management flow
- D4. Add basic operational error states and success feedback

Exit criteria:

- Staff can view children and enter observations
- Admin navigation does not dead-end to missing routes

### Phase E: Production rails

Goal: safe launch and safe rollback.

- E1. Implement first real FastAPI service
- E2. Add deployment runbook
- E3. Add backup and restore runbook
- E4. Add monitoring and alerting baseline
- E5. Define launch checklist and cohort rollout plan

Exit criteria:

- There is an executable release procedure
- There is a rollback path
- There is a backup policy
- There is incident visibility

## Immediate Priority Queue

Work these in order unless blocked:

1. Auth pages
2. Migration and RLS verification
3. Event registration funnel verification
4. Parent child/passport real-data flow
5. First FastAPI production service
6. Deployment/backup/monitoring runbooks

## Risks To Kill Early

- auth routes referenced by UI but missing in repo
- placeholder portal content mistaken for shipped functionality
- migration ordering ambiguity
- task status inflation in backlog
- deployment docs not matching current Nuxt architecture

