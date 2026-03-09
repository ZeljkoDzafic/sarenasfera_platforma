# Sarena Sfera Digital - Platform Architecture

This folder contains both active architecture documents and historical decision records.

Before using any document here, read:

1. `docs/PROJECT-STATUS.md`
2. `docs/AGENT-HANDBOOK.md`
3. this file

## Documentation Index

| # | Document | Description |
|---|----------|-------------|
| 01 | [System Overview](01-system-overview.md) | High-level goals, subsystems, metrics |
| 02 | [Tech Stack](02-tech-stack.md) | Technology choices + cost breakdown |
| 03 | [Database Schema](03-database-schema.md) | 61 tables, ER diagram, all SQL |
| 04 | [Auth & Roles](04-auth-and-roles.md) | Supabase GoTrue, JWT, RBAC |
| 05 | [API Design](05-api-design.md) | PostgREST + Python FastAPI routes |
| 06 | [Child Passport](06-child-passport.md) | Core feature: 6 domains, scoring |
| 07 | [Frontend Structure](07-frontend-structure.md) | Historical frontend concept, superseded by 11 |
| 08 | [Deployment](08-deployment.md) | Deployment direction, partially outdated |
| 09 | [Activity Plan](09-activity-plan.md) | 12-week MVP timeline |
| 10 | [Competitive Analysis](10-competitive-analysis.md) | 9 competitors analyzed |
| **11** | **[Supabase Architecture](11-supabase-architecture.md)** | **PRIMARY — Nuxt 3 + Supabase** |
| **12** | **[Laravel Architecture](12-laravel-architecture.md)** | **ALTERNATIVE — post-launch assessment** |
| **13** | **[Architecture Comparison](13-architecture-comparison.md)** | **Side-by-side comparison** |
| **14** | **[Feature Flags & Tiers](14-feature-flags-and-tiers.md)** | **Staged rollout, 3 subscription tiers** |
| **15** | **[Competitive Learnings](15-competitive-learnings-aizdravo.md)** | **INTERNAL — competitive analysis notes** |
| **16** | **[Growth & Engagement Strategy](16-growth-engagement-strategy.md)** | **Quiz, referrals, pioneers, gamification** |
| **17** | **[Child Tracking & Education](17-child-tracking-and-education.md)** | **Enhanced passport, milestones, mini-LMS** |
| **18** | **[UI & Design Guidelines](18-ui-design-guidelines.md)** | **Brand colors, logo, fonts, component style** |

## Task Tracking

See [TASKS.md](../TASKS.md) for the full task breakdown (70+ tasks, 9 phases).

## Current Stack (Active)

```
Frontend:  Nuxt 3 (Vue 3 + TypeScript + Tailwind CSS)
Backend:   Self-hosted Supabase (PostgreSQL, Auth, Storage, Realtime)
Custom:    Python FastAPI (PDF, Email, Analytics, Cron)
DevOps:    Docker Compose (local), GitHub Actions (CI/CD)
```

## Architecture Decision

**Supabase chosen as primary architecture** for MVP. Laravel architecture
documented as alternative for post-launch assessment. See doc 13 for comparison.

## Canonical Documents

Use these as the active implementation guide:

- `docs/PROJECT-STATUS.md`
- `docs/AGENT-HANDBOOK.md`
- `docs/PRODUCTION-READINESS.md`
- [11 - Supabase Architecture](11-supabase-architecture.md)
- [14 - Feature Flags & Tiers](14-feature-flags-and-tiers.md)
- [17 - Child Tracking & Education](17-child-tracking-and-education.md)
- [18 - UI & Design Guidelines](18-ui-design-guidelines.md)

## Historical / Reference Documents

These are useful for context, comparison, or decision history, but should not be treated as the primary source of truth:

- [07 - Frontend Structure](07-frontend-structure.md)
- [08 - Deployment](08-deployment.md)
- [12 - Laravel Architecture](12-laravel-architecture.md)
- [13 - Architecture Comparison](13-architecture-comparison.md)
- [15 - Competitive Learnings](15-competitive-learnings-aizdravo.md)

## Important Status Note

`docs/TASKS.md` is the delivery backlog. Some task statuses reflect planning intent from earlier iterations and must be verified against the repo before being treated as complete.

## Business Model

- **3 tiers:** Free (0 KM) → Paid (15 KM/mj) → Premium (30 KM/mj)
- **Acquisition:** Development quiz + Workshop registration = Free account
- **"Roditelji Pioniri":** First 50 families get lifetime price lock
- **Referral system:** Parents earn free months by inviting friends
- **Staged rollout:** Features released gradually via admin feature flags
