"""Rollar va tenant izolyatsiyasi: `/api/v1/users/`."""

from types import SimpleNamespace

import pytest

from apps.accounts.models import Role
from apps.accounts.permissions import (
    IsManagerOrOwner,
    IsOwner,
    IsPlatformAdmin,
    IsTenantMember,
)

pytestmark = pytest.mark.django_db

USERS = "/api/v1/users/"


@pytest.mark.parametrize("role", [Role.OWNER, Role.MANAGER])
def test_manager_and_owner_list_own_staff(client_as, make_user, tenant, other_tenant, role):
    me = make_user(tenant, role=role)
    cashier = make_user(tenant, role=Role.CASHIER)
    make_user(other_tenant, role=Role.CASHIER)
    response = client_as(me).get(USERS)
    assert response.status_code == 200
    ids = {row["id"] for row in response.json()["results"]}
    assert ids == {str(me.id), str(cashier.id)}


def test_cashier_cannot_access_manager_endpoint(client_as, make_user, tenant):
    cashier = make_user(tenant, role=Role.CASHIER)
    response = client_as(cashier).get(USERS)
    assert response.status_code == 403


def test_other_tenant_user_not_visible(client_as, owner, make_user, other_tenant):
    foreign = make_user(other_tenant, role=Role.CASHIER)
    response = client_as(owner).get(f"{USERS}{foreign.id}/")
    assert response.status_code == 404


def test_own_user_detail_has_no_secrets(client_as, owner, make_user, tenant):
    cashier = make_user(tenant, role=Role.CASHIER, pin="1234")
    body = client_as(owner).get(f"{USERS}{cashier.id}/").json()
    assert body["id"] == str(cashier.id)
    assert "pin_hash" not in body
    assert "password" not in body


def test_platform_admin_is_not_tenant_staff(client_as, make_user):
    admin = make_user(role=Role.PLATFORM_ADMIN)
    assert client_as(admin).get(USERS).status_code == 403


def test_users_requires_auth(api_client):
    assert api_client.get(USERS).status_code == 401


def test_users_is_read_only(client_as, owner):
    response = client_as(owner).post(USERS, {"full_name": "X"}, format="json")
    assert response.status_code == 405


def _request(role, tenant_id="t1", active=True):
    user = SimpleNamespace(is_authenticated=True, is_active=active, role=role, tenant_id=tenant_id)
    return SimpleNamespace(user=user)


@pytest.mark.parametrize(
    ("permission", "allowed"),
    [
        (IsPlatformAdmin, {Role.PLATFORM_ADMIN}),
        (IsOwner, {Role.OWNER}),
        (IsManagerOrOwner, {Role.OWNER, Role.MANAGER}),
        (IsTenantMember, {Role.OWNER, Role.MANAGER, Role.CASHIER}),
    ],
)
def test_role_matrix(permission, allowed):
    for role in Role:
        tenant_id = None if role == Role.PLATFORM_ADMIN else "t1"
        result = permission().has_permission(_request(role, tenant_id), None)
        assert result is (role in allowed), (permission.__name__, role)


def test_inactive_user_denied():
    assert not IsOwner().has_permission(_request(Role.OWNER, active=False), None)


def test_tenant_role_without_tenant_denied():
    assert not IsTenantMember().has_permission(_request(Role.CASHIER, tenant_id=None), None)
