from datetime import date

import pytest
from rest_framework.test import APIClient

from apps.billing.services import record_payment, start_subscription
from apps.devices.models import Device
from apps.devices.services import register_device

pytestmark = pytest.mark.django_db

ME = "/api/v1/devices/me/"


@pytest.fixture
def device_and_token(tenant, plan, owner):
    start_subscription(tenant, plan)
    device, token, _ = register_device(user=owner, name="Kassa", platform="android")
    return device, token


def _client(token, keyword="Device"):
    return APIClient(HTTP_AUTHORIZATION=f"{keyword} {token}")


def test_device_me(device_and_token):
    device, token = device_and_token
    response = _client(token).get(ME)
    assert response.status_code == 200
    body = response.json()
    assert body["device"]["id"] == str(device.id)
    assert body["subscription"]["status"] == "trial"
    assert body["subscription"]["offline_days"] == 7
    assert body["server_time"]
    device.refresh_from_db()
    assert device.last_seen_at is not None
    assert device.last_ip == "127.0.0.1"


def test_device_me_shows_paid_subscription(device_and_token, tenant):
    _, token = device_and_token
    record_payment(tenant, amount_tiyin=100, months=1, method="cash")
    sub = _client(token).get(ME).json()["subscription"]
    assert sub["status"] == "active"
    assert date.fromisoformat(sub["paid_until"]) > date.today()


@pytest.mark.parametrize(
    "header",
    ["Device", "Device dev_wrong", "Device notprefixed", "Device a b"],
)
def test_bad_token_401(device_and_token, header):
    response = APIClient(HTTP_AUTHORIZATION=header).get(ME)
    assert response.status_code == 401
    assert response["WWW-Authenticate"].startswith("Device")


def test_no_token_401(api_client):
    assert api_client.get(ME).status_code == 401


def test_blocked_device_403(device_and_token):
    device, token = device_and_token
    Device.objects.filter(pk=device.pk).update(is_blocked=True)
    response = _client(token).get(ME)
    assert response.status_code == 403
    assert response.json()["error"]["code"] == "device_blocked"


def test_readonly_tenant_device_still_connects(device_and_token, tenant):
    # Obuna tugasa ham sinxron ishlaydi (sync.md).
    _, token = device_and_token
    tenant.is_blocked = True
    tenant.save()
    response = _client(token).get(ME)
    assert response.status_code == 200
    assert response.json()["subscription"]["status"] == "blocked"


def test_device_token_not_accepted_on_user_endpoints(device_and_token):
    _, token = device_and_token
    assert _client(token).get("/api/v1/users/").status_code == 401
    assert _client(token).get("/api/v1/auth/me/").status_code == 401


def test_user_jwt_not_accepted_on_device_endpoint(api_client, owner):
    login = api_client.post(
        "/api/v1/auth/login/",
        {"phone": owner.phone, "password": "Parol-2026!"},
        format="json",
    )
    access = login.json()["access"]
    assert _client(access, keyword="Bearer").get(ME).status_code == 401


def test_device_token_with_bearer_keyword_rejected(device_and_token):
    _, token = device_and_token
    assert _client(token, keyword="Bearer").get(ME).status_code == 401
