import pytest
from django.core.management import call_command

from apps.core.models import ImmutableRecordError
from apps.inventory.models import MovementType, ProductStock, StockMovement
from apps.inventory.services import (
    current_stock,
    rebuild_stock,
    record_movement,
    stock_from_movements,
)

pytestmark = pytest.mark.django_db

STOCK = "/api/v1/stock/"
MOVEMENTS = "/api/v1/stock-movements/"


def _move(product, store, qty, type=MovementType.ADJUSTMENT):
    return record_movement(product=product, store=store, qty_milli=qty, type=type)


def test_cache_equals_sum_of_movements(product, store):
    for qty in (5_000, -1_250, 750, -6_000):
        _move(product, store, qty)
    assert current_stock(product, store) == stock_from_movements(product, store) == -1_500


@pytest.mark.parametrize("qty", [0, 1.0, True, "5"])
def test_record_movement_rejects_bad_qty(product, store, qty):
    with pytest.raises(ValueError, match="non-zero int"):
        _move(product, store, qty)


def test_record_movement_rejects_cross_tenant(make_product, other_tenant, store):
    with pytest.raises(ValueError, match="different tenants"):
        _move(make_product(other_tenant), store, 1)


def test_movement_is_immutable(product, store):
    movement = _move(product, store, 1_000)
    movement.qty_milli = 2_000
    with pytest.raises(ImmutableRecordError):
        movement.save()
    with pytest.raises(ImmutableRecordError):
        movement.delete()
    assert StockMovement.objects.get(pk=movement.pk).qty_milli == 1_000


def test_rebuild_stock_fixes_drift(product, make_product, tenant, store, other_tenant):
    _move(product, store, 3_000)
    ProductStock.objects.filter(product=product).update(qty_milli=99)
    orphan = make_product(tenant, name="Sut")
    ProductStock.objects.create(tenant=tenant, product=orphan, store=store, qty_milli=7)
    foreign = make_product(other_tenant)
    other_store = other_tenant.stores.get()
    _move(foreign, other_store, 1)
    ProductStock.objects.filter(product=foreign).update(qty_milli=50)

    assert rebuild_stock(tenant.id) == 2
    assert current_stock(product, store) == 3_000
    assert current_stock(orphan, store) == 0
    # Boshqa tenantga tegilmadi.
    assert current_stock(foreign, other_store) == 50

    ProductStock.objects.filter(product=product).delete()
    call_command("rebuild_stock")
    assert current_stock(product, store) == 3_000
    assert current_stock(foreign, other_store) == 1
    assert rebuild_stock() == 0


def test_stock_list_and_filters(client_as, cashier, product, make_product, tenant, store):
    low = make_product(tenant, name="Sut", min_stock_milli=5_000)
    negative = make_product(tenant, name="Tuz")
    _move(product, store, 10_000, MovementType.RECEIPT)
    _move(low, store, 2_000, MovementType.RECEIPT)
    _move(negative, store, -1_000, MovementType.SALE)
    client = client_as(cashier)

    rows = client.get(STOCK).json()["results"]
    assert {r["product"]: r["qty_milli"] for r in rows} == {
        str(product.id): 10_000,
        str(low.id): 2_000,
        str(negative.id): -1_000,
    }
    assert rows[0]["store"] == str(store.id)

    def products(query):
        return [r["product"] for r in client.get(f"{STOCK}?{query}").json()["results"]]

    assert products("low=true") == [str(low.id)]
    assert products("negative=true") == [str(negative.id)]
    assert products(f"product={product.id}") == [str(product.id)]
    assert client.get(f"{STOCK}?product=abc").status_code == 400


def test_movements_history_newest_first(client_as, cashier, product, store):
    first = _move(product, store, 1_000, MovementType.RECEIPT)
    second = _move(product, store, -250, MovementType.SALE)
    client = client_as(cashier)
    rows = client.get(f"{MOVEMENTS}?product={product.id}").json()["results"]
    assert [r["id"] for r in rows] == [str(second.id), str(first.id)]
    assert rows[0]["qty_milli"] == -250
    rows = client.get(f"{MOVEMENTS}?type=receipt").json()["results"]
    assert [r["id"] for r in rows] == [str(first.id)]


def test_stock_endpoints_are_read_only(client_as, owner):
    client = client_as(owner)
    assert client.post(STOCK, {}, format="json").status_code == 405
    assert client.post(MOVEMENTS, {}, format="json").status_code == 405


def test_stock_requires_auth(api_client):
    assert api_client.get(STOCK).status_code == 401
    assert api_client.get(MOVEMENTS).status_code == 401


def test_other_tenant_isolated(client_as, product, store, make_user, other_tenant):
    _move(product, store, 1_000, MovementType.RECEIPT)
    stranger = client_as(make_user(other_tenant, role="cashier"))
    assert stranger.get(STOCK).json()["count"] == 0
    assert stranger.get(f"{MOVEMENTS}?product={product.id}").json()["count"] == 0
