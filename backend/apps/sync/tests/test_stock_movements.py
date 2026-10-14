import pytest

from apps.core.ids import new_id
from apps.inventory.models import MovementType
from apps.inventory.services import record_movement

pytestmark = pytest.mark.django_db

URL = "/api/v1/sync/stock-movements/"


@pytest.fixture
def movements(product, manager, tenant):
    store = tenant.stores.get()
    record_movement(
        product=product, store=store, qty_milli=10_000, type=MovementType.RECEIPT, user=manager
    )
    record_movement(product=product, store=store, qty_milli=-2_000, type=MovementType.SALE)


def test_device_reads_movements_newest_first(kassa, product, manager, movements):
    _, client = kassa
    response = client.get(URL, {"product": str(product.id)})
    assert response.status_code == 200
    rows = response.json()
    assert [(r["type"], r["qty_milli"]) for r in rows] == [("sale", -2_000), ("receipt", 10_000)]
    assert rows[1]["created_by_name"] == manager.full_name
    assert rows[0]["created_by_name"] is None


def test_other_tenant_device_gets_404(make_device, other_tenant, product, movements):
    _, client = make_device(other_tenant)
    assert client.get(URL, {"product": str(product.id)}).status_code == 404


def test_bad_or_unknown_product(kassa):
    _, client = kassa
    assert client.get(URL, {"product": str(new_id())}).status_code == 404
    assert client.get(URL, {"product": "x"}).status_code == 400


def test_user_jwt_is_not_enough(client_as, manager, product):
    assert client_as(manager).get(URL, {"product": str(product.id)}).status_code in (401, 403)
