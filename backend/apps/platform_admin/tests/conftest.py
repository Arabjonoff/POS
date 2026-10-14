import pytest

from apps.accounts.models import Role
from apps.billing.services import start_subscription
from apps.devices.models import Device
from apps.devices.tokens import hash_token, new_token
from apps.platform_admin.models import AdminAuditLog


@pytest.fixture
def admin(make_user):
    return make_user(None, role=Role.PLATFORM_ADMIN)


@pytest.fixture
def api(client_as, admin):
    return client_as(admin)


@pytest.fixture
def subscribed(tenant, plan):
    start_subscription(tenant, plan)
    return tenant


@pytest.fixture
def make_device():
    def factory(tenant, number=1, **kwargs):
        return Device.objects.create(
            tenant=tenant,
            store=tenant.stores.get(),
            number=number,
            name=f"Kassa {number}",
            platform="android",
            token_hash=hash_token(new_token()),
            **kwargs,
        )

    return factory


@pytest.fixture
def last_audit():
    def factory(action):
        return AdminAuditLog.objects.filter(action=action).latest("at")

    return factory
