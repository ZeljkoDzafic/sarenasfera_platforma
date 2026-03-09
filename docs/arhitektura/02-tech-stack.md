# 02 - Technology Stack

## The Stack (3 things only)

```
Frontend:  Vite + TypeScript + Tailwind CSS + Alpine.js
           Builds to static HTML/CSS/JS -> deploy ANYWHERE
Backend:   Self-hosted Supabase (DigitalOcean)
Custom:    Python FastAPI (PDF, Email, Analytics)
```

**Total technologies: 3.** No PHP. No server-side rendering. No complexity.

## Why This Stack?

### Frontend: Vite + TypeScript + Tailwind + Alpine.js

| Choice | Why |
|--------|-----|
| **Vite** | Lightning fast build tool. `npm run build` -> static files in 2 seconds |
| **TypeScript** | Type safety, better autocomplete, fewer bugs |
| **Tailwind CSS** | Modern responsive UI, utility-first, no custom CSS needed |
| **Alpine.js** | Lightweight reactivity (15KB). Like Vue but simpler. No virtual DOM overhead |

**Why NOT React/Next.js?**
- React adds complexity (JSX, state management, build config)
- Next.js requires a Node.js server (or special deployment)
- Our pages are mostly data display, not complex UIs
- Alpine.js handles all our interactivity needs with 10x less code
- Static HTML files deploy anywhere - React apps need specific hosting

**Why NOT PHP?**
- Adding PHP means maintaining two languages on frontend
- PHP needs a PHP server - limits deployment options
- Supabase JS client handles all data operations from the browser
- No benefit over static TS/JS when Supabase IS the backend

### How it works:

```
1. Vite builds TypeScript -> JavaScript
2. HTML pages use Tailwind for styling
3. Alpine.js handles interactivity (forms, modals, dynamic lists)
4. Supabase JS client (browser) handles:
   - Authentication (signup, login, sessions)
   - Data fetching (CRUD via PostgREST)
   - File uploads (Storage API)
   - Real-time subscriptions (notifications)
5. Result: static HTML/CSS/JS files that work on ANY web server
```

### Backend: Self-hosted Supabase on DigitalOcean

| What you get | How |
|-------------|-----|
| PostgreSQL database | Included |
| REST API (auto-generated) | PostgREST |
| Authentication | GoTrue |
| File storage | Storage API |
| Real-time | WebSocket server |
| Admin UI | Supabase Studio |
| Row Level Security | Built into PostgreSQL |

**Self-hosting vs Cloud:**

| Aspect | Supabase Cloud (Free) | Self-hosted (DigitalOcean) |
|--------|----------------------|--------------------------|
| Cost | Free but limited | ~$12/mo (predictable) |
| Database | 500MB limit | 50GB+ (droplet disk) |
| Storage | 1GB limit | 50GB+ |
| Control | Limited | Full |
| Backups | Limited | You control |
| Custom config | No | Yes |

**Recommendation:** Start with Supabase Cloud free tier for development.
Move to self-hosted on DigitalOcean for production.

### Custom Backend: Python FastAPI

Runs on the same DigitalOcean droplet. Handles things Supabase can't:

| Task | Why Python |
|------|-----------|
| PDF report generation | WeasyPrint / ReportLab libraries |
| Email campaigns | Resend / SMTP integration |
| Quarterly report logic | Complex data aggregation |
| Cron jobs | Scheduled reminders, alerts |
| Future AI features | Claude/OpenAI APIs are Python-native |

## Cost Breakdown

| Service | Monthly Cost | Notes |
|---------|-------------|-------|
| DigitalOcean droplet | $12-24 | Supabase + Python API |
| Frontend hosting | $0 | HostGator (existing) or free tier anywhere |
| Resend (email) | $0 | 3,000 emails/mo free |
| Domain | Already owned | sarenasfera.com |
| **Total** | **$12-24/mo** | |

## Development Tools

| Tool | Purpose |
|------|---------|
| VS Code + Claude Code | Development |
| Node.js + npm | Build frontend |
| Vite | Dev server + build |
| Supabase CLI | Local dev, migrations |
| Docker | Self-host Supabase |
| Git + GitHub | Version control |

## npm Dependencies (minimal)

```json
{
  "devDependencies": {
    "vite": "^6.x",
    "typescript": "^5.x",
    "tailwindcss": "^4.x",
    "@tailwindcss/vite": "^4.x"
  },
  "dependencies": {
    "@supabase/supabase-js": "^2.x",
    "alpinejs": "^3.x",
    "chart.js": "^4.x"
  }
}
```

**6 dependencies total.** Clean and minimal.
