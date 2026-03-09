# 13 - Architecture Comparison: Supabase vs Laravel

## Side-by-Side

| Aspect | Supabase | Laravel |
|--------|----------|---------|
| **Frontend** | Nuxt 3 (identical) | Nuxt 3 (identical) |
| **Backend language** | SQL + TypeScript (+ Python) | PHP |
| **API** | Auto-generated (PostgREST) | Hand-written controllers |
| **Auth** | GoTrue (built-in) | Sanctum (built-in) |
| **Authorization** | RLS policies (SQL) | Policies & Gates (PHP) |
| **ORM** | Supabase client (JS) | Eloquent (PHP) |
| **Realtime** | Built-in (WebSocket) | Laravel Reverb (extra) |
| **File storage** | Storage API (built-in) | Laravel Storage (built-in) |
| **Background jobs** | Python FastAPI | Laravel Queues |
| **PDF generation** | Python (WeasyPrint) | PHP (DomPDF) |
| **Email** | Python (Resend) | Laravel Mail |
| **Database** | PostgreSQL (Supabase) | PostgreSQL |
| **Cache** | Not needed (client-side) | Redis |
| **Testing** | Vitest + Playwright | PHPUnit/Pest + Playwright |

## Development Speed

| Task | Supabase | Laravel |
|------|----------|---------|
| Auth (login/register/forgot) | 1 day | 2-3 days |
| CRUD for 1 entity | 2 hours | 4-6 hours |
| All 61 tables API | 1 day (auto) | 2-3 weeks |
| RLS / Authorization | 3-4 days | 2-3 days |
| File uploads | 2 hours | 4 hours |
| Realtime notifications | 2 hours | 1 day |
| PDF reports | 1 day (Python) | 1 day |
| Email sending | 0.5 day (Python) | 0.5 day |
| **Estimated MVP** | **4-6 weeks** | **8-12 weeks** |

## Code Volume

| Component | Supabase | Laravel |
|-----------|----------|---------|
| Frontend | ~8,000 lines | ~8,000 lines |
| Backend | ~500 lines SQL + ~800 lines Python | ~5,000 lines PHP |
| Migrations | ~2,000 lines SQL | ~3,000 lines PHP |
| Tests | ~1,000 lines | ~2,000 lines |
| **Total backend** | **~3,300 lines** | **~10,000 lines** |

## Cost Comparison

| | Supabase (self-hosted) | Laravel |
|---|---|---|
| Server | $12-24/mo (DO droplet) | $12-24/mo (DO droplet) |
| Frontend hosting | $0 (Vercel/Netlify) | $0 (Vercel/Netlify) |
| Email | $0 (Resend free tier) | $0 (Resend free tier) |
| **Total** | **$12-24/mo** | **$12-24/mo** |

Cost is identical. Difference is in development time and complexity.

## When to Choose Supabase

- Solo developer or small team
- Need MVP fast (weeks not months)
- Most features are CRUD-heavy
- Want built-in realtime without extra setup
- Comfortable with SQL-based authorization
- Don't mind Python for PDF/email
- Project scope is well-defined

## When to Choose Laravel

- Team will grow (easier to onboard PHP devs)
- Complex business logic beyond CRUD
- Need heavy background processing
- Want single-language backend (no Python)
- Strong testing requirements
- Plan to build admin panel with complex workflows
- Already know PHP/Laravel well

## Recommendation for Sarena Sfera

**Start with Supabase** because:

1. **Solo developer** — Supabase saves 50%+ backend code
2. **CRUD-heavy** — 80% of features are read/write operations
3. **RLS is perfect** — child data privacy is the #1 security concern
4. **Built-in realtime** — parent notifications, attendance updates
5. **Faster MVP** — 4-6 weeks vs 8-12 weeks
6. **Python already planned** — for PDF/email (small codebase)

**Consider migrating to Laravel if:**
- Business logic grows complex
- Need to hire PHP developers
- Supabase RLS becomes hard to maintain
- Need advanced queue processing

## Migration Path (Supabase → Laravel)

If needed later, migration is straightforward:
1. Database stays PostgreSQL (identical schema)
2. Frontend composables: change `supabase.from()` to `$fetch('/api/')`
3. Write Laravel controllers for each Supabase table operation
4. Move Python services into Laravel Jobs/Services
5. Replace GoTrue with Sanctum
6. Replace RLS with Laravel Policies

Estimated migration effort: **2-3 weeks** (with existing schema + frontend).

The frontend (Nuxt 3) stays 95% the same — only the data-fetching layer changes.
