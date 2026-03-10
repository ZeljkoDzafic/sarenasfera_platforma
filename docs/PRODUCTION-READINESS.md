# Production Readiness

Last updated: 2026-03-09
Status: Not yet production-ready

This document is the launch gate, not a motivational summary. If this file, [SECURITY-REVIEW.md](/Users/zeljkodzafic/Documents/sarenasfera_platforma/docs/SECURITY-REVIEW.md), and [PROJECT-STATUS.md](/Users/zeljkodzafic/Documents/sarenasfera_platforma/docs/PROJECT-STATUS.md) disagree, trust the more conservative statement.

## Current Truth

The repo now contains meaningful production scaffolding:

- local setup and config verification scripts
- production Dockerfiles for frontend and API
- production compose path with Kong and nginx wiring
- internal protection for FastAPI email endpoints
- frontend sanitization for rich educational content
- deployment and verification documentation

That is not enough for launch sign-off.

The platform must still be treated as not ready for production traffic until the blocking verification work is completed and recorded.

## Canonical Verification Docs

Run and update these before any launch decision:

1. [SECURITY-REVIEW.md](/Users/zeljkodzafic/Documents/sarenasfera_platforma/docs/SECURITY-REVIEW.md)
2. [AUTH-E2E-CHECKLIST.md](/Users/zeljkodzafic/Documents/sarenasfera_platforma/docs/AUTH-E2E-CHECKLIST.md)
3. [DATABASE-RLS-VERIFICATION.md](/Users/zeljkodzafic/Documents/sarenasfera_platforma/docs/DATABASE-RLS-VERIFICATION.md)
4. [DEPLOYMENT-RUNBOOK.md](/Users/zeljkodzafic/Documents/sarenasfera_platforma/docs/DEPLOYMENT-RUNBOOK.md)
5. [PRODUCTION-DEPLOYMENT.md](/Users/zeljkodzafic/Documents/sarenasfera_platforma/docs/PRODUCTION-DEPLOYMENT.md)
6. [PRODUCTION-STATUS.md](/Users/zeljkodzafic/Documents/sarenasfera_platforma/docs/PRODUCTION-STATUS.md)

## Release Gate

All items below must be true before the status can change to production-ready.

### 1. Access control is verified

- auth registration, verification, login, logout, forgot-password, and reset-password all pass on a clean stack
- role redirects are verified for parent, staff, and admin
- no privileged frontend path is accessible without correct auth state

### 2. Database access rules are verified

- critical tables are tested role-by-role with real users
- parent access is limited to own children and related records
- staff access is limited to assigned operational scope
- admin access is confirmed where intended
- expert read-only boundaries are confirmed where intended

### 3. Production packaging is field-proven

- `npm run verify:config` passes
- production images build successfully
- production compose boots on a real target host
- nginx starts with real certificate mounts
- Kong routes auth, REST, storage, and frontend traffic correctly
- rollback steps are exercised, not just documented

### 4. Frontend and API verification is recorded

- `cd frontend && npm ci` passes
- `cd frontend && npm run typecheck` passes
- production build completes successfully
- API startup and health checks pass with production-like env values

Current evidence recorded on 2026-03-09:

- root `npm run verify:config` passed after `.env.production.example` was corrected to a valid Compose env-file format
- frontend `npm run typecheck` passed after strict TypeScript cleanup
- frontend `npm run build` passed, including Nitro prerender for `/`, `/program`, `/contact`, and `/resources`
- `python3 -m compileall api/app` passed
- clean local Docker validation now proves that `auth` and `api` can boot, but the database migration chain still stops on late historical migration conflicts and is not yet fully green
- this does not remove the remaining launch blockers around auth E2E, RLS verification, and real-host deployment validation

### 5. Operational safety exists

- backups and restore steps are documented and exercised
- monitoring and alerting are configured for the first release
- secrets are real, non-placeholder, and stored outside the repo
- known placeholder or synthetic admin data is removed or clearly isolated

## What Is Implemented But Not Yet Sign-Off

These are meaningful improvements, but they are not launch proof on their own:

- production env templates
- compose-based deployment path
- Kong declarative config
- internal API key protection
- HTML sanitization on selected rich-content routes
- education seed data
- production-oriented docs and runbooks

## Fastest Honest Path To Launch

1. Install dependencies on a clean machine and rerun frontend checks.
2. Run the auth E2E checklist and record exact pass/fail results.
3. Run the RLS verification checklist and record exact pass/fail results.
4. Boot the production compose stack on a real host with real certs and secrets.
5. Execute one rollback drill and one restore drill.
6. Update this file and [PRODUCTION-STATUS.md](/Users/zeljkodzafic/Documents/sarenasfera_platforma/docs/PRODUCTION-STATUS.md) with evidence, not intention.

## Sign-Off Rule

Do not mark this project as `production-ready`, `ready for launch`, or equivalent unless:

- the release gate items above are complete
- the linked verification docs contain recorded outcomes
- the statement is consistent with [SECURITY-REVIEW.md](/Users/zeljkodzafic/Documents/sarenasfera_platforma/docs/SECURITY-REVIEW.md)

Until then, the correct public status is:

`Not yet production-ready. Strong scaffolding exists, but launch blockers remain.`
