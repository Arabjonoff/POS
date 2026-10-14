import pytest
from rest_framework.test import APIClient

from apps.accounts.models import Role
from apps.billing.services import start_subscription
from apps.core.ids import new_id
from apps.devices.models import Device
from apps.devices.tokens import hash_token

pytestmark = pytest.mark.django_db

REGISTER = "/api/v1/devices/register/"
DEVICES = "/api/v1/devices/"


@pytest.fixture
def subscribed(tenant, plan):
    start_subscription(tenant, plan)  # plan.max_devices == 2
    return tenant


def _register(client, **extra):
    payload = {"name": "Kassa 1", "platform": "windows", "app_version": "0.1.0"} | extra
    return client.post(REGISTER, payload, format="json")


def _code(response):
    return response.json()["error"]["code"]


def test_owner_registers_device(client_as, owner, subscribed):
    response = _register(client_as(owner))
    assert response.status_code == 201
    body = response.json()
    token = body["token"]
    assert token.startswith("dev_")
    assert len(token) > 40
    device = Device.objects.get(pk=body["device"]["id"])
    assert device.tenant_id == subscribed.id
    assert device.store == subscribed.stores.get()
    assert device.number == 1
    assert body["device"]["code"] == "D1"
    assert device.registered_by == owner
    # Token ochiq saqlanmaydi.
    assert device.token_hash == hash_token(token)
    assert token not in device.token_hash


@pytest.mark.parametrize("role", [Role.MANAGER, Role.CASHIER])
def test_only_owner_can_register(client_as, make_user, subscribed, role):
    user = make_user(subscribed, role=role)
    assert _register(client_as(user)).status_code == 403
    assert not Device.objects.exists()


def test_register_requires_auth(api_client, subscribed):
    assert _register(api_client).status_code == 401


def test_device_limit_reached(client_as, owner, subscribed):
    client = client_as(owner)
    assert _register(client, name="K1").status_code == 201
    assert _register(client, name="K2").status_code == 201
    response = _register(client, name="K3")
    assert response.status_code == 409
    assert _code(response) == "device_limit_reached"
    assert response.json()["error"]["details"] == {"max_devices": 2}
    assert Device.objects.count() == 2


def test_blocked_device_frees_slot_and_number_not_reused(client_as, owner, subscribed):
    client = client_as(owner)
    _register(client, name="K1")
    second = _register(client, name="K2").json()["device"]["id"]
    Device.objects.filter(pk=second).update(is_blocked=True)
    response = _register(client, name="K3")
    assert response.status_code == 201
    assert response.json()["device"]["number"] == 3


def test_no_subscription(client_as, owner):
    response = _register(client_as(owner))
    assert response.status_code == 409
    assert _code(response) == "no_subscription"


def test_retry_with_same_id_is_idempotent(client_as, owner, subscribed):
    client = client_as(owner)
    device_id = str(new_id())
    first = _register(client, id=device_id)
    assert first.status_code == 201
    second = _register(client, id=device_id, app_version="0.1.1")
    assert second.status_code == 200
    assert second.json()["device"]["id"] == device_id
    assert second.json()["device"]["app_version"] == "0.1.1"
    assert Device.objects.count() == 1
    # Eski token bekor, yangisi ishlaydi.
    me = "/api/v1/devices/me/"
    old = APIClient(HTTP_AUTHORIZATION=f"Device {first.json()['token']}")
    new = APIClient(HTTP_AUTHORIZATION=f"Device {second.json()['token']}")
    assert old.get(me).status_code == 401
    assert new.get(me).status_code == 200


def test_retry_at_limit_still_works(client_as, owner, subscribed):
    client = client_as(owner)
    device_id = str(new_id())
    _register(client, id=device_id)
    _register(client)
    assert _register(client, id=device_id).status_code == 200


def test_reregister_blocked_device(client_as, owner, subscribed):
    client = client_as(owner)
    device_id = str(new_id())
    _register(client, id=device_id)
    Device.objects.filter(pk=device_id).update(is_blocked=True)
    response = _register(client, id=device_id)
    assert response.status_code == 403
    assert _code(response) == "device_blocked"


def test_device_id_of_other_tenant(client_as, owner, subscribed, make_user, other_tenant, plan):
    start_subscription(other_tenant, plan)
    foreign_owner = make_user(other_tenant)
    device_id = str(new_id())
    _register(client_as(foreign_owner), id=device_id)
    response = _register(client_as(owner), id=device_id)
    assert response.status_code == 409
    assert _code(response) == "device_id_conflict"
    assert Device.objects.get(pk=device_id).tenant_id == other_tenant.id


def test_store_of_other_tenant_rejected(client_as, owner, subscribed, other_tenant):
    response = _register(client_as(owner), store=str(other_tenant.stores.get().id))
    assert response.status_code == 400
    assert "store" in response.json()["error"]["details"]


def test_invalid_platform(client_as, owner, subscribed):
    response = _register(client_as(owner), platform="linux")
    assert response.status_code == 400


def test_numbers_are_per_tenant(client_as, owner, subscribed, make_user, other_tenant, plan):
    start_subscription(other_tenant, plan)
    _register(client_as(owner))
    other = _register(client_as(make_user(other_tenant)))
    assert other.json()["device"]["number"] == 1


def test_list_devices_own_tenant_only(client_as, owner, subscribed, make_user, other_tenant, plan):
    start_subscription(other_tenant, plan)
    own = _register(client_as(owner)).json()["device"]["id"]
    foreign = _register(client_as(make_user(other_tenant))).json()["device"]["id"]
    manager = make_user(subscribed, role=Role.MANAGER)
    response = client_as(manager).get(DEVICES)
    assert response.status_code == 200
    rows = response.json()["results"]
    assert [row["id"] for row in rows] == [own]
    assert "token_hash" not in rows[0]
    assert client_as(manager).get(f"{DEVICES}{foreign}/").status_code == 404


def test_cashier_cannot_list_devices(client_as, make_user, subscribed):
    cashier = make_user(subscribed, role=Role.CASHIER)
    assert client_as(cashier).get(DEVICES).status_code == 403
