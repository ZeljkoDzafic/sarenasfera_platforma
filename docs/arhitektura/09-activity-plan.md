# 09 - Activity Plan (Detailed)

## Phase 1: MVP (Weeks 1-12)

**Goal:** Working platform with registration, child passport, and basic admin panel.
**Budget:** $12/mo (DigitalOcean)
**Stack:** Vite + TypeScript + Tailwind + Alpine.js | Supabase | Python FastAPI

---

### Week 1-2: Foundation & Infrastructure

| Day | Task | Deliverable |
|-----|------|-------------|
| 1 | Set up DigitalOcean droplet | Running Ubuntu server |
| 1-2 | Install & configure self-hosted Supabase | Supabase accessible at supabase.sarenasfera.com |
| 2 | Configure DNS (supabase + api subdomains) | SSL certificates working |
| 3 | Create database schema (all MVP tables) | Tables created via Supabase Studio |
| 3-4 | Set up RLS policies | All tables secured |
| 4 | Init Vite + TypeScript + Tailwind project | `npm run dev` works |
| 4-5 | Set up Supabase JS client + Alpine.js | Auth + data fetching working |
| 5 | Create shared layout (nav, footer, auth guard) | Base HTML templates ready |

**Milestone:** Infrastructure ready, can create users and query data.

---

### Week 3-4: Authentication & Registration

| Day | Task | Deliverable |
|-----|------|-------------|
| 1-2 | Build registration page (registracija.html) | Parents can sign up |
| 2-3 | Build login page (prijava.html) | Parents can log in |
| 3 | Email verification flow | Verified accounts only |
| 4 | Onboarding wizard - add child form | Parents add child info |
| 5 | Profile page (profil.html) | Users can edit their profile |
| 5 | Auth middleware for protected routes | Unauthorized users redirected |

**Milestone:** Parents can register, verify email, add child, log in/out.

---

### Week 5-6: Parent Portal - Child Passport

| Day | Task | Deliverable |
|-----|------|-------------|
| 1-2 | Parent dashboard (dashboard.html) | Overview with child cards |
| 2-3 | Children list page (djeca.html) | View/add/edit children |
| 3-5 | Child passport page (dijete.html) | Full passport view |
| 4 | Radar chart for 6 domains (Chart.js) | Visual development overview |
| 5 | Observation timeline view | Chronological staff notes |
| 5 | Attendance calendar view | Workshop attendance visualization |

**Milestone:** Parents can see their child's development data visually.

---

### Week 7-8: Admin Panel - Core

| Day | Task | Deliverable |
|-----|------|-------------|
| 1 | Admin dashboard (admin/dashboard.html) | Overview stats |
| 1-2 | Children management (admin/djeca.html) | View all children, search, filter |
| 2-3 | Group management (admin/grupe.html) | Create/edit groups, assign children |
| 3-4 | Workshop planning (admin/radionice.html) | Create workshops, assign to groups |
| 4-5 | Attendance tracking (admin/prisustvo.html) | Mark attendance per workshop |

**Milestone:** Staff can manage children, groups, and workshops.

---

### Week 9-10: Admin Panel - Observations

| Day | Task | Deliverable |
|-----|------|-------------|
| 1-3 | Quick observation entry (admin/opservacije.html) | Mobile-optimized form |
| 2-3 | Observation templates/snippets | Quick-select common observations |
| 3-4 | Photo upload for observations | Upload child work photos |
| 4-5 | Assessment entry (domain scores) | Score children per domain per quarter |
| 5 | Child detail view for admin | Full history of a child |

**Milestone:** Staff can quickly enter observations from their phone.

---

### Week 11: Public Site

| Day | Task | Deliverable |
|-----|------|-------------|
| 1-2 | Landing page (index.html) | Attractive landing with CTA |
| 2-3 | Program page (program.html) | 12 months / 96 workshops overview |
| 3 | About page (about.html) | Team, mission, methodology |
| 4 | Contact page (kontakt.html) | Contact form (saves to lead_contacts) |
| 5 | Free resources page (resursi.html) | Lead magnet downloads |

**Milestone:** Public site ready for visitors and lead collection.

---

### Week 12: Testing, Polish & Launch

| Day | Task | Deliverable |
|-----|------|-------------|
| 1-2 | End-to-end testing (all user flows) | Bug list |
| 2-3 | Fix bugs, responsive design fixes | Clean mobile experience |
| 3-4 | Performance testing, loading optimization | Fast page loads |
| 4 | Seed data (sample workshops, demo content) | Platform looks alive |
| 5 | **MVP LAUNCH** | Live platform |

---

## Phase 2: Full Platform (Months 4-9)

| Feature | Weeks | Description |
|---------|-------|-------------|
| Blog system | 2 | Blog listing + single post pages, admin editor |
| Email integration | 2 | Python API for transactional + marketing emails |
| Quarterly PDF reports | 2 | Auto-generated PDF reports (Python + WeasyPrint) |
| Home activities feedback | 1 | Parents mark activities as done, add comments |
| Workshop materials | 1 | Upload and display materials per workshop |
| Parent messaging | 2 | Staff sends messages to parents (per group or individual) |
| Basic analytics | 2 | Admin dashboard with charts (attendance, retention) |
| Subscription management | 2 | Plan selection, payment tracking |

## Phase 3: Scale (Months 10-18)

| Feature | Weeks | Description |
|---------|-------|-------------|
| Parent community/forum | 4 | Discussion boards by age group |
| Video library | 2 | Home activity video tutorials |
| Push notifications | 2 | Browser push for reminders |
| Multi-language (EN) | 2 | English translation |
| AI activity suggestions | 3 | Claude API for personalized recommendations |
| Mobile app (PWA) | 4 | Progressive Web App for app-like experience |
| Multi-location support | 3 | Franchise model, multiple centers |

## Priority Matrix

```
                    HIGH IMPACT
                        |
    Quarterly Reports   |   Child Passport ****
    Email System        |   Observation Entry ****
    Analytics           |   Registration ****
                        |   Parent Dashboard ****
  ──────────────────────┼──────────────────────
                        |
    Forum/Community     |   Blog
    Multi-language      |   Home Activities
    AI Suggestions      |   Lead Magnets
                        |
                    LOW IMPACT

        HARD <──────────────────────> EASY
```

**Strategy:** Start bottom-right (easy + high impact), move left.

## Development Workflow

```
1. Pick task from weekly plan
2. Create feature branch: git checkout -b feature/observation-entry
3. Develop locally: npm run dev (Vite) + Supabase local/cloud
4. Test on mobile (responsive design)
5. Commit + push to GitHub
6. Build: npm run build -> deploy dist/ to server
7. Quick smoke test on production
8. Move to next task
```
