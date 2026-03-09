# Production Readiness

This checklist is optimized for moving the platform to production quickly without skipping the failure points that usually hurt real launches.

## Release Gate

Do not launch broadly until all items in these sections are complete:

- Auth and access control
- Data integrity
- Deployment and rollback
- Monitoring and backups
- Legal and privacy basics

## 1. Auth And Access Control

- Parent registration works end-to-end
- Staff/admin login works end-to-end
- Password reset works
- Email verification policy is defined and enforced
- Session refresh and logout flows are tested
- Route middleware behavior is verified for:
  - anonymous
  - parent
  - staff
  - admin
  - expert
- RLS policies are validated with real role-specific test users

## 2. Data Integrity

- Migrations apply cleanly on a fresh local database
- Seed data loads successfully
- Foreign keys and unique constraints cover critical relations
- Key tables have indexes for expected reads
- Soft-delete behavior is explicit where needed
- Audit fields exist on sensitive workflows

## 3. Frontend Quality

- Public pages render correctly in SSR/prerendered mode
- Portal/admin routes handle loading, empty, and error states
- No broken links to non-existent routes
- Placeholder data is either removed or clearly marked temporary
- Mobile experience works for parent and staff workflows

## 4. Backend Services

- FastAPI has at least one real production responsibility implemented
- Error responses are structured and logged
- Timeouts and retries are defined for external providers
- Service-role Supabase access is isolated to server-side code

## 5. Deployment And Operations

- Environment variables are documented and versioned via templates
- CI blocks broken frontend builds
- Deployment process is executable, not placeholder text
- Rollback path is documented
- Database backup policy exists
- Restore drill is documented

## 6. Monitoring

- Frontend error tracking
- API error tracking
- Uptime checks for public site, Supabase gateway, FastAPI
- Basic product analytics for funnel and retention
- Alert destination defined for production incidents

## 7. Security And Privacy

- Secret rotation process exists
- Public vs private storage buckets are reviewed
- Rate limiting exists at gateway or app boundary
- Data export and delete process is defined
- Privacy policy and terms are ready before public launch

## 8. Commercial Readiness

- Tiers are enforced consistently in UI and backend
- Billing edge cases are defined:
  - upgrade
  - downgrade
  - grace period
  - failed payment
- Workshop registration funnel is measurable
- Referral attribution is testable

## Recommended Fastest Path To Launch

1. Complete auth pages and role verification.
2. Verify migrations and RLS on a clean local stack.
3. Ship public funnel:
   landing, events, quiz, registration.
4. Ship paid parent value:
   children, passport, workshops, activities.
5. Ship core staff ops:
   children, observations, sessions, groups.
6. Add one production-grade FastAPI service.
7. Add monitoring, backups, and rollback process.
8. Launch with feature flags and limited cohort rollout.
