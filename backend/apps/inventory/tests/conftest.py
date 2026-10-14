import pytest

from apps.accounts.models import Role
from apps.catalog.models import Product


@pytest.fixture
def manager(make_user, tenant):
    return make_user(tenant, role=Role.MANAGER)


@pytest.fixture
def cashier(make_user, tenant):
    return make_user(tenant, role=Role.CASHIER)


@pytest.fixture
def store(tenant):
    return tenant.stores.get()


@pytest.fixture
def make_product():
    def factory(tenant, **kwargs):
        kwargs.setdefault("name", "Non")
        kwargs.setdefault("sell_price_tiyin", 400_000)
        kwargs.setdefault("cost_price_tiyin", 300_000)
        return Product.objects.create(tenant=tenant, unit=tenant.units.get(code="pcs"), **kwargs)

    return factory


@pytest.fixture
def product(make_product, tenant):
    return make_product(tenant)
