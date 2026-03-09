# Production Deployment Runbook

**Platform:** Sarena Sfera
**Date:** 2026-03-09
**Owner:** Operations Team

This runbook contains step-by-step procedures for deploying, rolling back, backing up, and monitoring the Sarena Sfera platform in production.

---

## Table of Contents

1. [Pre-Deployment Checklist](#pre-deployment-checklist)
2. [Deployment Procedures](#deployment-procedures)
3. [Rollback Procedures](#rollback-procedures)
4. [Backup & Restore](#backup--restore)
5. [Monitoring & Alerts](#monitoring--alerts)
6. [Incident Response](#incident-response)
7. [Routine Maintenance](#routine-maintenance)

---

## Pre-Deployment Checklist

Before deploying to production, verify ALL items:

### Code Readiness
- [ ] All tests pass locally (`npm run test`, `pytest`)
- [ ] Type checking passes (`npx nuxt typecheck`)
- [ ] Linting passes (`npm run lint`)
- [ ] No `console.log` or debug statements in production code
- [ ] Git branch is up-to-date with `main`
- [ ] All changes are committed and pushed

### Database Readiness
- [ ] All migration files are sequentially numbered (001-021)
- [ ] Migrations have been tested in staging environment
- [ ] RLS policies are verified (see `DATABASE-RLS-VERIFICATION.md`)
- [ ] Backup of current production database is available
- [ ] Database migrations are idempotent (can run multiple times safely)

### Environment Configuration
- [ ] `.env` files are configured for production
- [ ] All API keys are valid and active
- [ ] CORS origins include production domain
- [ ] Email from address is verified with Resend
- [ ] Supabase service role key is secure and not exposed

### Infrastructure Readiness
- [ ] DigitalOcean droplets/apps are provisioned
- [ ] DNS records are configured
- [ ] SSL certificates are valid
- [ ] CDN is configured (if using)
- [ ] Monitoring is set up (health checks, logs)

### Stakeholder Communication
- [ ] Deploy window communicated to team
- [ ] Rollback plan reviewed and understood
- [ ] On-call engineer identified
- [ ] Users notified if downtime expected (maintenance page ready)

---

## Deployment Procedures

### 1. Frontend Deployment (Nuxt 3)

#### Option A: Manual Deploy to DigitalOcean

```bash
# 1. Build frontend locally
cd frontend
npm run build

# 2. Upload to server
rsync -avz --delete .output/ user@your-server:/var/www/sarenasfera/

# 3. Restart PM2 process
ssh user@your-server "pm2 restart sarenasfera-frontend"

# 4. Verify deployment
curl https://sarenasfera.com/health
```

#### Option B: DigitalOcean App Platform (Recommended)

```bash
# 1. Commit and push to main
git push origin main

# 2. Trigger deploy via doctl CLI
doctl apps create-deployment <app-id>

# 3. Monitor deployment
doctl apps list-deployments <app-id>

# 4. Wait for "active" status
doctl apps get-deployment <app-id> <deployment-id>
```

**Expected Deploy Time:** 5-8 minutes

#### Post-Deploy Verification

```bash
# Test critical paths
curl https://sarenasfera.com
curl https://sarenasfera.com/events
curl https://sarenasfera.com/pricing

# Verify auth flow
# (Manual test: register new account, login, logout)

# Check browser console for errors
# Open https://sarenasfera.com and check DevTools Console
```

---

### 2. API Deployment (FastAPI)

#### Build and Deploy Docker Container

```bash
# 1. Build Docker image
cd api
docker build -t registry.digitalocean.com/sarenasfera/api:$(git rev-parse --short HEAD) .
docker tag registry.digitalocean.com/sarenasfera/api:$(git rev-parse --short HEAD) \
           registry.digitalocean.com/sarenasfera/api:latest

# 2. Push to registry
docker push registry.digitalocean.com/sarenasfera/api:$(git rev-parse --short HEAD)
docker push registry.digitalocean.com/sarenasfera/api:latest

# 3. Deploy to server
doctl apps update <api-app-id> --spec .do/api.yaml

# 4. Verify health
curl https://api.sarenasfera.com/health
```

**Expected Deploy Time:** 3-5 minutes

#### Post-Deploy Verification

```bash
# Test health endpoint
curl https://api.sarenasfera.com/health

# Expected response:
{
  "status": "healthy",
  "app_name": "Sarena Sfera API",
  "version": "1.0.0",
  "environment": "production",
  "dependencies": {
    "resend": {"status": "healthy"},
    "supabase": {"status": "healthy"}
  }
}

# Test email endpoint (send test email)
curl -X POST https://api.sarenasfera.com/email/registration \
  -H "Content-Type: application/json" \
  -d '{
    "to": "test@sarenasfera.com",
    "parent_name": "Test User",
    "child_name": "Test Child",
    "login_url": "https://sarenasfera.com/auth/login"
  }'
```

---

### 3. Database Migration

**⚠️ CRITICAL: Always backup before running migrations in production.**

```bash
# 1. Backup current database
# (See "Backup & Restore" section below)

# 2. Connect to Supabase via psql
psql postgresql://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres

# 3. Check current migration status
SELECT * FROM supabase_migrations.schema_migrations ORDER BY version;

# 4. Run pending migrations
\i supabase/migrations/020_developmental_milestones.sql
\i supabase/migrations/021_education.sql

# 5. Verify migration success
SELECT * FROM supabase_migrations.schema_migrations ORDER BY version DESC LIMIT 5;

# 6. Test critical queries
SELECT COUNT(*) FROM developmental_milestones;
SELECT COUNT(*) FROM children WHERE is_active = true;
```

**Expected Migration Time:** 1-3 minutes per file

#### Automated Migration (Supabase CLI)

```bash
# 1. Install Supabase CLI
npm install -g supabase

# 2. Link to production project
supabase link --project-ref [YOUR-PROJECT-REF]

# 3. Push migrations
supabase db push

# 4. Verify
supabase db diff
```

---

## Rollback Procedures

### When to Rollback

Rollback immediately if:

- 5xx error rate > 5% after deploy
- Critical feature broken (auth, registration, payments)
- Database corruption detected
- User reports of data loss

### Frontend Rollback

```bash
# Option A: Revert to previous commit
git revert HEAD
git push origin main
# (Trigger redeploy via DO App Platform)

# Option B: Manual rollback to previous version
doctl apps list-deployments <app-id>  # Find previous deployment ID
doctl apps rollback <app-id> <previous-deployment-id>

# Verify rollback
curl https://sarenasfera.com
```

**Expected Rollback Time:** 5-8 minutes

### API Rollback

```bash
# Rollback to previous Docker image
doctl apps update <api-app-id> --image registry.digitalocean.com/sarenasfera/api:<previous-git-sha>

# Verify
curl https://api.sarenasfera.com/health
```

**Expected Rollback Time:** 3-5 minutes

### Database Rollback

**⚠️ CRITICAL: Database rollbacks are complex. Prefer forward fixes.**

If you must rollback a migration:

```bash
# 1. Connect to database
psql postgresql://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres

# 2. Create rollback script (example for migration 020)
BEGIN;

-- Drop tables created in migration 020
DROP TABLE IF EXISTS child_milestones CASCADE;
DROP TABLE IF EXISTS developmental_milestones CASCADE;

-- Remove migration record
DELETE FROM supabase_migrations.schema_migrations WHERE version = '020';

COMMIT;

# 3. Restore from backup if data loss occurred
# (See "Restore from Backup" section)
```

---

## Backup & Restore

### Automated Daily Backups

Supabase provides automated daily backups. Verify they are enabled:

```bash
# Check backup settings in Supabase Dashboard:
# https://app.supabase.com/project/[PROJECT-REF]/settings/database

# Retention: 7 days (free tier), 30 days (pro tier)
```

### Manual Backup (Before Migration)

```bash
# Full database dump
pg_dump postgresql://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres \
  > backup_$(date +%Y%m%d_%H%M%S).sql

# Compressed backup
pg_dump postgresql://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres \
  | gzip > backup_$(date +%Y%m%d_%H%M%S).sql.gz

# Upload to DigitalOcean Spaces (S3-compatible)
s3cmd put backup_*.sql.gz s3://sarenasfera-backups/database/
```

### Restore from Backup

**⚠️ Only run in emergencies. Data created after backup will be lost.**

```bash
# 1. Stop all API services to prevent writes
doctl apps update <api-app-id> --spec .do/api-maintenance.yaml

# 2. Restore database
psql postgresql://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres \
  < backup_20260309_100000.sql

# 3. Verify restoration
psql postgresql://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres \
  -c "SELECT COUNT(*) FROM children;"

# 4. Restart API services
doctl apps update <api-app-id> --spec .do/api.yaml
```

**Expected Restore Time:** 10-30 minutes (depends on database size)

---

## Monitoring & Alerts

### Health Checks

#### Frontend Health

```bash
# Monitor every 1 minute
watch -n 60 'curl -s https://sarenasfera.com | head -n 1'

# Expected: HTTP 200 OK
```

#### API Health

```bash
# Monitor API health
watch -n 60 'curl -s https://api.sarenasfera.com/health | jq .status'

# Expected: "healthy"
```

#### Database Health

```bash
# Check active connections
psql -c "SELECT count(*) FROM pg_stat_activity;"

# Check database size
psql -c "SELECT pg_database_size('postgres');"
```

### Key Metrics to Monitor

| Metric | Threshold | Alert |
|--------|-----------|-------|
| Frontend response time | > 3s | Warning |
| API response time | > 1s | Warning |
| 5xx error rate | > 1% | Critical |
| 4xx error rate | > 10% | Warning |
| Database CPU | > 80% | Critical |
| Database connections | > 90% of max | Warning |
| Disk usage | > 85% | Warning |
| Email send failures | > 5% | Critical |

### Setting Up Alerts

#### DigitalOcean Monitoring

```bash
# Create alert policy via doctl
doctl monitoring alert create \
  --type v1/insights/droplet/cpu \
  --compare GreaterThan \
  --value 80 \
  --window 5m \
  --entities <droplet-id>
```

#### Uptime Monitoring (External)

Use services like:
- **UptimeRobot** (free): https://uptimerobot.com
- **Pingdom**
- **Datadog**

Monitor these URLs:
- `https://sarenasfera.com`
- `https://api.sarenasfera.com/health`

### Log Aggregation

```bash
# View recent logs (Frontend)
doctl apps logs <app-id> --type run --tail

# View recent logs (API)
doctl apps logs <api-app-id> --type run --tail

# Filter for errors
doctl apps logs <api-app-id> --type run --tail | grep ERROR
```

---

## Incident Response

### Severity Levels

| Level | Description | Response Time |
|-------|-------------|---------------|
| **P0 - Critical** | Complete outage, data loss | Immediate |
| **P1 - High** | Major feature broken | 30 minutes |
| **P2 - Medium** | Minor feature degraded | 2 hours |
| **P3 - Low** | Cosmetic issue | Next business day |

### Incident Response Process

#### 1. Identify Incident

```bash
# Check system status
curl https://sarenasfera.com
curl https://api.sarenasfera.com/health

# Check error logs
doctl apps logs <app-id> --type run --tail | grep ERROR

# Check database
psql -c "SELECT version();"
```

#### 2. Assess Impact

- How many users affected?
- What functionality is broken?
- Is data at risk?

#### 3. Communicate

```bash
# Notify team
# Post in #incidents Slack channel

# Update status page (if available)
# https://status.sarenasfera.com

# Notify users (if major outage)
# Via email or in-app banner
```

#### 4. Mitigate

- **Rollback** if recent deploy caused issue
- **Scale up** if performance issue
- **Disable feature** if specific feature causing problems
- **Restore backup** if data corruption

#### 5. Resolve

- Fix root cause
- Deploy fix
- Verify resolution

#### 6. Post-Mortem

Write incident report including:
- Timeline of events
- Root cause analysis
- Preventive measures
- Action items

---

## Routine Maintenance

### Weekly Tasks

- [ ] Review error logs for patterns
- [ ] Check disk usage and cleanup old logs
- [ ] Verify backups are running successfully
- [ ] Review monitoring alerts and tune thresholds
- [ ] Update dependencies (security patches)

### Monthly Tasks

- [ ] Review database performance and optimize slow queries
- [ ] Rotate API keys and secrets
- [ ] Review and cleanup unused database records (soft deletes)
- [ ] Test backup restoration process
- [ ] Review user access and remove inactive accounts

### Quarterly Tasks

- [ ] Full security audit
- [ ] Performance testing and optimization
- [ ] Review and update runbooks
- [ ] Disaster recovery drill
- [ ] Review and optimize infrastructure costs

---

## Emergency Contacts

| Role | Name | Contact |
|------|------|---------|
| **Platform Owner** | [Name] | [Email/Phone] |
| **DevOps Lead** | [Name] | [Email/Phone] |
| **Database Admin** | [Name] | [Email/Phone] |
| **On-Call Engineer** | [Rotation] | [Pager/Slack] |

### External Support

| Service | Support Contact |
|---------|----------------|
| **DigitalOcean** | support@digitalocean.com |
| **Supabase** | support@supabase.com |
| **Resend** | support@resend.com |
| **Domain Registrar** | [Support link] |

---

## Appendix

### Useful Commands

```bash
# View all running apps
doctl apps list

# Get app details
doctl apps get <app-id>

# View deployments
doctl apps list-deployments <app-id>

# View app logs
doctl apps logs <app-id> --type run --tail

# Scale app
doctl apps update <app-id> --spec .do/app-scaled.yaml

# SSH into droplet
doctl compute ssh <droplet-name>

# Database connection
psql postgresql://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres
```

### Configuration Files

| File | Purpose |
|------|---------|
| `.do/app.yaml` | Frontend app config for DigitalOcean |
| `.do/api.yaml` | API app config for DigitalOcean |
| `supabase/config.toml` | Supabase configuration |
| `api/.env` | API environment variables |
| `frontend/.env` | Frontend environment variables |

---

**Last Updated:** 2026-03-09
**Next Review:** 2026-04-09
**Document Owner:** Operations Team
