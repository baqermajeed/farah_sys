from typing import Optional
from app.config import get_settings

settings = get_settings()

async def send_sms(phone: str, message: str) -> None:
    """Send SMS via configured provider.
    - 'dummy': prints to logs (dev only).
    - 'twilio': send via Twilio creds in .env (implementation placeholder).
    """
    provider = settings.SMS_PROVIDER.lower()
    if provider == "dummy":
        # In dev, just log the message; integrate with your logger if needed.
        print(f"[SMS:DUMMY] to={phone} msg={message}")
        return
    elif provider == "twilio":
        # To keep the base lightweight, we avoid importing Twilio SDK by default.
        # You can install 'twilio' package and uncomment below to send real SMS.
        # from twilio.rest import Client
        # client = Client(settings.TWILIO_ACCOUNT_SID, settings.TWILIO_AUTH_TOKEN)
        # client.messages.create(to=phone, from_=settings.TWILIO_FROM_NUMBER, body=message)
        print(f"[SMS:TWILIO-STUB] Would send to {phone}: {message}")
        return
    else:
        print(f"[SMS:UNKNOWN] {provider} not supported; message not sent.")
        return