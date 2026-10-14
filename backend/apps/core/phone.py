"""Telefon raqami: yagona ko'rinish `+998XXXXXXXXX` (O'zbekiston, 9 raqamli abonent qismi)."""

import re

from django.core.exceptions import ValidationError
from django.utils.translation import gettext_lazy as _

COUNTRY_CODE = "998"
PHONE_RE = re.compile(r"^\+998\d{9}$")
_SEPARATORS_RE = re.compile(r"[\s\-()]")


def normalize_phone(raw: str) -> str:
    """`90 123 45 67`, `+998 (90) 123-45-67`, `998901234567` → `+998901234567`.

    Noto'g'ri raqam bo'lsa `ValueError`.
    """
    value = _SEPARATORS_RE.sub("", raw or "")
    if value.startswith("+"):
        value = value[1:]
    if not value.isdigit():
        raise ValueError("phone must contain only digits")
    if len(value) == 9:
        value = COUNTRY_CODE + value
    normalized = "+" + value
    if not PHONE_RE.match(normalized):
        raise ValueError("phone must be +998 followed by 9 digits")
    return normalized


def validate_phone(value: str) -> None:
    """Model maydoni uchun: faqat normallashtirilgan ko'rinish qabul qilinadi."""
    if not PHONE_RE.match(value or ""):
        raise ValidationError(_("Telefon raqami +998XXXXXXXXX ko'rinishida bo'lishi kerak."))
