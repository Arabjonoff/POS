from datetime import UTC, date, datetime

import pytest
import time_machine

from apps.billing.models import ImmutableRecordError, Subscription, SubscriptionPayment
from apps.billing.services import (
    record_payment,
    reverse_payment,
    start_subscription,
    subscription_status,
    tenant_today,
)
from apps.billing.status import Status
from apps.core.exceptions import DomainError

pytestmark = pytest.mark.django_db

START = date(2026, 10, 1)


@pytest.fixture
def sub(tenant, plan):
    return start_subscription(tenant, plan, trial_days=14, today=START)


def _pay(tenant, today, months=1, amount=15_000_000, **kwargs):
    return record_payment(
        tenant, amount_tiyin=amount, months=months, method="cash", today=today, **kwargs
    )


def _reload(sub):
    return Subscription.objects.get(pk=sub.pk)


def test_start_subscription_trial(sub):
    assert sub.trial_ends_at == date(2026, 10, 15)
    assert sub.paid_until is None
    assert sub.status == Status.TRIAL
    assert sub.grace_days == 3
    assert sub.offline_days == 7


def test_second_subscription_rejected(sub, tenant, plan):
    tenant.refresh_from_db()
    with pytest.raises(DomainError) as exc:
        start_subscription(tenant, plan)
    assert exc.value.code == "subscription_exists"


def test_payment_during_trial_starts_after_trial(sub, tenant):
    # Q-002 (B): sinov kunlari kuymaydi.
    payment = _pay(tenant, date(2026, 10, 5))
    assert (payment.period_from, payment.period_to) == (date(2026, 10, 15), date(2026, 11, 15))
    assert payment.previous_paid_until is None
    sub = _reload(sub)
    assert sub.paid_until == date(2026, 11, 15)
    assert sub.status == Status.ACTIVE


def test_payment_extends_active_period(sub, tenant):
    _pay(tenant, date(2026, 10, 5))
    payment = _pay(tenant, date(2026, 11, 1), months=3, amount=45_000_000)
    assert (payment.period_from, payment.period_to) == (date(2026, 11, 15), date(2027, 2, 15))
    assert payment.previous_paid_until == date(2026, 11, 15)
    assert _reload(sub).paid_until == date(2027, 2, 15)


def test_payment_after_readonly_makes_active_again(sub, tenant):
    _pay(tenant, date(2026, 10, 5))  # paid_until 15-noyabr
    late = date(2026, 12, 20)
    assert subscription_status(tenant, late).status == Status.READONLY
    payment = _pay(tenant, late)
    assert payment.period_from == late
    sub = _reload(sub)
    assert sub.paid_until == date(2027, 1, 20)
    assert sub.status == Status.ACTIVE
    assert subscription_status(tenant, late).status == Status.ACTIVE


@pytest.mark.parametrize(
    ("kwargs", "code"),
    [
        ({"amount_tiyin": -1}, "invalid_amount"),
        ({"amount_tiyin": 150.5}, "invalid_amount"),
        ({"amount_tiyin": True}, "invalid_amount"),
        ({"months": 0}, "invalid_months"),
        ({"months": 1.0}, "invalid_months"),
        ({"method": "bitcoin"}, "invalid_method"),
    ],
)
def test_invalid_payment(sub, tenant, kwargs, code):
    params = {"amount_tiyin": 100, "months": 1, "method": "cash", "today": START} | kwargs
    with pytest.raises(DomainError) as exc:
        record_payment(tenant, **params)
    assert exc.value.code == code
    assert not SubscriptionPayment.objects.exists()


def test_payment_without_subscription(tenant):
    with pytest.raises(DomainError) as exc:
        _pay(tenant, START)
    assert exc.value.code == "no_subscription"


def test_payment_records_who(sub, tenant, make_user):
    from apps.accounts.models import Role

    admin = make_user(role=Role.PLATFORM_ADMIN)
    payment = _pay(tenant, START, recorded_by=admin, note="Naqd, ofisda")
    assert payment.recorded_by == admin
    assert payment.note == "Naqd, ofisda"


def test_reverse_latest_payment_restores_paid_until(sub, tenant):
    first = _pay(tenant, date(2026, 10, 5))
    second = _pay(tenant, date(2026, 11, 1), months=2, amount=30_000_000)
    reversal = reverse_payment(second, note="Xato kiritildi", today=date(2026, 11, 2))
    assert reversal.reverses == second
    assert reversal.amount_tiyin == -30_000_000
    assert reversal.months == -2
    assert _reload(sub).paid_until == first.period_to
    # Endi birinchisi oxirgi — uni ham bekor qilsa bo'ladi; sinovga qaytadi.
    reverse_payment(first, today=date(2026, 10, 6))
    sub = _reload(sub)
    assert sub.paid_until is None
    assert sub.status == Status.TRIAL


def test_reverse_non_latest_rejected(sub, tenant):
    first = _pay(tenant, date(2026, 10, 5))
    _pay(tenant, date(2026, 11, 1))
    with pytest.raises(DomainError) as exc:
        reverse_payment(first)
    assert exc.value.code == "only_latest_payment"


def test_reverse_twice_rejected(sub, tenant):
    payment = _pay(tenant, date(2026, 10, 5))
    reversal = reverse_payment(payment)
    with pytest.raises(DomainError) as exc:
        reverse_payment(payment)
    assert exc.value.code == "already_reversed"
    with pytest.raises(DomainError) as exc:
        reverse_payment(reversal)
    assert exc.value.code == "cannot_reverse_reversal"


def test_payment_is_immutable(sub, tenant):
    payment = _pay(tenant, START)
    payment.amount_tiyin = 1
    with pytest.raises(ImmutableRecordError):
        payment.save()
    with pytest.raises(ImmutableRecordError):
        payment.delete()
    assert SubscriptionPayment.objects.get(pk=payment.pk).amount_tiyin == 15_000_000


def test_blocked_tenant_status(sub, tenant):
    tenant.is_blocked = True
    tenant.save()
    assert subscription_status(tenant, date(2026, 10, 5)).status == Status.BLOCKED


def test_tenant_without_subscription_is_readonly(tenant):
    assert subscription_status(tenant, START).status == Status.READONLY


def test_tenant_today_uses_tenant_timezone(tenant):
    # 14-oktabr 20:30 UTC = 15-oktabr 01:30 Toshkent.
    with time_machine.travel(datetime(2026, 10, 14, 20, 30, tzinfo=UTC), tick=False):
        assert tenant_today(tenant) == date(2026, 10, 15)
        tenant.timezone = "UTC"
        assert tenant_today(tenant) == date(2026, 10, 14)
