# 06 - Child Passport (Djeciji Pasos) System

## Overview

The Child Passport is the core feature of the platform. It's a digital development
record for each child, tracking progress across 6 developmental domains over time.

## Data Model

```
Child Passport = child record + assessments + observations + attendance + reports

child (base info)
  ├── assessments[]      (scores 1-5 per domain per quarter)
  ├── observations[]     (staff notes per workshop)
  ├── attendance[]       (workshop attendance + participation level)
  ├── home_activities[]  (parent feedback on home activities)
  └── quarterly_reports[] (auto-generated PDF reports)
```

## The 6 Development Domains

| Domain | Key | What's tracked | Example indicators |
|--------|-----|---------------|-------------------|
| Emotional | `emotional` | Emotion recognition & regulation | Names emotions, handles frustration, shows empathy |
| Social | `social` | Peer and adult relationships | Shares, cooperates, waits turn, communicates needs |
| Creative | `creative` | Expression through various media | Uses materials creatively, experiments, expresses ideas |
| Cognitive | `cognitive` | Thinking, problem solving | Categorizes, solves problems, asks questions |
| Motor | `motor` | Gross and fine motor skills | Movement control, precision, coordination |
| Language | `language` | Understanding and expression | Vocabulary, narration, listening, communication |

## Scoring System

Each domain is scored 1-5 per quarter:

| Score | Label | Description |
|-------|-------|-------------|
| 1 | Beginning | Not yet showing this skill |
| 2 | Emerging | Occasionally shows with support |
| 3 | Developing | Shows consistently with some support |
| 4 | Proficient | Shows independently most of the time |
| 5 | Advanced | Shows independently and helps others |

## Parent View (Portal)

### Dashboard Card
```
┌──────────────────────────────────────────┐
│  [Photo]  Ana Markovic                   │
│           Age: 4 years, 2 months         │
│           Group: Bees (3-4 years)        │
│           Since: September 2025          │
│                                          │
│  ★★★★☆ Emotional    ★★★☆☆ Social       │
│  ★★★★★ Creative     ★★★☆☆ Cognitive    │
│  ★★★★☆ Motor        ★★★★☆ Language     │
│                                          │
│  Attendance: 85% (17/20 workshops)       │
│  [View Full Passport]  [Latest Report]   │
└──────────────────────────────────────────┘
```

### Full Passport Page
```
┌──────────────────────────────────────────┐
│  CHILD PASSPORT - Ana Markovic           │
│                                          │
│  [Radar Chart - 6 domains]              │
│     Current quarter vs previous          │
│                                          │
│  ─── Development Timeline ───            │
│  Q1 2026: ████████░░ 4.2 avg            │
│  Q4 2025: ██████░░░░ 3.5 avg            │
│  Q3 2025: ████░░░░░░ 2.8 avg            │
│                                          │
│  ─── Recent Observations ───             │
│  Mar 3: "Showed great empathy when..."   │
│  Feb 28: "Built a complex tower..."      │
│  Feb 24: "First time sharing toys..."    │
│                                          │
│  ─── Workshop Attendance ───             │
│  [Calendar grid with colored dots]       │
│  Green = present, Gray = absent          │
│                                          │
│  [Download Q1 Report PDF]                │
└──────────────────────────────────────────┘
```

## Staff View (Admin Panel)

### Quick Observation Entry (Mobile Optimized)

This is the most important staff interaction - must be fast and easy.

```
┌──────────────────────────────────────────┐
│  Post-Workshop Observation Entry         │
│                                          │
│  Workshop: "My Emotions - Joy" (Mar 3)   │
│  Group: Bees (3-4 years)                 │
│                                          │
│  ─── Quick Entry Per Child ───           │
│                                          │
│  [Photo] Ana M.                          │
│  Attended: [✓Yes] [No]                   │
│  Participation: [Obs] [Partial] [●Full]  │
│  Quick note: [________________]          │
│  Domain: [Emotional ▼]                   │
│  Photo of work: [📷 Upload]              │
│                                          │
│  [Photo] Marko S.                        │
│  Attended: [✓Yes] [No]                   │
│  ...                                     │
│                                          │
│  [Save All]  [Save & Send to Parents]    │
└──────────────────────────────────────────┘
```

### Pre-built Observation Templates

Staff can pick from common observation snippets to speed up entry:

```javascript
const OBSERVATION_TEMPLATES = {
  emotional: [
    "Named the emotion of {emotion} independently",
    "Showed empathy when a peer was upset",
    "Managed frustration well during {activity}",
    "Expressed feelings through art/words",
    "Needed support to calm down after {situation}"
  ],
  social: [
    "Shared materials with peers without prompting",
    "Cooperated well in group activity",
    "Waited for their turn patiently",
    "Initiated play with another child",
    "Communicated needs verbally to peers"
  ],
  creative: [
    "Used materials in an original way",
    "Combined multiple art techniques",
    "Showed creative problem-solving",
    "Expressed a unique idea during {activity}",
    "Experimented with new materials confidently"
  ],
  // ... motor, cognitive, language
};
```

## Quarterly Report Generation

### Trigger
- Manually by admin (button click)
- Automatically via cron at end of each quarter
- Python FastAPI generates the PDF

### Report Content

```
┌──────────────────────────────────────┐
│  SARENA SFERA DIGITAL                │
│  Quarterly Development Report        │
│                                      │
│  Child: Ana Markovic                 │
│  Period: Q1 2026 (Jan - Mar)         │
│  Group: Bees (3-4 years)            │
│  Leader: Amina Hadzic               │
│                                      │
│  [Radar Chart: 6 domains]           │
│  [Bar Chart: Q1 vs Q4 comparison]   │
│                                      │
│  ATTENDANCE: 85% (17/20 workshops)  │
│                                      │
│  TOP STRENGTHS:                      │
│  1. Creative expression              │
│  2. Motor skill development          │
│  3. Emotional awareness              │
│                                      │
│  AREAS TO ENCOURAGE:                 │
│  1. Social interaction with peers    │
│  2. Verbal communication             │
│                                      │
│  RECOMMENDED HOME ACTIVITIES:        │
│  - Play cooperative board games      │
│  - Read stories and discuss feelings │
│  - Practice sharing during playdates │
│                                      │
│  STAFF NOTES:                        │
│  Ana has shown remarkable progress   │
│  in emotional awareness this quarter │
│  ...                                 │
└──────────────────────────────────────┘
```

### PDF Generation Flow

```
[Admin clicks "Generate Reports"]
     |
     v
[Python API /v1/reports/quarterly]
     |
     v
[Fetch: child + assessments + attendance + observations]
     |
     v
[Render HTML template with data + charts]
     |
     v
[WeasyPrint converts HTML to PDF]
     |
     v
[Upload PDF to Supabase Storage]
     |
     v
[Save reference in quarterly_reports table]
     |
     v
[Optionally email PDF to parent]
```

## Visualization Libraries

For the radar/bar charts in the browser:
- **Chart.js** (lightweight, CDN, no build step)
- Radar chart for 6 domains
- Bar chart for quarterly comparison
- Line chart for progress over time

```html
<canvas id="radarChart" width="300" height="300"></canvas>
<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
<script>
  new Chart(document.getElementById('radarChart'), {
    type: 'radar',
    data: {
      labels: ['Emotional', 'Social', 'Creative', 'Cognitive', 'Motor', 'Language'],
      datasets: [{
        label: 'Q1 2026',
        data: [4, 3, 5, 3, 4, 4],
        borderColor: '#FF6B6B',
        backgroundColor: 'rgba(255,107,107,0.2)'
      }, {
        label: 'Q4 2025',
        data: [3, 2, 4, 3, 3, 3],
        borderColor: '#4ECDC4',
        backgroundColor: 'rgba(78,205,196,0.2)'
      }]
    }
  });
</script>
```
