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

- verified end-to-end auth flow
- verified table-by-table RLS coverage
- field-proven production rollout with real certs and secrets
- complete production hardening across monitoring, backups, and restore drills

## Goal

Move fast toward a production-ready platform without losing architectural clarity. The canonical docs in `docs/` are structured to support parallel work by Codex, Claude, Qwen, and human contributors.

## Local Setup

Prerequisites:

- Node.js 22 (`nvm use` reads [.nvmrc](/Users/zeljkodzafic/Documents/sarenasfera_platforma/.nvmrc))
- npm 10+
- Python 3.12
- Docker Desktop

Initial setup:

```bash
npm run setup:local
npm run verify:config
npm run install:all
```

Then update local env files:

- `frontend/.env`
  - `NUXT_PUBLIC_SUPABASE_URL=http://localhost:54321`
  - `NUXT_PUBLIC_SUPABASE_ANON_KEY=<value from .env ANON_KEY>`
  - `NUXT_PUBLIC_API_URL=http://localhost:8080`
- `api/.env`
  - `SUPABASE_URL=http://localhost:54321`
  - `SUPABASE_SERVICE_ROLE_KEY=<value from .env SERVICE_ROLE_KEY>`
  - `SUPABASE_ANON_KEY=<value from .env ANON_KEY>`
  - `INTERNAL_API_KEY=<shared key for internal API calls>`

Run local development:

```bash
npm run dev:stack
npm run dev:api
npm run dev:frontend
```

Useful local URLs:

- Frontend: `http://localhost:3000`
- Supabase Studio: `http://localhost:3001`
- Kong/API Gateway: `http://localhost:54321`
- FastAPI: `http://localhost:8080`
- Mailpit: `http://localhost:8025`

## Build And Publish

Frontend production build:

```bash
npm run build:frontend
```

Build production Docker images:

```bash
npm run build:prod
```

Start production compose stack:

```bash
cp .env.production.example .env.production
npm run publish:prod
```

Production note:

- `docker-compose.prod.yml` now expects `INTERNAL_API_KEY` for protected FastAPI email endpoints.
- HTTPS nginx setup still expects real certificates mounted under `certs/`.
