import dj_database_url

from .base import *
from .env import env_str

DEBUG = False
SECRET_KEY = "test-secret-key-not-for-production"
DATABASES = {
    "default": dj_database_url.parse(
        env_str("DATABASE_URL", "postgres://pos:pos@localhost:5432/pos"),
    )
}
# Testlarda tezlik uchun: argon2 sekin, MD5 faqat testda.
PASSWORD_HASHERS = ["django.contrib.auth.hashers.MD5PasswordHasher"]
LOGGING = {"version": 1, "disable_existing_loggers": False, "root": {"level": "WARNING"}}
