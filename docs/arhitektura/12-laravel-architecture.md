# 12 - Laravel Architecture (Alternative)

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                    CLIENT (Browser)                      │
│                                                          │
│  Nuxt 3 (Vue 3 + TypeScript + Tailwind CSS)             │
│  ├── SSR for public pages (SEO)                         │
│  ├── SPA mode for portal/admin                          │
│  └── Calls Laravel API via fetch/axios                   │
└──────────┬──────────────────────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────────────────────────┐
│  LARAVEL 11 (PHP 8.3)                                   │
│                                                          │
│  ├── API Routes (JSON REST API)                         │
│  ├── Laravel Sanctum (Auth - token-based)               │
│  ├── Eloquent ORM (PostgreSQL)                          │
│  ├── Laravel Storage (file uploads)                     │
│  ├── Laravel Queues (background jobs)                   │
│  ├── Laravel Scheduler (cron)                           │
│  ├── Laravel Mail (email)                               │
│  ├── Laravel Broadcasting (Reverb - WebSockets)         │
│  └── Policies & Gates (authorization)                   │
│                                                          │
│  Single unified backend — no Python needed               │
└──────────┬──────────────────────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────────────────────────┐
│  PostgreSQL 15 + Redis (cache/queue/sessions)           │
└─────────────────────────────────────────────────────────┘
```

## Why Laravel?

| Benefit | Detail |
|---------|--------|
| **Mature ecosystem** | 10+ years, massive package library |
| **Single language backend** | Everything in PHP — no Python needed |
| **Eloquent ORM** | Elegant DB operations, relationships, scopes |
| **Built-in everything** | Auth, mail, queues, cache, storage, events |
| **Policies & Gates** | Clean authorization logic (not SQL-based) |
| **Laravel Queues** | PDF generation, emails — all async |
| **Artisan CLI** | Migrations, seeders, commands, generators |
| **Testing** | PHPUnit + Pest built-in, great testing DX |
| **Team-friendly** | Huge talent pool, well-documented |

## System Components

### 1. Frontend: Nuxt 3 (Same as Supabase track)

Identical frontend structure. Only difference: composables call Laravel API
instead of Supabase client.

```typescript
// Supabase approach:
const { data } = await supabase.from('children').select('*')

// Laravel approach:
const { data } = await $fetch('/api/children', {
  headers: { Authorization: `Bearer ${token}` }
})
```

### 2. Laravel Backend

```
api/
├── app/
│   ├── Http/
│   │   ├── Controllers/
│   │   │   ├── Auth/
│   │   │   │   ├── LoginController.php
│   │   │   │   ├── RegisterController.php
│   │   │   │   └── ForgotPasswordController.php
│   │   │   ├── Portal/
│   │   │   │   ├── DashboardController.php
│   │   │   │   ├── ChildController.php
│   │   │   │   ├── PassportController.php
│   │   │   │   ├── WorkshopController.php
│   │   │   │   └── ActivityController.php
│   │   │   ├── Admin/
│   │   │   │   ├── ChildController.php
│   │   │   │   ├── GroupController.php
│   │   │   │   ├── WorkshopController.php
│   │   │   │   ├── ObservationController.php
│   │   │   │   ├── AttendanceController.php
│   │   │   │   ├── UserController.php
│   │   │   │   └── AnalyticsController.php
│   │   │   └── Public/
│   │   │       ├── BlogController.php
│   │   │       ├── ContactController.php
│   │   │       └── ResourceController.php
│   │   ├── Middleware/
│   │   │   ├── EnsureRole.php          # role:admin, role:staff
│   │   │   └── EnsureParentOfChild.php # verify parent-child relation
│   │   ├── Requests/
│   │   │   ├── StoreObservationRequest.php
│   │   │   ├── StoreChildRequest.php
│   │   │   └── ...FormRequest classes
│   │   └── Resources/
│   │       ├── ChildResource.php       # API response transformers
│   │       ├── ObservationResource.php
│   │       └── PassportResource.php
│   ├── Models/
│   │   ├── User.php                    # extends Authenticatable
│   │   ├── Child.php
│   │   ├── Group.php
│   │   ├── Workshop.php
│   │   ├── Observation.php
│   │   ├── Assessment.php
│   │   ├── Attendance.php
│   │   ├── QuarterlyReport.php
│   │   ├── Subscription.php
│   │   └── ... (all 61 tables)
│   ├── Policies/
│   │   ├── ChildPolicy.php            # who can view/edit children
│   │   ├── ObservationPolicy.php      # who can add observations
│   │   └── WorkshopPolicy.php
│   ├── Services/
│   │   ├── PassportService.php        # child passport calculations
│   │   ├── PdfReportService.php       # DomPDF/Snappy PDF generation
│   │   ├── AnalyticsService.php       # aggregated statistics
│   │   └── NotificationService.php
│   ├── Jobs/
│   │   ├── GenerateQuarterlyReport.php
│   │   ├── SendWorkshopSummary.php
│   │   ├── ProcessPhotoUpload.php     # resize, thumbnails
│   │   └── SendEmailCampaign.php
│   ├── Events/
│   │   ├── ObservationCreated.php     # → notify parent
│   │   ├── AttendanceMarked.php       # → update dashboard
│   │   └── ReportGenerated.php        # → email parent
│   ├── Listeners/
│   │   ├── NotifyParentOfObservation.php
│   │   └── SendReportEmail.php
│   └── Console/
│       └── Commands/
│           ├── SendAttendanceReminders.php
│           ├── GenerateMonthlyReports.php
│           └── CleanupOldSessions.php
├── database/
│   ├── migrations/                    # 61+ migration files
│   ├── seeders/
│   │   ├── DatabaseSeeder.php
│   │   ├── RoleSeeder.php
│   │   ├── DemoDataSeeder.php
│   │   └── WorkshopTemplateSeeder.php
│   └── factories/                     # Model factories for testing
├── routes/
│   ├── api.php                        # All API routes
│   └── channels.php                   # Broadcasting channels
├── config/
├── tests/
│   ├── Feature/
│   │   ├── Auth/
│   │   ├── Portal/
│   │   └── Admin/
│   └── Unit/
├── Dockerfile
├── docker-compose.yml
└── .env.example
```

### 3. API Routes

```php
// routes/api.php

// Public
Route::get('/blog', [BlogController::class, 'index']);
Route::get('/blog/{slug}', [BlogController::class, 'show']);
Route::post('/contact', [ContactController::class, 'store']);
Route::get('/resources', [ResourceController::class, 'index']);

// Auth
Route::post('/auth/register', [RegisterController::class, 'store']);
Route::post('/auth/login', [LoginController::class, 'store']);
Route::post('/auth/forgot-password', [ForgotPasswordController::class, 'store']);
Route::post('/auth/reset-password', [ForgotPasswordController::class, 'reset']);

// Authenticated (Sanctum)
Route::middleware('auth:sanctum')->group(function () {

    // Portal (parents)
    Route::prefix('portal')->group(function () {
        Route::get('/dashboard', [DashboardController::class, 'index']);
        Route::apiResource('/children', Portal\ChildController::class)->only(['index', 'show']);
        Route::get('/children/{child}/passport', [PassportController::class, 'show']);
        Route::get('/workshops', [Portal\WorkshopController::class, 'index']);
        Route::get('/activities', [ActivityController::class, 'index']);
        Route::post('/activities/{activity}/complete', [ActivityController::class, 'complete']);
        Route::get('/gallery', [GalleryController::class, 'index']);
    });

    // Admin (staff + admin)
    Route::prefix('admin')->middleware('role:staff,admin')->group(function () {
        Route::apiResource('/children', Admin\ChildController::class);
        Route::apiResource('/groups', Admin\GroupController::class);
        Route::apiResource('/workshops', Admin\WorkshopController::class);
        Route::apiResource('/observations', Admin\ObservationController::class);
        Route::post('/attendance/bulk', [AttendanceController::class, 'bulkStore']);
        Route::get('/analytics/dashboard', [AnalyticsController::class, 'dashboard']);

        // Admin only
        Route::middleware('role:admin')->group(function () {
            Route::apiResource('/users', Admin\UserController::class);
            Route::post('/reports/quarterly', [ReportController::class, 'generate']);
            Route::post('/email/campaign', [EmailController::class, 'campaign']);
        });
    });
});
```

### 4. Authorization (Policies)

```php
// app/Policies/ChildPolicy.php
class ChildPolicy
{
    public function view(User $user, Child $child): bool
    {
        // Admin sees all
        if ($user->role === 'admin') return true;

        // Staff sees children in their groups
        if ($user->role === 'staff') {
            return $child->groups()
                ->whereHas('staff', fn($q) => $q->where('user_id', $user->id))
                ->exists();
        }

        // Parent sees own children
        return $child->parents()->where('user_id', $user->id)->exists();
    }

    public function update(User $user, Child $child): bool
    {
        return $user->role === 'admin'
            || ($user->role === 'staff' && $this->isStaffOfChild($user, $child));
    }
}
```

### 5. Eloquent Models (examples)

```php
// app/Models/Child.php
class Child extends Model
{
    protected $fillable = [
        'first_name', 'last_name', 'date_of_birth',
        'gender', 'allergies', 'special_needs', 'photo_url'
    ];

    public function parents() {
        return $this->belongsToMany(User::class, 'parent_children', 'child_id', 'parent_id');
    }

    public function groups() {
        return $this->belongsToMany(Group::class, 'child_groups');
    }

    public function observations() {
        return $this->hasMany(Observation::class);
    }

    public function assessments() {
        return $this->hasMany(Assessment::class);
    }

    public function attendance() {
        return $this->hasMany(Attendance::class);
    }

    public function quarterlyReports() {
        return $this->hasMany(QuarterlyReport::class);
    }

    // Computed: passport data
    public function getPassportData(string $period = null): array {
        return app(PassportService::class)->calculate($this, $period);
    }
}
```

## Data Flow

### Parent views child passport:
```
Browser → Nuxt ($fetch('/api/portal/children/123/passport'))
       → Laravel (Sanctum auth → ChildPolicy::view → PassportController)
       → Eloquent (load assessments, observations, attendance)
       → PassportResource (transform + calculate radar scores)
       → JSON response → Render radar chart + timeline
```

### Staff enters observation:
```
Browser → Nuxt (POST /api/admin/observations)
       → Laravel (Sanctum → StoreObservationRequest validation → ObservationController)
       → Eloquent (create observation)
       → Event: ObservationCreated
       → Listener: NotifyParentOfObservation (queue)
       → Broadcasting: push to parent's channel
```

### Quarterly report generation:
```
Scheduler → GenerateQuarterlyReport job (queue)
         → PassportService (calculate all scores)
         → PdfReportService (DomPDF → PDF)
         → Storage::put('reports/...')
         → DB: save QuarterlyReport record
         → Event: ReportGenerated → email parent
```

## Local Development Stack

```yaml
# docker-compose.yml
services:
  app:
    build: ./api
    ports: ["8000:8000"]
    volumes: ["./api:/var/www"]
    depends_on: [db, redis]

  db:
    image: postgres:15-alpine
    ports: ["5432:5432"]
    environment:
      POSTGRES_DB: sarenasfera
      POSTGRES_USER: sarenasfera
      POSTGRES_PASSWORD: secret

  redis:
    image: redis:7-alpine
    ports: ["6379:6379"]

  queue:
    build: ./api
    command: php artisan queue:work
    depends_on: [db, redis]

  scheduler:
    build: ./api
    command: php artisan schedule:work
    depends_on: [db, redis]

  mailpit:
    image: axllent/mailpit
    ports: ["8025:8025", "1025:1025"]  # UI + SMTP

  # Frontend runs natively: nuxt dev (port 3000)
```

## Production Deployment

```
DigitalOcean Droplet ($12-24/mo)
├── Nginx (reverse proxy + SSL)
├── PHP-FPM 8.3 (Laravel)
├── PostgreSQL 15
├── Redis 7
├── Supervisor (queue workers)
└── Frontend: Vercel/Netlify (free) or Nginx static
```

OR with Docker:
```
DigitalOcean Droplet
├── Nginx (reverse proxy + SSL)
├── Docker: laravel-app (PHP-FPM + Nginx)
├── Docker: postgres
├── Docker: redis
├── Docker: queue-worker
└── Docker: scheduler
```

## Scaling Path

| Users | Infrastructure | Cost |
|-------|---------------|------|
| 0-200 | 1 droplet (2GB) | $12/mo |
| 200-1000 | 1 droplet (4GB), managed DB | $40/mo |
| 1000-5000 | Load balancer, 2 app servers, managed DB | $100/mo |
| 5000+ | Kubernetes / Laravel Forge / Vapor | varies |

## Pros & Cons

### Pros
- **Single unified backend** — no Python, no Supabase, everything in Laravel
- **Eloquent ORM** — cleaner than raw SQL/PostgREST for complex queries
- **Policies** — authorization logic in PHP, easier to test and debug
- **Queues** — background PDF, email, notifications — built-in
- **Testing** — PHPUnit/Pest, model factories, HTTP tests — amazing DX
- **Ecosystem** — packages for everything (Spatie permissions, DomPDF, etc.)
- **Team scaling** — PHP/Laravel devs are everywhere
- **Migrations** — version-controlled schema changes via Artisan

### Cons
- **More code to write** — no auto-generated API (must write controllers)
- **Custom auth** — must build login/register endpoints (Sanctum helps)
- **No built-in realtime** — need Laravel Reverb or Pusher
- **Server required** — PHP needs a server (no static deploy)
- **PHP stigma** — some developers avoid PHP (though Laravel is excellent)
- **More infrastructure** — need PHP-FPM, Redis, queue workers
- **Slower MVP** — more boilerplate than Supabase for simple CRUD

## Key Laravel Packages

| Package | Purpose |
|---------|---------|
| `laravel/sanctum` | API token auth |
| `spatie/laravel-permission` | Roles & permissions |
| `barryvdh/laravel-dompdf` | PDF generation |
| `laravel/reverb` | WebSocket server (realtime) |
| `spatie/laravel-medialibrary` | File uploads + conversions |
| `spatie/laravel-query-builder` | API filtering/sorting |
| `laravel/horizon` | Queue monitoring |
| `pestphp/pest` | Testing framework |
