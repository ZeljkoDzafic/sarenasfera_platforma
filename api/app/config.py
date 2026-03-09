"""
API Configuration
Loads environment variables and provides centralized config access.
"""

from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    """Application settings from environment variables."""

    # App info
    app_name: str = "Sarena Sfera API"
    app_version: str = "1.0.0"
    environment: str = "development"  # development, staging, production

    # CORS
    cors_origins: list[str] = [
        "http://localhost:3000",
        "https://sarenasfera.com",
        "https://www.sarenasfera.com",
    ]

    # Supabase
    supabase_url: str
    supabase_anon_key: str
    supabase_service_role_key: str

    # Resend Email API
    resend_api_key: str
    resend_from_email: str = "Šarena Sfera <noreply@sarenasfera.com>"

    # WeasyPrint PDF settings
    pdf_base_url: str = "https://sarenasfera.com"

    # Rate limiting
    rate_limit_enabled: bool = True
    rate_limit_per_minute: int = 60

    # Logging
    log_level: str = "INFO"

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


@lru_cache
def get_settings() -> Settings:
    """
    Get cached settings instance.
    Uses lru_cache to ensure settings are loaded only once.
    """
    return Settings()
