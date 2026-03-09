# 05 - API Design

## Two API Layers

### Layer 1: Supabase Auto-API (PostgREST)

For all standard CRUD operations. Frontend JS directly talks to Supabase.
No custom backend code needed for basic operations.

```javascript
// Example: Fetch current parent's children
const { data: children } = await supabase
  .from('children')
  .select('*, child_groups(group:groups(name))')
  .order('created_at', { ascending: false });

// Example: Add observation (staff only - RLS enforced)
const { data } = await supabase
  .from('observations')
  .insert({
    child_id: childId,
    workshop_id: workshopId,
    staff_id: user.id,
    content: 'Child independently named the emotion of sadness for the first time.',
    domain: 'emotional'
  });

// Example: Fetch child passport data (all in one query)
const { data: passport } = await supabase
  .from('children')
  .select(`
    *,
    assessments(domain, score, period),
    observations(content, domain, created_at, photo_url),
    attendance(status, participation_level, workshops(title, scheduled_date)),
    quarterly_reports(period, pdf_url, strengths, areas_to_improve)
  `)
  .eq('id', childId)
  .single();

// Example: Upload child work photo
const { data } = await supabase.storage
  .from('observations')
  .upload(`${childId}/${Date.now()}.jpg`, file);
```

**Supabase covers:** profiles, children, groups, workshops, attendance,
observations, assessments, blog posts, subscriptions, home activities, leads.

### Layer 2: Python FastAPI (custom logic)

For operations Supabase can't handle alone. Runs on DigitalOcean.

```
BASE_URL: https://api.sarenasfera.com/v1

POST /reports/quarterly              -- generate quarterly report (PDF)
GET  /reports/quarterly/{id}/pdf     -- download PDF
POST /email/send                     -- send single email
POST /email/campaign                 -- send campaign
POST /email/workshop-summary         -- auto-send post-workshop summary
GET  /analytics/dashboard            -- aggregated admin data
GET  /analytics/child/{id}/trend     -- child development trend
POST /cron/attendance-reminder       -- remind parents about upcoming workshop
POST /cron/inactive-child-alert      -- alert for children who haven't attended
POST /ai/activity-suggestion         -- (Phase 3) AI activity recommendation
```

### Python API Implementation

```python
from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from supabase import create_client
from weasyprint import HTML
import os

app = FastAPI(title="Sarena Sfera API", version="1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://sarenasfera.com"],
    allow_methods=["*"],
    allow_headers=["*"],
)

supabase = create_client(
    os.environ["SUPABASE_URL"],
    os.environ["SUPABASE_SERVICE_KEY"]
)

@app.post("/v1/reports/quarterly")
async def generate_quarterly_report(child_id: str, period: str):
    """Generate quarterly PDF report for a child."""

    # 1. Fetch data
    child = supabase.table("children").select("*").eq("id", child_id).single().execute()
    assessments = supabase.table("assessments").select("*") \
        .eq("child_id", child_id).eq("period", period).execute()
    attendance_records = supabase.table("attendance") \
        .select("*, workshops(*)").eq("child_id", child_id).execute()
    observations = supabase.table("observations") \
        .select("*").eq("child_id", child_id).execute()

    # 2. Generate PDF
    html_content = render_report_template(
        child.data, assessments.data,
        attendance_records.data, observations.data
    )
    pdf_bytes = HTML(string=html_content).write_pdf()

    # 3. Upload to Supabase Storage
    path = f"reports/{child_id}/{period}.pdf"
    supabase.storage.from_("reports").upload(path, pdf_bytes)

    # 4. Save reference in database
    supabase.table("quarterly_reports").upsert({
        "child_id": child_id,
        "period": period,
        "pdf_url": path,
        "attendance_percentage": calc_attendance_pct(attendance_records.data),
        "strengths": identify_strengths(assessments.data),
        "areas_to_improve": identify_improvements(assessments.data)
    }).execute()

    return {"status": "generated", "path": path}


@app.post("/v1/email/workshop-summary")
async def send_workshop_summary(workshop_id: str):
    """Send post-workshop email summary to all parents."""

    workshop = supabase.table("workshops").select("*").eq("id", workshop_id).single().execute()
    attendees = supabase.table("attendance") \
        .select("*, children(*, profiles!parent_id(*))") \
        .eq("workshop_id", workshop_id).execute()

    for record in attendees.data:
        parent_email = record["children"]["profiles"]["email"]
        # Send personalized email with child's observation
        send_email(
            to=parent_email,
            subject=f"Workshop Summary: {workshop.data['title']}",
            body=format_summary_email(record)
        )

    return {"status": "sent", "count": len(attendees.data)}
```

## Conventions

| Aspect | Convention |
|--------|-----------|
| Naming | snake_case for tables and columns |
| ID format | UUID v4 |
| Dates | ISO 8601 (TIMESTAMPTZ) |
| Pagination | `?limit=20&offset=0` (Supabase built-in) |
| Filtering | Supabase query builder operators |
| Errors | HTTP status codes + JSON message |
| Auth | Bearer token in Authorization header |

## Data Flow Diagram

```
[Browser on HostGator page]
     |
     |-- Direct to Supabase (CRUD, Auth, Storage)
     |     Uses: supabase-js client
     |     Auth: JWT token (anon key + user session)
     |
     |-- To Python API (reports, email, analytics)
           Uses: fetch() with auth token
           Auth: Validates Supabase JWT
```
