"""
Sarena Sfera API
FastAPI application for transactional emails, PDF reports, and background jobs.
"""

import logging
import sys
from contextlib import asynccontextmanager
from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded

from app.config import get_settings
from app.routers import email

settings = get_settings()

# Configure logging
logging.basicConfig(
    level=getattr(logging, settings.log_level.upper(), logging.INFO),
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    handlers=[logging.StreamHandler(sys.stdout)],
)
logger = logging.getLogger(__name__)

# Rate limiter
limiter = Limiter(key_func=get_remote_address)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan events."""
    logger.info("🚀 Sarena Sfera API starting up...")
    logger.info(f"Environment: {settings.environment}")
    logger.info(f"CORS Origins: {settings.cors_origins}")
    yield
    logger.info("👋 Sarena Sfera API shutting down...")


# FastAPI app
app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    description="Custom API for transactional emails, PDF reports, analytics, and cron jobs.",
    docs_url="/docs" if settings.environment != "production" else None,
    redoc_url="/redoc" if settings.environment != "production" else None,
    lifespan=lifespan,
)

# Add rate limiting
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Exception handlers
@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    """Handle validation errors with structured response."""
    logger.warning(f"Validation error on {request.url}: {exc.errors()}")
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={
            "detail": "Validation error",
            "errors": exc.errors(),
        },
    )


@app.exception_handler(Exception)
async def generic_exception_handler(request: Request, exc: Exception):
    """Handle unexpected errors."""
    logger.error(f"Unhandled exception on {request.url}: {exc}", exc_info=True)
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={
            "detail": "Internal server error",
            "message": str(exc) if settings.environment != "production" else "An error occurred",
        },
    )


# Health check
@app.get(
    "/health",
    tags=["Health"],
    summary="Health check endpoint",
    description="Returns the health status of the API and its dependencies.",
)
@limiter.limit("30/minute")
async def health_check(request: Request):
    """
    Health check endpoint.
    Returns API status and dependency checks.
    """
    health_status = {
        "status": "healthy",
        "app_name": settings.app_name,
        "version": settings.app_version,
        "environment": settings.environment,
        "dependencies": {
            "resend": _check_resend(),
            "supabase": _check_supabase(),
        },
    }

    # If any dependency is down, return 503
    all_healthy = all(
        dep["status"] == "healthy" for dep in health_status["dependencies"].values()
    )

    return JSONResponse(
        status_code=status.HTTP_200_OK if all_healthy else status.HTTP_503_SERVICE_UNAVAILABLE,
        content=health_status,
    )


def _check_resend() -> dict:
    """Check if Resend API key is configured."""
    if settings.resend_api_key and settings.resend_api_key != "":
        return {"status": "healthy", "message": "API key configured"}
    return {"status": "unhealthy", "message": "API key not configured"}


def _check_supabase() -> dict:
    """Check if Supabase is configured."""
    if settings.supabase_url and settings.supabase_anon_key:
        return {"status": "healthy", "message": "Configured"}
    return {"status": "unhealthy", "message": "Not configured"}


# Include routers
app.include_router(email.router)


# Root endpoint
@app.get("/", tags=["Root"])
async def root():
    """Root endpoint."""
    return {
        "message": "Sarena Sfera API",
        "version": settings.app_version,
        "docs": "/docs" if settings.environment != "production" else "Not available in production",
    }
