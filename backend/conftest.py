import itertools

import pytest
from rest_framework.test import APIClient

_phone_seq = itertools.count(1)


@pytest.fixture
def api_client() -> APIClient:
    return APIClient()


@pytest.fixture
def make_tenant(db):
    """Tenant yaratuvchi: `make_tenant(name="Do'kon")`. Har biriga noyob telefon."""
    from apps.tenants.models import Tenant

    def factory(**kwargs):
        kwargs.setdefault("name", f"Do'kon {next(_phone_seq)}")
        kwargs.setdefault("owner_phone", f"+99890{next(_phone_seq):07d}")
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
