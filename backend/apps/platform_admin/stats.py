"""Platforma statistikasi (platform-api.md "Statistika")."""

from collections import Counter
from datetime import datetime, time, timedelta
from zoneinfo import ZoneInfo

from django.db.models import Q, Sum
from django.db.models.functions import TruncMonth
from django.utils import timezone

from apps.billing.models import SubscriptionPayment
from apps.billing.services import tenant_today
from apps.billing.status import Status, compute_status
from apps.devices.models import Device
from apps.tenants.models import DEFAULT_TIMEZONE, Tenant

PLATFORM_TZ = ZoneInfo(DEFAULT_TIMEZONE)
EXPIRING_DAYS = 7
STALE_DAYS = 3
STATUSES = ("trial", "active", "grace", "readonly", "blocked")


def stale_q(days: int) -> Q:
    """`days` kundan beri sinxronlanmagan (yoki hech qachon)."""
    border = timezone.now() - timedelta(days=days)
    return Q(last_sync_at__isnull=True) | Q(last_sync_at__lt=border)


def _month_start(day) -> datetime:
    return datetime.combine(day.replace(day=1), time.min, PLATFORM_TZ)


def _shift_months(day, months: int):
    index = day.year * 12 + day.month - 1 + months
    return day.replace(year=index // 12, month=index % 12 + 1, day=1)


def platform_stats() -> dict:
    counts = Counter()
    mrr = 0
    expiring = []
    for tenant in Tenant.objects.select_related("subscription__plan"):
        sub = getattr(tenant, "subscription", None)
        today = tenant_today(tenant)
        info = compute_status(
            today=today,
            trial_ends_at=sub.trial_ends_at if sub else None,
            paid_until=sub.paid_until if sub else None,
            grace_days=sub.grace_days if sub else 0,
            is_blocked=tenant.is_blocked,
        )
        counts[info.status] += 1
        if info.status in (Status.ACTIVE, Status.GRACE):
            mrr += sub.plan.price_tiyin_per_month
        if info.status == Status.ACTIVE and (sub.paid_until - today).days < EXPIRING_DAYS:
            expiring.append(
                {
                    "tenant": tenant.pk,
                    "name": tenant.name,
                    "paid_until": sub.paid_until,
                    "days_left": info.days_left,
                }
            )
    expiring.sort(key=lambda row: (row["paid_until"], row["name"]))

    today = timezone.now().astimezone(PLATFORM_TZ).date()
    this_month = _month_start(today)
    revenue_this_month = (
        SubscriptionPayment.objects.filter(paid_at__gte=this_month).aggregate(
            s=Sum("amount_tiyin")
        )["s"]
        or 0
    )
    first = _shift_months(today, -11)
    by_month = {
        row["month"].date(): row["total"]
        for row in SubscriptionPayment.objects.filter(paid_at__gte=_month_start(first))
        .annotate(month=TruncMonth("paid_at", tzinfo=PLATFORM_TZ))
        .values("month")
        .annotate(total=Sum("amount_tiyin"))
    }
    months = [_shift_months(first, i) for i in range(12)]
    return {
        "tenants": {"total": sum(counts.values()), **{s: counts[s] for s in STATUSES}},
        "mrr_tiyin": mrr,
        "revenue_this_month_tiyin": revenue_this_month,
        "expiring_soon": expiring,
        "stale_devices": Device.objects.filter(stale_q(STALE_DAYS), is_blocked=False).count(),
        "monthly_revenue": [
            {"month": m.strftime("%Y-%m"), "revenue_tiyin": by_month.get(m, 0)} for m in months
        ],
    }
