# Production Deployment Runbook

Last updated: 2026-03-09
Status: Drafted, partially verified
Owner: Operations Team

This runbook is for the current canonical production path only: root-level production Docker Compose.

Use with:

- [PRODUCTION-READINESS.md](/Users/zeljkodzafic/Documents/sarenasfera_platforma/docs/PRODUCTION-READINESS.md)
- [PRODUCTION-DEPLOYMENT.md](/Users/zeljkodzafic/Documents/sarenasfera_platforma/docs/PRODUCTION-DEPLOYMENT.md)
- [SECURITY-REVIEW.md](/Users/zeljkodzafic/Documents/sarenasfera_platforma/docs/SECURITY-REVIEW.md)

## Pre-Deployment Checklist

Do not deploy until all are true:

- frontend dependencies install cleanly
- `cd frontend && npm run typecheck` passes
- auth E2E flow is verified
- RLS verification is complete
- `.env.production` exists with real values
- real certificates are available on the target host
- backup and rollback plans are prepared for the same host

## Deployment Procedure

From the repo root:

```bash
cp .env.production.example .env.production
npm run verify:config
npm run build:prod
npm run publish:prod
npm run logs:prod
```

## First Boot Verification

After first boot on the real target host:

1. Confirm all containers are healthy.
2. Check frontend root page and one public route.
3. Check FastAPI `/health`.
4. Check Supabase gateway routes through Kong.
5. Check nginx starts with real certificate mounts.
6. Verify one parent auth flow manually.
7. Verify one admin-only route manually.

## Rollback Procedure

If the release is unhealthy:

1. Stop new rollout traffic.
2. Restore the previous known-good image set or compose state.
3. Re-check frontend root, API health, and one protected route.
4. Record the failure cause before the next deploy attempt.

This repo documents the rollback requirement, but rollback is not considered verified until it has been exercised on the real target host.

## Backup And Restore

Before production migrations:

1. Create a database backup.
2. Store it outside the application host.
3. Record timestamp, operator, and restore target.

Restore is not considered ready until one restore drill has been executed and documented.

## Monitoring Baseline

The first release should have at minimum:

- uptime check for frontend
- uptime check for API health endpoint
- error reporting for frontend and API
- alert routing to an operator-owned channel

## Non-Claims

This runbook does not claim that:

- App Platform deployment is the canonical path
- multi-cloud deployment is production-ready
- rollback has already been rehearsed
- monitoring is fully configured today

It only defines the intended operational path for the current repo.
