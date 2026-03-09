"""Security helpers for internal API protection."""

import secrets

from fastapi import Depends, Header, HTTPException, status

from app.config import Settings, get_settings


def verify_internal_api_key(
    x_internal_api_key: str | None = Header(default=None, alias="X-Internal-API-Key"),
    settings: Settings = Depends(get_settings),
) -> None:
    """Require an internal API key when configured."""
    expected = settings.internal_api_key
    if not expected:
        return

    if not x_internal_api_key or not secrets.compare_digest(x_internal_api_key, expected):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid internal API key",
        )
