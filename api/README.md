# Sarena Sfera API

Production-ready FastAPI service for transactional emails, PDF report generation, and background jobs.

## Features

- ✅ **Transactional Emails** via Resend API
  - Registration confirmation
  - Event registration confirmation
  - Password reset
  - Custom HTML templates in Bosnian (BHS)

- ✅ **PDF Report Generation** via WeasyPrint
  - Quarterly development reports (planned)
  - Child passport exports (planned)

- ✅ **Production-Ready Infrastructure**
  - Structured error handling
  - Rate limiting (60 req/min default)
  - Request validation with Pydantic
  - Health check with dependency verification
  - Structured logging
  - CORS configuration

## Tech Stack

- **Framework:** FastAPI 0.115.6
- **Email:** Resend API
- **PDF:** WeasyPrint 63.1
- **Database:** Supabase (Python client)
- **Validation:** Pydantic 2.10.5
- **Rate Limiting:** SlowAPI

## Quick Start

### 1. Install Dependencies

```bash
cd api
pip install -r requirements.txt
```

### 2. Configure Environment

Copy `.env.example` to `.env` and fill in the values:

```bash
cp .env.example .env
```

Required environment variables:

```bash
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-key
RESEND_API_KEY=re_your_api_key_here
```

### 3. Run Locally

```bash
uvicorn app.main:app --reload --port 8080
```

API will be available at:
- **API:** http://localhost:8080
- **Docs:** http://localhost:8080/docs
- **Health:** http://localhost:8080/health

### 4. Run with Docker

```bash
docker build -t sarenasfera-api .
docker run -p 8080:8080 --env-file .env sarenasfera-api
```

## API Endpoints

### Health Check

```http
GET /health
```

Returns API status and dependency health:

```json
{
  "status": "healthy",
  "app_name": "Sarena Sfera API",
  "version": "1.0.0",
  "environment": "development",
  "dependencies": {
    "resend": {"status": "healthy", "message": "API key configured"},
    "supabase": {"status": "healthy", "message": "Configured"}
  }
}
```

### Send Registration Email

```http
POST /email/registration
Content-Type: application/json

{
  "to": "parent@example.com",
  "parent_name": "Amira Hodžić",
  "child_name": "Sara",
  "login_url": "https://sarenasfera.com/auth/login",
  "magic_link": "https://sarenasfera.com/auth/magic?token=..."
}
```

### Send Event Registration Email

```http
POST /email/event-registration
Content-Type: application/json

{
  "to": "parent@example.com",
  "parent_name": "Amira Hodžić",
  "child_name": "Sara",
  "event_title": "Kreativna radionica: Proljeće u bojama",
  "event_date": "15. mart 2026",
  "event_time": "10:00-11:30",
  "event_location": "Šarena Sfera Centar, Sarajevo"
}
```

### Send Password Reset Email

```http
POST /email/password-reset
Content-Type: application/json

{
  "to": "user@example.com",
  "reset_link": "https://sarenasfera.com/auth/reset?token=..."
}
```

## Error Handling

All endpoints return structured errors:

### Validation Error (422)

```json
{
  "detail": "Validation error",
  "errors": [
    {
      "loc": ["body", "to"],
      "msg": "value is not a valid email address",
      "type": "value_error.email"
    }
  ]
}
```

### Server Error (500)

```json
{
  "detail": "Internal server error",
  "message": "Failed to send email: API key invalid"
}
```

### Rate Limit (429)

```json
{
  "error": "Rate limit exceeded: 30 per minute"
}
```

## Development

### Project Structure

```
api/
├── app/
│   ├── __init__.py
│   ├── main.py              # FastAPI app + middleware
│   ├── config.py            # Settings from environment
│   ├── models/
│   │   ├── __init__.py
│   │   └── email.py         # Pydantic models
│   ├── routers/
│   │   ├── __init__.py
│   │   └── email.py         # Email endpoints
│   └── services/
│       ├── __init__.py
│       └── email.py         # Email service with Resend
├── requirements.txt
├── Dockerfile
├── .env.example
└── README.md
```

### Adding New Endpoints

1. **Define Pydantic models** in `app/models/`
2. **Create service** in `app/services/`
3. **Add router** in `app/routers/`
4. **Include router** in `app/main.py`

Example:

```python
# app/routers/reports.py
from fastapi import APIRouter

router = APIRouter(prefix="/reports", tags=["Reports"])

@router.get("/quarterly/{child_id}")
async def generate_quarterly_report(child_id: str):
    # Implementation
    pass

# app/main.py
from app.routers import reports
app.include_router(reports.router)
```

## Testing

### Manual Testing

```bash
# Health check
curl http://localhost:8080/health

# Send test email
curl -X POST http://localhost:8080/email/registration \
  -H "Content-Type: application/json" \
  -d '{
    "to": "test@example.com",
    "parent_name": "Test Parent",
    "child_name": "Test Child",
    "login_url": "https://sarenasfera.com/auth/login"
  }'
```

### Unit Tests (Planned)

```bash
pytest tests/
```

## Deployment

See `/docs/DEPLOYMENT-RUNBOOK.md` for production deployment instructions.

Quick deploy to DigitalOcean App Platform:

```bash
doctl apps create --spec .do/app.yaml
```

## Monitoring

### Logs

Logs are structured and output to stdout in JSON format:

```
2026-03-09 10:00:00 - app.services.email - INFO - Registration email sent to user@example.com: {...}
```

### Metrics

Monitor these endpoints:

- `/health` — Overall API health
- `/metrics` — Prometheus metrics (planned)

### Alerts

Set up alerts for:

- Health check failures
- 5xx error rate > 1%
- Email send failures
- Rate limit hits

## Security

- ✅ Rate limiting enabled (60 req/min default)
- ✅ CORS configured for trusted origins only
- ✅ Environment variables for secrets (never commit `.env`)
- ✅ Non-root user in Docker container
- ✅ Structured error messages (no stack traces in production)
- ✅ Request validation via Pydantic

## License

Proprietary - Sarena Sfera Platform © 2026
