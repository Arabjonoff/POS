import pytest
from rest_framework_simplejwt.tokens import RefreshToken

from apps.accounts.models import Role
from conftest import DEFAULT_PASSWORD

pytestmark = pytest.mark.django_db

LOGIN = "/api/v1/auth/login/"
REFRESH = "/api/v1/auth/refresh/"
ME = "/api/v1/auth/me/"


def _login(client, phone, password=DEFAULT_PASSWORD):
    return client.post(LOGIN, {"phone": phone, "password": password}, format="json")


def _error_code(response):
    return response.json()["error"]["code"]


def test_owner_login_returns_tokens_and_user(api_client, owner, tenant):
    response = _login(api_client, owner.phone)
    assert response.status_code == 200
    body = response.json()
    assert body["access"]
    assert body["refresh"]
    assert body["user"] == {
        "id": str(owner.id),
        "phone": owner.phone,
        "full_name": owner.full_name,
        "role": "owner",
        "tenant": {"id": str(tenant.id), "name": tenant.name},
    }
    owner.refresh_from_db()
    assert owner.last_login is not None


def test_login_accepts_human_phone_format(api_client, make_user, tenant):
    make_user(tenant, role=Role.MANAGER, phone="+998935554433")
    assert _login(api_client, "93 555 44 33").status_code == 200


def test_access_token_works_for_me(api_client, owner):
    access = _login(api_client, owner.phone).json()["access"]
    api_client.credentials(HTTP_AUTHORIZATION=f"Bearer {access}")
    response = api_client.get(ME)
    assert response.status_code == 200
    assert response.json()["id"] == str(owner.id)


@pytest.mark.parametrize(
    ("phone", "password"),
    [
        ("+998900000000", DEFAULT_PASSWORD),  # bunday foydalanuvchi yo'q
        (None, "noto'g'ri-parol"),  # parol noto'g'ri
        ("salom", DEFAULT_PASSWORD),  # telefon emas
    ],
)
def test_invalid_credentials(api_client, owner, phone, password):
    response = _login(api_client, phone or owner.phone, password)
    assert response.status_code == 401
    assert _error_code(response) == "invalid_credentials"


def test_missing_fields_is_validation_error(api_client):
    response = api_client.post(LOGIN, {}, format="json")
    assert response.status_code == 400
    assert _error_code(response) == "validation_error"


def test_inactive_user_cannot_login(api_client, owner):
    owner.is_active = False
    owner.save()
    response = _login(api_client, owner.phone)
    assert response.status_code == 401
    assert _error_code(response) == "invalid_credentials"


def test_cashier_cannot_login_with_password(api_client, make_user, tenant):
    cashier = make_user(tenant, role=Role.CASHIER, phone="+998901234000")
    cashier.set_password(DEFAULT_PASSWORD)
    cashier.save()
    response = _login(api_client, cashier.phone)
    assert response.status_code == 401
    assert _error_code(response) == "invalid_credentials"


def test_platform_admin_login_has_no_tenant(api_client, make_user):
    admin = make_user(role=Role.PLATFORM_ADMIN)
    response = _login(api_client, admin.phone)
    assert response.status_code == 200
    assert response.json()["user"]["tenant"] is None
    assert response.json()["user"]["role"] == "platform_admin"


def test_refresh_rotates_tokens(api_client, owner):
    refresh = _login(api_client, owner.phone).json()["refresh"]
    response = api_client.post(REFRESH, {"refresh": refresh}, format="json")
    assert response.status_code == 200
    body = response.json()
    assert body["access"]
    assert body["refresh"]
    assert body["refresh"] != refresh


def test_refresh_rejects_garbage(api_client):
    response = api_client.post(REFRESH, {"refresh": "not-a-token"}, format="json")
    assert response.status_code == 401
    assert _error_code(response) == "token_not_valid"


def test_refresh_rejects_inactive_user(api_client, owner):
    refresh = str(RefreshToken.for_user(owner))
    owner.is_active = False
    owner.save()
    response = api_client.post(REFRESH, {"refresh": refresh}, format="json")
    assert response.status_code == 401
    assert _error_code(response) == "no_active_account"


def test_me_requires_auth(api_client):
    response = api_client.get(ME)
    assert response.status_code == 401


def test_cashier_me(client_as, make_user, tenant):
    cashier = make_user(tenant, role=Role.CASHIER)
    response = client_as(cashier).get(ME)
    assert response.status_code == 200
    assert response.json()["role"] == "cashier"
    assert response.json()["phone"] is None


def test_login_is_throttled(api_client, owner):
    statuses = [_login(api_client, owner.phone, "wrong").status_code for _ in range(21)]
    assert statuses[:20] == [401] * 20
    assert statuses[20] == 429
