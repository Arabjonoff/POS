"""Kassir PIN'i: hash formati kassada (Dart) oflayn tekshiriladi — qaror 0006.

Format: `pbkdf2_sha256$120000$<salt>$<base64 hash>` (Django PBKDF2 formati).
Umumiy test vektorlari: `testdata/pin_hash.json`.
"""

import re

from django.contrib.auth.hashers import PBKDF2PasswordHasher

PIN_RE = re.compile(r"^[0-9]{4,6}$")  # \d emas: u boshqa yozuvlardagi raqamlarni ham oladi
PIN_ITERATIONS = 120_000


class PinHasher(PBKDF2PasswordHasher):
    iterations = PIN_ITERATIONS


_hasher = PinHasher()


def validate_pin(pin: str) -> None:
    if not isinstance(pin, str) or not PIN_RE.match(pin):
        raise ValueError("pin must be 4-6 digits")


def hash_pin(pin: str, salt: str | None = None) -> str:
    validate_pin(pin)
    return _hasher.encode(pin, salt or _hasher.salt())


def verify_pin(pin: str, encoded: str) -> bool:
    """Saqlangan iteratsiya soni bilan tekshiradi; bo'sh yoki boshqa formatdagi hash — `False`."""
    if not encoded or not encoded.startswith(f"{_hasher.algorithm}$"):
        return False
    if not isinstance(pin, str) or not PIN_RE.match(pin):
        return False
    return _hasher.verify(pin, encoded)
