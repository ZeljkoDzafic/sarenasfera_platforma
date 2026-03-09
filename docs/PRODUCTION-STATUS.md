# Production Status

Last updated: 2026-03-09
Status: In progress

This file is a short operational snapshot. It must stay consistent with:

- [PROJECT-STATUS.md](/Users/zeljkodzafic/Documents/sarenasfera_platforma/docs/PROJECT-STATUS.md)
- [SECURITY-REVIEW.md](/Users/zeljkodzafic/Documents/sarenasfera_platforma/docs/SECURITY-REVIEW.md)
- [PRODUCTION-READINESS.md](/Users/zeljkodzafic/Documents/sarenasfera_platforma/docs/PRODUCTION-READINESS.md)

## Current Position

The platform has credible production scaffolding, but it is not yet ready for a public launch.

## Implemented

- local setup flow and config verification scripts
- root production scripts for compose-based build and publish
- production Dockerfiles for frontend and API
- production compose path with Kong and nginx wiring
- internal API protection for FastAPI email endpoints
- application-level sanitization for rich education content
- seed data and portal/admin surfaces sufficient for meaningful local testing
- production and security documentation that now reflects blockers more honestly
- local verification evidence now exists for:
  - `npm run verify:config`
  - `cd frontend && npm run typecheck`
  - `cd frontend && npm run build`
  - `python3 -m compileall api/app`

## Still Blocking Launch

- auth flow is not yet verified end-to-end on a clean stack
- RLS is not yet verified role-by-role and table-by-table
- production rollout on a real host with real certificates is not yet verified
- rollback and restore drills are not yet recorded as completed
- some placeholder or synthetic data remains on selected surfaces

## Readiness Estimate

Use this only as a planning aid, not as sign-off.

| Area | Status |
|------|--------|
| Security hardening in repo | strong but still verification-gated |
| Auth verification | incomplete |
| RLS verification | incomplete |
| Production packaging | materially improved |
| Monitoring and restore readiness | partial |
| Documentation quality | strong |

## Immediate Next Actions

1. Run [AUTH-E2E-CHECKLIST.md](/Users/zeljkodzafic/Documents/sarenasfera_platforma/docs/AUTH-E2E-CHECKLIST.md).
2. Run [DATABASE-RLS-VERIFICATION.md](/Users/zeljkodzafic/Documents/sarenasfera_platforma/docs/DATABASE-RLS-VERIFICATION.md).
3. Boot the production compose stack on a real target host.
4. Execute one rollback drill and one restore drill.
5. Record evidence in docs, not just terminal output.
