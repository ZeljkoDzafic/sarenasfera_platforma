# Multi-Cloud Deployment Notes

Last updated: 2026-03-09
Status: Historical reference, not canonical

This file preserves earlier provider-specific deployment directions. It is useful for planning, but it is not the active release guide for the current repository.

Read these first:

1. [PRODUCTION-READINESS.md](/Users/zeljkodzafic/Documents/sarenasfera_platforma/docs/PRODUCTION-READINESS.md)
2. [PRODUCTION-STATUS.md](/Users/zeljkodzafic/Documents/sarenasfera_platforma/docs/PRODUCTION-STATUS.md)
3. [PRODUCTION-DEPLOYMENT.md](/Users/zeljkodzafic/Documents/sarenasfera_platforma/docs/PRODUCTION-DEPLOYMENT.md)
4. [DEPLOYMENT-RUNBOOK.md](/Users/zeljkodzafic/Documents/sarenasfera_platforma/docs/DEPLOYMENT-RUNBOOK.md)

## Purpose

Use this document only for:

- comparing hosting options
- estimating future infrastructure directions
- evaluating provider tradeoffs after the MVP launch path is stable

Do not use this document as proof that the project has a tested multi-cloud deployment strategy.

## Current Canonical Path

The current repo-standard production path is compose-based:

- [docker-compose.prod.yml](/Users/zeljkodzafic/Documents/sarenasfera_platforma/docker-compose.prod.yml)
- [`.env.production.example`](/Users/zeljkodzafic/Documents/sarenasfera_platforma/.env.production.example)
- root [package.json](/Users/zeljkodzafic/Documents/sarenasfera_platforma/package.json) production scripts

If this file conflicts with the compose-based path, the compose-based path wins.

## Historical Provider Directions

These directions remain only as planning references:

- DigitalOcean as likely first hosted path
- AWS as a later-scale option
- Azure as an enterprise-oriented option
- shared hosting as a low-fit fallback with major constraints

None of the above should be treated as implemented or validated from the current repo alone.

## Explicit Non-Claims

This file does not claim that:

- `scripts/deploy.sh` exists and is production-approved
- GitHub Actions already perform end-to-end production rollout
- DigitalOcean App Platform is verified for this repo
- AWS or Azure infrastructure templates are present and current
- multi-cloud failover has been rehearsed

## When To Expand This File

Expand this document only after:

- one canonical production path is live and verified
- rollback and restore drills are complete
- provider-specific infrastructure is actually codified in repo

Until then, keep this file short and historical.
