# Agent Handbook

This document is for Codex, Claude, Qwen, and human contributors working in parallel.

## Primary Objective

Build a production-grade child development platform fast, without sacrificing data safety, architectural coherence, or delivery clarity.

## Non-Negotiables

- The active stack is Nuxt + Supabase + FastAPI.
- Child and parent data are sensitive. Privacy and access control are first-class requirements.
- Documentation must distinguish clearly between:
  - current repo state
  - approved target architecture
  - future ideas
- Do not mark work as done unless it is implemented and locally verifiable.
- Avoid adding parallel patterns for the same concern. Extend existing composables, layouts, migrations, and UI primitives.

## Canonical Read Order For Agents

1. `docs/PROJECT-STATUS.md`
2. `docs/arhitektura/11-supabase-architecture.md`
3. Relevant domain doc in `docs/arhitektura/`
4. `docs/PRODUCTION-READINESS.md`
5. `docs/TASKS.md`

## Repo Truth Rules

- If code and docs conflict, code wins until docs are updated.
- If `TASKS.md` says `DONE` but the repo does not prove it, treat the task as `partial`.
- If a document is marked historical, do not use it as the primary implementation guide.

## Delivery Standard

Every meaningful change should aim to leave behind:

- implementation
- minimal verification
- updated documentation if behavior or architecture changed

For each feature, prefer vertical slices over isolated mockups:

1. schema or data contract
2. access control
3. UI flow
4. empty/loading/error states
5. operational notes

## Production-First Engineering Rules

- Prefer boring, well-supported libraries and patterns.
- Use SSR only where SEO matters.
- Keep portal and admin interactions resilient to auth refresh and network failures.
- Every schema addition should consider:
  - indexes
  - RLS
  - seed/dev ergonomics
  - auditability
- Every external integration should consider:
  - retry behavior
  - timeout behavior
  - secrets management
  - observability

## Definition Of Done

A task is done only if all apply:

- code exists in the expected location
- acceptance criteria are substantially satisfied
- key route or service path runs locally
- obvious edge cases are handled
- relevant docs are updated if needed

## Preferred Work Order

Use this order when several options are possible:

1. unblock core auth and data integrity
2. unblock revenue and acquisition paths
3. unblock parent portal core value
4. unblock staff/admin operational efficiency
5. polish design and growth loops

## Highest-Priority Product Surface

1. Public funnel
   - landing
   - events
   - quiz
   - registration
2. Parent portal
   - child profile
   - child passport
   - workshops
   - activities
3. Staff/admin
   - children
   - observations
   - groups
   - sessions
4. Platform operations
   - billing tiers
   - feature flags
   - notifications
   - analytics

## Documentation Update Rule

When you change system behavior, update one of:

- `docs/PROJECT-STATUS.md`
- the relevant `docs/arhitektura/*.md`
- `docs/PRODUCTION-READINESS.md`

Do not leave major architecture changes documented only in code comments.

