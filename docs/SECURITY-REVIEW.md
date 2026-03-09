# Security Review

Date: 2026-03-09
Reviewer: Codex

This review is based on the current repository state. It distinguishes between:

- fixed in this pass
- still open and blocking production launch

## Critical Findings

### 1. Internal email API endpoints were callable without server-side authentication

Severity: Critical

Risk:

- anonymous abuse of transactional email endpoints
- password-reset and registration email spam
- operational cost and reputation damage

Status:

- fixed in [api/app/security.py](/Users/zeljkodzafic/Documents/sarenasfera_platforma/api/app/security.py)
- enforced on [api/app/routers/email.py](/Users/zeljkodzafic/Documents/sarenasfera_platforma/api/app/routers/email.py)
- production startup now fails if `INTERNAL_API_KEY` is missing via [api/app/config.py](/Users/zeljkodzafic/Documents/sarenasfera_platforma/api/app/config.py)

Required before launch:

- all callers of FastAPI email endpoints must send `X-Internal-API-Key`
- production `.env.production` must include a strong random `INTERNAL_API_KEY`

### 2. Rich HTML from education content could be rendered unsanitized in the portal

Severity: Critical

Risk:

- stored XSS through admin-authored course/resource HTML
- credential theft or session abuse in portal routes

Status:

- mitigated with sanitization in [frontend/utils/sanitizeHtml.ts](/Users/zeljkodzafic/Documents/sarenasfera_platforma/frontend/utils/sanitizeHtml.ts)
- applied to [frontend/pages/portal/education/courses/[slug]/lessons/[id].vue](/Users/zeljkodzafic/Documents/sarenasfera_platforma/frontend/pages/portal/education/courses/[slug]/lessons/[id].vue)
- applied to [frontend/pages/portal/education/resources/[slug].vue](/Users/zeljkodzafic/Documents/sarenasfera_platforma/frontend/pages/portal/education/resources/[slug].vue)

Residual risk:

- sanitization is application-level and should still be complemented by server-side content validation if admin-authored HTML becomes a major product surface

### 3. Production gateway config was inconsistent with production service names

Severity: Critical

Risk:

- broken auth/rest/storage routing in production
- failed deploy despite apparently valid compose file

Status:

- fixed by adding [docker/kong/kong.prod.yml](/Users/zeljkodzafic/Documents/sarenasfera_platforma/docker/kong/kong.prod.yml)
- wired in [docker-compose.prod.yml](/Users/zeljkodzafic/Documents/sarenasfera_platforma/docker-compose.prod.yml)
- production Kong now runs in declarative mode instead of mixed database/declarative mode

## High Findings

### 4. Production compose workflow did not actually consume `.env.production`

Severity: High

Risk:

- deploy commands using wrong environment values
- false sense of reproducible production packaging

Status:

- fixed in [package.json](/Users/zeljkodzafic/Documents/sarenasfera_platforma/package.json)
- production scripts now use `docker compose --env-file .env.production`

### 5. Email templates interpolated user-controlled values directly into HTML

Severity: High

Risk:

- HTML injection in outgoing email bodies
- link manipulation inside transactional email content

Status:

- mitigated by escaping in [api/app/services/email.py](/Users/zeljkodzafic/Documents/sarenasfera_platforma/api/app/services/email.py)
- request URL fields tightened in [api/app/models/email.py](/Users/zeljkodzafic/Documents/sarenasfera_platforma/api/app/models/email.py)

### 6. Production auth email autoconfirm was enabled

Severity: High

Risk:

- accounts could bypass intended email verification policy

Status:

- set to `false` in [docker-compose.prod.yml](/Users/zeljkodzafic/Documents/sarenasfera_platforma/docker-compose.prod.yml)

## Open Launch Blockers

These still block a credible production launch:

### 1. RLS coverage is not verified table-by-table

Severity: Critical

Current state:

- migrations contain significant policy work
- full role-based verification is not documented as completed

Required:

- run policy verification with real test users for parent, staff, admin, expert, anon
- document exact pass/fail results

### 2. End-to-end auth flow is still not verified on a clean local stack

Severity: High

Current state:

- auth pages exist
- local stack wiring improved
- runtime verification is still pending

Required:

- test register, verify, login, forgot-password, reset-password, logout
- test post-login redirects for parent and staff/admin

### 3. Production certificates and final nginx deployment inputs are not present

Severity: High

Current state:

- nginx config expects mounted certs
- repo does not contain real certificates and should not

Required:

- provision certs on target host
- verify nginx startup with real mounted paths

### 4. No verified test suite beyond limited syntax/static checks

Severity: High

Current state:

- Python syntax compiles
- `npm run verify:config` passes
- frontend `npm run typecheck` passes
- frontend `npm run build` passes

Required:

- add and run real API and frontend smoke tests
- run auth E2E and RLS verification against a live local stack

### 5. Placeholder or synthetic data still exists in some admin/portal surfaces

Severity: Medium

Risk:

- operators make decisions on fake numbers
- launch quality and trust degrade

Known example:

- [frontend/pages/admin/stats/index.vue](/Users/zeljkodzafic/Documents/sarenasfera_platforma/frontend/pages/admin/stats/index.vue)

## Verification Performed In This Pass

- Python syntax compile passed for current FastAPI sources
- `npm run verify:config` passed
- frontend `npm run typecheck` passed
- frontend `npm run build` passed
- static config review passed for:
  - production compose env wiring
  - Kong declarative routing
  - root package scripts

## Recommended Next Gate

Do not call the platform production-ready until these are complete:

1. clean local install and boot using `npm run setup:local` and `npm run install:all`
2. auth flow verification
3. RLS verification
4. production compose boot on a real host with valid `.env.production`
5. rollback and restore drill on the target deployment model
