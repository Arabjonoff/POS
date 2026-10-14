"""Obuna amallari. `paid_until` faqat shu yerda o'zgaradi."""

from datetime import date, timedelta
from zoneinfo import ZoneInfo

from django.db import transaction
from django.utils import timezone

from apps.core.exceptions import DomainError

from .models import PaymentMethod, Plan, Subscription, SubscriptionPayment
from .status import StatusInfo, add_months, compute_status

DEFAULT_TRIAL_DAYS = 14


def tenant_today(tenant) -> date:
    return timezone.localdate(timezone=ZoneInfo(tenant.timezone))


def subscription_status(tenant, today: date | None = None) -> StatusInfo:
    """Tenantning hozirgi obuna holati (har so'rovda shu bilan tekshiriladi)."""
    today = today or tenant_today(tenant)
    sub = Subscription.objects.filter(tenant=tenant).first()
    return compute_status(
        today=today,
        trial_ends_at=sub.trial_ends_at if sub else None,
        paid_until=sub.paid_until if sub else None,
        grace_days=sub.grace_days if sub else 0,
        is_blocked=tenant.is_blocked,
    )


def subscription_snapshot(tenant) -> dict:
    """Kassaga beriladigan obuna holati (`/devices/me/`, `/sync/pull/`)."""
    info = subscription_status(tenant)
    sub = Subscription.objects.filter(tenant=tenant).first()
    return {
        "status": info.status,
        "paid_until": sub.paid_until if sub else None,
        "days_left": info.days_left,
        "offline_days": sub.offline_days if sub else 0,
    }


def refresh_status(sub: Subscription, today: date | None = None) -> bool:
    """Kesh holatni yangilaydi; o'zgargan bo'lsa `True`."""
    info = subscription_status(sub.tenant, today)
    if sub.status == info.status:
        return False
    sub.status = info.status
    sub.status_changed_at = timezone.now()
    sub.save(update_fields=["status", "status_changed_at", "updated_at"])
    return True


def start_subscription(
    tenant, plan: Plan, trial_days: int = DEFAULT_TRIAL_DAYS, today: date | None = None
) -> Subscription:
    if hasattr(tenant, "subscription"):
        raise DomainError("subscription_exists", "Tenant already has a subscription.")
    today = today or tenant_today(tenant)
    sub = Subscription.objects.create(
        tenant=tenant, plan=plan, trial_ends_at=today + timedelta(days=trial_days)
    )
    refresh_status(sub, today)
    return sub


@transaction.atomic
def record_payment(
    tenant,
    *,
    amount_tiyin: int,
    months: int,
    method: str,
    recorded_by=None,
    note: str = "",
    today: date | None = None,
) -> SubscriptionPayment:
    if not isinstance(amount_tiyin, int) or isinstance(amount_tiyin, bool) or amount_tiyin < 0:
        raise DomainError("invalid_amount", "Amount must be a non-negative integer (tiyin).")
    if not isinstance(months, int) or isinstance(months, bool) or months < 1:
        raise DomainError("invalid_months", "Months must be a positive integer.")
    if method not in PaymentMethod.values:
        raise DomainError("invalid_method", "Unknown payment method.")
    sub = Subscription.objects.select_for_update().filter(tenant=tenant).first()
    if sub is None:
        raise DomainError("no_subscription", "Tenant has no subscription.", status_code=409)
    today = today or tenant_today(tenant)
    # Q-002 (B): sinov ichida to'lansa, to'langan davr sinovdan keyin boshlanadi.
    candidates = [today]
    if sub.paid_until is not None:
        candidates.append(sub.paid_until)
    if sub.trial_ends_at is not None:
        candidates.append(sub.trial_ends_at)
    period_from = max(candidates)
    period_to = add_months(period_from, months)
    payment = SubscriptionPayment.objects.create(
        tenant=tenant,
        amount_tiyin=amount_tiyin,
        months=months,
        period_from=period_from,
        period_to=period_to,
        previous_paid_until=sub.paid_until,
        method=method,
        note=note,
        recorded_by=recorded_by,
    )
    sub.paid_until = period_to
    sub.save(update_fields=["paid_until", "updated_at"])
    refresh_status(sub, today)
    return payment


@transaction.atomic
def reverse_payment(
    payment: SubscriptionPayment, *, recorded_by=None, note: str = "", today: date | None = None
) -> SubscriptionPayment:
    """Oxirgi bekor qilinmagan to'lovni bekor qiladi: teskari yozuv, `paid_until` qaytadi."""
    sub = Subscription.objects.select_for_update().get(tenant_id=payment.tenant_id)
    if payment.reverses_id is not None:
        raise DomainError("cannot_reverse_reversal", "A reversal cannot be reversed.")
    if SubscriptionPayment.objects.filter(reverses=payment).exists():
        raise DomainError("already_reversed", "Payment is already reversed.")
    latest = (
        SubscriptionPayment.objects.filter(
            tenant_id=payment.tenant_id, reverses__isnull=True, reversal__isnull=True
        )
        .order_by("-period_to", "-paid_at", "-id")
        .first()
    )
    if latest is None or latest.pk != payment.pk or sub.paid_until != payment.period_to:
        raise DomainError("only_latest_payment", "Only the latest payment can be reversed.")
    reversal = SubscriptionPayment.objects.create(
        tenant_id=payment.tenant_id,
        amount_tiyin=-payment.amount_tiyin,
        months=-payment.months,
        period_from=payment.period_from,
        period_to=payment.period_to,
        previous_paid_until=sub.paid_until,
        method=payment.method,
        note=note,
        recorded_by=recorded_by,
        reverses=payment,
    )
    sub.paid_until = payment.previous_paid_until
    sub.save(update_fields=["paid_until", "updated_at"])
    refresh_status(sub, today)
    return reversal
