import pytest

from apps.catalog.models import Category, Product
from apps.catalog.services import soft_delete_category
from apps.core.ids import new_id
from apps.customers.models import Customer
from apps.customers.services import record_sale_debt
from apps.inventory.models import MovementType
from apps.inventory.services import record_movement
from apps.sync.models import ChangeLog
from apps.sync.pull import parse_cursor

from .helpers import PULL, push, sale_completed, shift_opened

pytestmark = pytest.mark.django_db


def _pull(client, cursor="0", limit=500):
    response = client.get(PULL, {"cursor": cursor, "limit": limit})
    assert response.status_code == 200, response.json()
    return response.json()


def _drain(client, cursor="0", limit=500):
    """Hamma sahifalarni o'qiydi → (changes, oxirgi kursor)."""
    changes = []
    while True:
        page = _pull(client, cursor, limit)
        changes += page["changes"]
        cursor = page["next_cursor"]
        if not page["has_more"]:
            return changes, cursor


def _by_entity(changes, entity):
    return {c["id"]: c for c in changes if c["entity"] == entity}


def test_initial_pull_has_store_units_and_users(kassa, tenant, cashier):
    _, client = kassa
    page = _pull(client)
    assert page["has_more"] is False
    assert page["subscription"]["status"]
    assert page["server_time"]
    changes = page["changes"]

    stores = _by_entity(changes, "store")
    assert set(stores) == {str(tenant.stores.get().id)}
    units = _by_entity(changes, "unit")
    assert {u["data"]["code"] for u in units.values()} >= {"pcs", "kg"}
    user = _by_entity(changes, "user")[str(cashier.id)]["data"]
    assert user["role"] == "cashier"
    assert "pin_hash" in user


def test_cursor_only_returns_newer_changes(kassa, tenant):
    _, client = kassa
    _, cursor = _drain(client)
    assert _pull(client, cursor)["changes"] == []

    category = Category.objects.create(tenant=tenant, name="Ichimlik")
    page = _pull(client, cursor)
    assert [(c["entity"], c["op"], c["id"]) for c in page["changes"]] == [
        ("category", "upsert", str(category.id))
    ]
    assert page["changes"][0]["data"]["name"] == "Ichimlik"


def test_pagination_without_gaps_or_repeats(kassa, tenant):
    _, client = kassa
    _, cursor = _drain(client)
    created = {str(Category.objects.create(tenant=tenant, name=f"K{i}").id) for i in range(7)}
    changes, _ = _drain(client, cursor, limit=3)
    ids = [c["id"] for c in changes]
    assert sorted(ids) == sorted(created)


def test_page_dedupes_same_object(kassa, tenant):
    _, client = kassa
    _, cursor = _drain(client)
    category = Category.objects.create(tenant=tenant, name="A")
    for name in ("B", "C"):
        category.name = name
        category.save()
    changes = _pull(client, cursor)["changes"]
    assert len(changes) == 1
    assert changes[0]["data"]["name"] == "C"


def test_soft_delete_is_delete_op(kassa, tenant):
    _, client = kassa
    parent = Category.objects.create(tenant=tenant, name="Oziq-ovqat")
    child = Category.objects.create(tenant=tenant, name="Non", parent=parent)
    product = Product.objects.create(
        tenant=tenant,
        name="Non",
        unit=tenant.units.get(code="pcs"),
        sell_price_tiyin=1,
        category=child,
    )
    _, cursor = _drain(client)

    soft_delete_category(parent)
    changes = _pull(client, cursor)["changes"]
    categories = _by_entity(changes, "category")
    assert {c["op"] for c in categories.values()} == {"delete"}
    assert set(categories) == {str(parent.id), str(child.id)}
    assert all(c["data"] is None for c in categories.values())
    # Tovar kategoriyasiz qoldi — u ham yangilanadi.
    assert _by_entity(changes, "product")[str(product.id)]["data"]["category"] is None


def test_product_with_barcodes(kassa, client_as, owner, tenant):
    _, client = kassa
    _, cursor = _drain(client)
    response = client_as(owner).post(
        "/api/v1/products/",
        {
            "name": "Sut",
            "unit": str(tenant.units.get(code="pcs").id),
            "sell_price_tiyin": 1_200_000,
            "barcodes": ["4780000000007"],
        },
        format="json",
    )
    assert response.status_code == 201
    product = _by_entity(_pull(client, cursor)["changes"], "product")[response.json()["id"]]
    assert product["data"]["barcodes"] == ["4780000000007"]


def test_stock_and_debt_after_sale(kassa, tenant, cashier, product):
    _, client = kassa
    customer = Customer.objects.create(tenant=tenant, full_name="Anvar")
    _, cursor = _drain(client)
    shift_id = new_id()
    push(client, shift_opened(cashier, shift_id), sale_completed(shift_id, cashier, product))
    entry = record_sale_debt(customer, amount_tiyin=5_000, sale_id=new_id())

    changes = _pull(client, cursor)["changes"]
    stock = _by_entity(changes, "stock")[str(product.id)]["data"]
    assert stock["qty_milli"] == -1_000
    debt = _by_entity(changes, "debt_entry")[str(entry.id)]["data"]
    assert debt["amount_tiyin"] == 5_000


def test_stock_change_via_update_is_logged(kassa, tenant, product):
    _, client = kassa
    store = tenant.stores.get()
    record_movement(product=product, store=store, qty_milli=1_000, type=MovementType.RECEIPT)
    _, cursor = _drain(client)
    # Ikkinchi harakat keshni `update()` bilan o'zgartiradi (signal yo'q).
    record_movement(product=product, store=store, qty_milli=500, type=MovementType.RECEIPT)
    stock = _by_entity(_pull(client, cursor)["changes"], "stock")[str(product.id)]["data"]
    assert stock["qty_milli"] == 1_500


def test_customer_has_balance(kassa, tenant):
    _, client = kassa
    customer = Customer.objects.create(tenant=tenant, full_name="Anvar")
    record_sale_debt(customer, amount_tiyin=7_000, sale_id=new_id())
    changes, _ = _drain(client)
    assert _by_entity(changes, "customer")[str(customer.id)]["data"]["balance_tiyin"] == 7_000


def test_new_tenant_units_logged(make_tenant):
    tenant = make_tenant()
    entities = set(ChangeLog.objects.filter(tenant=tenant).values_list("entity", flat=True))
    assert {"unit", "store"} <= entities


def test_other_tenant_changes_invisible(kassa, other_tenant):
    _, client = kassa
    foreign = Category.objects.create(tenant=other_tenant, name="Begona")
    changes, _ = _drain(client)
    assert str(foreign.id) not in {c["id"] for c in changes}
    assert str(other_tenant.stores.get().id) not in {c["id"] for c in changes}


@pytest.mark.parametrize(
    "query", [{"cursor": "abc"}, {"cursor": "1"}, {"limit": 0}, {"limit": 501}]
)
def test_bad_query(kassa, query):
    _, client = kassa
    assert client.get(PULL, query).status_code == 400


def test_cursor_format():
    assert parse_cursor("0") == (0, 0)
    assert parse_cursor("12:34") == (12, 34)
    with pytest.raises(ValueError, match="cursor"):
        parse_cursor("-1:2")


def test_requires_device_token(api_client):
    assert api_client.get(PULL).status_code == 401


def test_pull_updates_device(kassa):
    device, client = kassa
    _pull(client)
    device.refresh_from_db()
    assert device.last_sync_at is not None
