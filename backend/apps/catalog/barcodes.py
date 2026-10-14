"""Shtrix-kod: normalizatsiya va EAN/UPC nazorat raqami (barcode.md, catalog-api.md)."""

import re

BARCODE_RE = re.compile(r"^[\x21-\x7e]{4,64}$")  # ko'rinadigan ASCII, bo'shliqsiz
CHECKED_LENGTHS = frozenset({8, 12, 13})  # EAN-8, UPC-A, EAN-13


class BarcodeError(ValueError):
    def __init__(self, code: str, message: str):
        super().__init__(message)
        self.code = code


def gtin_check_digit(body: str) -> int:
    """GTIN (EAN-8/UPC-A/EAN-13) nazorat raqami: o'ngdan og'irliklar 3, 1, 3, 1 …"""
    total = sum(int(d) * (3 if i % 2 == 0 else 1) for i, d in enumerate(reversed(body)))
    return (10 - total % 10) % 10


def normalize_barcode(raw: str) -> str:
    """Bosh/oxirgi bo'shliqlarni olib tashlaydi; boshidagi nollar saqlanadi. Xato — `BarcodeError`."""
    value = (raw or "").strip()
    if not BARCODE_RE.match(value):
        raise BarcodeError("invalid_barcode", "Barcode must be 4-64 visible ASCII characters.")
    if value.isdigit() and len(value) in CHECKED_LENGTHS:
        if gtin_check_digit(value[:-1]) != int(value[-1]):
            raise BarcodeError("invalid_check_digit", "Barcode check digit is wrong.")
    return value
