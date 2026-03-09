# Sarena Sfera Platform

Production-oriented digital platform for child development tracking, parent engagement, workshop operations, and growth funnels.

## Start Here

For the most accurate project context, read in this order:

1. `docs/README.md`
2. `docs/PROJECT-STATUS.md`
3. `docs/AGENT-HANDBOOK.md`
4. `docs/arhitektura/README.md`

## Active Stack

- Frontend: Nuxt 4 + Vue 3 + TypeScript + Tailwind CSS
- Data/Auth: Self-hosted Supabase
- Custom backend: Python FastAPI
- DevOps: Docker Compose + GitHub Actions

## Repository Reality

The repo already contains:

- Nuxt public pages, portal pages, and admin pages
- Supabase migrations and seed data
- Auth, tier, and feature composables
- CI/CD baseline

The repo does not yet fully contain:

- auth UI pages
- production-grade FastAPI services
- complete deployment automation
- verified production-hardening across auth, RLS, backups, and monitoring

## Goal

Move fast toward a production-ready platform without losing architectural clarity. The canonical docs in `docs/` are structured to support parallel work by Codex, Claude, Qwen, and human contributors.
