from django.core.exceptions import ImproperlyConfigured

from .base import *
from .env import env_bool, env_int, env_list, env_str

DEBUG = False
if SECRET_KEY == "insecure-dev-only-key":
    raise ImproperlyConfigured("DJANGO_SECRET_KEY o'rnatilmagan")

SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")
SECURE_SSL_REDIRECT = env_bool("DJANGO_SECURE_SSL_REDIRECT", True)
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
SECURE_HSTS_SECONDS = env_int("DJANGO_HSTS_SECONDS", 0)
SECURE_CONTENT_TYPE_NOSNIFF = True
CSRF_TRUSTED_ORIGINS = env_list("DJANGO_CSRF_TRUSTED_ORIGINS", "")

# Xatolar monitoringi: `SENTRY_DSN` berilsa yoqiladi (shaxsiy ma'lumot yuborilmaydi).
SENTRY_DSN = env_str("SENTRY_DSN")
if SENTRY_DSN:
    import sentry_sdk
    from sentry_sdk.integrations.django import DjangoIntegration

    sentry_sdk.init(
        dsn=SENTRY_DSN,
        integrations=[DjangoIntegration()],
        environment=env_str("SENTRY_ENVIRONMENT", "production"),
        release=env_str("APP_VERSION") or None,
        traces_sample_rate=float(env_str("SENTRY_TRACES_SAMPLE_RATE", "0")),
        send_default_pii=False,
    )
