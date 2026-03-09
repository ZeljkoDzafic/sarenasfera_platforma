# Auth E2E Checklist

Date: 2026-03-09

Use this checklist against a fresh local stack after:

- `npm run setup:local`
- `npm run install:all`
- `npm run dev:stack`
- `npm run dev:api`
- `npm run dev:frontend`

## Required Test Accounts

- new parent account created from public registration
- staff account created manually in Supabase with staff role
- admin account created manually in Supabase with admin role

## Parent Flow

1. Register through `/auth/register`
2. Confirm whether:
   - account is created
   - parent profile row exists
   - first child onboarding completes
3. Login through `/auth/login`
4. Verify redirect to `/portal`
5. Refresh browser
6. Verify session persists
7. Logout
8. Verify redirect to `/auth/login`

## Password Recovery

1. Open `/auth/forgot-password`
2. Request reset email
3. Open local Mailpit at `http://localhost:8025`
4. Follow reset link
5. Verify `/auth/reset-password` accepts new password
6. Login with new password

## Role Routing

### Staff

1. Login with staff account
2. Verify redirect to `/admin`
3. Verify protected portal/admin routes behave correctly

### Admin

1. Login with admin account
2. Verify redirect to `/admin`
3. Verify admin pages open without role-loop or blank state

## Negative Cases

- wrong password shows clear error
- duplicate email registration shows clear error
- guest cannot open `/portal/*`
- guest cannot open `/admin/*`
- parent cannot open `/admin/*`

## Launch Gate

Do not mark auth ready until every step above is marked:

- pass
- fail
- blocked
