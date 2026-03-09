# Sarena Sfera Digital Platform

Child development tracking platform ("Djeciji Pasos" / Children's Passport) for tracking children's progress across 6 developmental domains over a 12-month program of 96 workshops.

## Quick Start

### Prerequisites
- Node.js 20+
- Docker & Docker Compose
- Python 3.12+ (for API development)

### Local Development

```bash
# 1. Clone and install
git clone <repo-url>
cd sarenasfera_platforma

# 2. Environment
cp .env.example .env
# Edit .env — generate real JWT_SECRET: openssl rand -base64 32

# 3. Start Supabase (database, auth, storage, API gateway)
docker compose up -d

# 4. Frontend
cd frontend
npm install
npm run dev
# → http://localhost:3000

# 5. Python API (optional, for PDF/email features)
cd api
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8080
```

### Service URLs (Local)

| Service | URL | Purpose |
|---------|-----|---------|
| Frontend | http://localhost:3000 | Nuxt 3 dev server |
| Supabase API | http://localhost:54321 | Kong API gateway (PostgREST, Auth, Storage) |
| Supabase Studio | http://localhost:3001 | Database admin UI |
| Python API | http://localhost:8080 | FastAPI (PDF, email, analytics) |
| PostgreSQL | localhost:5432 | Direct DB access |
| Mailpit | http://localhost:8025 | Email testing UI |

## Project Structure

```
sarenasfera_platforma/
├── frontend/              # Nuxt 3 (Vue 3 + TypeScript + Tailwind CSS)
│   ├── pages/             # File-based routing
│   │   ├── index.vue      # Landing page (SSR)
│   │   ├── auth/          # Login, register, password reset
│   │   ├── portal/        # Parent portal (SPA)
│   │   ├── admin/         # Staff/admin panel (SPA)
│   │   ├── events/        # Public event pages (SSR)
│   │   └── quiz/          # Development quiz (SSR)
│   ├── composables/       # useAuth, useSupabase, useFeatures, useTier
│   ├── components/        # Reusable Vue components
│   ├── layouts/           # default (public), portal, admin
│   ├── middleware/         # auth, guest, role guards
│   ├── types/             # TypeScript types (database.ts)
│   └── assets/css/        # Tailwind + brand styles
├── api/                   # Python FastAPI
│   └── app/main.py        # Health, PDF reports, email, analytics
├── supabase/
│   ├── migrations/        # SQL migration files (ordered)
│   └── kong.yml           # API gateway routing config
├── docker-compose.yml     # 9 services for local dev
├── .github/workflows/     # CI (lint, typecheck, build) + Deploy
└── docs/
    ├── TASKS.md           # 90+ tasks across 10 phases
    └── arhitektura/       # 18 architecture documents
```

## Architecture

```
┌─────────────────────────────────────────────────┐
│  Frontend: Nuxt 3 (SSR public + SPA portal)     │
│  Fonts: Nunito + Baloo 2  |  Colors: Brand      │
└──────────────────┬──────────────────────────────┘
                   │
          ┌────────┴────────┐
          │  Kong Gateway   │  :54321
          │  /auth/v1/      │──→ GoTrue (auth)
          │  /rest/v1/      │──→ PostgREST (CRUD)
          │  /storage/v1/   │──→ Storage API
          └────────┬────────┘
                   │
          ┌────────┴────────┐
          │  PostgreSQL 15  │  61+ tables, RLS on all
          └─────────────────┘
                   │
          ┌────────┴────────┐
          │  Python FastAPI  │  :8080
          │  PDF, Email,     │
          │  Analytics, Cron │
          └─────────────────┘
```

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Nuxt 3, Vue 3, TypeScript, Tailwind CSS |
| Auth | Supabase GoTrue (JWT, magic links, OAuth) |
| Database | PostgreSQL 15 with Row Level Security |
| API (auto) | PostgREST (auto-generated REST from schema) |
| API (custom) | Python FastAPI (PDF, email, analytics) |
| Storage | Supabase Storage (photos, documents) |
| Realtime | Supabase Realtime (WebSocket subscriptions) |
| Gateway | Kong (API routing, rate limiting) |
| CI/CD | GitHub Actions |
| Deploy | Docker Compose on DigitalOcean |

## Key Features

| Feature | Description | Tier |
|---------|-------------|------|
| Workshop registration | Public event pages, auto-creates account | Free |
| Development quiz | 8-10 question quiz, radar chart results | Free |
| Child Passport | 6-domain tracking with radar charts | Paid |
| Milestone tracking | Age-appropriate developmental milestones | Paid |
| Activity library | 200+ home activities, filterable | Tiered |
| Online courses | Self-paced video/text modules (mini-LMS) | Tiered |
| Quarterly PDF reports | Auto-generated development reports | Premium |
| Community forum | Parent community, expert Q&A | Premium |
| Referral system | Invite friends, earn free months | All |
| "Roditelji Pioniri" | First 50 families, lifetime price lock | Special |

## User Roles

| Role | Access |
|------|--------|
| Parent | Portal: children, passport, workshops, activities, education |
| Staff | Admin: observations, attendance, groups, messaging |
| Admin | Full admin: users, settings, feature flags, subscriptions |
| Expert | Read-only: observations, assessments (for consulting) |

## 6 Development Domains

Each domain has a dedicated brand color used throughout the platform:

| Domain | Color | Hex |
|--------|-------|-----|
| Emocionalni (Emotional) | Red | `#cf2e2e` |
| Socijalni (Social) | Amber | `#fcb900` |
| Kreativni (Creative) | Purple | `#9b51e0` |
| Kognitivni (Cognitive) | Blue | `#0693e3` |
| Motoricki (Motor) | Green | `#00d084` |
| Jezicki (Language) | Pink | `#f78da7` |

## Documentation

All architecture docs are in `docs/arhitektura/`:

| Doc | Topic |
|-----|-------|
| 03 | Database schema (61 tables) |
| 06 | Child Passport system |
| 11 | Supabase architecture (PRIMARY) |
| 14 | Feature flags & subscription tiers |
| 16 | Growth & engagement strategy |
| 17 | Child tracking & educational content |
| 18 | UI & design guidelines |

Full index: `docs/arhitektura/README.md`

## Task Tracking

See `docs/TASKS.md` for 90+ tasks across 10 phases with dependency graph.

### Phases Overview

| Phase | Focus | Tasks |
|-------|-------|-------|
| 0 | Architecture & docs | T-001..T-004 (done) |
| 1 | Scaffolding & DevOps | T-100..T-105 |
| 2 | Auth & authorization | T-200..T-203 |
| 3 | Parent portal | T-300..T-307 |
| 4 | Admin panel | T-400..T-409 |
| 5 | Python API | T-500..T-504 |
| 6 | Public website | T-600..T-603 |
| 7 | Testing & deploy | T-700..T-703 |
| 8 | Feature flags, tiers, events | T-810..T-840 |
| 9 | Growth & engagement | T-900..T-908 |
| 10 | Child tracking & education | T-1000..T-1015 |

## Working with AI Agents

This project is designed for parallel development by multiple AI agents.
Each task in `docs/TASKS.md` is self-contained with:
- Clear dependencies
- Acceptance criteria
- Input/output files
- Agent scope description

See agent-specific instructions:
- **Claude Code:** `CLAUDE.md`
- **OpenAI Codex:** `CODEX.md`

## Business Model

- **Free:** Register via workshop, basic portal access
- **Paid (15 KM/mj):** Passport, activities, courses, messaging
- **Premium (30 KM/mj):** PDF reports, community, expert sessions, full LMS

## License

Proprietary. All rights reserved.
