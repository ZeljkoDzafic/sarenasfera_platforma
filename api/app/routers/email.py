"""Email endpoints for transactional emails."""

from fastapi import APIRouter, HTTPException, Depends, status
from app.models.email import (
    RegistrationEmailRequest,
    EventRegistrationEmailRequest,
    PasswordResetEmailRequest,
    EmailResponse,
)
from app.services.email import EmailService
from app.config import Settings, get_settings
import logging

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/email", tags=["Email"])


def get_email_service(settings: Settings = Depends(get_settings)) -> EmailService:
    """Dependency injection for EmailService."""
    return EmailService(settings)


@router.post(
    "/registration",
    response_model=EmailResponse,
    status_code=status.HTTP_200_OK,
    summary="Send registration confirmation email",
    description="Sends a welcome email to a newly registered user with login credentials.",
)
async def send_registration_email(
    request: RegistrationEmailRequest,
    email_service: EmailService = Depends(get_email_service),
) -> EmailResponse:
    """Send registration confirmation email."""
    success, message_id, error = await email_service.send_registration_email(
        to=request.to,
        parent_name=request.parent_name,
        child_name=request.child_name,
        login_url=request.login_url,
        magic_link=request.magic_link,
    )

    if not success:
        logger.error(f"Registration email failed: {error}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to send email: {error}",
        )

    return EmailResponse(success=True, message_id=message_id)


@router.post(
    "/event-registration",
    response_model=EmailResponse,
    status_code=status.HTTP_200_OK,
    summary="Send event registration confirmation",
    description="Sends a confirmation email after a user registers for an event/workshop.",
)
async def send_event_registration_email(
    request: EventRegistrationEmailRequest,
    email_service: EmailService = Depends(get_email_service),
) -> EmailResponse:
    """Send event registration confirmation email."""
    success, message_id, error = await email_service.send_event_registration_email(
        to=request.to,
        parent_name=request.parent_name,
        child_name=request.child_name,
        event_title=request.event_title,
        event_date=request.event_date,
        event_time=request.event_time,
        event_location=request.event_location,
        confirmation_url=request.confirmation_url,
    )

    if not success:
        logger.error(f"Event registration email failed: {error}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to send email: {error}",
        )

    return EmailResponse(success=True, message_id=message_id)


@router.post(
    "/password-reset",
    response_model=EmailResponse,
    status_code=status.HTTP_200_OK,
    summary="Send password reset email",
    description="Sends a password reset link to the user's email.",
)
async def send_password_reset_email(
    request: PasswordResetEmailRequest,
    email_service: EmailService = Depends(get_email_service),
) -> EmailResponse:
    """Send password reset email."""
    success, message_id, error = await email_service.send_password_reset_email(
        to=request.to,
        reset_link=request.reset_link,
    )

    if not success:
        logger.error(f"Password reset email failed: {error}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to send email: {error}",
        )

    return EmailResponse(success=True, message_id=message_id)
