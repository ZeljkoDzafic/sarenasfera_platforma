# 11 - Supabase Architecture (Primary)

This is the primary architecture document for active implementation.

Read together with:

- `docs/PROJECT-STATUS.md`
- `docs/PRODUCTION-READINESS.md`

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                    CLIENT (Browser)                      │
│                                                          │
│  Nuxt 3 (Vue 3 + TypeScript + Tailwind CSS)             │
│  ├── SSR for public pages (SEO)                         │
│  ├── SPA mode for portal/admin (fast navigation)        │
│  └── Auto-imports, file-based routing                    │
└──────────┬──────────────────────┬───────────────────────┘
           │                      │
           ▼                      ▼
┌──────────────────────┐  ┌──────────────────────┐
│  SUPABASE (BaaS)     │  │  PYTHON API          │
│                      │  │  (FastAPI)            │
│  ├── PostgreSQL 15   │  │                      │
│  ├── PostgREST       │  │  ├── PDF reports     │
│  ├── GoTrue (Auth)   │  │  ├── Email service   │
│  ├── Storage API     │  │  ├── Analytics       │
│  ├── Realtime        │  │  └── Cron jobs       │
│  └── Edge Functions  │  │                      │
│                      │  │  Connects to Supabase│
│  RLS on ALL tables   │  │  via service_role key│
└──────────────────────┘  └──────────────────────┘
```

## Why Supabase?

| Benefit | Detail |
|---------|--------|
| **80% less backend code** | Auth, CRUD, storage, realtime — all built-in |
| **Row Level Security** | Child data privacy enforced at database level |
| **Auto-generated REST API** | PostgREST creates endpoints from your schema |
| **Real-time subscriptions** | Live updates for notifications, attendance |
| **Built-in auth** | Email/password, magic links, OAuth — zero custom code |
| **Storage API** | File uploads with access policies |
| **Supabase Studio** | Admin UI for database management |
| **Self-hostable** | Full control, no vendor lock-in |

## System Components

### 1. Frontend: Nuxt 3

```
frontend/
├── nuxt.config.ts           # Nuxt configuration
├── app.vue                  # Root app component
├── pages/
│   ├── index.vue            # Landing page (SSR)
│   ├── program.vue          # Program info (SSR)
│   ├── blog/
│   │   ├── index.vue        # Blog listing (SSR)
│   │   └── [slug].vue       # Blog post (SSR)
│   ├── auth/
│   │   ├── login.vue        # Login page
│   │   ├── register.vue     # Registration + onboarding
│   │   └── forgot.vue       # Password reset
│   ├── portal/              # Parent portal (SPA, auth required)
│   │   ├── index.vue        # Dashboard
│   │   ├── children/
│   │   │   ├── index.vue    # My children list
│   │   │   └── [id].vue     # Child detail + passport
│   │   ├── workshops.vue    # Workshop calendar
│   │   ├── activities.vue   # Home activities
│   │   ├── gallery.vue      # Photo gallery
│   │   └── profile.vue      # My profile
│   └── admin/               # Admin panel (SPA, staff/admin only)
│       ├── index.vue        # Admin dashboard
│       ├── children/
│       ├── groups/
│       ├── workshops/
│       ├── observations/
│       ├── attendance/
│       ├── messages/
│       └── users/
├── components/
│   ├── ui/                  # Base UI components
│   │   ├── Button.vue
│   │   ├── Input.vue
│   │   ├── Modal.vue
│   │   ├── Card.vue
│   │   └── DataTable.vue
│   ├── charts/
│   │   ├── RadarChart.vue   # Child passport radar
│   │   └── BarChart.vue     # Attendance stats
│   ├── portal/
│   │   ├── ChildCard.vue
│   │   ├── PassportView.vue
│   │   └── ActivityCard.vue
│   └── admin/
│       ├── ObservationForm.vue
│       ├── AttendanceGrid.vue
│       └── StatsWidget.vue
├── composables/
│   ├── useSupabase.ts       # Supabase client
│   ├── useAuth.ts           # Auth state & methods
│   ├── useChildren.ts       # Children CRUD
│   ├── useObservations.ts   # Observations CRUD
│   └── useWorkshops.ts      # Workshop operations
├── middleware/
│   ├── auth.ts              # Require authentication
│   ├── role.ts              # Role-based access (parent/staff/admin)
│   └── guest.ts             # Redirect if already logged in
├── layouts/
│   ├── default.vue          # Public pages layout
│   ├── portal.vue           # Parent portal layout (sidebar)
│   └── admin.vue            # Admin panel layout (sidebar)
├── server/
│   └── api/                 # Nuxt server routes (optional BFF)
│       └── health.get.ts    # Health check
└── types/
    ├── database.ts          # Generated Supabase types
    └── index.ts             # App-level types
```

## Current Repo Snapshot

The repository already contains a meaningful Nuxt application, but not every item in the ideal structure above is fully implemented.

### Confirmed present

- public pages for `program`, `blog`, `resources`, `contact`, `pricing`, `referrals`, `events`, `quiz`
- portal pages under `pages/portal/`
- admin pages under `pages/admin/`
- composables:
  - `useSupabase`
  - `useAuth`
  - `useFeatures`
  - `useTier`
- route middleware:
  - `auth`
  - `guest`
  - `role`

### Confirmed missing or incomplete

- `pages/auth/*` routes are not yet present in the repo
- FastAPI is still a minimal service skeleton
- some frontend pages still use placeholder/demo content
- deployment automation is not production-complete

## Delivery Principle

Use this document as the target architecture, but validate implementation status against `docs/PROJECT-STATUS.md` before assuming a subsystem already exists.

## Production Priorities

If the goal is fast production readiness, prioritize work in this order:

1. auth flows and role correctness
2. RLS verification and migration reliability
3. public acquisition funnel
4. parent portal core value
5. staff/admin operational workflows
6. monitoring, backups, deployment, rollback

### 2. Supabase Backend

#### Database (PostgreSQL 15)

61 tables organized into domains:
- **Core:** profiles, children, parent_children, locations
- **Groups:** groups, group_staff, child_groups
- **Workshops:** workshops, workshop_templates, sessions
- **Tracking:** observations, assessments, milestones, child_milestones
- **Attendance:** attendance, daily_routines, check_ins
- **Reports:** quarterly_reports, learning_stories, portfolio_items
- **Communication:** messages, notifications, email_campaigns
- **Content:** blog_posts, resources, home_activities
- **Billing:** subscriptions, subscription_plans, payments
- **CRM:** leads, lead_activities, enrollment_pipeline

#### Row Level Security (RLS)

Every table has RLS policies. Examples:

```sql
-- Parents can only see their own children
CREATE POLICY "parents_see_own_children" ON children
  FOR SELECT USING (
    id IN (
      SELECT child_id FROM parent_children
      WHERE parent_id = auth.uid()
    )
  );

-- Staff can see children in their groups
CREATE POLICY "staff_see_group_children" ON children
  FOR SELECT USING (
    id IN (
      SELECT cg.child_id FROM child_groups cg
      JOIN group_staff gs ON gs.group_id = cg.group_id
      WHERE gs.staff_id = auth.uid()
    )
  );

-- Admins see everything
CREATE POLICY "admin_full_access" ON children
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );
```

#### Authentication (GoTrue)

- Email + password registration
- Email verification (mandatory for parents)
- Password reset via email
- JWT tokens with custom claims (role in `app_metadata`)
- Session management (refresh tokens)

#### Storage Buckets

| Bucket | Purpose | Access |
|--------|---------|--------|
| `avatars` | Profile photos | Public read, owner write |
| `observations` | Observation photos | Staff write, parent read (own child) |
| `reports` | PDF quarterly reports | Service role write, parent read |
| `resources` | Educational materials | Public read, admin write |
| `blog` | Blog post images | Public read, admin write |

#### Realtime Subscriptions

```typescript
// Live attendance updates for admin
supabase
  .channel('attendance')
  .on('postgres_changes', {
    event: '*',
    schema: 'public',
    table: 'attendance',
    filter: `session_id=eq.${sessionId}`
  }, (payload) => {
    updateAttendanceGrid(payload.new)
  })
  .subscribe()

// Live notifications for parents
supabase
  .channel('notifications')
  .on('postgres_changes', {
    event: 'INSERT',
    schema: 'public',
    table: 'notifications',
    filter: `user_id=eq.${userId}`
  }, (payload) => {
    showNotification(payload.new)
  })
  .subscribe()
```

### 3. Python FastAPI (Custom Logic)

```
api/
├── app/
│   ├── main.py              # FastAPI app + CORS
│   ├── config.py            # Environment config
│   ├── dependencies.py      # Auth verification, Supabase client
│   ├── routers/
│   │   ├── reports.py       # PDF report generation
│   │   ├── email.py         # Email sending (Resend)
│   │   ├── analytics.py     # Aggregated statistics
│   │   └── cron.py          # Scheduled task triggers
│   ├── services/
│   │   ├── pdf_service.py   # WeasyPrint PDF generation
│   │   ├── email_service.py # Resend integration
│   │   └── analytics_service.py
│   └── templates/
│       ├── report.html      # Quarterly report template
│       └── emails/          # Email templates
├── requirements.txt
├── Dockerfile
└── tests/
```

## Data Flow

### Parent views child passport:
```
Browser → Nuxt (useChildren composable)
       → supabase.from('children').select('*, assessments(*), observations(*)')
       → PostgREST → PostgreSQL (RLS check: is parent of this child?)
       → JSON response → Render radar chart + timeline
```

### Staff enters observation:
```
Browser → Nuxt (ObservationForm.vue)
       → supabase.from('observations').insert({...})
       → PostgREST → PostgreSQL (RLS check: is staff in child's group?)
       → Success → Realtime: notify parent
```

### Quarterly report generation:
```
Cron trigger → Python API /v1/reports/quarterly
            → Supabase (service_role: fetch all data)
            → WeasyPrint → PDF
            → Supabase Storage (upload)
            → Supabase DB (save reference)
            → Email notification to parent
```

## Local Development Stack

```yaml
# docker-compose.yml services:
supabase-db:       PostgreSQL 15 (port 5432)
supabase-auth:     GoTrue (port 9999)
supabase-rest:     PostgREST (port 3000)
supabase-storage:  Storage API (port 5000)
supabase-studio:   Studio UI (port 3001)
supabase-kong:     API Gateway (port 8000)
python-api:        FastAPI (port 8080)
# Frontend runs natively: nuxt dev (port 3000 → remapped to 3002)
```

## Production Deployment

```
DigitalOcean Droplet ($12-24/mo)
├── Nginx (reverse proxy + SSL)
├── Supabase (Docker Compose)
├── Python API (Docker)
└── Frontend: deployed to Vercel/Netlify (free)
    OR served by Nginx on same droplet
```

## Scaling Path

| Users | Infrastructure | Cost |
|-------|---------------|------|
| 0-200 | 1 droplet (2GB) | $12/mo |
| 200-500 | 1 droplet (4GB) | $24/mo |
| 500-2000 | DB on managed Postgres, app on separate droplet | $50/mo |
| 2000+ | Supabase Cloud Pro + dedicated API server | $100+/mo |

## Pros & Cons

### Pros
- Very fast MVP development (weeks, not months)
- Built-in auth, storage, realtime — no custom code
- RLS = security at database level (can't bypass)
- Supabase client works from browser (no API layer needed for CRUD)
- Self-hostable = full control + cost predictable
- Great DX with TypeScript type generation

### Cons
- Complex business logic in RLS policies can be hard to debug
- PostgREST has limitations for complex queries (use DB functions)
- Self-hosting Supabase requires Docker knowledge
- Less ecosystem than Laravel (packages, tutorials)
- Vendor-specific patterns (not standard REST API)
- Team scaling: not everyone knows Supabase
