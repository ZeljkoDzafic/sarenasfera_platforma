# Sarena Sfera Platform - Task Breakdown

## Strategy

**Architecture:** Supabase (primary). Laravel alternative assessed post-launch.
**Frontend:** Nuxt 3 (Vue 3 + TypeScript + Tailwind CSS)
**Backend:** Self-hosted Supabase + Python FastAPI
**Each task is self-contained** — designed for independent AI agent pickup.

### Launch Strategy: Staged Rollout
- Platform launches in sections, not all at once
- Admin can toggle features: **Active** / **Coming Soon** / **Hidden**
- Primary user acquisition: **Workshop registration = Account creation**
- 3 subscription tiers: **Free** (register) → **Paid** (15 KM/mj) → **Premium** (30 KM/mj)
- See `docs/arhitektura/14-feature-flags-and-tiers.md` for full details

---

## PHASE 0: Architecture & Documentation ✅ DONE

| ID | Task | Status | Output |
|----|------|--------|--------|
| T-001 | Supabase architecture document | ✅ DONE | `docs/arhitektura/11-supabase-architecture.md` |
| T-002 | Laravel architecture document | ✅ DONE | `docs/arhitektura/12-laravel-architecture.md` |
| T-003 | Architecture comparison | ✅ DONE | `docs/arhitektura/13-architecture-comparison.md` |
| T-004 | Task breakdown (this file) | ✅ DONE | `docs/TASKS.md` |

---

## PHASE 1: Project Scaffolding & DevOps

### T-100: Initialize Nuxt 3 Project
- **Status:** ✅ DONE
- **Depends on:** Nothing
- **Agent scope:** Create Nuxt 3 project in `frontend/`
- **Acceptance criteria:**
  - `npx nuxi init` with TypeScript
  - Tailwind CSS 4 configured
  - ESLint + Prettier configured
  - Base `app.vue` with router
  - `nuxt.config.ts` with SSR enabled
  - TypeScript strict mode
  - `.gitignore` updated
- **Output:** `frontend/` directory with working `npm run dev`

### T-101: Docker Compose — Local Supabase
- **Status:** ✅ DONE
- **Depends on:** Nothing
- **Agent scope:** Create Docker setup for local Supabase
- **Acceptance criteria:**
  - `docker-compose.yml` at project root
  - Services: PostgreSQL 15, GoTrue, PostgREST, Storage, Studio, Realtime, Kong
  - Studio accessible at `http://localhost:3001`
  - API accessible at `http://localhost:8000`
  - `.env.docker` with all required secrets (generated)
  - `scripts/setup-local.sh` — one-command setup
  - Volume mounts for persistence
- **Output:** `docker-compose.yml`, `.env.docker`, `scripts/`
- **Test:** `docker compose up -d` → all services healthy

### T-102: Database Migrations (SQL)
- **Status:** ✅ DONE (Claude — `supabase/migrations/010-018_*.sql`)
- **Depends on:** T-101
- **Agent scope:** Convert schema doc to executable SQL migrations
- **Input:** `docs/arhitektura/03-database-schema.md` (61 tables)
- **Acceptance criteria:**
  - `supabase/migrations/` directory with ordered SQL files
  - `001_core.sql` — profiles, children, parent_children, locations
  - `002_groups.sql` — groups, group_staff, child_groups
  - `003_workshops.sql` — workshop_templates, workshops, sessions
  - `004_tracking.sql` — observations, assessments, milestones
  - `005_attendance.sql` — attendance, daily_routines, check_ins
  - `006_reports.sql` — quarterly_reports, learning_stories, portfolio
  - `007_communication.sql` — messages, notifications, email_campaigns
  - `008_content.sql` — blog_posts, resources, home_activities
  - `009_billing.sql` — subscriptions, plans, payments
  - `010_crm.sql` — leads, lead_activities, enrollment_pipeline
  - `011_rls_policies.sql` — RLS for ALL tables
  - `012_functions.sql` — database functions and triggers
  - All tables have: UUID PKs, timestamps, is_active
  - Trigger: auto-create profile on auth.users insert
- **Output:** `supabase/migrations/*.sql`
- **Test:** Run against local PostgreSQL, no errors

### T-103: Seed Data
- **Status:** ✅ DONE (Claude — `supabase/migrations/018_seed.sql`)
- **Depends on:** T-102
- **Agent scope:** Create seed data for development/demo
- **Acceptance criteria:**
  - `supabase/seed.sql`
  - 1 admin user, 2 staff users, 5 parent users
  - 10 children with varied ages (2-6 years)
  - 3 groups (Mala, Srednja, Velika)
  - 1 location
  - 8 workshop templates (1 per month × 8 workshops)
  - 4 sessions (upcoming + past)
  - 20+ observations (mixed domains)
  - Sample assessments for 3 children
  - 2 blog posts
  - 5 home activities
  - All data in BHS (Bosnian) language
- **Output:** `supabase/seed.sql`

### T-104: GitHub Actions CI/CD
- **Status:** ✅ DONE
- **Depends on:** T-100
- **Agent scope:** Set up CI/CD pipeline
- **Acceptance criteria:**
  - `.github/workflows/ci.yml` — runs on every PR
    - Lint (ESLint)
    - Type check (nuxt typecheck)
    - Unit tests (Vitest)
    - Build check (nuxt build)
  - `.github/workflows/deploy.yml` — manual trigger + on merge to main
    - Build Docker images
    - Push to GitHub Container Registry
    - SSH deploy to DigitalOcean (optional, manual trigger)
  - `.github/workflows/db-check.yml` — validate SQL migrations
- **Output:** `.github/workflows/*.yml`

### T-105: Environment & Config
- **Status:** ✅ DONE
- **Depends on:** T-100, T-101
- **Agent scope:** Environment files and configuration
- **Acceptance criteria:**
  - `.env.example` — documented template
  - `frontend/.env.example` — Nuxt env vars
  - `.env.docker` — Docker Compose env
  - `frontend/nuxt.config.ts` — runtime config for env vars
  - Document in README how to set up locally
- **Output:** `.env.*` files, updated `nuxt.config.ts`

---

## PHASE 2: Authentication & Authorization

### T-200: Supabase Client Composable
- **Status:** ✅ DONE
- **Depends on:** T-100, T-101
- **Agent scope:** Create Nuxt composable for Supabase
- **Acceptance criteria:**
  - `frontend/composables/useSupabase.ts` — singleton client
  - `frontend/plugins/supabase.ts` — Nuxt plugin for initialization
  - `frontend/types/database.ts` — TypeScript types for all tables
  - Auto-refresh session on expiry
  - Handle auth state changes
- **Output:** `composables/useSupabase.ts`, `plugins/supabase.ts`, `types/database.ts`

### T-201: Auth Pages
- **Depends on:** T-200
- **Agent scope:** Login, register, forgot password, email verification
- **Acceptance criteria:**
  - `pages/auth/login.vue` — email/password login
  - `pages/auth/register.vue` — registration with role selection
    - Onboarding wizard for parents (add first child)
  - `pages/auth/forgot-password.vue` — send reset email
  - `pages/auth/reset-password.vue` — set new password
  - `pages/auth/verify.vue` — email verification callback
  - Form validation (client-side)
  - Error messages (wrong password, email taken, etc.)
  - Redirect after login: parents → /portal, staff → /admin
  - Mobile responsive
- **Output:** `pages/auth/*.vue`

### T-202: Auth Middleware
- **Status:** ✅ DONE
- **Depends on:** T-200
- **Agent scope:** Route protection middleware
- **Acceptance criteria:**
  - `middleware/auth.ts` — redirect to login if not authenticated
  - `middleware/guest.ts` — redirect to portal/admin if already logged in
  - `middleware/role.ts` — check user role (parent, staff, admin, expert)
  - `/portal/*` requires auth + parent role
  - `/admin/*` requires auth + staff or admin role
  - Public pages accessible without auth
- **Output:** `middleware/*.ts`

### T-203: RLS Policies
- **Depends on:** T-102
- **Agent scope:** Row Level Security for ALL tables
- **Input:** `docs/arhitektura/04-auth-and-roles.md`
- **Acceptance criteria:**
  - Every table has SELECT, INSERT, UPDATE, DELETE policies
  - Parents: see own children + related data only
  - Staff: see children in their groups
  - Admin: full access
  - Expert: read-only on observations/assessments
  - Service role bypasses RLS (for Python API)
  - Test each policy with different user roles
- **Output:** `supabase/migrations/011_rls_policies.sql` (updated)

---

## PHASE 3: Parent Portal

### T-300: Portal Layout ✅ DONE (Codex)
- **Depends on:** T-202
- **Agent scope:** Portal shell with navigation
- **Acceptance criteria:**
  - `layouts/portal.vue` — sidebar + top nav + main content area
  - Sidebar: Dashboard, Moja Djeca, Radionice, Aktivnosti, Galerija, Profil
  - Mobile: hamburger menu → slide-out sidebar
  - User info in top-right (name, avatar, logout)
  - Notification bell with badge count
  - Breadcrumbs
  - Active route highlighting
- **Output:** `layouts/portal.vue`, `components/portal/Sidebar.vue`, `components/portal/TopNav.vue`

### T-301: Parent Dashboard ✅ DONE (Codex)
- **Depends on:** T-300
- **Agent scope:** Main portal dashboard
- **Acceptance criteria:**
  - `pages/portal/index.vue`
  - Children cards with mini radar chart per child
  - Upcoming workshops (next 7 days)
  - Recent observations (last 5)
  - Pending home activities
  - Quick links to child passport
  - Responsive grid layout
- **Output:** `pages/portal/index.vue`, related components

### T-302: Children List & Detail ✅ DONE (Codex)
- **Depends on:** T-300
- **Agent scope:** My children management
- **Acceptance criteria:**
  - `pages/portal/children/index.vue` — list of parent's children
  - `pages/portal/children/[id].vue` — child detail with tabs
    - Tab: Overview (basic info + current group)
    - Tab: Passport (radar chart + domain breakdown)
    - Tab: Observations (timeline view)
    - Tab: Attendance (calendar heatmap)
    - Tab: Reports (downloadable PDFs)
- **Output:** `pages/portal/children/`

### T-303: Child Passport Component ✅ DONE (Codex)
- **Depends on:** T-302
- **Agent scope:** The core feature — 6-domain development visualization
- **Input:** `docs/arhitektura/06-child-passport.md`
- **Acceptance criteria:**
  - `components/portal/PassportView.vue` — main passport view
  - `components/charts/RadarChart.vue` — 6-axis radar (Chart.js)
  - 6 domains: emotional, social, creative, cognitive, motor, language
  - Score range: 1-5 per domain
  - Period selector (Q1, Q2, Q3, Q4, full year)
  - Compare periods overlay on radar
  - Domain detail cards (score + recent observations)
  - Progress timeline per domain
  - Print-friendly view
- **Output:** Passport components + RadarChart

<<<<<<< claude/review-tasks-documentation-Dj0Ne
### T-304: Workshop Calendar
- **Status:** ✅ DONE (Claude — `pages/portal/calendar.vue`)
=======
### T-304: Workshop Calendar ✅ DONE (Codex)
>>>>>>> main
- **Depends on:** T-300
- **Agent scope:** Workshop schedule and materials
- **Acceptance criteria:**
  - `pages/portal/workshops.vue`
  - Calendar view (month) showing scheduled sessions
  - List view alternative
  - Session detail: title, description, date, group, materials
  - Filter by child / group
  - Downloadable workshop materials (PDF, images)
  - Past workshops with attendance status
- **Output:** `pages/portal/workshops.vue`, calendar components

### T-305: Home Activities
- **Status:** ✅ DONE (Claude — `pages/portal/activities.vue`)
- **Depends on:** T-300
- **Agent scope:** Activities parents can do at home
- **Acceptance criteria:**
  - `pages/portal/activities.vue`
  - List of assigned activities (by staff)
  - Activity card: title, description, domain, instructions
  - Mark as completed (with optional photo/note)
  - Filter by domain, status (pending/done)
  - Activity history
- **Output:** `pages/portal/activities.vue`

### T-306: Photo Gallery
- **Status:** ✅ DONE (Claude — `pages/portal/gallery.vue`)
- **Depends on:** T-300
- **Agent scope:** Child photos from observations
- **Acceptance criteria:**
  - `pages/portal/gallery.vue`
  - Grid of photos from observations (own children only)
  - Lightbox view
  - Filter by child, date range, domain
  - Download individual / bulk download
- **Output:** `pages/portal/gallery.vue`

### T-307: Profile Settings
- **Status:** ✅ DONE (Claude — `pages/portal/settings.vue`)
- **Depends on:** T-300
- **Agent scope:** Parent profile management
- **Acceptance criteria:**
  - `pages/portal/profile.vue`
  - Edit name, phone, avatar
  - Change password
  - Notification preferences (email on/off per type)
  - Language preference (future)
  - Account deletion request
- **Output:** `pages/portal/profile.vue`

---

## PHASE 4: Admin Panel

### T-400: Admin Layout
- **Status:** ✅ DONE (layouts/admin.vue already exists)
- **Depends on:** T-202
- **Agent scope:** Admin shell with navigation
- **Acceptance criteria:**
  - `layouts/admin.vue` — sidebar + top nav
  - Sidebar: Dashboard, Djeca, Grupe, Radionice, Opservacije, Prisustvo, Poruke, Korisnici, Statistike
  - Collapsible sidebar
  - Quick-add button (observation, attendance)
  - Mobile optimized (staff use phones in workshops)
- **Output:** `layouts/admin.vue`, admin nav components

### T-401: Admin Dashboard
- **Status:** ✅ DONE (Claude — `pages/admin/index.vue`)
- **Depends on:** T-400
- **Agent scope:** Admin overview with key metrics
- **Acceptance criteria:**
  - `pages/admin/index.vue`
  - Stat cards: total children, groups, upcoming workshops, today's attendance
  - Chart: observations per week (last 8 weeks)
  - Chart: attendance trend
  - Today's schedule
  - Recent activity log
  - Quick actions: add observation, mark attendance
- **Output:** `pages/admin/index.vue`

### T-402: Children Management (Admin)
- **Depends on:** T-400
- **Agent scope:** Full CRUD for children
- **Acceptance criteria:**
  - `pages/admin/children/index.vue` — searchable, filterable data table
  - `pages/admin/children/[id].vue` — child detail + edit
  - `pages/admin/children/new.vue` — add new child
  - Search by name
  - Filter by group, age, status
  - Assign/remove from groups
  - Link parent accounts
  - View observations, assessments, attendance
  - Bulk actions (assign to group, export)
- **Output:** `pages/admin/children/`

### T-403: Groups Management
- **Depends on:** T-400
- **Agent scope:** Group CRUD
- **Acceptance criteria:**
  - `pages/admin/groups/index.vue` — groups list
  - `pages/admin/groups/[id].vue` — group detail
  - Create/edit group: name, age range, schedule, max capacity, location
  - Assign staff to groups
  - Assign/remove children
  - View group roster
  - Capacity indicator
- **Output:** `pages/admin/groups/`

### T-404: Workshop Management
- **Depends on:** T-400
- **Agent scope:** Workshop templates + session scheduling
- **Acceptance criteria:**
  - `pages/admin/workshops/index.vue` — templates list + sessions calendar
  - `pages/admin/workshops/[id].vue` — template detail
  - Create workshop template: title, description, domain, methodology, materials
  - Schedule session from template: date, time, group, location
  - Upload materials (PDF, images)
  - Session status: scheduled → in-progress → completed
  - Duplicate templates
- **Output:** `pages/admin/workshops/`

### T-405: Observation Entry (Mobile-First)
- **Depends on:** T-400
- **Agent scope:** Quick observation entry — THE core admin feature
- **Acceptance criteria:**
  - `pages/admin/observations/index.vue` — observation list + filters
  - `pages/admin/observations/new.vue` — quick entry form
  - Select child (searchable dropdown or recent children)
  - Select domain (6 colorful buttons)
  - Text content (with templates/quick phrases)
  - Photo upload (camera on mobile)
  - Link to workshop session (optional)
  - Milestone tagging (optional)
  - **< 2 minute entry time on mobile**
  - Batch entry mode (multiple children, same workshop)
  - Draft saving (auto-save)
- **Output:** `pages/admin/observations/`

### T-406: Attendance Tracking
- **Depends on:** T-400
- **Agent scope:** Daily attendance management
- **Acceptance criteria:**
  - `pages/admin/attendance/index.vue`
  - Grid view: children (rows) × dates (columns)
  - Status: present, absent, late, excused
  - Bulk mark (all present, then mark exceptions)
  - Check-in / check-out times
  - Filter by group, date range
  - Attendance statistics per child
  - Export to CSV
- **Output:** `pages/admin/attendance/`

### T-407: User Management (Admin only)
- **Depends on:** T-400
- **Agent scope:** Manage platform users
- **Acceptance criteria:**
  - `pages/admin/users/index.vue` — user list
  - `pages/admin/users/[id].vue` — user detail
  - Create user (invite by email)
  - Assign/change role
  - Activate/deactivate accounts
  - View user activity log
  - Reset password
  - Admin-only access
- **Output:** `pages/admin/users/`

### T-408: Messaging
- **Depends on:** T-400
- **Agent scope:** Parent-staff communication
- **Acceptance criteria:**
  - `pages/admin/messages/index.vue` — inbox/sent
  - Compose message: to parent(s), subject, body
  - Broadcast to group (all parents in a group)
  - Message templates
  - Read/unread status
  - Realtime via Supabase subscriptions
- **Output:** `pages/admin/messages/`

### T-409: Statistics & Analytics
- **Depends on:** T-400
- **Agent scope:** Admin analytics dashboard
- **Acceptance criteria:**
  - `pages/admin/statistics.vue`
  - Charts: enrollment over time, attendance rates, observations by domain
  - Per-group comparison
  - Per-staff activity (observations entered)
  - Export reports to CSV
  - Date range selector
- **Output:** `pages/admin/statistics.vue`

---

## PHASE 5: Python API

### T-500: FastAPI Scaffolding
- **Depends on:** T-101
- **Agent scope:** Python API project setup
- **Acceptance criteria:**
  - `api/` directory with FastAPI app
  - `api/app/main.py` — app + CORS
  - `api/app/config.py` — env config
  - `api/app/dependencies.py` — Supabase client, auth verification
  - `api/Dockerfile`
  - `api/requirements.txt`
  - Health check endpoint: `GET /health`
  - JWT verification (validates Supabase tokens)
  - Added to `docker-compose.yml` as service
- **Output:** `api/` directory

### T-501: PDF Report Service
- **Depends on:** T-500
- **Agent scope:** Quarterly report PDF generation
- **Acceptance criteria:**
  - `POST /v1/reports/quarterly` — generate report
  - `GET /v1/reports/quarterly/{id}/pdf` — download PDF
  - Report includes: child info, radar chart, observations summary, attendance %, recommendations
  - Template in HTML → WeasyPrint → PDF
  - Upload to Supabase Storage
  - Save reference in quarterly_reports table
- **Output:** Report endpoints + HTML template

### T-502: Email Service
- **Depends on:** T-500
- **Agent scope:** Email sending via Resend
- **Acceptance criteria:**
  - `POST /v1/email/send` — single email
  - `POST /v1/email/campaign` — bulk send
  - `POST /v1/email/workshop-summary` — auto post-workshop email
  - Email templates (HTML)
  - Resend integration
  - Rate limiting
- **Output:** Email endpoints + templates

### T-503: Analytics API
- **Depends on:** T-500
- **Agent scope:** Aggregated analytics for admin
- **Acceptance criteria:**
  - `GET /v1/analytics/dashboard` — overview stats
  - `GET /v1/analytics/child/{id}/trend` — development trend
  - `GET /v1/analytics/group/{id}/summary` — group summary
  - Complex aggregations (beyond PostgREST capability)
- **Output:** Analytics endpoints

### T-504: Cron Jobs
- **Depends on:** T-500
- **Agent scope:** Scheduled tasks
- **Acceptance criteria:**
  - Attendance reminders (day before workshop)
  - Inactive child alerts (no attendance in 2 weeks)
  - Weekly staff digest email
  - Monthly parent progress summary
  - APScheduler or system cron integration
- **Output:** Cron endpoints + scheduler config

---

## PHASE 6: Public Website

### T-600: Landing Page
- **Depends on:** T-100
- **Agent scope:** Homepage — SSR for SEO
- **Acceptance criteria:**
  - `pages/index.vue` — hero, features, testimonials, CTA
  - SEO meta tags
  - Mobile responsive
  - Fast loading (< 2s)
  - Links to registration
- **Output:** `pages/index.vue`

### T-601: Program Page
- **Status:** ✅ DONE (Claude — `pages/program.vue`)
- **Depends on:** T-100
- **Agent scope:** Program overview
- **Acceptance criteria:**
  - `pages/program.vue`
  - 6 development domains explained
  - Workshop structure (12 months, 96 workshops)
  - Methodologies (Montessori, NTC, custom)
  - Pricing tiers
- **Output:** `pages/program.vue`

### T-602: Blog
- **Status:** ✅ DONE (Claude — `pages/blog/index.vue`, `pages/blog/[slug].vue`)
- **Depends on:** T-100
- **Agent scope:** Blog with SSR for SEO
- **Acceptance criteria:**
  - `pages/blog/index.vue` — blog listing with pagination
  - `pages/blog/[slug].vue` — single post (SSR)
  - Categories, tags
  - SEO: structured data, OG tags, sitemap
  - Reading time estimate
- **Output:** `pages/blog/`

### T-603: Contact & Resources
- **Status:** ✅ DONE (Claude — `pages/contact.vue`, `pages/resources.vue`)
- **Depends on:** T-100
- **Agent scope:** Contact form + downloadable resources
- **Acceptance criteria:**
  - `pages/contact.vue` — contact form (saves to leads table)
  - `pages/resources.vue` — free PDF guides, worksheets (lead magnets)
  - Download requires email (lead capture)
- **Output:** `pages/contact.vue`, `pages/resources.vue`

---

## PHASE 7: Testing & Launch

### T-700: Unit Tests
- **Depends on:** All PHASE 2-4
- **Agent scope:** Vitest component/composable tests
- **Acceptance criteria:**
  - Test all composables (useAuth, useChildren, etc.)
  - Test key components (RadarChart, ObservationForm, AttendanceGrid)
  - Minimum 70% coverage on composables
  - `npm run test` passes
- **Output:** `tests/unit/`

### T-701: E2E Tests
- **Depends on:** All PHASE 2-4
- **Agent scope:** Playwright end-to-end tests
- **Acceptance criteria:**
  - Auth flow: register → verify → login → logout
  - Parent: view dashboard → view child passport → download report
  - Admin: add observation → mark attendance → send message
  - Mobile viewport tests
- **Output:** `tests/e2e/`

### T-702: Production Docker
- **Depends on:** T-101
- **Agent scope:** Production-ready Docker setup
- **Acceptance criteria:**
  - `docker-compose.prod.yml`
  - Nginx reverse proxy + SSL (Let's Encrypt)
  - Supabase production config (secure passwords, limited Studio access)
  - Python API production config
  - Automated backups (daily pg_dump)
  - Log rotation
  - Health checks on all services
- **Output:** `docker-compose.prod.yml`, `nginx/`, `scripts/backup.sh`

### T-703: Deploy to DigitalOcean
- **Depends on:** T-702
- **Agent scope:** Production deployment
- **Acceptance criteria:**
  - Deploy script: `scripts/deploy.sh`
  - DNS configuration documented
  - SSL certificates (auto-renewal)
  - Smoke tests pass on production
  - Monitoring set up (UptimeRobot)
- **Output:** `scripts/deploy.sh`, deployment docs

---

## UI Component Library & Design (Shared)

> Full design spec: `docs/arhitektura/18-ui-design-guidelines.md`
> Logo source: sarenasfera.com — use official logo + brand colors
> Fonts: Nunito (body) + Baloo 2 (headings) from Google Fonts
> Style: Colorful ("sarene"), rounded corners, soft shadows, playful but professional

### T-790: Brand Assets & Fonts Setup
- **Status:** ✅ DONE
- **Depends on:** T-100
- **Agent scope:** Set up logo, favicon, fonts, and brand foundation
- **Acceptance criteria:**
  - Download logo from sarenasfera.com → `/public/logo.svg`, `/public/logo.png`
  - Create white variant → `/public/logo-white.svg`
  - Create icon-only variant → `/public/logo-icon.svg`
  - Favicon: `/public/favicon.ico` (32x32 from logo icon)
  - Apple touch icon: `/public/apple-touch-icon.png` (180x180)
  - Google Fonts loaded: Nunito (400, 600, 700, 800) + Baloo 2 (500, 600, 700, 800)
  - Tailwind config uses brand colors from sarenasfera.com (already configured)
  - Verify BHS character support (c, c, s, z, dj)
- **Output:** `/public/logo*`, font loading in `nuxt.config.ts` or `app.vue`

### T-800: Base UI Components
- **Depends on:** T-100, T-790
- **Agent scope:** Reusable Tailwind components — colorful, rounded, branded
- **Input:** `docs/arhitektura/18-ui-design-guidelines.md`
- **Acceptance criteria:**
  - `components/ui/Button.vue` — variants: primary (purple), secondary (outline), danger (red), success (green), ghost
    - Rounded-xl, font-bold, shadow-colorful on primary
  - `components/ui/Input.vue` — text, email, password, textarea (rounded-xl, focus ring in primary color)
  - `components/ui/Select.vue` — dropdown with search
  - `components/ui/Modal.vue` — dialog with backdrop, rounded-2xl
  - `components/ui/Card.vue` — white, rounded-2xl, shadow-card, optional color top bar
  - `components/ui/DomainCard.vue` — card with domain color left border + icon
  - `components/ui/DataTable.vue` — sortable, filterable table
  - `components/ui/Badge.vue` — status badges (tier, domain, parent status) with brand colors
  - `components/ui/Toast.vue` — notification toasts (4 variants: info/success/warning/error using brand colors)
  - `components/ui/Tabs.vue` — tab navigation with active indicator in primary color
  - `components/ui/Calendar.vue` — date picker / calendar view
  - `components/ui/ProgressBar.vue` — colorful progress bar (domain-colored)
  - `components/ui/Avatar.vue` — rounded photo with optional colored ring border
  - All components use brand colors from tailwind.config.ts
  - All components use Nunito font, headings in Baloo 2
  - Rounded corners (xl to 2xl), soft shadows throughout
  - Accessible (ARIA attributes, focus states, contrast ratios)
  - Mobile-first, touch-friendly (44px min tap targets)
- **Output:** `components/ui/`

### T-801: Layout Components — Branded
- **Depends on:** T-800
- **Agent scope:** Branded header, footer, sidebar components
- **Acceptance criteria:**
  - Public header: logo (from `/public/logo.svg`), colorful nav, mobile hamburger
  - Public footer: logo, links, social icons, brand gradient divider
  - Portal sidebar: logo at top, domain-colored icons for child sections, active state with primary color
  - Admin sidebar: logo at top, clean professional style with brand accents
  - All layouts use the official Sarena Sfera logo
  - Gradient accents (purple → pink) on key sections
- **Output:** Updated `layouts/`, `components/layout/`

---

## PHASE 8: Feature Flags, Tiers & Event Registration (HIGH PRIORITY)

> These tasks enable the soft-launch strategy. Build BEFORE or IN PARALLEL with Phases 3-4.
> Full spec: `docs/arhitektura/14-feature-flags-and-tiers.md`

### T-810: Feature Flags — Database & Composable
- **Depends on:** T-102, T-200
- **Agent scope:** Feature flag system (backend + frontend)
- **Acceptance criteria:**
  - SQL migration: `feature_flags` table + `feature_interests` table
  - Seed all default flags (30+ entries from doc 14)
  - `composables/useFeatures.ts` — `isActive()`, `isComingSoon()`, `isVisible()`, `requiredTier()`
  - Features loaded once on app init, cached in state
  - RLS: anyone can read flags, only admin can update
- **Output:** migration file, seed data, `composables/useFeatures.ts`

### T-811: Feature Flags — Admin UI
- **Depends on:** T-400, T-810
- **Agent scope:** Admin page to manage feature toggles
- **Acceptance criteria:**
  - `pages/admin/features.vue`
  - List all features grouped by section (public, portal, admin)
  - Dropdown per feature: Active / Coming Soon / Hidden
  - Tier assignment per feature: Free / Paid / Premium
  - Save changes (instant update via Supabase)
  - Show interest count for "Coming Soon" features
- **Output:** `pages/admin/features.vue`

### T-812: Coming Soon Badge & Modal
- **Depends on:** T-810
- **Agent scope:** UI components for coming-soon features
- **Acceptance criteria:**
  - `components/ui/ComingSoonBadge.vue` — small badge next to nav items
  - `components/ui/ComingSoonModal.vue` — shows when user clicks
    - Feature name + description
    - "Obavijesti me" button (saves to `feature_interests`)
    - "Zatvori" button
  - Navigation items automatically show badge if feature is `coming_soon`
  - Navigation items hidden if feature is `hidden`
  - Both portal + admin layouts respect feature flags
- **Output:** `components/ui/ComingSoonBadge.vue`, `components/ui/ComingSoonModal.vue`

### T-820: Subscription Tiers — Database & Composable
- **Depends on:** T-102, T-200
- **Agent scope:** Subscription/tier system
- **Acceptance criteria:**
  - SQL migration: `subscription_plans`, `subscriptions`, `payments` tables
  - Add `subscription_tier` column to `profiles` table
  - Trigger: update `profiles.subscription_tier` when subscription changes
  - Seed 3 plans: Free (0 KM), Paid (15 KM), Premium (30 KM)
  - `composables/useTier.ts` — `tierName`, `hasAccess(tier)`, `canAddChild()`
  - Auto-assign free tier on registration
  - RLS: users see own subscription, admin sees all
- **Output:** migration file, `composables/useTier.ts`

### T-821: Upgrade Prompt Component
- **Depends on:** T-820
- **Agent scope:** UI for tier-gated features
- **Acceptance criteria:**
  - `components/ui/UpgradePrompt.vue` — shows when user lacks access
    - Shows required tier name + price
    - Lists features included in that tier
    - "Nadogradi" button → links to upgrade page or contact
    - "Možda kasnije" dismiss button
  - `components/ui/TierBadge.vue` — shows user's current tier in portal
  - Wrap tier-gated content with `<TierGate required="paid">` component
- **Output:** `components/ui/UpgradePrompt.vue`, `components/ui/TierBadge.vue`, `components/ui/TierGate.vue`

### T-822: Subscription Management — Admin
- **Depends on:** T-400, T-820
- **Agent scope:** Admin manages user subscriptions
- **Acceptance criteria:**
  - `pages/admin/subscriptions.vue`
  - Overview: count per tier (Free: 45, Paid: 12, Premium: 3)
  - User list with current tier, filterable
  - Manually assign/change tier for a user
  - Record payment (amount, method: cash/bank/card, reference)
  - View payment history per user
  - Admin-only access
- **Output:** `pages/admin/subscriptions.vue`

### T-830: Public Events Page
- **Status:** ✅ DONE (Claude — `pages/events/index.vue`, `pages/events/[slug].vue`, `supabase/migrations/001_events.sql`)
- **Depends on:** T-100
- **Agent scope:** Public workshop/event listing (SSR, no auth)
- **Acceptance criteria:**
  - SQL migration: `events` table, `event_registrations` table
  - `pages/events/index.vue` — list upcoming events (SSR for SEO)
    - Event card: title, date, time, age range, location, spots left
    - Filter by age range, domain
    - Past events hidden by default
  - `pages/events/[slug].vue` — event detail page
    - Full description, image, location map
    - "Prijavi dijete" CTA button → registration form
  - Public (no auth required)
  - Responsive, mobile-first
- **Output:** `pages/events/`, migration file

### T-831: Workshop Registration Form (creates account)
- **Depends on:** T-830, T-200
- **Agent scope:** THE primary acquisition funnel
- **Acceptance criteria:**
  - `pages/events/[slug]/register.vue` — registration form
  - Fields: parent name, email, phone, child name, DOB, allergies, consent
  - On submit:
    1. Check if email exists → link to existing account OR create new
    2. Create Supabase auth user (auto-gen password, send magic link)
    3. Create child record + parent_children link
    4. Create event_registration record
    5. Check capacity → confirmed or waitlist
    6. Auto-assign free subscription tier
  - Confirmation page: "Uspješna prijava!" + details + login link
  - Already have account? → "Prijavite se" link
  - Validation: all required fields, email format, child age within range
  - Success email: workshop details + account credentials
- **Output:** `pages/events/[slug]/register.vue`, server API route for registration logic

### T-832: Event Management — Admin
- **Depends on:** T-400, T-830
- **Agent scope:** Admin creates/manages public events
- **Acceptance criteria:**
  - `pages/admin/events/index.vue` — event list (upcoming + past)
  - `pages/admin/events/new.vue` — create event form
  - `pages/admin/events/[id].vue` — event detail + edit
  - `pages/admin/events/[id]/registrations.vue` — registration list
    - Table: parent name, child, age, status, registration date
    - Change status: confirmed / waitlist / cancelled
    - Export to CSV
    - Send reminder email to all registered
  - Create event from workshop template (optional link)
  - Publish/unpublish events
  - Duplicate event (for recurring workshops)
  - View capacity: spots filled vs max
- **Output:** `pages/admin/events/`

### T-833: Post-Event Workflow
- **Depends on:** T-832, T-406
- **Agent scope:** After workshop happens: attendance → observation → parent notification
- **Acceptance criteria:**
  - Admin marks attendance for event (links to attendance system)
  - event_registration.status updates: attended / no_show
  - Quick observation entry pre-filtered for event attendees
  - Email sent to parents: "Vaše dijete je danas prisustvovalo radionici"
  - If parent has paid tier: include observation preview
  - If free tier: teaser "Nadogradite za uvid u opservacije"
- **Output:** Server logic + email template

### T-840: Pricing Page
- **Depends on:** T-100, T-820
- **Agent scope:** Public pricing page showing tiers
- **Acceptance criteria:**
  - `pages/pricing.vue` (SSR for SEO)
  - 3 tier cards side by side (Free / Paid / Premium)
  - Feature comparison checklist
  - CTA: "Registrujte se" (free), "Započnite" (paid), "Sve uključeno" (premium)
  - FAQ section about pricing
  - Annual discount display (if applicable)
  - Mobile responsive (stacked cards)
- **Output:** `pages/pricing.vue`

---

## PHASE 9: Growth & Engagement (Inspired by AIZdravo.com)

> Learnings from AIZdravo analysis: `docs/arhitektura/15-competitive-learnings-aizdravo.md`
> These features drive acquisition, retention, and upsell.

### T-900: Development Quiz (Lead Generation) — CRITICAL
- **Status:** ✅ DONE (Claude — `pages/quiz/index.vue`, `supabase/migrations/002_quiz.sql`)
- **Depends on:** T-100
- **Agent scope:** Public quiz that profiles a child's development and captures leads
- **Acceptance criteria:**
  - `pages/quiz/index.vue` — 8-10 question quiz (no auth needed)
  - Questions: child age, behaviour, preferences, concerns, expectations
  - Multi-step form with progress bar
  - Mobile-first, engaging UI (one question per screen)
  - Result page: mini radar chart + strengths + areas to improve
  - Recommended workshops based on answers
  - CTA: "Registrujte se besplatno" or "Prijavite dijete na radionicu"
  - Email capture: "Pošaljite mi rezultate na email" (saves to leads table)
  - SQL: `quiz_responses` table (saves answers + results for analytics)
  - Admin can view quiz analytics (how many started, completed, converted)
  - Shareable result: "Podijelite rezultat" link for social media
  - SSR landing page for SEO: `/quiz`
- **Output:** `pages/quiz/`, `quiz_responses` migration, quiz logic

### T-901: Referral System ("Preporuči prijatelja")
- **Depends on:** T-200, T-820
- **Agent scope:** Referral system for parents
- **Acceptance criteria:**
  - SQL: `referrals` table (referrer_id, referred_email, status, reward_granted)
  - Each parent gets unique referral code/link
  - `pages/portal/referral.vue` — referral dashboard
    - Unique link display + copy button
    - Share buttons: WhatsApp, Viber, Facebook, email
    - Stats: invites sent, registered, active
    - Rewards earned
  - Reward: referrer gets 1 free month Paid tier per successful referral
  - Referred parent gets 1 month free Paid trial
  - Referral tracking: from registration form (source field)
  - Admin view: referral stats per user
  - Sidebar link: "Preporuči prijatelja" in portal navigation
- **Output:** `pages/portal/referral.vue`, migration, referral logic

### T-902: "Roditelji Pioniri" Program
- **Depends on:** T-820
- **Agent scope:** Early adopter / founding member program
- **Acceptance criteria:**
  - SQL: `pioneer_slots` table or config (max 50 slots, counter)
  - Landing page section or dedicated page: `/pioniri`
    - Benefits listed (lifetime price lock, badge, priority access, pioneer wall)
    - Counter: "Preostalo X od 50 mjesta"
    - CTA → registration with pioneer flag
  - Profile badge: "Roditelj Pionir" shown in portal header + community
  - Lifetime price: 10 KM/mj (Paid) or 20 KM/mj (Premium)
  - Admin: view pioneer list, manage slots
  - "Zid Pionira" (Pioneer Wall) — names displayed on public site
- **Output:** `/pioniri` page, badge component, pioneer logic

### T-903: Activity Library ("Biblioteka aktivnosti")
- **Depends on:** T-200, T-810
- **Agent scope:** Searchable library of home activities
- **Acceptance criteria:**
  - SQL: `activity_library` table (title, description, domain, age_min, age_max, type, duration, materials, instructions, difficulty, image_url, tier_required)
  - `pages/portal/library/index.vue` — searchable, filterable grid
    - Filter by: domain (6), age range, type (indoor/outdoor/creative/physical/sensory), duration
    - Search by keyword
    - Card layout: title, domain color, age, duration, difficulty
    - Tier gate: Free=10 activities, Paid=50, Premium=all
  - `pages/portal/library/[id].vue` — activity detail
    - Step-by-step instructions
    - Materials list
    - Photo/illustration
    - "Uradi i podijeli" (mark complete + upload photo)
    - Related activities
  - Seed: 30+ initial activities across all domains
  - Admin: CRUD for activities (`pages/admin/library/`)
- **Output:** `pages/portal/library/`, `pages/admin/library/`, migration, seed data

### T-904: Personalized Development Path ("Razvojna putanja")
- **Depends on:** T-303, T-820
- **Agent scope:** Personalized development journey per child
- **Acceptance criteria:**
  - `pages/portal/children/[id]/path.vue` — development path view
  - Timeline showing: past milestones → current focus areas → upcoming goals
  - Based on: quiz results + staff observations + assessments
  - Recommendations engine:
    - Suggested next workshops
    - Suggested home activities
    - Domain-specific tips
  - Updates as new observations/assessments are entered
  - Paid tier feature
  - Visual: vertical timeline with domain-colored nodes
- **Output:** `pages/portal/children/[id]/path.vue`, recommendation composable

### T-905: Parent Progress & Engagement Tracking
- **Depends on:** T-300, T-820
- **Agent scope:** Track parent's engagement level
- **Acceptance criteria:**
  - `pages/portal/progress.vue` — parent's own progress dashboard
  - Metrics:
    - Workshops attended (this month / total)
    - Home activities completed
    - Forum posts (if active)
    - Consecutive weeks with attendance (streak)
  - Engagement score calculation
  - Badges earned (displayed as icons)
  - Sidebar link: "Moj napredak" in portal navigation
  - Paid tier feature
- **Output:** `pages/portal/progress.vue`

### T-906: Certificates & Achievements
- **Depends on:** T-303, T-820
- **Agent scope:** Certificate and badge system
- **Acceptance criteria:**
  - SQL: `certificates` table, `badges` table, `user_badges` table
  - **Child certificates:**
    - Program completion (12-month Dječiji pasoš)
    - Domain mastery ("Kreativni istraživač", "Mali govornik", etc.)
    - Attendance milestones (25, 50, 75, 96 workshops)
  - **Parent badges:**
    - "Roditelj Pionir" — early adopter
    - "Aktivni roditelj" — 10+ home activities completed
    - "Ambasador" — 3+ referrals
    - "Redovan" — 8+ workshops in a month
  - `pages/portal/certificates.vue` — list all earned
  - PDF certificate generation (via Python API)
  - Badge display on profile + forum posts
  - Sidebar link: "Sertifikati" in portal navigation
  - Certificates: Premium tier; Badges: all tiers
- **Output:** `pages/portal/certificates.vue`, migrations, badge components

### T-907: Community Forum ("Zajednica") — Phase 3
- **Depends on:** T-200, T-810
- **Agent scope:** Parent community forum (Premium feature)
- **Acceptance criteria:**
  - SQL: `forum_categories`, `forum_topics`, `forum_posts` tables
  - `pages/portal/community/index.vue` — forum home
    - Category tabs: Opšte, Po uzrastu, Po domenu, Aktivnosti, Pitaj stručnjaka
    - Thread list: title, author, date, replies, views
    - Sorting: Najnovije, Najaktivnije
    - "+ Nova diskusija" button
  - `pages/portal/community/[id].vue` — topic detail + replies
  - Right sidebar: Trending teme, Top kontributori (with avatars + post counts)
  - Expert badge on staff/expert replies
  - Photo sharing in posts
  - Admin: pin/delete posts, moderate
  - Premium tier feature
- **Output:** `pages/portal/community/`, migrations

### T-908: Partner/Affiliate Program — Phase 3
- **Depends on:** T-901, T-822
- **Agent scope:** Program for kindergartens, paediatricians, partner organizations
- **Acceptance criteria:**
  - SQL: `partners` table (name, type, code, commission_rate)
  - Partner gets unique code
  - Partner dashboard: referrals tracked, commission earned
  - Admin: manage partners, view stats
  - Co-branded certificates (partner logo)
  - Types: kindergarten, school, pediatrician, organization
  - Commission: 20% of first month or free group license for 10+ referrals
- **Output:** Partner system (Phase 3, low priority)

---

## PHASE 10: Enhanced Child Tracking & Educational Content

> Extends the Child Passport (doc 06) with milestone tracking, and adds a mini-LMS
> for online courses, events, and resources.
> Full spec: `docs/arhitektura/17-child-tracking-and-education.md`

### T-1000: Developmental Milestones — Database & Seed
- **Depends on:** T-102
- **Agent scope:** Milestone tracking system (schema + seed data)
- **Acceptance criteria:**
  - SQL migration: `developmental_milestones` table, `child_milestones` table
  - `developmental_milestones`: domain, age_range_min/max, title, description, sort_order
  - `child_milestones`: child_id, milestone_id, status (not_started/emerging/achieved), achieved_at, observed_by
  - Seed ~200 milestones across 6 domains × 4 age brackets (2-3, 3-4, 4-5, 5-6)
  - All milestone text in BHS (Bosnian)
  - RLS: parents see own children's milestones, staff see children in their groups, admin full access
- **Output:** migration file, seed data

### T-1001: Child Growth Timeline View
- **Depends on:** T-302, T-1000
- **Agent scope:** Visual timeline of child's growth milestones
- **Acceptance criteria:**
  - `pages/portal/children/[id]/progress.vue` — growth timeline tab
  - Monthly grouping: milestones achieved, photos added, observations received
  - Domain-colored milestone icons (reuse domain color scheme)
  - Status indicators: achieved (green), emerging (yellow), not started (gray)
  - Filter by domain
  - Paid tier feature
- **Output:** `pages/portal/children/[id]/progress.vue`, timeline components

### T-1002: Domain Detail View
- **Depends on:** T-303, T-1000
- **Agent scope:** Per-domain breakdown page for a child
- **Acceptance criteria:**
  - `pages/portal/children/[id]/domain/[domain].vue`
  - Current score + progress bar (X of Y milestones achieved)
  - Milestone checklist: achieved, emerging, upcoming
  - Trend chart (score over quarters)
  - Recommended activities for this domain
  - Link to related home activities from library
  - Paid tier feature
- **Output:** Domain detail page

### T-1003: Staff Milestone Quick-Entry
- **Depends on:** T-405, T-1000
- **Agent scope:** Add milestone marking to observation entry flow
- **Acceptance criteria:**
  - Extend observation entry form (T-405) with milestone checklist
  - When staff selects a domain, show available milestones for that child's age
  - Checkbox to mark milestones as "emerging" or "achieved"
  - Auto-link milestone to observation
  - Bulk milestone marking for post-workshop assessment
- **Output:** Updated observation form components

### T-1004: Parent Observations (Moderated)
- **Depends on:** T-302, T-200
- **Agent scope:** Let parents submit home observations for staff review
- **Acceptance criteria:**
  - SQL migration: `parent_observations` table (child_id, parent_id, domain, content, photo_url, status)
  - `pages/portal/children/[id]/observe.vue` — parent observation form
    - Select domain, write note, upload photo
    - Status: pending → approved/rejected by staff
  - Staff view: `pages/admin/parent-observations.vue` — review queue
    - Approve (link to child record) or reject (with note)
  - Approved observations appear in child timeline
  - Notification to parent when reviewed
- **Output:** Migration, portal + admin pages

### T-1005: Passport Comparison View
- **Depends on:** T-303
- **Agent scope:** Compare child development across time periods
- **Acceptance criteria:**
  - `components/portal/PassportComparison.vue`
  - Radar chart overlay: current quarter vs previous vs age average
  - Table view: domain scores side by side with change indicators (↑/↓)
  - Highlight biggest improvement and area needing attention
  - Paid tier feature
- **Output:** Comparison component

### T-1010: Educational Content — Database
- **Depends on:** T-102
- **Agent scope:** Schema for all educational content types
- **Acceptance criteria:**
  - SQL migration with tables:
    - `educational_content` — master table (courses, events, resources)
    - `course_modules` — module grouping for courses
    - `course_lessons` — individual lessons (text, video, attachments)
    - `course_enrollments` — user enrollment tracking
    - `lesson_progress` — per-lesson completion tracking
    - `content_registrations` — event registration (replaces/extends event_registrations)
    - `resource_materials` — attachments for resource content
  - All indexes from doc 17
  - RLS: public can see published content, users track own progress, admin full CRUD
- **Output:** Migration file

### T-1011: Online Courses — Portal View
- **Depends on:** T-300, T-1010
- **Agent scope:** Course browsing, enrollment, and lesson viewing for parents
- **Acceptance criteria:**
  - `pages/portal/education/courses/index.vue` — course catalog
    - Grid of course cards (cover, title, duration, lessons count, tier badge)
    - Filter by domain, age range, tier
  - `pages/portal/education/courses/[slug].vue` — course detail + syllabus
    - Module/lesson tree with progress indicators
    - Enroll button (or continue)
    - Preview first lesson (free)
  - `pages/portal/education/courses/[slug]/lessons/[id].vue` — lesson view
    - HTML content or video player
    - Downloadable attachments
    - Mark as complete
    - Previous/Next navigation
  - Progress tracking (auto-save, resume where left off)
  - Tier gate: Free=1st lesson, Paid=3 courses, Premium=all
- **Output:** `pages/portal/education/courses/`

### T-1012: Events & Webinars — Portal + Public
- **Depends on:** T-830, T-1010
- **Agent scope:** Combined online/offline event listing and registration
- **Acceptance criteria:**
  - Extend existing events pages (T-830) to support all 4 event types
  - `pages/events/index.vue` — add tabs: Sve / Radionice / Webinari / Dogadjaji
  - Event card shows: type icon (online/offline), date, location/link, spots left
  - Registration form handles both online (sends meeting link) and offline events
  - Portal view: `pages/portal/education/events.vue` — my registered events
  - Past event recordings accessible (Premium tier)
  - Calendar download (.ics) for registered events
- **Output:** Updated event pages, portal events page

### T-1013: Educational Resources — Portal View
- **Depends on:** T-300, T-1010
- **Agent scope:** Article, PDF, and video resource library
- **Acceptance criteria:**
  - `pages/portal/education/resources/index.vue` — resource library
    - Filter by type (article, PDF, video, worksheet), domain, age
    - Card layout with type icon
  - `pages/portal/education/resources/[slug].vue` — resource detail
    - Article: rendered HTML
    - PDF: download button + preview
    - Video: embedded player
  - Download tracking (count, last downloaded)
  - Tier gate: Free=5, Paid=20/month, Premium=unlimited
  - Public resources available without login (lead capture on download)
- **Output:** `pages/portal/education/resources/`

### T-1014: Educational Content — Admin Management
- **Depends on:** T-400, T-1010
- **Agent scope:** Admin CRUD for all educational content
- **Acceptance criteria:**
  - `pages/admin/education/index.vue` — content list (all types, filterable)
  - `pages/admin/education/courses/new.vue` — course creator
    - Course details form
    - Module manager (add, reorder, delete)
    - Lesson editor per module (rich text, video URL, attachments)
    - Preview mode
  - `pages/admin/education/events/new.vue` — event creator
    - Type selector (4 types)
    - Scheduling, location/link, capacity
    - Registration management (confirm, waitlist, cancel)
  - `pages/admin/education/resources/new.vue` — resource creator
    - Type selector, file upload, content editor
  - Publish/draft/archive status management
  - Duplicate content (for recurring events)
  - Analytics per content item (views, enrollments, completion rate)
- **Output:** `pages/admin/education/`

### T-1015: Education Seed Data
- **Depends on:** T-1010
- **Agent scope:** Seed educational content for development/demo
- **Acceptance criteria:**
  - 2 sample online courses (3 modules, 5 lessons each, BHS text)
  - 3 upcoming events (1 offline workshop, 1 webinar, 1 open day)
  - 5 resources (2 articles, 2 PDFs, 1 video)
  - Content across multiple domains
  - Mix of free and tiered content
- **Output:** Seed SQL file

---

## Dependency Graph

```
T-100 (Nuxt) ──┬──> T-104 (CI/CD)
               ├──> T-105 (Env)
               ├──> T-800 (UI Components)
               ├──> T-830 (Public Events) ──> T-831 (Registration Form)
               └──> T-200 (Supabase Client)
                      ├──> T-810 (Feature Flags) ──> T-811 (Admin UI) + T-812 (Coming Soon)
                      ├──> T-820 (Tiers) ──> T-821 (Upgrade UI) + T-822 (Admin Subs)
                      ├──> T-201 (Auth Pages)
                      └──> T-202 (Auth Middleware)
                              ├──> T-300..T-307 (Portal, respects flags + tiers)
                              └──> T-400..T-409 (Admin)
                                     └──> T-832 (Event Admin) ──> T-833 (Post-Event)

T-101 (Docker) ──> T-102 (Migrations, includes events/flags/tiers tables)
              ├──> T-103 (Seed)
              ├──> T-500 (FastAPI)
              ├──> T-105 (Env)
              └──> T-203 (RLS)

T-100 ──> T-600..T-603 (Public Site)
T-100 ──> T-840 (Pricing Page)

T-102 ──> T-1000 (Milestones DB) ──> T-1001 (Timeline), T-1002 (Domain Detail), T-1003 (Staff Entry)
T-102 ──> T-1010 (Education DB) ──> T-1011 (Courses), T-1012 (Events), T-1013 (Resources), T-1014 (Admin Edu)
T-302 ──> T-1001, T-1004 (Parent Observations)
T-303 ──> T-1002, T-1005 (Comparison)
T-405 ──> T-1003 (Staff Milestone Entry)
```

## Parallel Work Streams

**Stream A (Frontend Core):** T-100 → T-800 → T-200 → T-201/T-202
**Stream B (Backend/DB):** T-101 → T-102 → T-103 → T-203 → T-500..T-504
**Stream C (DevOps):** T-104, T-105 (independent)
**Stream D (Public + Events):** T-600..T-603 + T-830 → T-831 (after T-100)
**Stream E (Feature Flags):** T-810 → T-811 + T-812 (after T-200)
**Stream F (Tiers):** T-820 → T-821 + T-822 + T-840 (after T-200)
**Stream G (Portal):** T-300..T-307 (after T-202, respects flags + tiers)
**Stream H (Admin):** T-400..T-409 + T-832 → T-833 (after T-202)
**Stream I (Testing):** T-700, T-701 (after phases 2-4)
**Stream J (Deploy):** T-702 → T-703 (after everything)
**Stream K (Child Tracking):** T-1000 → T-1001..T-1005 (after T-102 + T-302/T-303)
**Stream L (Education/LMS):** T-1010 → T-1011..T-1015 (after T-102 + T-300)

## Recommended Build Order (Soft Launch Priority)

```
WEEK 1:  T-100, T-101, T-102 (scaffolding + DB)
WEEK 2:  T-200, T-201, T-202, T-800 (auth + UI components)
WEEK 3:  T-810, T-820, T-830, T-900 (flags, tiers, events page, QUIZ)
WEEK 4:  T-831, T-811, T-812, T-902 (registration, feature admin, coming soon, PIONEERS)
         ──── SOFT LAUNCH: Public site + Quiz + Events + Pioneer program ────
WEEK 5:  T-400, T-832, T-901 (admin layout + event mgmt + REFERRALS)
WEEK 6:  T-405, T-406, T-903 (observations + attendance + ACTIVITY LIBRARY)
WEEK 7:  T-300, T-301, T-302, T-303 (portal + passport)
WEEK 8:  T-821, T-822, T-840, T-905 (tier gates + subs + pricing + PROGRESS)
         ──── PAID FEATURES LAUNCH ────
WEEK 9:  T-833, T-904, T-906 (post-event + dev path + CERTIFICATES)
WEEK 10: T-600..T-603, T-500..T-504 (full public site + Python API)
WEEK 11: T-700, T-701, T-907 (testing + COMMUNITY FORUM)
WEEK 12: T-1000, T-1010, T-1015 (MILESTONES DB + EDUCATION DB + SEED)
WEEK 13: T-1001, T-1002, T-1011, T-1013 (CHILD TIMELINE + DOMAIN DETAIL + COURSES + RESOURCES)
WEEK 14: T-1003, T-1004, T-1005, T-1012, T-1014 (MILESTONE ENTRY + PARENT OBS + EVENTS + ADMIN EDU)
WEEK 15: T-702, T-703 (production deploy)
```
