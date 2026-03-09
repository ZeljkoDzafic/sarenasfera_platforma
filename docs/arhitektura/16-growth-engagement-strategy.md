# 16 - Growth, Engagement & Retention Strategy

## Overview

Platform growth strategy based on three pillars:
1. **Acquisition** — get parents to register (quiz + workshop registration)
2. **Engagement** — keep them active (activities, progress, community)
3. **Monetization** — convert free → paid → premium (value gates + social proof)

---

## 1. Development Assessment Quiz (Lead Magnet)

### What
A free, public quiz that assesses a child's developmental profile across 6 domains.
No registration required. Result shown immediately. Email capture optional.

### Why
- Parents get immediate value (mini report)
- Platform demonstrates expertise before asking for anything
- Quiz answers feed into personalized recommendations after registration
- Social shareability ("Podijelite rezultat")

### Flow
```
[Public quiz page] → 8-10 questions (1 per screen)
     → Results: mini radar chart + strengths + areas to improve
     → CTA: "Pošaljite rezultate na email" (lead capture)
     → CTA: "Registrujte se besplatno" or "Prijavite dijete na radionicu"
```

### Questions (draft)
```
1. Koliko godina ima vaše dijete?
   [2-3 / 3-4 / 4-5 / 5-6]

2. Da li vaše dijete pohađa vrtić ili organizovane aktivnosti?
   [Da, redovno / Ponekad / Ne]

3. Kako vaše dijete reaguje na nove situacije i nepoznate ljude?
   [Radoznalo prilazi / Posmatra sa strane / Traži roditelja / Zavisi od situacije]

4. Koliko vremena dijete provodi u kreativnim aktivnostima (crtanje, građenje, igra uloga)?
   [Svaki dan / Nekoliko puta sedmično / Jednom sedmično / Rijetko]

5. Da li dijete voli grupne aktivnosti sa drugom djecom?
   [Obožava, uvijek traži društvo / Voli, ali mu treba vrijeme za zagrijavanje /
    Preferira samostalnu igru / Izbjegava grupe]

6. Koje aktivnosti vaše dijete najviše voli? (izaberite do 3)
   [Crtanje i bojenje / Građenje i slagalice / Trčanje i fizička igra /
    Priče i knjige / Muzika i ples / Igre uloga i maštanje]

7. Kako biste opisali govorni razvoj vašeg djeteta u odnosu na vršnjake?
   [Naprednije / Prosječno / Malo sporije / Nisam siguran/na]

8. Da li ste primijetili nešto što vas brine u razvoju djeteta?
   [Ne, sve izgleda u redu / Govor i komunikacija / Motoričke vještine /
    Socijalizacija / Koncentracija i pažnja / Emocionalne reakcije]

9. Šta najviše očekujete od razvojnog programa?
   [Praćenje napretka djeteta / Socijalizacija s vršnjacima /
    Nove aktivnosti i ideje / Stručna podrška i savjeti / Sve navedeno]
```

### Result Page
```
┌──────────────────────────────────────────────────┐
│  Razvojni profil vašeg djeteta                    │
│                                                    │
│        [Radar chart — 6 domains]                  │
│                                                    │
│  Snage vašeg djeteta:                             │
│  ⭐ Kreativni razvoj — odlično koristi maštu     │
│  ⭐ Motorički razvoj — aktivno i koordinirano    │
│                                                    │
│  Područja za dodatni poticaj:                     │
│  📈 Socijalni razvoj — podsticati grupne igre    │
│  📈 Jezički razvoj — čitati zajedno svaki dan    │
│                                                    │
│  Preporučene radionice za vaše dijete:            │
│  🎨 "Kreativni svijet boja" — Sub 15.03          │
│  💬 "Pričam ti priču" — Sub 22.03                │
│                                                    │
│  ┌────────────────────────────────────────────┐   │
│  │ [📧 Pošaljite rezultate na email]          │   │
│  │ [📝 Registrujte se besplatno]              │   │
│  │ [🎯 Prijavite dijete na radionicu]         │   │
│  └────────────────────────────────────────────┘   │
│                                                    │
│  [Podijelite rezultat] 📱 WhatsApp  📘 Facebook  │
└──────────────────────────────────────────────────┘
```

### Database
```sql
CREATE TABLE public.quiz_responses (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  -- Optional user link (null if anonymous)
  user_id UUID REFERENCES profiles(id),
  email TEXT,                          -- captured if they opt in
  -- Child info
  child_age_range TEXT,
  -- Answers (JSONB for flexibility)
  answers JSONB NOT NULL,
  -- Calculated results
  results JSONB NOT NULL,              -- { emotional: 3, social: 2, ... }
  -- Tracking
  source TEXT,                         -- utm_source
  completed BOOLEAN DEFAULT true,
  converted BOOLEAN DEFAULT false,     -- did they register after?
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_quiz_responses_email ON quiz_responses(email);
CREATE INDEX idx_quiz_responses_converted ON quiz_responses(converted);
```

---

## 2. Zero-Friction Registration

### Principle
Never show pricing during registration. The goal is to get the parent IN first.

### Registration entry points (all create Free account):
1. **Workshop registration** → account created automatically
2. **Quiz result** → "Registrujte se za puni izvještaj"
3. **Standard signup** → name, email, password (no tier selection)
4. **Google OAuth** → one-click signup

### Post-registration onboarding:
```
Step 1: Dobro došli! Dodajte vaše dijete.
        [Ime djeteta] [Datum rođenja]

Step 2: Izaberite grupu za radionicu.
        [Mala 2-3g] [Srednja 3-4g] [Velika 5-6g]

Step 3: Gotovi ste! Evo šta možete dalje:
        → Pregledajte nadolazeće radionice
        → Pogledajte rezultate razvojne procjene
        → Istražite kućne aktivnosti
```

---

## 3. Parent Status System (Gamification)

### Status Levels

| Status | Criteria | Badge | Benefits |
|--------|----------|-------|----------|
| **Novi roditelj** | Just registered | 🌱 | Access to free features |
| **Aktivan roditelj** | 4+ workshops attended | 🌿 | Visibility in community |
| **Posvećen roditelj** | 12+ workshops + 5 home activities | 🌳 | Featured in newsletter |
| **Ambasador** | 3+ referrals OR 10+ forum posts | ⭐ | Special recognition |
| **Roditelj Pionir** | First 50 families (permanent) | 🏅 | Lifetime price lock |

### Badge Display
- Profile page header (next to name)
- Community forum posts (next to username)
- Leaderboard in community sidebar ("Top roditelji")

### Database
```sql
CREATE TABLE public.badges (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  key TEXT NOT NULL UNIQUE,           -- 'novi', 'aktivan', 'posvecen', 'ambasador', 'pionir'
  name TEXT NOT NULL,                 -- 'Aktivan roditelj'
  description TEXT,
  icon TEXT,                          -- emoji or icon name
  criteria JSONB,                     -- automated check rules
  sort_order INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE public.user_badges (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) NOT NULL,
  badge_id UUID REFERENCES badges(id) NOT NULL,
  awarded_at TIMESTAMPTZ DEFAULT now(),
  awarded_by UUID REFERENCES profiles(id), -- null = automatic, set = manual
  UNIQUE(user_id, badge_id)
);
```

---

## 4. Referral System ("Preporuči prijatelja")

### How it works
```
Parent A gets unique link: sarenasfera.com/r/ABC123
  → Shares via WhatsApp, Viber, Facebook, email
  → Parent B clicks link → registers → attends first workshop
  → Parent A gets: 1 month free Paid tier
  → Parent B gets: 1 month free Paid trial
```

### Portal page: `/portal/referral`
```
┌──────────────────────────────────────────────────┐
│  Preporuči prijatelja                             │
│                                                    │
│  Vaš link: sarenasfera.com/r/ABC123  [Kopiraj]   │
│                                                    │
│  [WhatsApp] [Viber] [Facebook] [Email]            │
│                                                    │
│  Vaše preporuke:                                  │
│  ✅ Ana M. — registrovana, prisustvovala          │
│  ⏳ Mirza B. — registrovan, čeka radionicu        │
│  📧 Selma F. — pozivnica poslana                  │
│                                                    │
│  Nagrade: 2 mjeseca besplatnog Osnovnog plana     │
│  zarađeno od preporuka!                           │
└──────────────────────────────────────────────────┘
```

### Database
```sql
CREATE TABLE public.referrals (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  referrer_id UUID REFERENCES profiles(id) NOT NULL,
  referral_code TEXT NOT NULL UNIQUE,
  referred_email TEXT,
  referred_user_id UUID REFERENCES profiles(id),
  status TEXT DEFAULT 'pending'
    CHECK (status IN ('pending', 'registered', 'attended', 'converted')),
  referrer_reward_granted BOOLEAN DEFAULT false,
  referred_reward_granted BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_referrals_code ON referrals(referral_code);
CREATE INDEX idx_referrals_referrer ON referrals(referrer_id);
```

---

## 5. "Roditelji Pioniri" Program

### Concept
First 50 families get exclusive benefits as founding members.
Creates urgency + exclusivity + early community building.

### Benefits
| Benefit | Detail |
|---------|--------|
| Lifetime price lock | 10 KM/mj (Paid) or 20 KM/mj (Premium) — never increases |
| "Roditelj Pionir" badge | Permanent badge on profile + forum |
| Priority access | First to try new features |
| Direct feedback | Channel to team for suggestions |
| Pioneer Wall | Name displayed on public website |
| Free first month | Try Paid tier free before committing |

### Implementation
- Counter on landing page: "Samo X mjesta preostalo od 50!"
- Dedicated page: `/pioniri` with benefits + signup
- After 50 slots filled: "Program zatvoren" + waitlist for next batch
- Badge assigned permanently (survives any plan changes)

---

## 6. Activity Library ("Biblioteka aktivnosti")

### Concept
Searchable, filterable collection of home activities parents can do with children.
The primary content value proposition for Paid tier.

### Organization
```
Filters:
├── Domena: [Emocionalni] [Socijalni] [Kreativni] [Kognitivni] [Motorički] [Jezički]
├── Uzrast: [2-3] [3-4] [4-5] [5-6]
├── Tip: [Kod kuće] [Na otvorenom] [Kreativna] [Fizička] [Senzorna]
├── Trajanje: [5 min] [15 min] [30 min] [45+ min]
└── Materijali: [Bez materijala] [Osnovni] [Specifični]
```

### Activity Card
```
┌─────────────────────────────────────┐
│ [🎨 Creative domain color bar]      │
│                                     │
│ Čarobni kolaž od prirodnih          │
│ materijala                          │
│                                     │
│ 🎂 3-5 god  ⏱️ 30 min  🏠 Kod kuće │
│ 📦 Osnovno: ljepilo, papir, lišće   │
│                                     │
│ [Pogledaj aktivnost →]              │
└─────────────────────────────────────┘
```

### Tier Access
| Tier | Activities Available |
|------|---------------------|
| Free | 10 curated (mix of domains) |
| Paid | 50 activities |
| Premium | All (200+) |

---

## 7. Personalized Development Path

### Concept
Each child gets an auto-generated development path based on:
- Quiz results (if taken)
- Staff observations and assessments
- Workshop attendance history
- Completed home activities

### View: Timeline
```
──── Prošli mjesec ────────────────────
  ✅ Emocionalni: Prepoznaje 4 emocije
  ✅ Motorički: Reže škarama po liniji

──── Trenutni fokus ───────────────────
  🎯 Socijalni: Čeka red u grupi
  🎯 Jezički: Priča u punim rečenicama

──── Nadolazeći ciljevi ───────────────
  🔜 Kognitivni: Sortira po 2 kriterija
  🔜 Kreativni: Koristi 3+ materijala
```

### Recommendations
- "Na osnovu opservacija, preporučujemo radionicu X"
- "Probajte kućnu aktivnost: Y (15 min, bez materijala)"
- "Vašem djetetu bi koristilo više grupnih igara"

---

## 8. Certificates & Achievements

### Child Certificates (printable PDF)
| Certificate | When Earned |
|------------|-------------|
| Dječiji Pasoš | Completion of 12-month program |
| "Kreativni istraživač" | Domain mastery (score 4+ in creative) |
| "Mali govornik" | Domain mastery (score 4+ in language) |
| "Hrabro srce" | Domain mastery (score 4+ in emotional) |
| "Prijatelj grupe" | Domain mastery (score 4+ in social) |
| "Mali sportista" | Domain mastery (score 4+ in motor) |
| "Pametna glavica" | Domain mastery (score 4+ in cognitive) |
| 25 radionica | Attendance milestone |
| 50 radionica | Attendance milestone |
| 96 radionica | Full program completion |

### Parent Badges
| Badge | Criteria | Auto? |
|-------|----------|-------|
| Roditelj Pionir 🏅 | First 50 families | Manual |
| Aktivan roditelj 🌿 | 4+ workshops attended | Auto |
| Posvećen roditelj 🌳 | 12+ workshops + 5 activities | Auto |
| Ambasador ⭐ | 3+ referrals | Auto |
| Redovan ✅ | 8 workshops in 1 month | Auto |
| Zajednica 💬 | 5+ forum contributions | Auto |

---

## 9. Expert Sessions ("Roditeljska radionica") — Premium

### Concept
Online live sessions with child development experts.
Monthly event + recorded archive.

### Format
- 45-60 minute live session
- Hosted by: child psychologist, pedagogist, or speech therapist
- Topics: age-appropriate development, common concerns, activity ideas
- Live Q&A section
- Recording available in library after session

### Tier Access
| | Free | Paid | Premium |
|---|---|---|---|
| Live session | No | No | Yes |
| Recordings | No | No | Yes (all) |
| Ask questions | No | No | Yes (live) |

---

## 10. FAQ Section (Landing Page)

### Questions to address
```
Q: Da li moram dolaziti na SVE radionice?
A: Ne! Program je fleksibilan. Dolazite kad vam odgovara.
   Preporučujemo barem 2 radionice mjesečno za optimalan napredak.

Q: Šta ako moje dijete ima posebne potrebe?
A: Naši voditelji su obučeni za rad sa svom djecom.
   Molimo vas da navedete posebne potrebe pri registraciji
   kako bismo se pripremili.

Q: Kako se čuvaju podaci o mom djetetu?
A: Vaši podaci su zaštićeni enkripcijom. Samo vi i ovlašteni
   voditelji imaju pristup. Ne dijelimo podatke s trećim stranama.

Q: Mogu li otkazati pretplatu?
A: Da, u bilo kojem trenutku. Vaš pristup ostaje aktivan do
   kraja plaćenog perioda. Podaci o djetetu ostaju sačuvani.

Q: Da li roditelji mogu prisustvovati radionicama?
A: Roditelji su dobrodošli na prve 2-3 radionice dok se dijete
   prilagodi. Nakon toga, radionice vode naši stručni voditelji.

Q: Koliko djece je u grupi?
A: Grupe imaju maksimalno 12 djece, što omogućava individualan
   pristup svakom djetetu.

Q: Šta ako moje dijete ne želi ostati bez mene?
A: To je potpuno normalno! Naši voditelji imaju iskustva sa
   periodom prilagodbe. Radimo postupno, u tempu djeteta.
```

---

## Conversion Funnel (Full Picture)

```
[Quiz / Social Media / Word of Mouth]
         ↓
[Public Event Page] — see upcoming workshops
         ↓
[Workshop Registration] — creates FREE account
         ↓
[Workshop Attended] — child has first experience
         ↓
[Observation Email] — "Your child was great today!"
         ↓ (FREE user sees teaser)
[Portal Login] — sees dashboard, limited features
         ↓ (Coming Soon badges create curiosity)
[Upgrade to Paid] — unlock passport, activities, messages
         ↓ (after 3 months, sees value)
[Upgrade to Premium] — PDF reports, video, community, expert
         ↓
[Referral] — "Preporuči prijatelja" → earn free months
         ↓
[Pioneer / Ambassador] — become platform advocate
```
