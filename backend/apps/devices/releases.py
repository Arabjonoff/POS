"""Kassa ilovasining oxirgi versiyasi (T-093) — `settings.APP_RELEASES` dan."""

from django.conf import settings


def app_release(platform: str) -> dict | None:
    """`{latest_version, download_url}` yoki sozlanmagan bo'lsa `None`."""
    release = settings.APP_RELEASES.get(platform) or {}
    version = (release.get("latest_version") or "").strip()
    if not version:
        return None
    return {"latest_version": version, "download_url": (release.get("download_url") or "").strip()}
