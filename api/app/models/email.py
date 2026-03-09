"""Email request/response models."""

from pydantic import BaseModel, EmailStr, Field
from typing import Optional


class EmailRequest(BaseModel):
    """Base email request model."""
    to: EmailStr = Field(..., description="Recipient email address")
    subject: str = Field(..., min_length=1, max_length=200, description="Email subject")


class RegistrationEmailRequest(EmailRequest):
    """Email sent after user registers."""
    parent_name: str = Field(..., min_length=1, description="Parent's full name")
    child_name: str = Field(..., min_length=1, description="Child's name")
    login_url: str = Field(..., description="Login URL for the platform")
    magic_link: Optional[str] = Field(None, description="Magic link for passwordless login")


class EventRegistrationEmailRequest(EmailRequest):
    """Email sent after event registration."""
    parent_name: str = Field(..., min_length=1, description="Parent's full name")
    child_name: str = Field(..., min_length=1, description="Child's name")
    event_title: str = Field(..., description="Event title")
    event_date: str = Field(..., description="Event date formatted")
    event_time: str = Field(..., description="Event time formatted")
    event_location: str = Field(..., description="Event location")
    confirmation_url: Optional[str] = Field(None, description="Confirmation URL")


class PasswordResetEmailRequest(EmailRequest):
    """Email sent for password reset."""
    reset_link: str = Field(..., description="Password reset link")


class EmailResponse(BaseModel):
    """Standard email response."""
    success: bool
    message_id: Optional[str] = None
    error: Optional[str] = None
