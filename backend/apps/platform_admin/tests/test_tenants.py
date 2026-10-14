import pytest
from django.utils import timezone

from apps.accounts.models import User
from apps.billing.models import Subscription
from apps.core.ids import new_id
from apps.platform_admin.models import AdminAuditLog
from apps.sync.models import SyncEvent
from apps.tenants.models import Tenant

pytestmark = pytest.mark.django_db

TENANTS = "/api/v1/platform/tenants/"


def _onboard(api, plan, **extra):
    payload = {
        "name": "Baraka do'koni",
        "address": "Chilonzor 5",
        "owner": {"phone": "90 123 45 67", "full_name": "Sardor Aliyev"},
        "plan": str(plan.id),
        "trial_days": 10,
    } | extra
    return api.post(TENANTS, payload, format="json")


def test_onboarding_creates_everything(api, admin, plan, api_client):
    response = _onboard(api, plan)
    assert response.status_code == 201, response.json()
    data = response.json()
    password = data["temporary_password"]
    assert len(password) == 10

    tenant = Tenant.objects.get(pk=data["tenant"]["id"])
    assert tenant.owner_phone == "+998901234567"
    assert tenant.stores.count() == 1
    assert tenant.units.filter(code="kg").exists()
    owner = User.objects.get(pk=data["owner"]["id"])
    assert (owner.role, owner.tenant_id, owner.full_name) == ("owner", tenant.id, "Sardor Aliyev")
    assert data["tenant"]["status"] == "trial"
    assert data["tenant"]["subscription"]["days_left"] == 10
    assert data["tenant"]["owner_name"] == "Sardor Aliyev"

    login = api_client.post(
        "/api/v1/auth/login/", {"phone": "+998901234567", "password": password}, format="json"
    )
    assert login.status_code == 200

    actions = set(AdminAuditLog.objects.filter(tenant=tenant).values_list("action", flat=True))
    assert actions == {"tenant.create", "user.create", "subscription.create"}
    user_log = AdminAuditLog.objects.get(action="user.create")
    assert user_log.actor == admin
    assert "password" not in user_log.after
    assert password not in str(AdminAuditLog.objects.values_list("after", flat=True))


def test_onboarding_with_given_password(api, plan):
    owner = {"phone": "+998901234568", "full_name": "Ali", "password": "Maxfiy-2026"}
    data = _onboard(api, plan, owner=owner).json()
    assert data["temporary_password"] is None
    assert User.objects.get(pk=data["owner"]["id"]).check_password("Maxfiy-2026")


def test_onboarding_phone_taken_rolls_back(api, plan, owner):
    payload = {"phone": owner.phone, "full_name": "Ikkinchi"}
    before = Tenant.objects.count()
    response = _onboard(api, plan, owner=payload)
    assert (response.status_code, response.json()["error"]["code"]) == (409, "phone_taken")
    assert Tenant.objects.count() == before
    assert not AdminAuditLog.objects.exists()


@pytest.mark.parametrize(
    "extra",
    [
        {"owner": {"phone": "123", "full_name": "X"}},
        {"timezone": "Mars/Olympus"},
        {"trial_days": 91},
        {"name": ""},
        {"owner": {"phone": "+998901234569", "full_name": "X", "password": "short"}},
    ],
)
def test_onboarding_validation(api, plan, extra):
    assert _onboard(api, plan, **extra).status_code == 400


def test_onboarding_rejects_inactive_plan(api, make_plan):
    old = make_plan(is_active=False)
    assert _onboard(api, old).status_code == 400


def test_list_search_and_status(api, subscribed, make_tenant, plan, make_user):
    make_user(subscribed, role="owner", full_name="Ega Egamov")
    blocked = make_tenant(name="Yopiq do'kon", is_blocked=True)
    rows = api.get(TENANTS).json()["results"]
    row = next(r for r in rows if r["id"] == str(subscribed.id))
    assert (row["status"], row["owner_name"], row["plan"]) == ("trial", "Ega Egamov", str(plan.id))

    found = api.get(TENANTS, {"search": "yopiq"}).json()["results"]
    assert [r["id"] for r in found] == [str(blocked.id)]
    by_phone = api.get(TENANTS, {"search": subscribed.owner_phone[-7:]}).json()["results"]
    assert str(subscribed.id) in [r["id"] for r in by_phone]
    assert [r["id"] for r in api.get(TENANTS, {"status": "blocked"}).json()["results"]] == [
        str(blocked.id)
    ]
    trial = api.get(TENANTS, {"status": "trial"}).json()["results"]
    assert str(subscribed.id) in [r["id"] for r in trial]


def test_devices_count_and_last_activity(api, subscribed, make_device):
    seen = timezone.now()
    make_device(subscribed, 1, last_seen_at=seen)
    make_device(subscribed, 2)
    data = api.get(f"{TENANTS}{subscribed.id}/").json()
    assert data["devices_count"] == 2
    assert data["last_activity_at"] is not None


def test_patch_tenant_audited(api, subscribed, last_audit):
    response = api.patch(
        f"{TENANTS}{subscribed.id}/", {"name": "Yangi nom", "notes": "VIP"}, format="json"
    )
    assert response.status_code == 200
    assert response.json()["name"] == "Yangi nom"
    log = last_audit("tenant.update")
    assert log.before["name"] != "Yangi nom"
    assert (log.after["name"], log.after["notes"]) == ("Yangi nom", "VIP")
    assert log.tenant_id == subscribed.id
    assert (
        api.patch(f"{TENANTS}{subscribed.id}/", {"timezone": "X/Y"}, format="json").status_code
        == 400
    )
    assert api.put(f"{TENANTS}{subscribed.id}/", {}, format="json").status_code == 405


def test_block_and_unblock(api, subscribed, last_audit):
    url = f"{TENANTS}{subscribed.id}/"
    assert api.post(f"{url}block/", {}, format="json").status_code == 400
    data = api.post(f"{url}block/", {"reason": "To'lov yo'q"}, format="json").json()
    assert (data["status"], data["is_blocked"], data["blocked_reason"]) == (
        "blocked",
        True,
        "To'lov yo'q",
    )
    assert Subscription.objects.get(tenant=subscribed).status == "blocked"
    log = last_audit("tenant.block")
    assert (log.reason, log.before["is_blocked"], log.after["is_blocked"]) == (
        "To'lov yo'q",
        False,
        True,
    )

    data = api.post(f"{url}unblock/", {}, format="json").json()
    assert (data["status"], data["blocked_reason"]) == ("trial", "")
    assert last_audit("tenant.unblock").after["is_blocked"] is False


def test_subscription_settings(api, subscribed, make_plan, last_audit):
    premium = make_plan(name="Premium")
    response = api.patch(
        f"{TENANTS}{subscribed.id}/subscription/",
        {"plan": str(premium.id), "grace_days": 5, "offline_days": 14},
        format="json",
    )
    assert response.status_code == 200
    sub = response.json()["subscription"]
    assert (sub["plan"], sub["grace_days"], sub["offline_days"]) == (str(premium.id), 5, 14)
    log = last_audit("subscription.update")
    assert log.after["plan_id"] == str(premium.id)
    assert log.tenant_id == subscribed.id
    # paid_until faqat to'lov orqali o'zgaradi.
    api.patch(
        f"{TENANTS}{subscribed.id}/subscription/", {"paid_until": "2030-01-01"}, format="json"
    )
    assert Subscription.objects.get(tenant=subscribed).paid_until is None


def test_subscription_missing(api, tenant):
    response = api.patch(f"{TENANTS}{tenant.id}/subscription/", {"grace_days": 1}, format="json")
    assert response.status_code == 409


def test_users_and_password_reset(api, subscribed, make_user, api_client, last_audit):
    owner = make_user(subscribed, role="owner")
    cashier = make_user(subscribed, role="cashier")
    users = api.get(f"{TENANTS}{subscribed.id}/users/").json()
    assert {u["id"] for u in users} == {str(owner.id), str(cashier.id)}

    response = api.post(f"/api/v1/platform/users/{owner.id}/reset-password/")
    password = response.json()["temporary_password"]
    login = api_client.post(
        "/api/v1/auth/login/", {"phone": owner.phone, "password": password}, format="json"
    )
    assert login.status_code == 200
    log = last_audit("user.reset_password")
    assert (log.target_id, log.tenant_id, log.before, log.after) == (
        str(owner.id),
        subscribed.id,
        None,
        None,
    )

    response = api.post(f"/api/v1/platform/users/{cashier.id}/reset-password/")
    assert response.status_code == 409


def test_reset_password_ignores_platform_admins(api, admin):
    assert api.post(f"/api/v1/platform/users/{admin.id}/reset-password/").status_code == 404


def test_sync_events(api, subscribed, make_device):
    device = make_device(subscribed)
    for status in ("applied", "rejected"):
        SyncEvent.objects.create(
            id=new_id(),
            tenant=subscribed,
            device=device,
            type="sale.completed",
            payload={},
            client_created_at=timezone.now(),
            status=status,
        )
    url = f"{TENANTS}{subscribed.id}/sync-events/"
    assert api.get(url).json()["count"] == 2
    rejected = api.get(url, {"status": "rejected"}).json()["results"]
    assert [e["status"] for e in rejected] == ["rejected"]
