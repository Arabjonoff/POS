import pytest

from apps.billing.models import Plan, Subscription, SubscriptionPayment

pytestmark = pytest.mark.django_db

PLANS = "/api/v1/platform/plans/"
PAYMENTS = "/api/v1/platform/payments/"


def test_plan_crud(api, last_audit, subscribed, plan):
    payload = {"name": "Premium", "price_tiyin_per_month": 30_000_000, "max_devices": 5}
    response = api.post(PLANS, payload, format="json")
    assert response.status_code == 201
    premium_id = response.json()["id"]
    assert last_audit("plan.create").after["name"] == "Premium"

    response = api.patch(f"{PLANS}{premium_id}/", {"max_users": 10}, format="json")
    assert response.json()["max_users"] == 10
    log = last_audit("plan.update")
    assert (log.before["max_users"], log.after["max_users"]) == (3, 10)

    assert api.delete(f"{PLANS}{premium_id}/").status_code == 204
    assert Plan.objects.get(pk=premium_id).is_active is False
    assert last_audit("plan.deactivate").after["is_active"] is False

    rows = {r["id"]: r for r in api.get(PLANS).json()["results"]}
    assert rows[str(plan.id)]["subscribers_count"] == 1


@pytest.mark.parametrize(
    "payload",
    [
        {"name": "X", "price_tiyin_per_month": 1.5},
        {"name": "X", "price_tiyin_per_month": -1},
        {"name": "", "price_tiyin_per_month": 1},
    ],
)
def test_plan_validation(api, payload):
    assert api.post(PLANS, payload, format="json").status_code == 400


def _pay(api, tenant, **extra):
    payload = {"amount_tiyin": 15_000_000, "months": 1, "method": "cash"} | extra
    return api.post(f"/api/v1/platform/tenants/{tenant.id}/payments/", payload, format="json")


def test_payment_record_and_reverse(api, admin, subscribed, last_audit):
    response = _pay(api, subscribed, note="naqd")
    assert response.status_code == 201
    payment = response.json()
    sub = Subscription.objects.get(tenant=subscribed)
    assert sub.paid_until.isoformat() == payment["period_to"]
    log = last_audit("payment.create")
    assert (log.actor, log.tenant_id, log.after["amount_tiyin"]) == (
        admin,
        subscribed.id,
        15_000_000,
    )
    assert SubscriptionPayment.objects.get(pk=payment["id"]).recorded_by == admin

    second = _pay(api, subscribed, months=2, amount_tiyin=30_000_000).json()
    # Faqat oxirgi to'lovni bekor qilish mumkin.
    response = api.post(f"{PAYMENTS}{payment['id']}/reverse/", {"note": "xato"}, format="json")
    assert (response.status_code, response.json()["error"]["code"]) == (400, "only_latest_payment")
    assert api.post(f"{PAYMENTS}{second['id']}/reverse/", {}, format="json").status_code == 400

    response = api.post(f"{PAYMENTS}{second['id']}/reverse/", {"note": "Ikki marta"}, format="json")
    assert response.status_code == 201
    assert response.json()["amount_tiyin"] == -30_000_000
    sub.refresh_from_db()
    assert sub.paid_until.isoformat() == payment["period_to"]
    log = last_audit("payment.reverse")
    assert (log.reason, log.before["id"], log.after["reverses_id"]) == (
        "Ikki marta",
        second["id"],
        second["id"],
    )


@pytest.mark.parametrize(
    "extra", [{"amount_tiyin": 1.0}, {"months": 0}, {"months": 37}, {"method": "bitcoin"}]
)
def test_payment_validation(api, subscribed, extra):
    assert _pay(api, subscribed, **extra).status_code == 400
    assert not SubscriptionPayment.objects.exists()


def test_payment_without_subscription(api, tenant):
    assert _pay(api, tenant).status_code == 409


def test_payments_list_with_total(api, subscribed, make_tenant, plan):
    from apps.billing.services import start_subscription

    other = make_tenant(name="Boshqa")
    start_subscription(other, plan)
    _pay(api, subscribed, amount_tiyin=10_000_000)
    _pay(api, subscribed, amount_tiyin=20_000_000)
    _pay(api, other, amount_tiyin=5_000_000)

    data = api.get(PAYMENTS).json()
    assert (data["count"], data["total_tiyin"]) == (3, 35_000_000)
    data = api.get(PAYMENTS, {"tenant": str(subscribed.id)}).json()
    assert (data["count"], data["total_tiyin"]) == (2, 30_000_000)
    assert data["results"][0]["tenant_name"] == subscribed.name
    assert (
        api.get(PAYMENTS, {"date_from": "2000-01-01", "date_to": "2000-01-31"}).json()["count"] == 0
    )
    assert api.get(PAYMENTS, {"date_from": "kecha"}).status_code == 400


def test_tenant_payments_history(api, subscribed):
    _pay(api, subscribed)
    rows = api.get(f"/api/v1/platform/tenants/{subscribed.id}/payments/").json()
    assert len(rows) == 1
