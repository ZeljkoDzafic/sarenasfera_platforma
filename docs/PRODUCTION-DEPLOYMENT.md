# Production Deployment Guide

Last updated: 2026-03-09
Status: Drafted, not field-verified

This guide is a practical companion to [DEPLOYMENT-RUNBOOK.md](/Users/zeljkodzafic/Documents/sarenasfera_platforma/docs/DEPLOYMENT-RUNBOOK.md). It does not override the runbook.

## Canonical Path

The current canonical deployment path in this repo is production Docker Compose driven by:

- [docker-compose.prod.yml](/Users/zeljkodzafic/Documents/sarenasfera_platforma/docker-compose.prod.yml)
- [package.json](/Users/zeljkodzafic/Documents/sarenasfera_platforma/package.json)
- [`.env.production.example`](/Users/zeljkodzafic/Documents/sarenasfera_platforma/.env.production.example)

Use this path first. Treat older multi-cloud examples as reference material, not the primary rollout mechanism.

## Preflight

Before any production attempt:

1. Prepare env file:
   `cp .env.production.example .env.production`
2. Fill all required real values in `.env.production`
3. Verify config renders:
   `npm run verify:config`
4. Build production images:
   `npm run build:prod`

Do not deploy if any of these are still unverified:

- auth E2E flow
- RLS verification
- real certificates on target host
- rollback plan for the same target host

## Deployment Commands

Build:

```bash
npm run build:prod
```

Start:

```bash
npm run publish:prod
```

Tail logs:

```bash
npm run logs:prod
```

## First Boot Verification

After first boot on the target host:

1. Check compose status
2. Check frontend health path and root page
3. Check API `/health`
4. Check Kong routing for auth/rest/storage
5. Check nginx startup with real cert mounts
6. Verify one auth flow manually
7. Verify one protected admin flow manually

## What This Guide Does Not Claim

This guide does not mean the platform is already production-ready. It only means:

- the repo now contains a coherent deployment path
- the compose and env structure are materially more aligned than before

Real production readiness still depends on:

- [PRODUCTION-READINESS.md](/Users/zeljkodzafic/Documents/sarenasfera_platforma/docs/PRODUCTION-READINESS.md)
- [SECURITY-REVIEW.md](/Users/zeljkodzafic/Documents/sarenasfera_platforma/docs/SECURITY-REVIEW.md)
- [AUTH-E2E-CHECKLIST.md](/Users/zeljkodzafic/Documents/sarenasfera_platforma/docs/AUTH-E2E-CHECKLIST.md)
- [DATABASE-RLS-VERIFICATION.md](/Users/zeljkodzafic/Documents/sarenasfera_platforma/docs/DATABASE-RLS-VERIFICATION.md)
