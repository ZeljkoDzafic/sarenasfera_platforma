# Sarena Sfera Documentation Hub

This directory is the canonical documentation entrypoint for the repository.

## Read Order

If you are a human contributor or an AI agent, read documents in this order:

1. `docs/PROJECT-STATUS.md`
2. `docs/SECURITY-REVIEW.md`
3. `docs/PRODUCTION-STATUS.md`
4. `docs/PRODUCTION-READINESS.md`
5. `docs/AGENT-HANDBOOK.md`
6. `docs/PRODUCTION-SPRINT.md`
7. `docs/AGENT-ASSIGNMENTS.md`
8. `docs/arhitektura/README.md`
9. `docs/TASKS.md`

## What Each Document Means

- `PROJECT-STATUS.md`
  - Current repository truth: implemented, partial, missing, risky.
- `SECURITY-REVIEW.md`
  - Security findings, launch blockers, and required verification.
- `PRODUCTION-STATUS.md`
  - Short launch snapshot that must stay aligned with project and security status.
- `AGENT-HANDBOOK.md`
  - Execution rules for Codex, Claude, Qwen, and human contributors.
- `PRODUCTION-READINESS.md`
  - Launch gate. This should stay conservative and evidence-based.
- `PRODUCTION-SPRINT.md`
  - Shortest production path from current repo state.
- `AGENT-ASSIGNMENTS.md`
  - Parallel task split for Codex, Claude, and Qwen.
- `arhitektura/`
  - Product and system design documents.
- `TASKS.md`
  - Delivery backlog and work decomposition. It is not the primary source of truth for implementation status unless verified against the repo.

## Source Of Truth Policy

When documents disagree, use this order:

1. Running code and file structure in the repo
2. `docs/PROJECT-STATUS.md`
3. `docs/SECURITY-REVIEW.md`
4. `docs/PRODUCTION-STATUS.md`
5. `docs/PRODUCTION-READINESS.md`
6. `docs/arhitektura/11-supabase-architecture.md`
7. Other documents in `docs/arhitektura/`
8. `plan.md` and historical alternatives

## Historical Documents

Some documents remain valuable for context but are not active implementation guides:

- `plan.md` - business and product concept
- `docs/arhitektura/07-frontend-structure.md` - legacy frontend concept
- `docs/arhitektura/08-deployment.md` - partially outdated deployment direction
- `docs/DEPLOYMENT.md` - historical provider options, not the canonical release path
- `docs/arhitektura/12-laravel-architecture.md` - alternative architecture, not active
- `docs/arhitektura/13-architecture-comparison.md` - decision history
