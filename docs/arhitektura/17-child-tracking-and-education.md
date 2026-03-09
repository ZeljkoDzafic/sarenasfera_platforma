# 17 - Enhanced Child Tracking & Educational Content Management

## Part A: Enhanced Child Section (Growth, Passport, Progress)

### Overview

Dedicated child-focused area that gives parents a rich, visual experience of their
child's developmental journey. Extends the existing Child Passport (doc 06) with
deeper tracking, milestone visualization, and growth insights.

---

### 1. Child Profile Hub

Each child gets a dedicated hub page accessible from the portal sidebar.

**URL:** `/portal/children/[id]`

```
┌──────────────────────────────────────────────────┐
│  [Photo]  Ana Markovic                            │
│           4 godine, 2 mjeseca                     │
│           Grupa: Pcelice (3-4 god)               │
│           Na programu od: Sep 2025               │
│           Broj radionica: 34                      │
│                                                    │
│  [Pasos] [Napredak] [Razvoj] [Galerija] [Izvj.]  │
└──────────────────────────────────────────────────┘
```

**Tabs:**

| Tab | Name | Description | Tier |
|-----|------|-------------|------|
| Pasos | Djeciji Pasos | Radar chart + 6 domain scores (existing) | Paid |
| Napredak | Napredak | Growth timeline + milestones achieved | Paid |
| Razvoj | Razvojna putanja | Personalized path + recommendations | Premium |
| Galerija | Galerija | Photos from observations + parent uploads | Free |
| Izvjestaji | Izvjestaji | Quarterly PDFs + summaries | Premium |

---

### 2. Growth & Milestone Tracking

**Concept:** Track and visualize concrete developmental milestones per domain,
per age bracket. Parents see what their child has achieved and what's coming next.

#### Milestone Categories (per domain)

```
Emocionalni razvoj (2-3 god):
  ☑ Prepoznaje srecu i tugu
  ☑ Reaguje na emocije drugih
  ☐ Imenuje 3+ emocije
  ☐ Koristi rijeci za izrazavanje osjecaja

Emocionalni razvoj (3-4 god):
  ☑ Imenuje 4+ emocije
  ☐ Regulise frustraciju uz podrsku
  ☐ Pokazuje empatiju prema vrsnjacima
  ☐ Prepoznaje emocije u pricama
```

#### Milestone Database

```sql
CREATE TABLE public.developmental_milestones (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  domain TEXT NOT NULL CHECK (domain IN (
    'emotional', 'social', 'creative', 'cognitive', 'motor', 'language'
  )),
  age_range_min INT NOT NULL,          -- months (24 = 2 years)
  age_range_max INT NOT NULL,          -- months (36 = 3 years)
  title TEXT NOT NULL,                  -- "Prepoznaje srecu i tugu"
  description TEXT,                     -- detailed explanation
  sort_order INT DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE public.child_milestones (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  child_id UUID REFERENCES children(id) NOT NULL,
  milestone_id UUID REFERENCES developmental_milestones(id) NOT NULL,
  achieved_at DATE,                     -- when milestone was observed
  observed_by UUID REFERENCES profiles(id), -- staff who observed
  observation_id UUID REFERENCES observations(id), -- linked observation
  notes TEXT,
  status TEXT DEFAULT 'not_started'
    CHECK (status IN ('not_started', 'emerging', 'achieved')),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(child_id, milestone_id)
);

CREATE INDEX idx_child_milestones_child ON child_milestones(child_id);
CREATE INDEX idx_child_milestones_status ON child_milestones(status);
CREATE INDEX idx_milestones_domain_age ON developmental_milestones(domain, age_range_min);
```

#### Growth Timeline View

```
──── Mart 2026 ──────────────────────────
  🟢 Emocionalni: Imenuje 4+ emocije
  🟢 Motoricki: Reze skarama po liniji
  📷 3 nove fotografije sa radionica

──── Februar 2026 ───────────────────────
  🟢 Socijalni: Dijeli igracke bez podsticaja
  🟡 Jezicki: Koristi slozene recenice (u toku)
  📋 1 nova opservacija od voditeljice

──── Januar 2026 ────────────────────────
  🟢 Kreativni: Kombinira 3+ materijala
  🟢 Kognitivni: Sortira po 2 kriterija
  📄 Kvartalni izvjestaj Q4 2025 dostupan
```

---

### 3. Domain Progress Visualization

Each domain gets a detailed breakdown page.

**URL:** `/portal/children/[id]/domain/[domain]`

```
┌──────────────────────────────────────────────────┐
│  Emocionalni razvoj — Ana Markovic               │
│                                                    │
│  Trenutna ocjena: ★★★★☆ (4/5 — Samostalna)      │
│                                                    │
│  [Progress bar: ███████████░░░░ 75%]              │
│  12 od 16 miljokaza postignuto                    │
│                                                    │
│  ─── Postignuti miljokazi ───                     │
│  ✅ Prepoznaje srecu i tugu              Sep 2025 │
│  ✅ Reaguje na emocije drugih            Okt 2025 │
│  ✅ Imenuje 4+ emocije                   Jan 2026 │
│  ...                                               │
│                                                    │
│  ─── Trenutni fokus ───                           │
│  🎯 Regulise frustraciju samostalno               │
│     Preporucena aktivnost: "Disanje s balonima"   │
│                                                    │
│  ─── Nadolazeci miljokazi ───                     │
│  🔜 Prepoznaje emocije u pricama                  │
│  🔜 Pomaze vrsnjacima kad su tuzni                │
│                                                    │
│  ─── Trend ───                                     │
│  [Line chart: score over quarters]                │
│  Q3/25: 2.5 → Q4/25: 3.0 → Q1/26: 4.0           │
└──────────────────────────────────────────────────┘
```

---

### 4. Passport Comparison View

Compare a child's development across time periods or against age-typical ranges.

```
┌──────────────────────────────────────────────────┐
│  Poredjenje razvoja — Ana Markovic               │
│                                                    │
│  [Radar Chart]                                    │
│  ── Q1 2026 (solid blue)                         │
│  ── Q4 2025 (dashed gray)                        │
│  ── Prosjek uzrasta (dotted green)               │
│                                                    │
│  Domena         Q4/25  Q1/26  Promjena  Prosjek  │
│  Emocionalni    3.0    4.0    ↑ +1.0    3.5      │
│  Socijalni      2.5    3.0    ↑ +0.5    3.0      │
│  Kreativni      4.0    5.0    ↑ +1.0    3.5      │
│  Kognitivni     3.0    3.5    ↑ +0.5    3.5      │
│  Motoricki      3.5    4.0    ↑ +0.5    3.5      │
│  Jezicki        3.0    3.5    ↑ +0.5    3.5      │
│                                                    │
│  Najveci napredak: Kreativni (+1.0)              │
│  Preporuka: Fokus na socijalne aktivnosti         │
└──────────────────────────────────────────────────┘
```

---

### 5. Staff Quick-Entry for Milestones

From the observation entry screen, staff can also mark milestones.

```
┌──────────────────────────────────────────────────┐
│  Opservacija — Ana M.                             │
│                                                    │
│  Domena: [Emocionalni ▼]                          │
│  Biljeska: [Ana je danas prvi put sama...]        │
│  Fotografija: [📷 Upload]                         │
│                                                    │
│  ─── Dostupni miljokazi ───                       │
│  ☐ Regulise frustraciju samostalno                │
│  ☐ Prepoznaje emocije u pricama                   │
│  ☑ Imenuje razloge za emocije ← (checked)        │
│                                                    │
│  [Sacuvaj opservaciju]                            │
└──────────────────────────────────────────────────┘
```

---

### 6. Parent-Contributed Updates

Parents can submit home observations (verified by staff before adding to passport).

```sql
CREATE TABLE public.parent_observations (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  child_id UUID REFERENCES children(id) NOT NULL,
  parent_id UUID REFERENCES profiles(id) NOT NULL,
  domain TEXT CHECK (domain IN (
    'emotional', 'social', 'creative', 'cognitive', 'motor', 'language'
  )),
  content TEXT NOT NULL,
  photo_url TEXT,
  status TEXT DEFAULT 'pending'
    CHECK (status IN ('pending', 'approved', 'rejected')),
  reviewed_by UUID REFERENCES profiles(id),
  reviewed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_parent_obs_child ON parent_observations(child_id);
CREATE INDEX idx_parent_obs_status ON parent_observations(status);
```

**Flow:**
```
Parent submits "Ana je danas sama napravila kolaž od lišća"
  → Appears in staff queue as "pending"
  → Staff approves → linked to child's creative domain
  → OR staff adds note + milestone tag
```

---

## Part B: Educational Content Management (Mini-LMS)

### Overview

The platform offers 4 types of educational content:

| Type | Format | Location | Example |
|------|--------|----------|---------|
| **Online Course** | Video/text modules, self-paced | Online (platform) | "Razumijevanje djecijih emocija" (10 lekcija) |
| **Offline Workshop** | In-person, scheduled | Physical location | "Kreativna radionica — Kolaž" (Sub 15.03, 10:00) |
| **Online Event** | Live webinar/session | Zoom/Meet/Platform | "Roditeljski webinar: Disciplina bez kazne" |
| **Offline Event** | In-person, open/ticketed | Physical location | "Dan otvorenih vrata" (28.03, 09:00-13:00) |

Additionally: **Educational Resources** (articles, PDFs, videos) as standalone content.

---

### 1. Unified Content Model

```sql
-- Master content types enum
-- content_type: 'online_course', 'offline_workshop', 'online_event', 'offline_event', 'resource'

CREATE TABLE public.educational_content (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  content_type TEXT NOT NULL CHECK (content_type IN (
    'online_course', 'offline_workshop', 'online_event', 'offline_event', 'resource'
  )),
  title TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE,
  description TEXT,
  short_description TEXT,             -- for card view
  cover_image_url TEXT,
  -- Categorization
  domain TEXT CHECK (domain IN (
    'emotional', 'social', 'creative', 'cognitive', 'motor', 'language', 'general'
  )),
  target_audience TEXT DEFAULT 'parent' CHECK (target_audience IN (
    'parent', 'child', 'both', 'professional'
  )),
  age_range_min INT,                  -- child age (months), null if for parents
  age_range_max INT,
  tags TEXT[],                        -- ['emocionalni razvoj', 'komunikacija']
  -- Access
  tier_required TEXT DEFAULT 'free' CHECK (tier_required IN ('free', 'paid', 'premium')),
  is_featured BOOLEAN DEFAULT false,
  is_published BOOLEAN DEFAULT false,
  published_at TIMESTAMPTZ,
  -- Scheduling (for events/workshops)
  starts_at TIMESTAMPTZ,
  ends_at TIMESTAMPTZ,
  location_type TEXT CHECK (location_type IN ('online', 'in_person', null)),
  location_name TEXT,                 -- "Sarena Sfera Studio" or "Zoom"
  location_address TEXT,
  location_url TEXT,                  -- meeting link for online
  max_participants INT,
  -- Pricing (if separate from tier)
  is_free BOOLEAN DEFAULT true,
  price_km DECIMAL(10,2) DEFAULT 0,
  -- Metadata
  duration_minutes INT,               -- estimated or actual
  difficulty_level TEXT CHECK (difficulty_level IN ('beginner', 'intermediate', 'advanced')),
  instructor_id UUID REFERENCES profiles(id),
  -- SEO
  meta_title TEXT,
  meta_description TEXT,
  -- Timestamps
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_edu_content_type ON educational_content(content_type);
CREATE INDEX idx_edu_content_published ON educational_content(is_published, published_at);
CREATE INDEX idx_edu_content_domain ON educational_content(domain);
CREATE INDEX idx_edu_content_tier ON educational_content(tier_required);
CREATE INDEX idx_edu_content_slug ON educational_content(slug);
CREATE INDEX idx_edu_content_starts ON educational_content(starts_at) WHERE starts_at IS NOT NULL;
```

---

### 2. Online Courses (Self-Paced)

Structured course with ordered modules/lessons.

```sql
CREATE TABLE public.course_modules (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  course_id UUID REFERENCES educational_content(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  sort_order INT DEFAULT 0,
  is_published BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE public.course_lessons (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  module_id UUID REFERENCES course_modules(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  -- Content (one of these is primary)
  content_html TEXT,                   -- rich text lesson
  video_url TEXT,                      -- video lesson (YouTube, Vimeo, or Storage)
  video_duration_seconds INT,
  attachment_urls TEXT[],              -- downloadable PDFs, worksheets
  -- Settings
  sort_order INT DEFAULT 0,
  is_published BOOLEAN DEFAULT true,
  is_previewable BOOLEAN DEFAULT false, -- can free users see this lesson?
  estimated_minutes INT DEFAULT 10,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE public.course_enrollments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) NOT NULL,
  course_id UUID REFERENCES educational_content(id) NOT NULL,
  enrolled_at TIMESTAMPTZ DEFAULT now(),
  completed_at TIMESTAMPTZ,
  progress_percent INT DEFAULT 0,
  UNIQUE(user_id, course_id)
);

CREATE TABLE public.lesson_progress (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) NOT NULL,
  lesson_id UUID REFERENCES course_lessons(id) NOT NULL,
  started_at TIMESTAMPTZ DEFAULT now(),
  completed_at TIMESTAMPTZ,
  time_spent_seconds INT DEFAULT 0,
  UNIQUE(user_id, lesson_id)
);

CREATE INDEX idx_course_modules_course ON course_modules(course_id, sort_order);
CREATE INDEX idx_course_lessons_module ON course_lessons(module_id, sort_order);
CREATE INDEX idx_enrollments_user ON course_enrollments(user_id);
CREATE INDEX idx_enrollments_course ON course_enrollments(course_id);
CREATE INDEX idx_lesson_progress_user ON lesson_progress(user_id);
```

#### Course View (Parent Portal)

```
┌──────────────────────────────────────────────────┐
│  Razumijevanje djecijih emocija                   │
│  🎓 Online kurs  |  ⏱ ~2h  |  📚 10 lekcija     │
│  👩‍🏫 Dr. Amina Hadzic, djeciji psiholog          │
│                                                    │
│  Napredak: ████████░░░░ 65% (7/10 lekcija)       │
│                                                    │
│  Modul 1: Osnove emocionalnog razvoja             │
│    ✅ Lekcija 1: Sta su emocije?                  │
│    ✅ Lekcija 2: Faze emocionalnog razvoja        │
│    ✅ Lekcija 3: Kako djeca izrazavaju emocije    │
│                                                    │
│  Modul 2: Strategije za roditelje                 │
│    ✅ Lekcija 4: Aktivno slusanje                 │
│    ✅ Lekcija 5: Imenovanje emocija               │
│    🔵 Lekcija 6: Tehnika ogledala ← TRENUTNA     │
│    ⬜ Lekcija 7: Regulacija kroz igru             │
│                                                    │
│  Modul 3: Prakticne vjezbe                        │
│    🔒 Lekcija 8-10 (Premium)                      │
│                                                    │
│  [Nastavi kurs →]                                 │
└──────────────────────────────────────────────────┘
```

---

### 3. Event Registration (Online & Offline)

Unified registration for all event types.

```sql
CREATE TABLE public.content_registrations (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  content_id UUID REFERENCES educational_content(id) NOT NULL,
  user_id UUID REFERENCES profiles(id),           -- null if anonymous
  -- Registration info
  parent_name TEXT NOT NULL,
  parent_email TEXT NOT NULL,
  parent_phone TEXT,
  child_name TEXT,                                  -- if child event
  child_age_months INT,
  -- Status
  status TEXT DEFAULT 'registered' CHECK (status IN (
    'registered', 'confirmed', 'waitlist', 'attended', 'no_show', 'cancelled'
  )),
  -- Payment (if event has separate price)
  payment_status TEXT DEFAULT 'not_required' CHECK (payment_status IN (
    'not_required', 'pending', 'paid', 'refunded'
  )),
  payment_amount DECIMAL(10,2),
  -- Online event specifics
  meeting_link_sent BOOLEAN DEFAULT false,
  -- Tracking
  source TEXT,                         -- utm_source, referral code
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_content_reg_content ON content_registrations(content_id);
CREATE INDEX idx_content_reg_user ON content_registrations(user_id);
CREATE INDEX idx_content_reg_email ON content_registrations(parent_email);
CREATE INDEX idx_content_reg_status ON content_registrations(status);
```

---

### 4. Educational Resources (Standalone)

Articles, PDFs, videos not part of a course.

```sql
CREATE TABLE public.resource_materials (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  content_id UUID REFERENCES educational_content(id) ON DELETE CASCADE NOT NULL,
  -- Can have multiple materials per resource
  material_type TEXT NOT NULL CHECK (material_type IN (
    'article', 'pdf', 'video', 'infographic', 'worksheet', 'checklist'
  )),
  title TEXT NOT NULL,
  content_html TEXT,                   -- for articles
  file_url TEXT,                       -- for PDFs, worksheets
  video_url TEXT,                      -- for videos
  sort_order INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_resource_materials_content ON resource_materials(content_id);
```

---

### 5. Navigation Structure

#### Parent Portal Sidebar (Updated)

```
Kontrolna tabla
Moja djeca
  └── [Ana] → Pasos / Napredak / Razvoj / Galerija / Izvjestaji
  └── [Marko] → ...
Radionice                        ← offline child workshops (existing)
Kucne aktivnosti                 ← home activity library
Edukacija                        ← NEW SECTION
  └── Online kursevi             ← self-paced courses
  └── Webinari                   ← online events
  └── Radionice za roditelje     ← offline parent events
  └── Resursi                    ← articles, PDFs, videos
Galerija
Moj napredak
Preporuci prijatelja
Sertifikati
Poruke
Profil & Pretplata
```

#### Public Site Navigation

```
Program
  └── Djecije radionice
  └── Edukacija za roditelje     ← NEW
Dogadjaji                        ← all upcoming events (online + offline)
Blog
Resursi
Quiz
Kontakt
```

---

### 6. Content Discovery Page

**URL:** `/portal/education` (or `/edukacija` for public)

```
┌──────────────────────────────────────────────────┐
│  Edukacija za roditelje                           │
│                                                    │
│  [Online kursevi] [Webinari] [Radionice] [Resursi]│
│                                                    │
│  Filteri:                                         │
│  Domena: [Sve] [Emocionalni] [Socijalni] ...      │
│  Uzrast: [Sve] [2-3] [3-4] [4-5] [5-6]          │
│  Format: [Sve] [Besplatno] [Premium]              │
│                                                    │
│  ─── Istaknuti kursevi ───                        │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐          │
│  │ [cover]  │ │ [cover]  │ │ [cover]  │          │
│  │ Emocije  │ │ Motorika │ │ Kreativa │          │
│  │ 10 lek.  │ │ 8 lek.   │ │ 6 lek.   │          │
│  │ ⭐ 4.8   │ │ ⭐ 4.5   │ │ 🆕 Novo  │          │
│  └──────────┘ └──────────┘ └──────────┘          │
│                                                    │
│  ─── Nadolazeci dogadjaji ───                     │
│  📍 Kreativna radionica — Sub 15.03, 10:00        │
│  💻 Webinar: Komunikacija — Pon 17.03, 20:00     │
│  📍 Dan otvorenih vrata — 28.03, 09:00-13:00     │
│                                                    │
│  ─── Novi resursi ───                             │
│  📄 "10 aktivnosti za razvoj govora" (PDF)        │
│  📹 "Kako citati djetetu" (video, 8 min)          │
│  📝 "Dnevna rutina za predskolce" (clanak)        │
└──────────────────────────────────────────────────┘
```

---

### 7. Tier Access for Educational Content

| Content Type | Free | Paid | Premium |
|---|---|---|---|
| Online courses | Preview (1st lesson free) | 3 courses | All courses |
| Online events (webinars) | No | No | Live + recordings |
| Offline workshops (child) | Pay per session | 8/month included | All included |
| Offline events | Free events only | All events | All + priority |
| Resources (articles) | 5 articles | 20 articles | All |
| Resources (PDFs/videos) | No | 10 downloads/month | Unlimited |

---

### 8. Admin Content Management

#### Content List Page

**URL:** `/admin/education`

```
┌──────────────────────────────────────────────────┐
│  Upravljanje edukativnim sadrzajem               │
│                                                    │
│  [+ Novi kurs] [+ Novi dogadjaj] [+ Novi resurs]  │
│                                                    │
│  Filter: [Svi tipovi ▼] [Sve domene ▼] [Status ▼]│
│                                                    │
│  Naslov              Tip          Status  Datum   │
│  ─────────────────────────────────────────────────│
│  Emocije kod djece   Online kurs  ✅ Live  Jan 26│
│  Kreativna radionica Offline      ✅ Live  Mar 26│
│  Webinar: Disciplina Online event 📅 15.03       │
│  Motoricki razvoj    Online kurs  ⬜ Draft  -    │
│  10 aktivnosti (PDF) Resurs       ✅ Live  Feb 26│
│                                                    │
│  [Statistika: 3 kursa, 12 dogadjaja, 8 resursa]  │
└──────────────────────────────────────────────────┘
```

#### Course Editor

```
┌──────────────────────────────────────────────────┐
│  Uredi kurs: Razumijevanje djecijih emocija      │
│                                                    │
│  Naslov: [_______________________________]        │
│  Slug: [razumijevanje-djecijih-emocija]           │
│  Opis: [_______________________________]          │
│  Cover: [📷 Upload]                               │
│  Domena: [Emocionalni ▼]  Uzrast: [3-6 god]      │
│  Tier: [Paid ▼]   Instruktor: [Dr. Amina H. ▼]  │
│                                                    │
│  ─── Moduli ───                                   │
│  [+ Dodaj modul]                                  │
│                                                    │
│  Modul 1: Osnove [Uredi] [⬆] [⬇] [🗑]           │
│    Lekcija 1: Sta su emocije [Uredi] [Preview]   │
│    Lekcija 2: Faze razvoja [Uredi] [Preview]     │
│    [+ Dodaj lekciju]                              │
│                                                    │
│  Modul 2: Strategije [Uredi] [⬆] [⬇] [🗑]       │
│    ...                                             │
│                                                    │
│  Status: [Draft ▼]  [Sacuvaj]  [Objavi]           │
└──────────────────────────────────────────────────┘
```

#### Event Creator

```
┌──────────────────────────────────────────────────┐
│  Novi dogadjaj                                    │
│                                                    │
│  Tip: (●) Offline radionica  ( ) Online webinar   │
│       ( ) Offline dogadjaj   ( ) Online dogadjaj  │
│                                                    │
│  Naslov: [_______________________________]        │
│  Datum: [15.03.2026]  Vrijeme: [10:00] - [11:30]  │
│                                                    │
│  -- Ako offline: --                               │
│  Lokacija: [Sarena Sfera Studio ▼]               │
│  Adresa: [Marsala Tita 25, Sarajevo]              │
│                                                    │
│  -- Ako online: --                                │
│  Meeting link: [https://zoom.us/...]              │
│                                                    │
│  Max ucesnika: [20]                               │
│  Cijena: (●) Besplatno  ( ) Placanje: [__] KM    │
│  Tier: [Free ▼]                                   │
│  Domena: [Kreativni ▼]                            │
│  Uzrast: [3-5 god]                                │
│  Instruktor: [Voditelj ▼]                         │
│                                                    │
│  [Sacuvaj kao draft]  [Objavi dogadjaj]           │
└──────────────────────────────────────────────────┘
```

---

### 9. Analytics for Educational Content

Admin dashboard section:

```
Kursevi:
  - Ukupno upisanih: 45
  - Prosjecan napredak: 62%
  - Najgledaniji: "Emocije kod djece" (28 upisanih)
  - Completion rate: 34%

Dogadjaji:
  - Nadolazeci: 3
  - Registrovanih: 42
  - Attendance rate: 78%
  - No-show rate: 12%

Resursi:
  - Ukupno pregleda: 234
  - Najpopularniji: "10 aktivnosti za razvoj govora" (89 preuzimanja)
  - Prosjecno vrijeme citanja: 4.2 min
```

---

### 10. Integration Points

| From | To | How |
|---|---|---|
| Child milestones | Course recommendations | "Your child needs emotional support → Take this course" |
| Course completion | Parent badges | "Completed 3 courses → Edukovan roditelj badge" |
| Event attendance | Child attendance | Offline workshop → auto-mark child as attended |
| Quiz results | Course suggestions | "Based on quiz → We recommend these 2 courses" |
| Resource downloads | Lead capture | Free resource → email capture if not logged in |
| Course progress | Parent progress | Counts toward parent engagement score |

---

## Summary of New Tables

| Table | Purpose | Records |
|---|---|---|
| `developmental_milestones` | Master list of age-appropriate milestones | ~200 (seeded) |
| `child_milestones` | Track which milestones each child has achieved | Many |
| `parent_observations` | Parent-submitted observations (moderated) | Many |
| `educational_content` | All educational content (courses, events, resources) | ~50+ |
| `course_modules` | Course module grouping | ~30 |
| `course_lessons` | Individual lessons within modules | ~100 |
| `course_enrollments` | User enrollment in courses | Many |
| `lesson_progress` | Per-lesson progress tracking | Many |
| `content_registrations` | Event registration (online + offline) | Many |
| `resource_materials` | Attachments to resource-type content | ~50 |
