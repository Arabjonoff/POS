"""Bir qatorli matn (nom): kassadagi `cleanLine` bilan bir xil qoida."""

import re

_CONTROL_RE = re.compile(r"[\x00-\x1f\x7f-\x9f]")
_SPACES_RE = re.compile(r"\s+")


def clean_line(text: str) -> str:
    """Boshqaruv belgilari (yangi qator, tab, ESC...) bo'shliqqa, ketma-ket bo'shliqlar bittaga."""
    return _SPACES_RE.sub(" ", _CONTROL_RE.sub(" ", text or "")).strip()
