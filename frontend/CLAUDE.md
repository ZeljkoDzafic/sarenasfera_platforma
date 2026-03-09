# Claude Code — Agent Instructions

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

## File Structure

```
frontend/                 # Nuxt 3 app
  pages/                  # File-based routing
  composables/            # useAuth, useSupabase, useFeatures, useTier
  components/ui/          # Reusable brand components
  layouts/                # default, portal, admin
  middleware/             # auth, guest, role
  types/database.ts       # Supabase TypeScript types
  tailwind.config.ts      # Brand colors, domain colors, fonts
  assets/css/main.css     # Base component classes

api/                      # Python FastAPI
  app/main.py

supabase/
  migrations/             # Ordered SQL files
  kong.yml

docs/
  TASKS.md                # 90+ tasks, 10 phases, dependency graph
  arhitektura/            # 18 architecture documents
```

## Key Architecture Documents

Read these BEFORE working on tasks:

| Task Area | Read First |
|-----------|-----------|
| Database / SQL | `docs/arhitektura/03-database-schema.md` |
| Auth / roles / RLS | `docs/arhitektura/04-auth-and-roles.md` |
| Child Passport | `docs/arhitektura/06-child-passport.md` |
| Overall architecture | `docs/arhitektura/11-supabase-architecture.md` |
| Feature flags, tiers | `docs/arhitektura/14-feature-flags-and-tiers.md` |
| Growth features | `docs/arhitektura/16-growth-engagement-strategy.md` |
| Child tracking, LMS | `docs/arhitektura/17-child-tracking-and-education.md` |
| UI / design / colors | `docs/arhitektura/18-ui-design-guidelines.md` |

## Task System

All tasks are in `docs/TASKS.md`. Each task has:
- **ID** (e.g., T-302)
- **Depends on** — do not start until dependencies are done
- **Agent scope** — what you should build
- **Acceptance criteria** — must meet all before marking done
- **Output** — expected files/directories

### How to Pick Tasks

1. Read `docs/TASKS.md`
2. Find tasks whose dependencies are already completed
3. Read the architecture docs listed in the task
4. Implement the task
5. Verify against acceptance criteria

### Parallel Work Streams (safe to work on simultaneously)

```
Stream A: Frontend core (T-100 → T-800 → T-200 → T-201/T-202)
Stream B: Database/backend (T-101 → T-102 → T-103 → T-203 → T-500)
Stream C: DevOps (T-104, T-105)
Stream D: Public site (T-600..T-603)
Stream K: Child tracking (T-1000 → T-1001..T-1005)
Stream L: Education/LMS (T-1010 → T-1011..T-1015)
```

## Brand & Design Rules

### Colors (use these, NOT generic Tailwind colors)

```
Primary action:  primary-500 (#9b51e0, purple)
Brand red:       brand-red (#cf2e2e)
Brand blue:      brand-blue (#0693e3)
Brand purple:    brand-purple (#9b51e0)
Brand pink:      brand-pink (#f78da7)
Brand amber:     brand-amber (#fcb900)
Brand green:     brand-green (#00d084)
```

### Domain Colors (always use these for domains)

```
domain-emotional: #cf2e2e (red)
domain-social:    #fcb900 (amber)
domain-creative:  #9b51e0 (purple)
domain-cognitive: #0693e3 (blue)
domain-motor:     #00d084 (green)
domain-language:  #f78da7 (pink)
```

### Component Classes (from main.css)

```
.btn-primary      Purple button, shadow-colorful
.btn-secondary    White with purple border
.btn-danger       Brand red
.btn-success      Brand green
.card             White, rounded-2xl, shadow-card
.card-domain      Card with colored left border
.card-featured    Purple-to-pink gradient, white text
.input            Rounded-xl, purple focus ring
.badge-free       Gray badge
.badge-paid       Amber badge
.badge-premium    Purple badge
.domain-emotional etc.  Domain color text + border
.domain-bg-emotional    Domain background (10% opacity)
```

## Conventions

- **Vue components:** PascalCase files, `<script setup lang="ts">`, Composition API
- **Composables:** `use` prefix, return reactive refs
- **Pages:** file-based routing (`pages/portal/children/[id].vue`)
- **SQL:** snake_case, UUID PKs, `created_at`/`updated_at` timestamps, `is_active` soft delete
- **RLS:** every table must have policies for all 4 roles
- **TypeScript:** strict mode, no `any` types
- **CSS:** Tailwind utility classes, component classes in `main.css` only for reusable patterns
- **Commit messages:** English, concise, "Add X" / "Fix Y" / "Update Z"

## Local Dev Commands

```bash
# Frontend
cd frontend && npm run dev          # Dev server :3000
cd frontend && npm run build        # Production build
cd frontend && npx nuxt typecheck   # Type checking

# Supabase
docker compose up -d                # Start all services
docker compose logs -f auth         # Debug auth service
docker compose down                 # Stop all

# Python API
cd api && uvicorn app.main:app --reload --port 8080

# Database
docker exec -it sarena-db psql -U postgres  # Direct SQL access
```

## Common Pitfalls

- Supabase GoTrue requires `GOTRUE_JWT_SECRET` matching `JWT_SECRET` in `.env`
- PostgREST needs `PGRST_JWT_SECRET` matching the same JWT secret
- Kong routes are in `supabase/kong.yml` — if an endpoint doesn't work, check routing
- RLS policies must use `auth.uid()` for current user — this comes from the JWT
- `app_metadata.role` stores the user role, set via service role key only
- BHS characters (c, c, s, z, dj) — always test with actual Bosnian text
- Charts need Chart.js (`vue-chartjs` wrapper in Vue components)
