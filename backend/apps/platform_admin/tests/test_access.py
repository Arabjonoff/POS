"""Har platforma endpoint'i: do'kon xodimi — 403, anonim — 401 (ROADMAP T-020 qabul mezoni)."""

import uuid

import pytest
from rest_framework.test import APIClient

from apps.platform_admin.models import AdminAuditLog

pytestmark = pytest.mark.django_db

ANY = str(uuid.uuid4())
ENDPOINTS = [
    ("get", "/api/v1/platform/tenants/"),
    ("post", "/api/v1/platform/tenants/"),
    ("get", f"/api/v1/platform/tenants/{ANY}/"),
    ("patch", f"/api/v1/platform/tenants/{ANY}/"),
    ("post", f"/api/v1/platform/tenants/{ANY}/block/"),
    ("post", f"/api/v1/platform/tenants/{ANY}/unblock/"),
    ("patch", f"/api/v1/platform/tenants/{ANY}/subscription/"),
    ("get", f"/api/v1/platform/tenants/{ANY}/users/"),
    ("get", f"/api/v1/platform/tenants/{ANY}/payments/"),
    ("post", f"/api/v1/platform/tenants/{ANY}/payments/"),
    ("get", f"/api/v1/platform/tenants/{ANY}/sync-events/"),
    ("post", f"/api/v1/platform/users/{ANY}/reset-password/"),
    ("get", "/api/v1/platform/plans/"),
    ("post", "/api/v1/platform/plans/"),
    ("patch", f"/api/v1/platform/plans/{ANY}/"),
    ("delete", f"/api/v1/platform/plans/{ANY}/"),
    ("get", "/api/v1/platform/payments/"),
    ("post", f"/api/v1/platform/payments/{ANY}/reverse/"),
    ("get", "/api/v1/platform/devices/"),
    ("post", f"/api/v1/platform/devices/{ANY}/block/"),
    ("post", f"/api/v1/platform/devices/{ANY}/unblock/"),
    ("get", "/api/v1/platform/stats/"),
    ("get", "/api/v1/platform/audit-log/"),
]


@pytest.mark.parametrize(("method", "url"), ENDPOINTS)
@pytest.mark.parametrize("role", ["owner", "manager", "cashier"])
def test_tenant_staff_forbidden(client_as, make_user, tenant, method, url, role):
    response = getattr(client_as(make_user(tenant, role=role)), method)(url, {}, format="json")
    assert response.status_code == 403
    assert not AdminAuditLog.objects.exists()


@pytest.mark.parametrize(("method", "url"), ENDPOINTS)
def test_anonymous_unauthorized(method, url):
    assert getattr(APIClient(), method)(url, {}, format="json").status_code == 401


@pytest.mark.parametrize(
    "url", [url for method, url in ENDPOINTS if method == "get" and ANY not in url]
)
def test_platform_admin_allowed(api, url):
    assert api.get(url).status_code == 200
