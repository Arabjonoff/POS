import pytest

from apps.catalog.models import PriceHistory
from apps.core.ids import new_id

pytestmark = pytest.mark.django_db

URL = "/api/v1/sync/price-history/"


@pytest.fixture
def history(product, manager):
    old = PriceHistory.objects.create(
        tenant=product.tenant,
        product=product,
        sell_price_tiyin=350_000,
        cost_price_tiyin=280_000,
        changed_by=manager,
    )
    new = PriceHistory.objects.create(
        tenant=product.tenant,
        product=product,
        sell_price_tiyin=400_000,
        cost_price_tiyin=300_000,
        changed_by=None,
    )
    return old, new


def test_device_reads_history_newest_first(kassa, product, manager, history):
    _, client = kassa
    response = client.get(URL, {"product": str(product.id)})
    assert response.status_code == 200
    rows = response.json()
    assert [r["sell_price_tiyin"] for r in rows] == [400_000, 350_000]
    assert rows[0]["changed_by_name"] is None
    assert rows[1]["changed_by_name"] == manager.full_name


def test_other_tenant_device_gets_404(make_device, other_tenant, product, history):
    _, client = make_device(other_tenant)
    assert client.get(URL, {"product": str(product.id)}).status_code == 404


def test_unknown_or_bad_product(kassa):
    _, client = kassa
    assert client.get(URL, {"product": str(new_id())}).status_code == 404
    assert client.get(URL, {"product": "x"}).status_code == 400
    assert client.get(URL).status_code == 400


def test_user_jwt_is_not_enough(client_as, manager, product):
    assert client_as(manager).get(URL, {"product": str(product.id)}).status_code in (401, 403)
