# 07 - Frontend Structure

## Stack: Vite + TypeScript + Tailwind CSS + Alpine.js

Zero server dependency. Builds to static HTML/CSS/JS. Deploy anywhere.

## Project Structure

```
frontend/
├── index.html                       # Landing page
├── program.html                     # Program overview
├── blog.html                        # Blog listing
├── blog-post.html                   # Single blog post
├── kontakt.html                     # Contact form
├── resursi.html                     # Free resources / lead magnets
├── about.html                       # About us, team
├── registracija.html                # Sign up
├── prijava.html                     # Log in
│
├── portal/                          # === PARENT PORTAL ===
│   ├── index.html                   # Dashboard
│   ├── djeca.html                   # My children list
│   ├── dijete.html                  # Child passport (reads ?id=UUID from URL)
│   ├── radionice.html               # Workshop materials
│   ├── aktivnosti.html              # Home activities
│   ├── galerija.html                # Photo gallery
│   └── profil.html                  # My profile
│
├── admin/                           # === STAFF / ADMIN PANEL ===
│   ├── index.html                   # Admin dashboard
│   ├── djeca.html                   # All children
│   ├── dijete.html                  # Child detail + observations
│   ├── grupe.html                   # Group management
│   ├── radionice.html               # Workshop planning
│   ├── opservacije.html             # Quick observation entry
│   ├── prisustvo.html               # Attendance tracking
│   ├── poruke.html                  # Messages to parents
│   ├── korisnici.html               # User management (admin only)
│   ├── statistike.html              # Analytics (admin only)
│   └── marketing.html               # Email campaigns (admin only)
│
├── src/                             # === TYPESCRIPT SOURCE ===
│   ├── main.ts                      # Global init (Supabase client, auth listener)
│   ├── supabase.ts                  # Supabase client setup
│   ├── auth.ts                      # Auth functions (signup, login, logout, guards)
│   ├── types.ts                     # TypeScript interfaces for all data models
│   │
│   ├── portal/                      # Portal-specific logic
│   │   ├── dashboard.ts             # Dashboard data loading
│   │   ├── child-passport.ts        # Passport data + charts
│   │   └── home-activities.ts       # Home activity feedback
│   │
│   ├── admin/                       # Admin-specific logic
│   │   ├── dashboard.ts             # Admin stats
│   │   ├── observations.ts          # Quick observation entry
│   │   ├── attendance.ts            # Attendance tracking
│   │   └── workshops.ts             # Workshop management
│   │
│   └── components/                  # Reusable Alpine.js components
│       ├── radar-chart.ts           # Radar chart for 6 domains
│       ├── notification-bell.ts     # Real-time notifications
│       ├── file-upload.ts           # Photo upload component
│       └── data-table.ts            # Sortable/filterable table
│
├── public/                          # Static assets (copied as-is)
│   ├── images/
│   ├── fonts/
│   └── favicon.ico
│
├── package.json
├── tsconfig.json
├── vite.config.ts
└── tailwind.config.ts               # (only if using Tailwind v3, v4 uses CSS)
```

## Vite Configuration

```typescript
// vite.config.ts
import { defineConfig } from 'vite';
import tailwindcss from '@tailwindcss/vite';

export default defineConfig({
  plugins: [tailwindcss()],
  build: {
    rollupOptions: {
      input: {
        // Public pages
        main: 'index.html',
        program: 'program.html',
        blog: 'blog.html',
        kontakt: 'kontakt.html',
        resursi: 'resursi.html',
        about: 'about.html',
        registracija: 'registracija.html',
        prijava: 'prijava.html',
        // Portal pages
        'portal-dashboard': 'portal/index.html',
        'portal-djeca': 'portal/djeca.html',
        'portal-dijete': 'portal/dijete.html',
        'portal-radionice': 'portal/radionice.html',
        'portal-aktivnosti': 'portal/aktivnosti.html',
        'portal-galerija': 'portal/galerija.html',
        'portal-profil': 'portal/profil.html',
        // Admin pages
        'admin-dashboard': 'admin/index.html',
        'admin-djeca': 'admin/djeca.html',
        'admin-dijete': 'admin/dijete.html',
        'admin-grupe': 'admin/grupe.html',
        'admin-radionice': 'admin/radionice.html',
        'admin-opservacije': 'admin/opservacije.html',
        'admin-prisustvo': 'admin/prisustvo.html',
        'admin-poruke': 'admin/poruke.html',
        'admin-korisnici': 'admin/korisnici.html',
        'admin-statistike': 'admin/statistike.html',
      }
    }
  }
});
```

## Core TypeScript Files

### Supabase Client

```typescript
// src/supabase.ts
import { createClient } from '@supabase/supabase-js';
import type { Database } from './types';

const SUPABASE_URL = import.meta.env.VITE_SUPABASE_URL;
const SUPABASE_ANON_KEY = import.meta.env.VITE_SUPABASE_ANON_KEY;

export const supabase = createClient<Database>(SUPABASE_URL, SUPABASE_ANON_KEY);
```

### Auth Module

```typescript
// src/auth.ts
import { supabase } from './supabase';

export async function signUp(email: string, password: string, fullName: string) {
  const { data, error } = await supabase.auth.signUp({
    email,
    password,
    options: { data: { full_name: fullName } }
  });
  if (error) throw error;
  return data;
}

export async function signIn(email: string, password: string) {
  const { data, error } = await supabase.auth.signInWithPassword({ email, password });
  if (error) throw error;
  return data;
}

export async function signOut() {
  await supabase.auth.signOut();
  window.location.href = '/prijava.html';
}

export async function getCurrentUser() {
  const { data: { user } } = await supabase.auth.getUser();
  return user;
}

export async function getUserRole(): Promise<string> {
  const user = await getCurrentUser();
  if (!user) return 'anonymous';
  const { data } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single();
  return data?.role ?? 'parent';
}

// Auth guard - call at top of protected pages
export async function requireAuth(allowedRoles?: string[]) {
  const user = await getCurrentUser();
  if (!user) {
    window.location.href = '/prijava.html';
    return null;
  }
  if (allowedRoles) {
    const role = await getUserRole();
    if (!allowedRoles.includes(role)) {
      window.location.href = '/portal/index.html';
      return null;
    }
  }
  return user;
}
```

### Type Definitions

```typescript
// src/types.ts
export interface Profile {
  id: string;
  full_name: string;
  phone: string | null;
  role: 'parent' | 'staff' | 'admin';
  avatar_url: string | null;
  city: string | null;
}

export interface Child {
  id: string;
  parent_id: string;
  full_name: string;
  date_of_birth: string;
  gender: 'male' | 'female' | 'other' | null;
  photo_url: string | null;
  enrollment_date: string;
  age_group: string | null;
  is_active: boolean;
}

export interface Assessment {
  id: string;
  child_id: string;
  domain: DevelopmentDomain;
  score: 1 | 2 | 3 | 4 | 5;
  period: string;
  notes: string | null;
}

export interface Observation {
  id: string;
  child_id: string;
  workshop_id: string | null;
  staff_id: string;
  content: string;
  domain: DevelopmentDomain | 'general';
  photo_url: string | null;
  is_visible_to_parent: boolean;
  created_at: string;
}

export type DevelopmentDomain =
  'emotional' | 'social' | 'creative' | 'cognitive' | 'motor' | 'language';

export interface Workshop {
  id: string;
  title: string;
  description: string | null;
  domain: DevelopmentDomain;
  scheduled_date: string;
  status: 'planned' | 'completed' | 'cancelled';
}

// Supabase generated types (run: supabase gen types typescript)
export type Database = {
  public: {
    Tables: {
      profiles: { Row: Profile; Insert: Partial<Profile>; Update: Partial<Profile> };
      children: { Row: Child; Insert: Partial<Child>; Update: Partial<Child> };
      // ... etc
    };
  };
};
```

## Alpine.js Pattern for Pages

Each HTML page has a corresponding Alpine.js `x-data` component:

```html
<!-- portal/index.html (Dashboard) -->
<!DOCTYPE html>
<html lang="bs">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Dashboard - Sarena Sfera</title>
  <link rel="stylesheet" href="/src/main.css">
</head>
<body class="bg-gray-50 min-h-screen">

  <!-- Navigation (reusable via Alpine component) -->
  <nav x-data="navigation()" class="bg-white shadow-sm sticky top-0 z-50">
    <div class="max-w-7xl mx-auto px-4 flex items-center justify-between h-16">
      <a href="/" class="text-xl font-bold text-purple-700">Sarena Sfera</a>
      <div class="flex items-center gap-4">
        <div x-data="notificationBell()" class="relative">
          <button @click="open = !open" class="relative p-2">
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                    d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6 6 0 10-12 0v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9"/>
            </svg>
            <span x-show="unreadCount > 0" x-text="unreadCount"
                  class="absolute -top-1 -right-1 bg-red-500 text-white text-xs w-5 h-5 rounded-full flex items-center justify-center">
            </span>
          </button>
        </div>
        <button @click="signOut()" class="text-sm text-gray-500 hover:text-gray-700">
          Log out
        </button>
      </div>
    </div>
  </nav>

  <!-- Main Content -->
  <main class="max-w-7xl mx-auto px-4 py-8" x-data="dashboard()">

    <!-- Loading state -->
    <div x-show="loading" class="flex justify-center py-12">
      <div class="animate-spin w-8 h-8 border-4 border-purple-500 border-t-transparent rounded-full"></div>
    </div>

    <!-- Content (hidden until loaded) -->
    <div x-show="!loading" x-cloak>
      <h1 class="text-2xl font-bold text-gray-800 mb-6">
        Welcome, <span x-text="userName"></span>!
      </h1>

      <!-- Children Grid -->
      <div class="grid md:grid-cols-2 gap-6">
        <template x-for="child in children" :key="child.id">
          <div class="bg-white rounded-xl shadow-sm p-6 border border-gray-100
                      hover:shadow-md transition-shadow">
            <div class="flex items-center gap-4 mb-4">
              <img :src="child.photo_url || '/images/child-default.svg'"
                   class="w-16 h-16 rounded-full object-cover bg-purple-100">
              <div>
                <h2 class="text-lg font-semibold" x-text="child.full_name"></h2>
                <p class="text-gray-500 text-sm" x-text="formatAge(child.date_of_birth)"></p>
              </div>
            </div>

            <!-- Domain scores -->
            <div class="grid grid-cols-2 gap-2 mb-4 text-sm">
              <template x-for="d in domains" :key="d.key">
                <div class="flex items-center gap-1">
                  <span x-text="d.icon" class="w-5"></span>
                  <span class="text-gray-600" x-text="d.label"></span>
                  <span class="ml-auto text-yellow-500"
                        x-text="getStars(child, d.key)"></span>
                </div>
              </template>
            </div>

            <a :href="'/portal/dijete.html?id=' + child.id"
               class="block text-center bg-purple-600 text-white rounded-lg py-2.5
                      font-medium hover:bg-purple-700 transition-colors">
              View Passport
            </a>
          </div>
        </template>
      </div>
    </div>
  </main>

  <!-- Scripts -->
  <script type="module" src="/src/main.ts"></script>
  <script type="module" src="/src/portal/dashboard.ts"></script>
</body>
</html>
```

### Dashboard TypeScript

```typescript
// src/portal/dashboard.ts
import Alpine from 'alpinejs';
import { supabase } from '../supabase';
import { requireAuth } from '../auth';
import type { Child, Assessment, DevelopmentDomain } from '../types';

const DOMAINS = [
  { key: 'emotional' as DevelopmentDomain, label: 'Emotional', icon: '💛' },
  { key: 'social' as DevelopmentDomain, label: 'Social', icon: '🤝' },
  { key: 'creative' as DevelopmentDomain, label: 'Creative', icon: '🎨' },
  { key: 'cognitive' as DevelopmentDomain, label: 'Cognitive', icon: '🧩' },
  { key: 'motor' as DevelopmentDomain, label: 'Motor', icon: '🏃' },
  { key: 'language' as DevelopmentDomain, label: 'Language', icon: '💬' },
];

Alpine.data('dashboard', () => ({
  loading: true,
  userName: '',
  children: [] as (Child & { assessments: Assessment[] })[],
  domains: DOMAINS,

  async init() {
    const user = await requireAuth();
    if (!user) return;

    // Load profile
    const { data: profile } = await supabase
      .from('profiles')
      .select('full_name')
      .eq('id', user.id)
      .single();
    this.userName = profile?.full_name ?? '';

    // Load children with assessments
    const { data: children } = await supabase
      .from('children')
      .select('*, assessments(domain, score, period)')
      .eq('parent_id', user.id)
      .eq('is_active', true);
    this.children = children ?? [];

    this.loading = false;
  },

  getStars(child: Child & { assessments: Assessment[] }, domain: string): string {
    const latest = child.assessments
      ?.filter(a => a.domain === domain)
      ?.sort((a, b) => b.period.localeCompare(a.period))?.[0];
    if (!latest) return '—';
    return '★'.repeat(latest.score) + '☆'.repeat(5 - latest.score);
  },

  formatAge(dob: string): string {
    const months = Math.floor(
      (Date.now() - new Date(dob).getTime()) / (1000 * 60 * 60 * 24 * 30.44)
    );
    return `${Math.floor(months / 12)} years, ${months % 12} months`;
  }
}));
```

## Admin: Quick Observation Entry (Mobile-First)

```typescript
// src/admin/observations.ts
import Alpine from 'alpinejs';
import { supabase } from '../supabase';
import { requireAuth } from '../auth';

const TEMPLATES: Record<string, string[]> = {
  emotional: [
    'Named an emotion independently',
    'Showed empathy when a peer was upset',
    'Managed frustration well during the activity',
    'Expressed feelings through art',
  ],
  social: [
    'Shared materials without prompting',
    'Cooperated well in group activity',
    'Waited for their turn patiently',
    'Initiated play with another child',
  ],
  creative: [
    'Used materials in an original way',
    'Combined multiple techniques',
    'Showed creative problem-solving',
  ],
  cognitive: [
    'Solved the problem independently',
    'Asked insightful questions',
    'Made connections between concepts',
  ],
  motor: [
    'Showed improved fine motor control',
    'Good hand-eye coordination',
    'Confident with new physical activities',
  ],
  language: [
    'Used new vocabulary words',
    'Told a story with clear sequence',
    'Expressed needs verbally to peers',
  ],
};

Alpine.data('observationEntry', () => ({
  workshops: [],
  selectedWorkshopId: '',
  children: [] as any[],
  loading: false,
  saving: false,

  async init() {
    const user = await requireAuth(['staff', 'admin']);
    if (!user) return;

    // Load recent/upcoming workshops
    const { data } = await supabase
      .from('workshops')
      .select('*')
      .order('scheduled_date', { ascending: false })
      .limit(20);
    this.workshops = data ?? [];
  },

  async loadChildren() {
    if (!this.selectedWorkshopId) return;
    this.loading = true;

    const workshop = this.workshops.find((w: any) => w.id === this.selectedWorkshopId);
    const { data } = await supabase
      .from('children')
      .select('*')
      .eq('is_active', true)
      .order('full_name');

    this.children = (data ?? []).map(child => ({
      ...child,
      _attended: null as boolean | null,
      _participation: 'full',
      _note: '',
      _domain: workshop?.domain ?? 'general',
      _photoFile: null as File | null,
    }));
    this.loading = false;
  },

  getTemplates(domain: string): string[] {
    return TEMPLATES[domain] ?? TEMPLATES.emotional;
  },

  addTemplate(child: any, template: string) {
    child._note += (child._note ? ' ' : '') + template;
  },

  async saveAll() {
    this.saving = true;
    const user = await supabase.auth.getUser();
    const staffId = user.data.user!.id;

    for (const child of this.children) {
      if (child._attended === null) continue;

      // Save attendance
      await supabase.from('attendance').upsert({
        workshop_id: this.selectedWorkshopId,
        child_id: child.id,
        status: child._attended ? 'present' : 'absent',
        participation_level: child._attended ? child._participation : null,
      });

      // Save observation (if note exists and attended)
      if (child._attended && child._note.trim()) {
        let photoUrl = null;
        if (child._photoFile) {
          const path = `${child.id}/${Date.now()}.jpg`;
          await supabase.storage.from('observations').upload(path, child._photoFile);
          photoUrl = path;
        }

        await supabase.from('observations').insert({
          child_id: child.id,
          workshop_id: this.selectedWorkshopId,
          staff_id: staffId,
          content: child._note,
          domain: child._domain,
          photo_url: photoUrl,
          is_visible_to_parent: true,
        });
      }
    }

    this.saving = false;
    alert('All observations saved!');
  }
}));
```

## Chart.js for Radar Chart (Child Passport)

```typescript
// src/components/radar-chart.ts
import { Chart, RadarController, RadialLinearScale, PointElement, LineElement, Filler } from 'chart.js';

Chart.register(RadarController, RadialLinearScale, PointElement, LineElement, Filler);

export function createRadarChart(
  canvas: HTMLCanvasElement,
  currentScores: number[],
  previousScores?: number[]
) {
  const datasets = [
    {
      label: 'Current Quarter',
      data: currentScores,
      borderColor: '#8B5CF6',
      backgroundColor: 'rgba(139, 92, 246, 0.2)',
      pointBackgroundColor: '#8B5CF6',
    }
  ];

  if (previousScores) {
    datasets.push({
      label: 'Previous Quarter',
      data: previousScores,
      borderColor: '#D1D5DB',
      backgroundColor: 'rgba(209, 213, 219, 0.1)',
      pointBackgroundColor: '#D1D5DB',
    });
  }

  return new Chart(canvas, {
    type: 'radar',
    data: {
      labels: ['Emotional', 'Social', 'Creative', 'Cognitive', 'Motor', 'Language'],
      datasets,
    },
    options: {
      scales: {
        r: {
          min: 0, max: 5,
          ticks: { stepSize: 1 },
        }
      },
      plugins: { legend: { position: 'bottom' } }
    }
  });
}
```

## Build & Development

```bash
# Development (hot reload)
npm run dev          # starts at localhost:5173

# Build for production
npm run build        # outputs to dist/

# Preview production build
npm run preview

# Deploy: just copy dist/ folder to ANY web server
```

## Environment Variables

```bash
# .env (development)
VITE_SUPABASE_URL=http://localhost:54321
VITE_SUPABASE_ANON_KEY=your-local-anon-key
VITE_API_URL=http://localhost:8080

# .env.production
VITE_SUPABASE_URL=https://supabase.sarenasfera.com
VITE_SUPABASE_ANON_KEY=your-production-anon-key
VITE_API_URL=https://api.sarenasfera.com
```
