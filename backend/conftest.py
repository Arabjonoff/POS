import itertools

import pytest
from django.core.cache import cache
from rest_framework.test import APIClient

_seq = itertools.count(1)

DEFAULT_PASSWORD = "Parol-2026!"


@pytest.fixture(autouse=True)
def _clear_cache():
    # Throttle hisoblagichlari testlar orasida o'tib ketmasin.
    cache.clear()
    yield
    cache.clear()


@pytest.fixture
def api_client() -> APIClient:
    return APIClient()


def _phone() -> str:
    return f"+99890{next(_seq):07d}"


@pytest.fixture
def make_tenant(db):
    """Tenant yaratuvchi: `make_tenant(name="Do'kon")`. Har biriga noyob telefon."""
    from apps.tenants.models import Tenant

    def factory(**kwargs):
        kwargs.setdefault("name", f"Do'kon {next(_seq)}")
        kwargs.setdefault("owner_phone", _phone())
        return Tenant.objects.create(**kwargs)

    return factory


@pytest.fixture
def tenant(make_tenant):
    """Joriy (o'z) tenant."""
    return make_tenant(name="Asosiy do'kon")


@pytest.fixture
def other_tenant(make_tenant):
    """Boshqa tenant — izolyatsiya testlari uchun: uning ma'lumoti ko'rinmasligi kerak."""
    return make_tenant(name="Begona do'kon")


@pytest.fixture
def make_user(db):
    """Foydalanuvchi yaratuvchi: `make_user(tenant, role="manager", pin="1234")`.

    Parolli rollarga `DEFAULT_PASSWORD` qo'yiladi; kassirga parol yo'q.
    """
    from apps.accounts.models import PASSWORD_ROLES, Role, User

    def factory(tenant=None, role=Role.OWNER, pin=None, **kwargs):
        if role in PASSWORD_ROLES:
            kwargs.setdefault("phone", _phone())
            kwargs.setdefault("password", DEFAULT_PASSWORD)
        kwargs.setdefault("full_name", f"Xodim {next(_seq)}")
        if role == Role.PLATFORM_ADMIN:
            user = User.objects.create_superuser(**kwargs)
        else:
            user = User.objects.create_user(tenant=tenant, role=role, **kwargs)
        if pin:
            user.set_pin(pin)
            user.save(update_fields=["pin_hash"])
        return user

    return factory


@pytest.fixture
def owner(make_user, tenant):
    return make_user(tenant, role="owner")


@pytest.fixture
def client_as():
    """`client_as(user)` — shu foydalanuvchi sifatida autentifikatsiya qilingan APIClient."""

    def factory(user):
        client = APIClient()
        client.force_authenticate(user=user)
        return client

    return factory
