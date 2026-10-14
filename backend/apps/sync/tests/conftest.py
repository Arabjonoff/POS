import pytest
from rest_framework.test import APIClient

from apps.accounts.models import Role
from apps.catalog.models import Product
from apps.devices.models import Device
from apps.devices.tokens import hash_token, new_token


@pytest.fixture
def manager(make_user, tenant):
    return make_user(tenant, role=Role.MANAGER)


@pytest.fixture
def cashier(make_user, tenant):
    return make_user(tenant, role=Role.CASHIER)


@pytest.fixture
def make_device():
    """`(device, client)` — client `Authorization: Device <token>` bilan."""

    def factory(tenant, number=1):
        token = new_token()
        device = Device.objects.create(
            tenant=tenant,
            store=tenant.stores.get(),
            number=number,
            name=f"Kassa {number}",
            platform="windows",
            token_hash=hash_token(token),
        )
        return device, APIClient(HTTP_AUTHORIZATION=f"Device {token}")

    return factory


@pytest.fixture
def kassa(make_device, tenant):
    return make_device(tenant)


@pytest.fixture
def product(tenant):
    return Product.objects.create(
        tenant=tenant,
        name="Non",
        unit=tenant.units.get(code="pcs"),
        sell_price_tiyin=400_000,
        cost_price_tiyin=300_000,
    )
