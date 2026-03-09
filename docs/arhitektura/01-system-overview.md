# 01 - System Overview

## What is Sarena Sfera Digital?

An online platform for tracking children's development through educational workshops.
Three user types: **parents**, **staff (workshop leaders)**, and **administrators**.

## Main Subsystems

### 1. Public Website (No auth required)
- Landing page, program overview, blog, contact
- Free resources (lead magnets - PDF guides, worksheets)
- SEO optimized
- **Tech:** Static HTML/CSS/JS (Vite + TypeScript + Tailwind)
- **Hosted on:** Any static host (DigitalOcean, HostGator, Netlify, etc.)

### 2. User Portal (Authenticated - parents)
- Dashboard with child progress overview
- Child Passport - complete development record
- Workshop materials and home activities
- Private photo gallery
- Parent community/forum (Phase 2)

### 3. Admin Panel (Staff & Admins)
- Child management, groups, attendance
- Quick observation entry (mobile optimized)
- Workshop planning
- Parent communication
- Statistics and analytics

### 4. Background Services (Python)
- Quarterly PDF report generation
- Email sending (automated + campaigns)
- Cron jobs (reminders, statistics)
- Future: AI activity recommendations

## Key Success Metrics

| Metric | Target (MVP) | Target (6 mo) |
|--------|-------------|---------------|
| Registered parents | 50 | 200 |
| Active children | 30 | 150 |
| Observations entered/week | 20 | 100 |
| Time to enter observation | < 2 min | < 1 min |
| Uptime | 99% | 99.5% |

## Constraints & Assumptions

- Budget: 500-1,500 KM for MVP
- Team: 1 developer (you) + AI assistant (Claude)
- Users primarily from Bosnia (BHS language)
- Internet access: mostly mobile
- GDPR-like compliance for child data
- DigitalOcean for backend (Supabase + Python API)
- Frontend deploys anywhere (static files)
- Tech stack: TypeScript/JS + Supabase + Python (no PHP)
