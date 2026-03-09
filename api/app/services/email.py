"""
Email service using Resend API.
Handles transactional emails for registration, password reset, events, etc.
"""

import html
import resend
import logging
from typing import Optional
from app.config import Settings

logger = logging.getLogger(__name__)


class EmailService:
    """Email service for sending transactional emails via Resend."""

    def __init__(self, settings: Settings):
        self.settings = settings
        resend.api_key = settings.resend_api_key
        self.from_email = settings.resend_from_email

    @staticmethod
    def _escape(value: str) -> str:
        return html.escape(value, quote=True)

    async def send_registration_email(
        self,
        to: str,
        parent_name: str,
        child_name: str,
        login_url: str,
        magic_link: Optional[str] = None,
    ) -> tuple[bool, Optional[str], Optional[str]]:
        """
        Send welcome email after registration.

        Returns:
            (success, message_id, error)
        """
        try:
            html_body = self._render_registration_template(
                parent_name=parent_name,
                child_name=child_name,
                login_url=login_url,
                magic_link=magic_link,
            )

            params = {
                "from": self.from_email,
                "to": [to],
                "subject": f"Dobrodošli u Šarenu Sferu! 🎨",
                "html": html_body,
            }

            response = resend.Emails.send(params)
            logger.info(f"Registration email sent to {to}: {response}")
            return (True, response.get("id"), None)

        except Exception as e:
            logger.error(f"Failed to send registration email to {to}: {e}")
            return (False, None, str(e))

    async def send_event_registration_email(
        self,
        to: str,
        parent_name: str,
        child_name: str,
        event_title: str,
        event_date: str,
        event_time: str,
        event_location: str,
        confirmation_url: Optional[str] = None,
    ) -> tuple[bool, Optional[str], Optional[str]]:
        """
        Send confirmation email after event registration.

        Returns:
            (success, message_id, error)
        """
        try:
            html_body = self._render_event_registration_template(
                parent_name=parent_name,
                child_name=child_name,
                event_title=event_title,
                event_date=event_date,
                event_time=event_time,
                event_location=event_location,
                confirmation_url=confirmation_url,
            )

            params = {
                "from": self.from_email,
                "to": [to],
                "subject": f"Prijava potvrđena: {event_title}",
                "html": html_body,
            }

            response = resend.Emails.send(params)
            logger.info(f"Event registration email sent to {to}: {response}")
            return (True, response.get("id"), None)

        except Exception as e:
            logger.error(f"Failed to send event registration email to {to}: {e}")
            return (False, None, str(e))

    async def send_password_reset_email(
        self,
        to: str,
        reset_link: str,
    ) -> tuple[bool, Optional[str], Optional[str]]:
        """
        Send password reset email.

        Returns:
            (success, message_id, error)
        """
        try:
            html_body = self._render_password_reset_template(reset_link=reset_link)

            params = {
                "from": self.from_email,
                "to": [to],
                "subject": "Resetovanje lozinke — Šarena Sfera",
                "html": html_body,
            }

            response = resend.Emails.send(params)
            logger.info(f"Password reset email sent to {to}: {response}")
            return (True, response.get("id"), None)

        except Exception as e:
            logger.error(f"Failed to send password reset email to {to}: {e}")
            return (False, None, str(e))

    # Template rendering methods

    def _render_registration_template(
        self,
        parent_name: str,
        child_name: str,
        login_url: str,
        magic_link: Optional[str] = None,
    ) -> str:
        """Render registration email HTML."""
        safe_parent_name = self._escape(parent_name)
        safe_child_name = self._escape(child_name)
        safe_login_url = self._escape(login_url)
        magic_section = ""
        if magic_link:
            safe_magic_link = self._escape(magic_link)
            magic_section = f"""
            <p style="margin: 20px 0;">
              <a href="{safe_magic_link}"
                 style="display: inline-block; background: #9b51e0; color: white; padding: 12px 24px;
                        text-decoration: none; border-radius: 8px; font-weight: bold;">
                Prijavite se direktno
              </a>
            </p>
            <p style="color: #666; font-size: 14px;">
              Ili kopirajte link: <br>
              <code style="background: #f5f5f5; padding: 4px 8px; border-radius: 4px;">{safe_magic_link}</code>
            </p>
            """

        return f"""
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="UTF-8">
          <title>Dobrodošli u Šarenu Sferu</title>
        </head>
        <body style="font-family: 'Nunito', sans-serif; margin: 0; padding: 0; background: #f9fafb;">
          <div style="max-width: 600px; margin: 40px auto; background: white; border-radius: 16px;
                      overflow: hidden; box-shadow: 0 4px 6px rgba(0,0,0,0.1);">

            <!-- Header -->
            <div style="background: linear-gradient(135deg, #9b51e0, #f78da7); padding: 40px 20px; text-align: center;">
              <h1 style="color: white; margin: 0; font-size: 28px;">🎨 Dobrodošli u Šarenu Sferu!</h1>
            </div>

            <!-- Body -->
            <div style="padding: 40px 30px;">
              <p style="font-size: 16px; color: #333; margin: 0 0 20px 0;">
                Poštovani/a <strong>{safe_parent_name}</strong>,
              </p>

              <p style="font-size: 16px; color: #333; line-height: 1.6;">
                Hvala što ste se pridružili Šarenoj Sferi sa <strong>{safe_child_name}</strong>!
                Mi smo oduševljeni da budemo dio razvojnog putovanja vašeg djeteta.
              </p>

              <p style="font-size: 16px; color: #333; line-height: 1.6;">
                Vaš nalog je kreiran i možete se odmah prijaviti na platformu:
              </p>

              {magic_section}

              <p style="font-size: 16px; color: #333; line-height: 1.6; margin-top: 30px;">
                Na platformi možete:
              </p>
              <ul style="font-size: 15px; color: #555; line-height: 1.8;">
                <li>Pratiti razvoj vašeg djeteta kroz 6 razvojnih domena</li>
                <li>Preuzimati materijale sa radionica</li>
                <li>Prijaviti se na nove radionice i događaje</li>
                <li>Pristupiti blogu i edukativnim resursima</li>
              </ul>

              <p style="font-size: 16px; color: #333; margin-top: 30px;">
                Ako imate bilo kakvih pitanja, slobodno nas kontaktirajte.
              </p>

              <p style="font-size: 16px; color: #333; margin-top: 30px;">
                Srdačan pozdrav,<br>
                <strong>Tim Šarene Sfere</strong>
              </p>
            </div>

            <!-- Footer -->
            <div style="background: #f9fafb; padding: 20px; text-align: center; border-top: 1px solid #e5e7eb;">
              <p style="color: #999; font-size: 12px; margin: 0;">
                © 2026 Šarena Sfera • Sarajevo, BiH<br>
                <a href="{safe_login_url}" style="color: #9b51e0; text-decoration: none;">sarenasfera.com</a>
              </p>
            </div>
          </div>
        </body>
        </html>
        """

    def _render_event_registration_template(
        self,
        parent_name: str,
        child_name: str,
        event_title: str,
        event_date: str,
        event_time: str,
        event_location: str,
        confirmation_url: Optional[str] = None,
    ) -> str:
        """Render event registration confirmation email HTML."""
        safe_parent_name = self._escape(parent_name)
        safe_child_name = self._escape(child_name)
        safe_event_title = self._escape(event_title)
        safe_event_date = self._escape(event_date)
        safe_event_time = self._escape(event_time)
        safe_event_location = self._escape(event_location)
        return f"""
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="UTF-8">
          <title>Prijava potvrđena</title>
        </head>
        <body style="font-family: 'Nunito', sans-serif; margin: 0; padding: 0; background: #f9fafb;">
          <div style="max-width: 600px; margin: 40px auto; background: white; border-radius: 16px;
                      overflow: hidden; box-shadow: 0 4px 6px rgba(0,0,0,0.1);">

            <div style="background: linear-gradient(135deg, #00d084, #0693e3); padding: 40px 20px; text-align: center;">
              <h1 style="color: white; margin: 0; font-size: 28px;">✅ Prijava Potvrđena!</h1>
            </div>

            <div style="padding: 40px 30px;">
              <p style="font-size: 16px; color: #333; margin: 0 0 20px 0;">
                Poštovani/a <strong>{safe_parent_name}</strong>,
              </p>

              <p style="font-size: 16px; color: #333; line-height: 1.6;">
                Vaša prijava za <strong>{safe_child_name}</strong> je uspješno zaprimljena!
              </p>

              <div style="background: #f0f9ff; border-left: 4px solid #0693e3; padding: 20px; margin: 30px 0; border-radius: 8px;">
                <h2 style="margin: 0 0 15px 0; color: #0693e3; font-size: 20px;">{safe_event_title}</h2>
                <p style="margin: 5px 0; color: #555; font-size: 15px;">
                  <strong>📅 Datum:</strong> {safe_event_date}<br>
                  <strong>⏰ Vrijeme:</strong> {safe_event_time}<br>
                  <strong>📍 Lokacija:</strong> {safe_event_location}
                </p>
              </div>

              <p style="font-size: 16px; color: #333; line-height: 1.6;">
                Primićete dodatne informacije putem emaila nekoliko dana prije događaja.
                Molimo da prisustvujete na vrijeme.
              </p>

              <p style="font-size: 16px; color: #333; margin-top: 30px;">
                Vidimo se uskoro!<br>
                <strong>Tim Šarene Sfere</strong>
              </p>
            </div>

            <div style="background: #f9fafb; padding: 20px; text-align: center; border-top: 1px solid #e5e7eb;">
              <p style="color: #999; font-size: 12px; margin: 0;">
                © 2026 Šarena Sfera • Sarajevo, BiH<br>
                <a href="https://sarenasfera.com" style="color: #9b51e0; text-decoration: none;">sarenasfera.com</a>
              </p>
            </div>
          </div>
        </body>
        </html>
        """

    def _render_password_reset_template(self, reset_link: str) -> str:
        """Render password reset email HTML."""
        safe_reset_link = self._escape(reset_link)
        return f"""
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="UTF-8">
          <title>Resetovanje lozinke</title>
        </head>
        <body style="font-family: 'Nunito', sans-serif; margin: 0; padding: 0; background: #f9fafb;">
          <div style="max-width: 600px; margin: 40px auto; background: white; border-radius: 16px;
                      overflow: hidden; box-shadow: 0 4px 6px rgba(0,0,0,0.1);">

            <div style="background: linear-gradient(135deg, #cf2e2e, #fcb900); padding: 40px 20px; text-align: center;">
              <h1 style="color: white; margin: 0; font-size: 28px;">🔐 Resetovanje Lozinke</h1>
            </div>

            <div style="padding: 40px 30px;">
              <p style="font-size: 16px; color: #333; line-height: 1.6;">
                Primili smo zahtjev za resetovanje lozinke za vaš nalog na Šarenoj Sferi.
              </p>

              <p style="font-size: 16px; color: #333; line-height: 1.6;">
                Kliknite na dugme ispod da postavite novu lozinku:
              </p>

              <p style="margin: 30px 0;">
                <a href="{safe_reset_link}"
                   style="display: inline-block; background: #cf2e2e; color: white; padding: 14px 28px;
                          text-decoration: none; border-radius: 8px; font-weight: bold; font-size: 16px;">
                  Resetuj Lozinku
                </a>
              </p>

              <p style="color: #666; font-size: 14px; line-height: 1.6;">
                Ovaj link je validan 24 sata. Ako niste zatražili resetovanje lozinke,
                slobodno ignorišite ovaj email.
              </p>

              <p style="font-size: 14px; color: #999; margin-top: 30px;">
                Link možete i kopirati:<br>
                <code style="background: #f5f5f5; padding: 8px; border-radius: 4px; font-size: 12px;
                             word-break: break-all; display: inline-block; margin-top: 10px;">{safe_reset_link}</code>
              </p>
            </div>

            <div style="background: #f9fafb; padding: 20px; text-align: center; border-top: 1px solid #e5e7eb;">
              <p style="color: #999; font-size: 12px; margin: 0;">
                © 2026 Šarena Sfera • Sarajevo, BiH<br>
                <a href="https://sarenasfera.com" style="color: #9b51e0; text-decoration: none;">sarenasfera.com</a>
              </p>
            </div>
          </div>
        </body>
        </html>
        """
