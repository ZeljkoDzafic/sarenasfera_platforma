# Database RLS Verification

Date: 2026-03-09

This document defines the minimum verification needed before production launch.

## Goal

Prove that the current migrations enforce the intended access model for:

- anonymous user
- parent
- staff
- admin
- expert
- service role

## Canonical Tables To Verify

### Identity and core relationships

- `profiles`
- `children`
- `parent_children`
- `groups`
- `group_staff`
- `child_groups`

### Operations and child data

- `sessions`
- `attendance`
- `observations`
- `observation_media`
- `assessments`
- `quarterly_reports`
- `child_milestones`
- `child_lesson_records`
- `daily_logs`
- `daily_log_meals`
- `daily_log_naps`
- `check_ins`
- `incident_reports`
- `learning_stories`
- `learning_story_media`
- `authorized_pickups`
- `emergency_contacts`

### Parent-facing content and actions

- `home_activities`
- `messages`
- `notifications`
- `challenge_submissions`
- `workshop_feedback`
- `parent_observations`

### Commercial and education

- `subscriptions`
- `payments`
- `feature_flags`
- `educational_content`
- `course_modules`
- `course_lessons`
- `course_enrollments`
- `lesson_progress`
- `content_registrations`
- `resource_materials`

## Expected Access Model

### Parent

- can read own profile
- can read and update own linked children where policy allows
- can read only own child-linked observations, assessments, reports, milestones, daily logs, stories
- can create allowed parent-originated records such as:
  - home activities
  - workshop feedback
  - parent observations
  - challenge submissions
- cannot read other families' children or records

### Staff

- can access only children in assigned groups unless table is explicitly broader
- can create and update operational records needed for sessions, attendance, observations, and milestone entry
- cannot see unrelated family-private data outside policy intent

### Admin

- full CRUD where the product requires it

### Expert

- verify intended read-only scope on observations and assessments
- verify no unintended write access

### Service role

- confirm expected bypass for server-side trusted workflows

## Verification Method

Run each test against a clean local stack after migrations are applied.

1. Create test actors:
   - one parent with child A
   - second parent with child B
   - one staff user assigned only to group containing child A
   - one admin
   - one expert
2. Seed minimal records for both children across all critical tables.
3. Authenticate as each actor and execute:
   - `SELECT`
   - allowed `INSERT`
   - allowed `UPDATE`
   - forbidden `SELECT`
   - forbidden `INSERT`
   - forbidden `UPDATE`
   - forbidden `DELETE`
4. Record each result as:
   - pass
   - fail
   - not applicable

## Required Output Table

For every table, record:

- table name
- role tested
- action
- expected result
- actual result
- pass/fail
- notes

## Launch Gate

Do not mark RLS complete until:

- all canonical tables above have an explicit result
- all failures are fixed or intentionally waived in writing
- service-role behavior is verified separately from normal user roles
