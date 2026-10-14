from datetime import timedelta
from zoneinfo import ZoneInfo

import pytest
from django.utils import timezone

from apps.billing.models import Subscription
from apps.billing.services import record_payment, start_subscription, tenant_today

pytestmark = pytest.mark.django_db

DEVICES = "/api/v1/platform/devices/"
STATS = "/api/v1/platform/stats/"


def test_device_list_filters(api, subscribed, make_tenant, make_device):
    old = timezone.now() - timedelta(days=5)
    fresh = make_device(subscribed, 1, last_sync_at=timezone.now())
    stale = make_device(subscribed, 2, last_sync_at=old)
    never = make_device(subscribed, 3)
    other = make_device(make_tenant(), 1, is_blocked=True)

    def ids(**params):
        return {r["id"] for r in api.get(DEVICES, params).json()["results"]}

    assert ids() == {str(d.id) for d in (fresh, stale, never, other)}
    assert ids(tenant=str(subscribed.id)) == {str(d.id) for d in (fresh, stale, never)}
    assert ids(blocked="true") == {str(other.id)}
    assert ids(tenant=str(subscribed.id), stale_days="3") == {str(stale.id), str(never.id)}
    row = api.get(f"{DEVICES}{fresh.id}/").json()
    assert (row["code"], row["tenant_name"]) == ("D1", subscribed.name)
    assert api.get(DEVICES, {"stale_days": "x"}).status_code == 400


def test_block_device(api, subscribed, make_device, last_audit):
    device = make_device(subscribed)
    assert api.post(f"{DEVICES}{device.id}/block/", {}, format="json").status_code == 400
    response = api.post(f"{DEVICES}{device.id}/block/", {"reason": "O'g'irlangan"}, format="json")
    assert response.json()["is_blocked"] is True
    log = last_audit("device.block")
    assert (log.reason, log.tenant_id, log.after["is_blocked"]) == (
        "O'g'irlangan",
        subscribed.id,
        True,
    )
    assert "token_hash" not in log.after
    response = api.post(f"{DEVICES}{device.id}/unblock/", {}, format="json")
    assert response.json()["is_blocked"] is False


def test_stats(api, make_tenant, make_plan, make_device):
    cheap = make_plan(name="Arzon", price_tiyin_per_month=10_000_000)
    rich = make_plan(name="Qimmat", price_tiyin_per_month=30_000_000)

    def tenant_with(plan, name):
        tenant = make_tenant(name=name)
        start_subscription(tenant, plan, trial_days=0)
        return tenant, Subscription.objects.get(tenant=tenant)

    trial = make_tenant(name="Sinov")
    start_subscription(trial, cheap)

    active, _ = tenant_with(rich, "Faol")
    record_payment(active, amount_tiyin=30_000_000, months=1, method="cash")

    expiring, sub = tenant_with(cheap, "Tugayapti")
    record_payment(expiring, amount_tiyin=10_000_000, months=1, method="card")
    sub.refresh_from_db()
    sub.paid_until = tenant_today(expiring) + timedelta(days=2)
    sub.save()

    grace, sub = tenant_with(cheap, "Grace")
    sub.paid_until = tenant_today(grace) - timedelta(days=1)
    sub.save()

    readonly, sub = tenant_with(rich, "Yopilgan")
    sub.paid_until = tenant_today(readonly) - timedelta(days=30)
    sub.save()

    blocked, _ = tenant_with(rich, "Blok")
    blocked.is_blocked = True
    blocked.save()

    make_device(active, 1, last_sync_at=timezone.now())
    make_device(active, 2, last_sync_at=timezone.now() - timedelta(days=10))
    make_device(trial, 1)
    make_device(grace, 1, is_blocked=True)

    data = api.get(STATS).json()
    assert data["tenants"] == {
        "total": 6,
        "trial": 1,
        "active": 2,
        "grace": 1,
        "readonly": 1,
        "blocked": 1,
    }
    # active (30 000 000 + 10 000 000) + grace (10 000 000)
    assert data["mrr_tiyin"] == 50_000_000
    assert data["revenue_this_month_tiyin"] == 40_000_000
    assert [(r["name"], r["days_left"]) for r in data["expiring_soon"]] == [("Tugayapti", 3)]
    assert data["stale_devices"] == 2
    months = data["monthly_revenue"]
    assert len(months) == 12
    assert months[-1] == {
        "month": timezone.now().astimezone(ZoneInfo("Asia/Tashkent")).strftime("%Y-%m"),
        "revenue_tiyin": 40_000_000,
    }
