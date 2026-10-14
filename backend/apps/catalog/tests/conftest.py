import pytest

from apps.accounts.models import Role


@pytest.fixture
def manager(make_user, tenant):
    return make_user(tenant, role=Role.MANAGER)


@pytest.fixture
def cashier(make_user, tenant):
    return make_user(tenant, role=Role.CASHIER)


@pytest.fixture
def unit_pcs(tenant):
    return tenant.units.get(code="pcs")


@pytest.fixture
def unit_kg(tenant):
    return tenant.units.get(code="kg")


@pytest.fixture
def product_payload(unit_pcs):
    def factory(**extra):
        return {
            "name": "Non",
            "unit": str(unit_pcs.id),
            "sell_price_tiyin": 400_000,
            "cost_price_tiyin": 320_000,
        } | extra

    return factory
