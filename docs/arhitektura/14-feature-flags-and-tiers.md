# 14 - Feature Flags, Subscription Tiers & Registration Flow

## Problem

Platform launches in stages. Not all features are ready at launch.
We need:
1. Admin ability to show/hide features ("Coming Soon" badges)
2. Workshop/event registration as primary user acquisition funnel
3. Three subscription tiers: Free, Paid, Premium

---

## Part 1: Feature Flags System

### Concept

Admin panel has a **Feature Manager** where each platform section can be toggled:
- **Active** — feature is live, accessible to users based on their tier
- **Coming Soon** — visible in navigation with a badge, but not functional
- **Hidden** — completely hidden from UI

### Database

```sql
CREATE TABLE public.feature_flags (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  key TEXT NOT NULL UNIQUE,          -- e.g. 'portal.gallery', 'portal.forum'
  name TEXT NOT NULL,                -- human-readable: 'Photo Gallery'
  description TEXT,                  -- what this feature does
  status TEXT NOT NULL DEFAULT 'hidden'
    CHECK (status IN ('active', 'coming_soon', 'hidden')),
  required_tier TEXT DEFAULT 'free'
    CHECK (required_tier IN ('free', 'paid', 'premium')),
  sort_order INT DEFAULT 0,
  metadata JSONB DEFAULT '{}',       -- extra config (e.g. release date estimate)
  updated_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_feature_flags_key ON feature_flags(key);
CREATE INDEX idx_feature_flags_status ON feature_flags(status);
```

### Default Feature Registry

| Key | Name | Initial Status | Tier |
|-----|------|---------------|------|
| `public.landing` | Landing Page | active | free |
| `public.blog` | Blog | active | free |
| `public.resources` | Besplatni resursi | active | free |
| `public.contact` | Kontakt | active | free |
| `auth.register` | Registracija | active | free |
| `auth.workshop_register` | Prijava na radionicu | active | free |
| `portal.dashboard` | Kontrolna tabla | active | free |
| `portal.children` | Moja djeca | active | free |
| `portal.workshops` | Radionice (pregled) | active | free |
| `portal.passport` | Dječiji pasoš | active | paid |
| `portal.passport.radar` | Radar grafikon | active | paid |
| `portal.passport.reports` | Kvartalni izvještaji (PDF) | coming_soon | premium |
| `portal.activities` | Kućne aktivnosti | active | paid |
| `portal.gallery` | Foto galerija | coming_soon | paid |
| `portal.messages` | Poruke | coming_soon | paid |
| `portal.forum` | Zajednica roditelja | coming_soon | premium |
| `portal.resources.video` | Video tutorijali | coming_soon | premium |
| `portal.resources.expert` | Pitaj stručnjaka | coming_soon | premium |
| `admin.dashboard` | Admin kontrolna tabla | active | — |
| `admin.children` | Upravljanje djecom | active | — |
| `admin.groups` | Upravljanje grupama | active | — |
| `admin.workshops` | Upravljanje radionicama | active | — |
| `admin.observations` | Opservacije | active | — |
| `admin.attendance` | Prisustvo | active | — |
| `admin.messages` | Poruke roditeljima | coming_soon | — |
| `admin.users` | Upravljanje korisnicima | active | — |
| `admin.statistics` | Statistike | coming_soon | — |
| `admin.feature_manager` | Upravljanje feature-ima | active | — |
| `admin.subscriptions` | Pretplate | coming_soon | — |
| `admin.email_campaigns` | Email kampanje | coming_soon | — |

### Frontend Implementation

```typescript
// composables/useFeatures.ts
export function useFeatures() {
  const features = useState<FeatureFlag[]>('features', () => [])

  async function loadFeatures() {
    const supabase = useSupabase()
    const { data } = await supabase
      .from('feature_flags')
      .select('*')
      .order('sort_order')
    features.value = data ?? []
  }

  function isActive(key: string): boolean {
    const f = features.value.find(f => f.key === key)
    return f?.status === 'active'
  }

  function isComingSoon(key: string): boolean {
    const f = features.value.find(f => f.key === key)
    return f?.status === 'coming_soon'
  }

  function isVisible(key: string): boolean {
    const f = features.value.find(f => f.key === key)
    return f?.status === 'active' || f?.status === 'coming_soon'
  }

  function requiredTier(key: string): string {
    return features.value.find(f => f.key === key)?.required_tier ?? 'free'
  }

  return { features, loadFeatures, isActive, isComingSoon, isVisible, requiredTier }
}
```

### Admin Feature Manager UI

```
/admin/features
┌──────────────────────────────────────────────────┐
│ Upravljanje Feature-ima                           │
├──────────────────────────────────────────────────┤
│                                                   │
│  [Portal]                                         │
│  ┌─────────────────────────────────────────────┐ │
│  │ ● Kontrolna tabla     [Active ▼]   Free     │ │
│  │ ● Moja djeca          [Active ▼]   Free     │ │
│  │ ● Radionice           [Active ▼]   Free     │ │
│  │ ● Dječiji pasoš       [Active ▼]   Paid     │ │
│  │ ● Kućne aktivnosti    [Active ▼]   Paid     │ │
│  │ ○ Foto galerija       [Coming Soon ▼] Paid  │ │
│  │ ○ Poruke              [Coming Soon ▼] Paid  │ │
│  │ ○ Zajednica           [Coming Soon ▼] Premium│ │
│  │ ○ Video tutorijali    [Coming Soon ▼] Premium│ │
│  │ ✕ Pitaj stručnjaka    [Hidden ▼]   Premium  │ │
│  └─────────────────────────────────────────────┘ │
│                                                   │
│  [Admin]                                          │
│  ┌─────────────────────────────────────────────┐ │
│  │ ● Kontrolna tabla     [Active ▼]            │ │
│  │ ● Djeca               [Active ▼]            │ │
│  │ ... etc                                      │ │
│  └─────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────┘
```

### "Coming Soon" Badge Component

When a feature is `coming_soon`, the navigation shows it with a badge but clicking
shows a modal:

```
┌───────────────────────────────────────┐
│                                       │
│   🔜 Uskoro dostupno!                │
│                                       │
│   Foto galerija je u pripremi.       │
│   Obavijestit ćemo vas čim bude     │
│   spremna!                            │
│                                       │
│   [Obavijesti me]  [Zatvori]         │
│                                       │
└───────────────────────────────────────┘
```

Clicking "Obavijesti me" saves interest in a `feature_interests` table:

```sql
CREATE TABLE public.feature_interests (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id),
  feature_key TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, feature_key)
);
```

This lets admin see demand: "87 users want Photo Gallery" → prioritize development.

---

## Part 2: Subscription Tiers

### Three Tiers

| | Free (Besplatno) | Paid (Osnovni) | Premium |
|---|---|---|---|
| **Cijena** | 0 KM/mj | 15 KM/mj | 30 KM/mj |
| **Kako se dobije** | Registracija/prijava na radionicu | Uplata | Uplata |
| | | | |
| **Javni sajt** | ✅ Blog, resursi, kontakt | ✅ | ✅ |
| **Registracija + profil** | ✅ | ✅ | ✅ |
| **Prijava na radionice** | ✅ | ✅ | ✅ |
| **Pregled radionica** | ✅ Nazivi + datumi | ✅ + materijali | ✅ + materijali |
| **Djeca (profili)** | ✅ 1 dijete | ✅ Do 3 djece | ✅ Neograničeno |
| | | | |
| **Dječiji pasoš** | ❌ | ✅ Pregled domena | ✅ Puni + radar + PDF |
| **Opservacije** | ❌ | ✅ Poslednje 3 | ✅ Sve opservacije |
| **Kućne aktivnosti** | ❌ | ✅ 2/mjesec | ✅ Sve |
| **Foto galerija** | ❌ | ❌ | ✅ |
| **Kvartalni PDF izvještaj** | ❌ | ❌ | ✅ Auto-generiran |
| | | | |
| **Poruke sa voditeljima** | ❌ | ✅ | ✅ |
| **Forum/zajednica** | ❌ | ❌ | ✅ |
| **Video tutorijali** | ❌ | ❌ | ✅ |
| **Pitaj stručnjaka** | ❌ | ❌ | ✅ 1x mjesečno |
| | | | |
| **Besplatni PDF resursi** | ✅ 3 ukupno | ✅ Svi | ✅ Svi |
| **Email obavještenja** | ✅ Osnovna | ✅ Sve | ✅ Sve + prioritetna |

### Database

```sql
-- Subscription plans (admin-defined)
CREATE TABLE public.subscription_plans (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,                 -- 'free', 'paid', 'premium'
  display_name TEXT NOT NULL,         -- 'Besplatni', 'Osnovni', 'Premium'
  description TEXT,
  price_monthly DECIMAL(10,2) DEFAULT 0,
  price_yearly DECIMAL(10,2) DEFAULT 0, -- discount for yearly
  max_children INT DEFAULT 1,
  features JSONB DEFAULT '{}',        -- tier-specific feature overrides
  is_active BOOLEAN DEFAULT true,
  sort_order INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- User subscriptions
CREATE TABLE public.subscriptions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) NOT NULL,
  plan_id UUID REFERENCES subscription_plans(id) NOT NULL,
  status TEXT NOT NULL DEFAULT 'active'
    CHECK (status IN ('active', 'past_due', 'cancelled', 'expired')),
  period TEXT DEFAULT 'monthly'
    CHECK (period IN ('monthly', 'yearly')),
  starts_at TIMESTAMPTZ DEFAULT now(),
  ends_at TIMESTAMPTZ,
  cancelled_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_subscriptions_user ON subscriptions(user_id);
CREATE INDEX idx_subscriptions_status ON subscriptions(status);

-- Payment records
CREATE TABLE public.payments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  subscription_id UUID REFERENCES subscriptions(id),
  user_id UUID REFERENCES profiles(id) NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  currency TEXT DEFAULT 'BAM',
  status TEXT DEFAULT 'pending'
    CHECK (status IN ('pending', 'completed', 'failed', 'refunded')),
  payment_method TEXT,                -- 'bank_transfer', 'cash', 'card'
  reference TEXT,                     -- payment reference / receipt number
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);
```

### Tier Check in Frontend

```typescript
// composables/useTier.ts
export function useTier() {
  const { user } = useAuth()
  const supabase = useSupabase()

  const subscription = useState<Subscription | null>('subscription', () => null)
  const tierName = computed(() => subscription.value?.plan?.name ?? 'free')

  async function loadSubscription() {
    if (!user.value) return
    const { data } = await supabase
      .from('subscriptions')
      .select('*, plan:subscription_plans(*)')
      .eq('user_id', user.value.id)
      .eq('status', 'active')
      .single()
    subscription.value = data
  }

  function hasAccess(requiredTier: string): boolean {
    const tiers = ['free', 'paid', 'premium']
    const userLevel = tiers.indexOf(tierName.value)
    const requiredLevel = tiers.indexOf(requiredTier)
    return userLevel >= requiredLevel
  }

  function canAddChild(): boolean {
    const max = subscription.value?.plan?.max_children ?? 1
    // compare with actual child count
    return true // placeholder
  }

  return { subscription, tierName, loadSubscription, hasAccess, canAddChild }
}
```

### Upgrade Prompt Component

When a user tries to access a feature above their tier:

```
┌───────────────────────────────────────┐
│                                       │
│   🔒 Ova funkcija zahtijeva          │
│      Osnovni plan                     │
│                                       │
│   Nadogradite na Osnovni plan za     │
│   samo 15 KM/mjesečno i pristupite: │
│                                       │
│   ✅ Dječiji pasoš                   │
│   ✅ Opservacije voditelja           │
│   ✅ Kućne aktivnosti                │
│   ✅ Poruke sa voditeljima           │
│                                       │
│   [Nadogradi]  [Možda kasnije]       │
│                                       │
└───────────────────────────────────────┘
```

---

## Part 3: Registration Flow (Workshop = Registration)

### Core Concept

**Registering for a workshop IS creating an account.**

The primary acquisition funnel:
1. Parent sees workshop/event on website or social media
2. Clicks "Prijavi se na radionicu"
3. Fills in: name, email, phone, child name + age
4. Gets account created (free tier) + workshop registration confirmed
5. Receives email: welcome + workshop details + login credentials

### Public Event Listing

Public page showing upcoming workshops/events (no auth required):

```
sarenasfera.com/events (or /radionice)

┌──────────────────────────────────────────────────┐
│  Nadolazeće radionice i događaji                  │
│                                                    │
│  ┌──────────────────────────────────────────────┐│
│  │ 🎨 Kreativni svijet boja                     ││
│  │ Subota, 15. mart 2026 | 10:00 - 11:30       ││
│  │ Uzrast: 3-5 godina | Lokacija: Centar        ││
│  │ Slobodna mjesta: 8/12                        ││
│  │                                               ││
│  │ [Prijavi dijete →]                            ││
│  └──────────────────────────────────────────────┘│
│                                                    │
│  ┌──────────────────────────────────────────────┐│
│  │ 🧠 Mali istraživači - NTC program            ││
│  │ Nedjelja, 16. mart 2026 | 10:00 - 11:30     ││
│  │ Uzrast: 4-6 godina | Lokacija: Centar        ││
│  │ Slobodna mjesta: 5/12                        ││
│  │                                               ││
│  │ [Prijavi dijete →]                            ││
│  └──────────────────────────────────────────────┘│
└──────────────────────────────────────────────────┘
```

### Workshop Registration Form (creates account)

```
┌──────────────────────────────────────────────────┐
│  Prijava na radionicu                              │
│  "Kreativni svijet boja" - 15. mart 2026          │
│                                                    │
│  ── Podaci o roditelju ──                         │
│  Ime i prezime:  [________________]               │
│  Email:          [________________]               │
│  Telefon:        [________________]               │
│                                                    │
│  ── Podaci o djetetu ──                           │
│  Ime djeteta:    [________________]               │
│  Datum rođenja:  [__/__/____]                     │
│  Alergije/posebne potrebe: [________________]     │
│                                                    │
│  □ Slažem se sa uslovima korištenja               │
│  □ Želim primati obavještenja o programu          │
│                                                    │
│  [Prijavi se na radionicu →]                      │
│                                                    │
│  Već imate račun? [Prijavite se]                  │
└──────────────────────────────────────────────────┘
```

### Database: Events/Public Workshops

```sql
-- Public events (workshops open for registration)
CREATE TABLE public.events (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  slug TEXT UNIQUE,
  description TEXT,
  domain TEXT CHECK (domain IN ('emotional', 'social', 'creative', 'cognitive', 'motor', 'language', 'mixed')),
  event_date DATE NOT NULL,
  start_time TIME,
  end_time TIME,
  location_id UUID REFERENCES locations(id),
  location_name TEXT,                -- fallback if no location record
  max_capacity INT DEFAULT 12,
  min_age_months INT,                -- minimum age in months
  max_age_months INT,                -- maximum age in months
  price DECIMAL(10,2) DEFAULT 0,     -- 0 = free event
  cover_image_url TEXT,
  is_published BOOLEAN DEFAULT false,
  is_recurring BOOLEAN DEFAULT false,
  recurring_schedule JSONB,          -- e.g. {"day": "saturday", "frequency": "weekly"}
  registration_opens_at TIMESTAMPTZ,
  registration_closes_at TIMESTAMPTZ,
  session_id UUID REFERENCES sessions(id), -- link to internal session (optional)
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_events_date ON events(event_date);
CREATE INDEX idx_events_published ON events(is_published);

-- Event registrations
CREATE TABLE public.event_registrations (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  event_id UUID REFERENCES events(id) NOT NULL,
  -- Parent info (may or may not have account yet)
  user_id UUID REFERENCES profiles(id),      -- null until account created
  parent_name TEXT NOT NULL,
  parent_email TEXT NOT NULL,
  parent_phone TEXT,
  -- Child info
  child_name TEXT NOT NULL,
  child_date_of_birth DATE,
  child_allergies TEXT,
  child_special_needs TEXT,
  -- Registration details
  status TEXT DEFAULT 'confirmed'
    CHECK (status IN ('pending', 'confirmed', 'waitlist', 'cancelled', 'attended', 'no_show')),
  notes TEXT,
  marketing_consent BOOLEAN DEFAULT false,
  -- After account creation
  child_id UUID REFERENCES children(id),     -- linked after account is created
  -- Tracking
  source TEXT,                                -- 'website', 'instagram', 'referral'
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_event_reg_event ON event_registrations(event_id);
CREATE INDEX idx_event_reg_email ON event_registrations(parent_email);
CREATE INDEX idx_event_reg_user ON event_registrations(user_id);
```

### Registration Flow (Backend Logic)

```
1. Parent fills workshop registration form
2. System checks: does email already exist?
   ├── YES: Link registration to existing user
   │        → Show "Već imate račun, prijavite se za detalje"
   │        → Create event_registration with user_id
   └── NO: Create new account
           → supabase.auth.signUp(email, auto-password)
           → Profile created (trigger)
           → subscription = free tier (auto)
           → Create child record
           → Link parent_children
           → Create event_registration
           → Send welcome email + workshop confirmation + login link
3. Capacity check: if full → status = 'waitlist'
4. Confirmation email sent with:
   - Workshop details (date, time, location, what to bring)
   - Account credentials (magic link to set password)
   - Link to portal
```

### Post-Registration Flow

After the workshop happens:
1. Staff marks attendance (from admin panel)
2. event_registration.status → 'attended' or 'no_show'
3. If attended → staff enters observation
4. Parent gets email: "Your child's observation is ready"
5. Parent logs in → sees observation (if paid tier)
6. If free tier → sees teaser: "Upgrade to see full observations"

### Conversion Funnel

```
Public Event Page (100 visitors)
  ↓
Workshop Registration Form (30 fill in)
  ↓
Free Account Created (30 new users)
  ↓
Workshop Attended (25 show up)
  ↓
Observation Email Sent (25 parents notified)
  ↓
Portal Visit (20 log in)
  ↓
Upgrade to Paid (5-8 convert = 15-25% conversion)
  ↓
Upgrade to Premium (2-3 after 3 months)
```

---

## Part 4: Admin Panel Additions

### Event Management (Admin)

```
/admin/events
┌──────────────────────────────────────────────────┐
│ Radionice i događaji                              │
│                                                    │
│ [+ Novi događaj]  [Kalendar]  [Lista]             │
│                                                    │
│ Nadolazeći:                                       │
│ ┌──────────────────────────────────────────────┐ │
│ │ Kreativni svijet boja | Sub 15.03 | 10:00    │ │
│ │ Prijave: 8/12 | Status: Otvoreno            │ │
│ │ [Prijave] [Uredi] [Kopiraj]                  │ │
│ └──────────────────────────────────────────────┘ │
│                                                    │
│ Prošli:                                           │
│ ┌──────────────────────────────────────────────┐ │
│ │ Mali istraživači | Sub 08.03 | 10:00         │ │
│ │ Prisustvo: 10/12 | Status: Završeno          │ │
│ │ [Prisustvo] [Opservacije] [Statistika]       │ │
│ └──────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────┘
```

### Registration View (Admin)

```
/admin/events/:id/registrations
┌──────────────────────────────────────────────────┐
│ Prijave: "Kreativni svijet boja" (8/12)          │
│                                                    │
│ Ime roditelja    | Dijete   | Uzrast | Status    │
│ ─────────────────┼──────────┼────────┼────────── │
│ Ana Hodžić       | Lejla    | 4g     | ✅ Potvrđ │
│ Mirza Bašić      | Amar     | 3g     | ✅ Potvrđ │
│ Selma Fazlić     | Hana     | 5g     | ⏳ Lista  │
│                                                    │
│ [Exportuj CSV]  [Pošalji podsjetnik]             │
└──────────────────────────────────────────────────┘
```

### Feature Manager (Admin)

New admin page to toggle feature flags (see Part 1).

### Subscription Management (Admin)

```
/admin/subscriptions
┌──────────────────────────────────────────────────┐
│ Pretplate                                         │
│                                                    │
│ Ukupno: 45 Free | 12 Paid | 3 Premium           │
│                                                    │
│ Korisnik       | Plan     | Status  | Od         │
│ ───────────────┼──────────┼─────────┼─────────── │
│ Ana Hodžić     | Paid     | Active  | 01.02.2026 │
│ Mirza Bašić    | Free     | Active  | 15.02.2026 │
│ Selma Fazlić   | Premium  | Active  | 01.01.2026 │
│                                                    │
│ [Dodijeli plan]  [Exportuj]                      │
└──────────────────────────────────────────────────┘
```

Note: Initially, admin manually upgrades users (bank transfer / cash).
Online payment integration comes later (Phase 2+).

---

## Part 5: Profile Tier Indicator

Add `subscription_tier` to profiles for quick access:

```sql
ALTER TABLE public.profiles
  ADD COLUMN subscription_tier TEXT DEFAULT 'free'
    CHECK (subscription_tier IN ('free', 'paid', 'premium'));
```

Updated by trigger when subscription changes:

```sql
CREATE OR REPLACE FUNCTION update_profile_tier()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE profiles SET subscription_tier = (
    SELECT COALESCE(
      (SELECT sp.name FROM subscriptions s
       JOIN subscription_plans sp ON s.plan_id = sp.id
       WHERE s.user_id = NEW.user_id AND s.status = 'active'
       ORDER BY sp.sort_order DESC LIMIT 1),
      'free'
    )
  ) WHERE id = NEW.user_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_subscription_change
  AFTER INSERT OR UPDATE ON subscriptions
  FOR EACH ROW EXECUTE FUNCTION update_profile_tier();
```

---

## Summary: What Launches First (Soft Launch)

### Day 1 (Soft Launch)
- Public site: landing, program info, blog, contact
- Event/workshop listing (public, no auth)
- Workshop registration form (creates free account)
- Admin: event management, registration list, attendance
- Feature flags: everything else marked "Coming Soon"

### Week 2-4 (Gradual Release)
- Portal: dashboard, children list
- Admin: children, groups, observations
- Toggle features from "Coming Soon" → "Active" in admin

### Month 2+ (Paid Features)
- Activate "Dječiji pasoš" for paid users
- Activate "Kućne aktivnosti" for paid users
- Admin: manual subscription management
- Upgrade prompts in portal

### Month 3+ (Premium)
- Quarterly PDF reports
- Photo gallery
- Video resources
- Community forum
