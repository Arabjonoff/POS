import pytest

from apps.accounts.models import Role
from apps.customers.models import Customer


@pytest.fixture
def manager(make_user, tenant):
    return make_user(tenant, role=Role.MANAGER)


@pytest.fixture
def cashier(make_user, tenant):
    return make_user(tenant, role=Role.CASHIER)


@pytest.fixture
def make_customer():
    def factory(tenant, **kwargs):
        kwargs.setdefault("full_name", "Anvar aka")
        return Customer.objects.create(tenant=tenant, **kwargs)

    return factory


@pytest.fixture
def customer(make_customer, tenant):
    return make_customer(tenant)
