import pytest
from django.test import Client

from apps.accounts.models import Role

pytestmark = pytest.mark.django_db


@pytest.fixture
def admin_client(make_user):
    client = Client()
    client.force_login(make_user(role=Role.PLATFORM_ADMIN))
    return client


@pytest.mark.parametrize(
    "url",
    [
        "/admin/",
        "/admin/accounts/user/",
        "/admin/accounts/user/add/",
        "/admin/tenants/tenant/",
        "/admin/tenants/tenant/add/",
        "/admin/tenants/store/",
    ],
)
def test_admin_pages_open(admin_client, url):
    assert admin_client.get(url).status_code == 200


def test_admin_user_change_page(admin_client, owner):
    assert admin_client.get(f"/admin/accounts/user/{owner.pk}/change/").status_code == 200


def test_tenant_staff_cannot_open_admin(owner):
    client = Client()
    client.force_login(owner)
    response = client.get("/admin/")
    assert response.status_code == 302
