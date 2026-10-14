"""Obuna holatini hisoblash — sof funksiyalar, bazaga bog'liq emas.

Qoidalar: subscription-billing.md, "Sanalar" bo'limi.
"""

import calendar
from dataclasses import dataclass
from datetime import date, timedelta

from django.db import models
from django.utils.translation import gettext_lazy as _

EXPIRY_WARNING_DAYS = 3  # active: tugashiga shuncha kun qolganda ogohlantirish


class Status(models.TextChoices):
    TRIAL = "trial", _("sinov")
    ACTIVE = "active", _("faol")
    GRACE = "grace", _("muddati o'tgan")
    READONLY = "readonly", _("faqat ko'rish")
    BLOCKED = "blocked", _("bloklangan")


# Savdo, kirim va boshqa yozuvchi amallar ruxsat etilgan holatlar.
WRITABLE_STATUSES = frozenset({Status.TRIAL, Status.ACTIVE, Status.GRACE})


@dataclass(frozen=True)
class StatusInfo:
    status: Status
    # Joriy holat tugashiga qolgan kunlar (bugun ham hisobga kiradi): trial, active, grace uchun.
    days_left: int | None = None

    @property
    def can_write(self) -> bool:
        return self.status in WRITABLE_STATUSES

    @property
    def expiry_warning(self) -> bool:
        return (
            self.status == Status.ACTIVE
            and self.days_left is not None
            and (self.days_left <= EXPIRY_WARNING_DAYS)
        )


def add_months(value: date, months: int) -> date:
    """Oy qo'shish; kun oy oxiridan oshsa — oy oxiri (31-yanvar + 1 = 28/29-fevral)."""
    month_index = value.month - 1 + months
    year = value.year + month_index // 12
    month = month_index % 12 + 1
    day = min(value.day, calendar.monthrange(year, month)[1])
    return date(year, month, day)


def covered_until(trial_ends_at: date | None, paid_until: date | None) -> date | None:
    """Qoplangan oxirgi kun: to'lov bo'lsa `paid_until`, bo'lmasa sinovning oxirgi kuni."""
    if paid_until is not None:
        return paid_until
    if trial_ends_at is not None:
        return trial_ends_at - timedelta(days=1)
    return None


def compute_status(
    *,
    today: date,
    trial_ends_at: date | None,
    paid_until: date | None,
    grace_days: int,
    is_blocked: bool = False,
) -> StatusInfo:
    if is_blocked:
        return StatusInfo(Status.BLOCKED)
    last_day = covered_until(trial_ends_at, paid_until)
    if last_day is None:
        return StatusInfo(Status.READONLY)
    if today <= last_day:
        status = Status.ACTIVE if paid_until is not None else Status.TRIAL
        return StatusInfo(status, (last_day - today).days + 1)
    grace_end = last_day + timedelta(days=grace_days)
    if today <= grace_end:
        return StatusInfo(Status.GRACE, (grace_end - today).days + 1)
    return StatusInfo(Status.READONLY)
