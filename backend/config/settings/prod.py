from django.core.exceptions import ImproperlyConfigured

from .base import *
from .env import env_bool, env_int, env_list

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
