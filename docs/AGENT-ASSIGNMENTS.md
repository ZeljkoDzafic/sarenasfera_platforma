# Agent Assignments

Last updated: 2026-03-09

This document assigns parallel work to Codex, Claude, and Qwen with minimal file collision.

## Coordination Rules

- One agent owns a file tree while a task is active.
- If a task requires crossing into another owned area, update this document first.
- Prefer vertical slices, but avoid concurrent edits in the same Vue page or migration file.
- Every agent should update docs if they change architecture, behavior, or status.

## Known Broken Or Suspicious Routes

Agents should validate these first instead of assuming they exist:

- `/auth/login`
- `/auth/register`
- `/admin/sessions/new`
- `/admin/observe`

## Ownership By Default

- Codex
  - auth flows
  - frontend route correctness
  - integration gaps between docs and code
- Claude
  - data model verification
  - backend/API scaffolding
  - operational and deployment docs
- Qwen
  - public funnel polish
  - parent/staff UX hardening
  - empty states, tier gating, and consistency passes

## Claude Tasks

Claude should take the tasks below first.

### CLAUDE-1: Migration and RLS verification

- Goal: prove the database is safe enough to build on.
- Files:
  - `supabase/migrations/`
  - `docs/PROJECT-STATUS.md`
  - `docs/PRODUCTION-READINESS.md`
- Deliverables:
  - identify duplicate/conflicting migration numbers
  - verify critical RLS coverage and gaps
  - document which schema areas are verified vs unverified
- Acceptance:
  - repo contains a clear note on verified RLS baseline
  - critical blockers are explicitly listed

### CLAUDE-2: First real FastAPI service

- Goal: turn `api/` from skeleton into a production-relevant service.
- Preferred scope:
  - transactional email service for registration / password recovery
  - or quarterly report generation if easier given existing schema
- Files:
  - `api/app/`
  - `api/requirements.txt`
  - `docs/PROJECT-STATUS.md`
- Acceptance:
  - at least one real endpoint beyond `/health`
  - structured errors
  - documented required env vars

### CLAUDE-3: Production operations docs

- Goal: make deploy/rollback/backup steps executable.
- Files:
  - `docs/PRODUCTION-READINESS.md`
  - `docs/arhitektura/08-deployment.md`
  - optionally new runbooks under `docs/`
- Deliverables:
  - release runbook
  - rollback steps
  - backup/restore baseline
  - monitoring baseline

## Qwen Tasks

Qwen should take the tasks below first.

### QWEN-1: Public funnel consistency pass

- Goal: make acquisition surfaces coherent and production-ready.
- Files:
  - `frontend/layouts/default.vue`
  - `frontend/pages/events/index.vue`
  - `frontend/pages/events/[slug].vue`
  - `frontend/pages/events/[slug]/register.vue`
  - `frontend/pages/pricing.vue`
  - `frontend/pages/quiz/index.vue`
- Deliverables:
  - remove broken paths
  - ensure CTA flow is consistent
  - add strong loading/empty/error states
  - align copy and CTA destinations with actual routes
- Acceptance:
  - a user can move from landing/quiz/pricing/events toward registration without dead ends
  - all CTA paths resolve to real routes or intentional placeholders

### QWEN-2: Parent portal reality pass

- Goal: reduce fake/demo feel in parent surfaces.
- Files:
  - `frontend/pages/portal/index.vue`
  - `frontend/pages/portal/children/index.vue`
  - `frontend/pages/portal/children/[id].vue`
  - `frontend/components/portal/PassportView.vue`
- Deliverables:
  - replace placeholder sections with real queries where feasible
  - otherwise add explicit empty states and loading skeletons
  - ensure tier gating matches product logic
- Acceptance:
  - parent portal no longer looks shipped while running on demo arrays

### QWEN-3: Admin workflow UX hardening

- Goal: improve staff confidence and task completion on real screens.
- Files:
  - `frontend/pages/admin/children/index.vue`
  - `frontend/pages/admin/children/[id].vue`
  - `frontend/pages/admin/observations/index.vue`
  - `frontend/pages/admin/events/index.vue`
- Deliverables:
  - better feedback for loading, empty, and failure states
  - fewer dead-end links
  - mobile-first cleanup where staff likely use phones

## Codex Tasks

Codex should take these in parallel or after the first agent wave.

### CODEX-1: Auth route implementation

- Goal: unblock the entire platform.
- Files:
  - `frontend/pages/auth/login.vue`
  - `frontend/pages/auth/register.vue`
  - `frontend/pages/auth/forgot-password.vue`
  - `frontend/pages/auth/reset-password.vue`
  - optionally `frontend/pages/auth/verify.vue`
- Acceptance:
  - routes exist
  - public nav no longer points to missing pages
  - middleware and redirects work with actual screens

### CODEX-2: Route integrity and broken-link pass

- Goal: remove path assumptions that do not exist in repo.
- Files:
  - public pages and layouts
  - portal/admin nav components
  - docs status files
- Acceptance:
  - no major navigation points to missing routes
  - known dead ends are removed, implemented, or explicitly disabled

## Suggested Execution Order

1. Codex: `CODEX-1`
2. Claude: `CLAUDE-1`
3. Qwen: `QWEN-1`
4. Qwen: `QWEN-2`
5. Claude: `CLAUDE-2`
6. Codex: `CODEX-2`
7. Claude: `CLAUDE-3`

## Handoff Format

Each agent should report:

- files changed
- what is now implemented
- what remains partial
- what another agent must not overwrite
