# OpenAI Codex — Agent Instructions

You are working on the **Sarena Sfera** child development platform.

## Critical Rules

- **NO PHP** — this project uses TypeScript (Nuxt 3) + Python (FastAPI) + SQL
- **All code comments and variable names in English** — UI text in BHS (Bosnian)
- **Always read the relevant architecture doc** before implementing a task
- **Never commit secrets** (.env, JWT keys, service role keys)
- **Use brand colors** from `frontend/tailwind.config.ts` — never use generic/default colors
- **Use official logo** from `/public/logo.svg` — never placeholder logos
- **Rounded UI** — all components use `rounded-xl` to `rounded-2xl`, soft shadows
- **Mobile-first** — staff use phones at workshops, parents browse on mobile

## Project Context

- Child development tracking platform for children aged 2-6
- 4 roles: parent, staff, admin, expert
- 6 developmental domains: emotional, social, creative, cognitive, motor, language
- 12-month program, 96 workshops (8/month)
- Self-hosted Supabase on DigitalOcean
- 3 subscription tiers: Free (0 KM), Paid (15 KM/mj), Premium (30 KM/mj)

## Tech Stack

| Layer | Technology | Notes |
|-------|-----------|-------|
| Frontend | Nuxt 3 + Vue 3 + TypeScript + Tailwind CSS | SSR for public, SPA for portal/admin |
| Backend | Self-hosted Supabase (PostgreSQL 15, GoTrue, PostgREST, Storage) | RLS on ALL tables |
| Custom API | Python 3.12 + FastAPI | PDF (WeasyPrint), email (Resend), analytics |
| Fonts | Nunito (body) + Baloo 2 (headings) | Google Fonts, support BHS chars |
| Gateway | Kong | Routes /auth/v1/, /rest/v1/, /storage/v1/ |

## Setup

```bash
# Environment
cp .env.example .env

# Supabase backend
docker compose up -d

# Frontend
cd frontend && npm install && npm run dev

# Python API
cd api && pip install -r requirements.txt
uvicorn app.main:app --reload --port 8080
```

## File Structure

```
frontend/                 # Nuxt 3 app
  pages/                  # File-based routing (index, auth/, portal/, admin/, events/, quiz/)
  composables/            # useAuth, useSupabase, useFeatures, useTier
  components/ui/          # Reusable brand components
  layouts/                # default (public), portal, admin
  middleware/             # auth, guest, role
  types/database.ts       # Supabase TypeScript types
  tailwind.config.ts      # Brand colors, domain colors, fonts
  assets/css/main.css     # Base component classes (.btn-primary, .card, .badge-*, .domain-*)

api/                      # Python FastAPI
  app/main.py

supabase/
  migrations/             # Ordered SQL files (001_core.sql, 002_groups.sql, ...)
  kong.yml

docs/
  TASKS.md                # 90+ tasks, 10 phases, dependency graph — READ THIS FIRST
  arhitektura/            # 18 architecture documents
```

## Task System

**All tasks are defined in `docs/TASKS.md`.**

Each task is self-contained and designed for independent AI agent pickup:
- **ID** — e.g., T-302, T-1011
- **Depends on** — prerequisite tasks (do NOT start until dependencies are done)
- **Agent scope** — what to build
- **Acceptance criteria** — checklist of requirements
- **Output** — expected files

### How to Work

1. Read `docs/TASKS.md` to see all tasks and their status
2. Pick a task whose dependencies are marked done or whose files exist
3. Read the architecture doc(s) referenced by the task
4. Implement to acceptance criteria
5. Test locally if possible

### Recommended Tasks for Codex

Codex excels at focused, file-scoped tasks. Good starting points:

**Database tasks (SQL only, no frontend):**
- T-102: Convert schema doc → SQL migration files
- T-103: Seed data (BHS language)
- T-1000: Developmental milestones schema + seed
- T-1010: Educational content schema

**Component tasks (single Vue file):**
- T-800: Base UI components (Button, Card, Input, Badge, etc.)
- T-801: Branded layout components
- T-303: RadarChart component (Chart.js)
- T-812: ComingSoonBadge + ComingSoonModal

**Python API tasks:**
- T-500: FastAPI scaffolding
- T-501: PDF report generation
- T-502: Email service

**Page tasks (read architecture doc first):**
- T-201: Auth pages (login, register, forgot password)
- T-301: Parent dashboard
- T-600: Landing page

## Key Architecture Documents

Read the relevant doc BEFORE implementing:

| Task Area | Document |
|-----------|----------|
| Database / schema | `docs/arhitektura/03-database-schema.md` (61 tables, all SQL) |
| Auth / roles | `docs/arhitektura/04-auth-and-roles.md` |
| Child Passport | `docs/arhitektura/06-child-passport.md` |
| Overall architecture | `docs/arhitektura/11-supabase-architecture.md` |
| Feature flags, tiers | `docs/arhitektura/14-feature-flags-and-tiers.md` |
| Growth features | `docs/arhitektura/16-growth-engagement-strategy.md` |
| Child tracking, LMS | `docs/arhitektura/17-child-tracking-and-education.md` |
| UI / design / colors | `docs/arhitektura/18-ui-design-guidelines.md` |

## Brand Colors

All colors are defined in `frontend/tailwind.config.ts`. Use ONLY these:

```
Primary (purple): #9b51e0  →  primary-500 (buttons, links, active states)
Brand red:        #cf2e2e  →  brand-red (CTAs, alerts, emotional domain)
Brand blue:       #0693e3  →  brand-blue (links, info, cognitive domain)
Brand pink:       #f78da7  →  brand-pink (accents, language domain)
Brand amber:      #fcb900  →  brand-amber (warnings, stars, social domain)
Brand green:      #00d084  →  brand-green (success, motor domain)
```

### 6 Domain Colors (use consistently everywhere)

```
emotional:  #cf2e2e (red)     — Heart icon
social:     #fcb900 (amber)   — People icon
creative:   #9b51e0 (purple)  — Palette icon
cognitive:  #0693e3 (blue)    — Lightbulb icon
motor:      #00d084 (green)   — Running icon
language:   #f78da7 (pink)    — Speech bubble icon
```

## CSS Classes Available (from main.css)

```css
/* Buttons */
.btn-primary     /* Purple, shadow-colorful, rounded-xl */
.btn-secondary   /* White, purple border */
.btn-danger      /* Brand red */
.btn-success     /* Brand green */
.btn-ghost       /* Transparent, purple text */

/* Cards */
.card            /* White, rounded-2xl, shadow-card */
.card-hover      /* Card with hover shadow lift */
.card-domain     /* Card with colored left border */
.card-featured   /* Purple→pink gradient, white text */

/* Inputs */
.input           /* Rounded-xl, purple focus ring */
.label           /* Semibold, gray-700 */

/* Badges */
.badge-free      /* Gray */
.badge-paid      /* Amber */
.badge-premium   /* Purple */

/* Domain utilities */
.domain-emotional, .domain-social, etc.      /* border + text color */
.domain-bg-emotional, .domain-bg-social, etc. /* 10% opacity background */
```

## Code Conventions

### Vue / TypeScript
- `<script setup lang="ts">` with Composition API
- PascalCase component files
- Composables: `use` prefix, return reactive refs
- Pages: file-based routing (`pages/portal/children/[id].vue`)
- TypeScript strict mode, no `any`
- Use `useSupabase()` composable for all DB operations
- Use `useAuth()` for authentication state

### SQL
- snake_case table and column names
- UUID primary keys: `id UUID DEFAULT gen_random_uuid() PRIMARY KEY`
- Always include: `created_at TIMESTAMPTZ DEFAULT now()`, `updated_at TIMESTAMPTZ DEFAULT now()`
- Soft delete with `is_active BOOLEAN DEFAULT true` where appropriate
- RLS policies required on every table for all 4 roles
- Use `auth.uid()` in RLS policies to reference current user

### Python
- FastAPI with async endpoints
- Pydantic models for request/response
- Supabase client via service role key (bypasses RLS)
- WeasyPrint for PDF generation
- Resend for email sending

## Parallel Work Streams

These streams can be worked on simultaneously without conflicts:

```
Stream A: Frontend scaffolding  → UI components → Auth
Stream B: Database migrations   → Seed data → RLS policies → FastAPI
Stream C: CI/CD + environment config
Stream D: Public pages (landing, program, blog)
Stream E: Feature flags system
Stream F: Subscription tier system
Stream G: Parent portal pages
Stream H: Admin panel pages
Stream K: Child milestone tracking
Stream L: Educational content (LMS)
```

## Testing

```bash
cd frontend && npx nuxt typecheck   # Type checking
cd frontend && npm run build        # Build check
cd api && python -m py_compile app/main.py  # Python syntax check
```
