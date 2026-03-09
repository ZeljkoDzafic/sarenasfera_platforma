# 18 - UI & Design Guidelines

## Brand Identity

**Name:** Sarena Sfera ("Colorful Sphere")
**Logo:** Use the official logo from sarenasfera.com — place in `/public/logo.svg` and `/public/logo.png`
**Tagline:** Kreativni centar za djecu (Creative Center for Children)

The platform name literally means "Colorful" — the UI must reflect this with
vibrant, playful, and warm visual design throughout.

---

## Color Palette (from sarenasfera.com)

### Brand Colors

| Color | Hex | Usage |
|-------|-----|-------|
| **Red** | `#cf2e2e` | CTAs, alerts, emotional domain |
| **Blue** | `#0693e3` | Links, info, cognitive domain |
| **Purple** | `#9b51e0` | Primary action, premium, creative domain |
| **Pink** | `#f78da7` | Soft accents, badges, language domain |
| **Amber** | `#fcb900` | Warnings, stars, social domain |
| **Green** | `#00d084` | Success, progress, motor domain |

### Primary Color (Purple)

Purple (`#9b51e0`) is the main action color — buttons, links, active states.
Full scale from `primary-50` (lightest) to `primary-950` (darkest) in Tailwind config.

### Domain Colors

Each development domain has its own vibrant color, used consistently across:
- Radar chart segments
- Domain cards and badges
- Sidebar icons and filters
- Milestone markers
- Progress indicators

| Domain | Color | Hex | Icon Idea |
|--------|-------|-----|-----------|
| Emocionalni | Red | `#cf2e2e` | Heart |
| Socijalni | Amber | `#fcb900` | People/Hands |
| Kreativni | Purple | `#9b51e0` | Palette/Star |
| Kognitivni | Blue | `#0693e3` | Lightbulb/Brain |
| Motoricki | Green | `#00d084` | Running/Body |
| Jezicki | Pink | `#f78da7` | Speech Bubble |

---

## Typography

### Fonts (Google Fonts, free)

| Font | Usage | Why |
|------|-------|-----|
| **Nunito** | Body text, UI elements | Rounded, friendly, excellent readability |
| **Baloo 2** | Headings, display text | Playful, child-friendly, works with Bosnian characters |

Both fonts support Latin Extended (required for BHS: č, ć, š, ž, đ).

### Loading

```html
<!-- In nuxt.config.ts or app.vue <head> -->
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Nunito:wght@400;600;700;800&family=Baloo+2:wght@500;600;700;800&display=swap" rel="stylesheet">
```

### Scale

| Element | Font | Weight | Size |
|---------|------|--------|------|
| Page title (h1) | Baloo 2 | 700 | 2rem (32px) |
| Section title (h2) | Baloo 2 | 600 | 1.5rem (24px) |
| Card title (h3) | Nunito | 700 | 1.25rem (20px) |
| Body text | Nunito | 400 | 1rem (16px) |
| Small text | Nunito | 400 | 0.875rem (14px) |
| Button text | Nunito | 700 | 0.875rem-1rem |
| Badge text | Nunito | 600 | 0.75rem (12px) |

---

## UI Components Style

### General Principles

1. **Colorful, not cluttered** — use color intentionally, white space generously
2. **Rounded corners** — everything uses `rounded-xl` to `rounded-2xl` (friendly, soft)
3. **Soft shadows** — `shadow-soft` or `shadow-card` (not harsh drop shadows)
4. **Playful but professional** — parents trust the platform with their child's data
5. **Mobile-first** — staff use phones at workshops, parents browse on mobile
6. **Accessible** — WCAG AA contrast ratios, focus states, ARIA labels

### Buttons

```
Primary:    bg-primary-500 text-white rounded-xl px-6 py-3 font-bold shadow-colorful
            hover:bg-primary-600 transition-all

Secondary:  bg-white border-2 border-primary-500 text-primary-500 rounded-xl
            hover:bg-primary-50

Danger:     bg-brand-red text-white rounded-xl
            hover:opacity-90

Success:    bg-brand-green text-white rounded-xl

Ghost:      bg-transparent text-primary-500 hover:bg-primary-50 rounded-xl
```

### Cards

```
Standard:   bg-white rounded-2xl shadow-card p-6
            hover:shadow-lg transition-shadow

Domain:     bg-white rounded-2xl shadow-card p-6
            border-l-4 border-domain-{color}

Featured:   bg-gradient-to-br from-primary-500 to-brand-pink rounded-2xl
            text-white p-6 shadow-colorful
```

### Domain Cards (6 domains — hero feature)

Each domain card has:
- Domain color as left border or top gradient bar
- Domain icon (matching color)
- White background with subtle domain-colored shadow

```html
<!-- Example: Emotional domain card -->
<div class="bg-white rounded-2xl shadow-card overflow-hidden">
  <div class="h-2 bg-brand-red"></div>
  <div class="p-6">
    <div class="w-12 h-12 rounded-xl bg-red-50 flex items-center justify-center mb-3">
      <HeartIcon class="w-6 h-6 text-brand-red" />
    </div>
    <h3 class="font-display font-bold text-lg">Emocionalni razvoj</h3>
    <p class="text-gray-600 mt-2">Prepoznavanje i regulacija emocija...</p>
  </div>
</div>
```

### Navigation

```
Sidebar:    bg-white border-r border-gray-100
            Active item: bg-primary-50 text-primary-600 border-l-3 border-primary-500
            Hover: bg-gray-50
            Icons: colored per section (domain colors for child pages)

Top nav:    bg-white shadow-sm
            Logo left, user avatar + notifications right
            Mobile: hamburger → slide-out sidebar
```

### Badges & Tags

```
Tier badge:    Free: bg-gray-100 text-gray-600
               Paid: bg-amber-100 text-amber-700
               Premium: bg-purple-100 text-purple-700 (with sparkle)

Domain tag:    bg-{domain-color}/10 text-{domain-color} rounded-full px-3 py-1 text-sm font-semibold

Status:        Active: bg-green-100 text-green-700
               Pending: bg-amber-100 text-amber-700
               Inactive: bg-gray-100 text-gray-500

Parent badge:  Novi: bg-green-50 text-green-600 (seedling icon)
               Aktivan: bg-green-100 text-green-700 (leaf icon)
               Posvecen: bg-green-200 text-green-800 (tree icon)
               Ambasador: bg-amber-100 text-amber-700 (star icon)
               Pionir: bg-purple-100 text-purple-700 (medal icon)
```

### Charts (Radar, Line, Bar)

Use brand colors for chart datasets:
- Current period: `#9b51e0` (primary purple)
- Previous period: `#0693e3` (brand blue) with dashed line
- Age average: `#00d084` (brand green) with dotted line
- Domain radar segments: use each domain's color

Chart.js config:
```javascript
{
  borderWidth: 2,
  pointRadius: 5,
  pointBackgroundColor: '#fff',
  pointBorderWidth: 2,
  fill: true,
  backgroundColor: 'rgba(155, 81, 224, 0.1)', // primary with opacity
}
```

---

## Page-Specific Design

### Landing Page

```
Hero:       Full-width gradient (purple → pink → amber)
            "Sarena Sfera" logo large, centered
            Tagline in white, Baloo 2 font
            CTA buttons: white with colored text

Domains:    6 colorful cards in 2x3 or 3x2 grid
            Each with domain color top bar + icon
            Hover: slight lift + shadow increase

Features:   Alternating left/right layout with illustrations
            Soft pastel backgrounds per section

CTA:        Gradient banner (brand colors)
            "Prijavite dijete" prominent button
```

### Portal Dashboard

```
Welcome:    Greeting card with user name
            Soft gradient background (purple → pink at 10% opacity)

Child cards: Each child as a card with:
             - Photo (rounded-full, colorful ring border)
             - Name + age
             - Mini radar chart (domain colors)
             - Quick link buttons

Stats:      4 stat cards in a row
            Each with different brand color icon
            Number in bold, label below
```

### Child Passport Page

```
Header:     Child photo (large, rounded-2xl)
            Name + group + age
            6 mini domain badges with scores

Radar:      Large centered radar chart
            6-color domain segments
            Period selector above (pills with active highlight)

Domains:    6 clickable domain cards below radar
            Domain color left border
            Current score as colored progress bar
            "Pogledaj detalje" link
```

---

## Logo Usage

### Where to Show Logo

| Location | Size | Variant |
|----------|------|---------|
| Public header | 160px width | Full logo (icon + text) |
| Portal sidebar top | 140px width | Full logo |
| Admin sidebar top | 140px width | Full logo |
| Login/register page | 200px width | Full logo, centered |
| Email templates | 120px width | Full logo |
| PDF reports header | 100px width | Full logo |
| Favicon | 32x32 / 16x16 | Icon only (the sphere) |
| Mobile nav | 120px width | Full logo |

### Logo Files Needed

```
/public/logo.svg          -- primary logo (vector, scalable)
/public/logo.png          -- fallback (PNG, 400px wide)
/public/logo-white.svg    -- white version for dark backgrounds
/public/logo-icon.svg     -- icon only (sphere) for favicon/small spaces
/public/favicon.ico       -- 32x32 favicon
/public/apple-touch-icon.png -- 180x180 for iOS
```

**Source:** Download/export from sarenasfera.com and place in `/public/`

---

## Illustration Style

Use simple, flat vector illustrations with brand colors:
- Children playing, learning, creating
- Parents with children
- Workshop scenes
- Domain-related imagery (heart for emotional, palette for creative, etc.)

Recommended free sources:
- unDraw (undraw.co) — customize with brand purple `#9b51e0`
- Storyset (storyset.com) — kid-friendly illustrations
- Humaaans — customizable people illustrations

---

## Responsive Breakpoints

```
sm:  640px   (mobile landscape)
md:  768px   (tablet)
lg:  1024px  (laptop)
xl:  1280px  (desktop)
2xl: 1536px  (wide desktop)
```

### Mobile Priorities
- Touch targets: minimum 44x44px
- Sidebar: off-screen, slide-in on hamburger tap
- Cards: full-width stacked
- Charts: scroll horizontally if needed
- Staff observation entry: optimized for one-thumb use

---

## Dark Mode

Not planned for MVP. Light mode only. Consider for Phase 3+.

---

## Summary

The Sarena Sfera UI should feel like walking into a bright, colorful children's
creative center — warm, inviting, trustworthy, and full of energy. Every screen
should use at least 2-3 brand colors intentionally. The 6 domain colors are the
visual backbone of the platform — they appear everywhere from the landing page
to the child's passport to the admin observation forms.
