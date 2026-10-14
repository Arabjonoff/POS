import pytest

from apps.catalog.models import Category
from apps.inventory.models import MovementType, StockMovement
from apps.inventory.services import current_stock, record_movement

pytestmark = pytest.mark.django_db

COUNTS = "/api/v1/inventory-counts/"


def _create(client, items, **extra):
    response = client.post(COUNTS, {"items": items} | extra, format="json")
    assert response.status_code == 201, response.json()
    return response.json()


def _receive(product, store, qty):
    record_movement(product=product, store=store, qty_milli=qty, type=MovementType.RECEIPT)


def test_post_inventory_records_difference(
    client_as, manager, product, make_product, tenant, store
):
    _receive(product, store, 10_000)
    exact = make_product(tenant, name="Sut")
    _receive(exact, store, 3_000)
    untouched = make_product(tenant, name="Tuz")
    _receive(untouched, store, 5_000)

    client = client_as(manager)
    count = _create(
        client,
        [
            {"product": str(product.id), "counted_milli": 7_500},
            {"product": str(exact.id), "counted_milli": 3_000},
        ],
    )
    assert count["status"] == "draft"
    assert count["items"][0]["expected_milli"] is None

    response = client.post(f"{COUNTS}{count['id']}/post/")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "posted"
    by_product = {i["product"]: i for i in data["items"]}
    assert by_product[str(product.id)]["expected_milli"] == 10_000
    assert by_product[str(product.id)]["diff_milli"] == -2_500
    assert by_product[str(exact.id)]["diff_milli"] == 0

    assert current_stock(product, store) == 7_500
    assert current_stock(exact, store) == 3_000
    # Sanalmagan tovar o'zgarmaydi.
    assert current_stock(untouched, store) == 5_000
    movements = list(StockMovement.objects.filter(type=MovementType.INVENTORY))
    assert [(m.product_id, m.qty_milli) for m in movements] == [(product.id, -2_500)]
    assert str(movements[0].ref_id) == count["id"]


def test_count_of_product_without_stock(client_as, manager, product, store):
    client = client_as(manager)
    count = _create(client, [{"product": str(product.id), "counted_milli": 4_000}])
    client.post(f"{COUNTS}{count['id']}/post/")
    assert current_stock(product, store) == 4_000


def test_negative_stock_corrected_to_zero(client_as, manager, product, store):
    record_movement(product=product, store=store, qty_milli=-2_000, type=MovementType.SALE)
    client = client_as(manager)
    count = _create(client, [{"product": str(product.id), "counted_milli": 0}])
    client.post(f"{COUNTS}{count['id']}/post/")
    assert current_stock(product, store) == 0


def test_duplicate_product_rejected(client_as, manager, product):
    items = [
        {"product": str(product.id), "counted_milli": 1},
        {"product": str(product.id), "counted_milli": 2},
    ]
    assert client_as(manager).post(COUNTS, {"items": items}, format="json").status_code == 400


@pytest.mark.parametrize("counted", [-1, 1.5, "10"])
def test_invalid_counted_rejected(client_as, manager, product, counted):
    items = [{"product": str(product.id), "counted_milli": counted}]
    assert client_as(manager).post(COUNTS, {"items": items}, format="json").status_code == 400


def test_category_scope_requires_category(client_as, manager, tenant):
    client = client_as(manager)
    assert client.post(COUNTS, {"scope": "category"}, format="json").status_code == 400
    category = Category.objects.create(tenant=tenant, name="Ichimlik")
    count = _create(client, [], scope="category", category=str(category.id))
    assert count["category"] == str(category.id)


def test_posted_count_is_immutable(client_as, manager, product):
    client = client_as(manager)
    count = _create(client, [{"product": str(product.id), "counted_milli": 1_000}])
    client.post(f"{COUNTS}{count['id']}/post/")
    for response in (
        client.post(f"{COUNTS}{count['id']}/post/"),
        client.patch(f"{COUNTS}{count['id']}/", {"note": "x"}, format="json"),
        client.delete(f"{COUNTS}{count['id']}/"),
    ):
        assert response.status_code == 409
        assert response.json()["error"]["code"] == "count_not_draft"
    assert StockMovement.objects.count() == 1


def test_empty_count_rejected(client_as, manager):
    client = client_as(manager)
    count = _create(client, [])
    response = client.post(f"{COUNTS}{count['id']}/post/")
    assert (response.status_code, response.json()["error"]["code"]) == (400, "count_empty")


def test_draft_can_be_edited_and_deleted(client_as, manager, product, make_product, tenant):
    client = client_as(manager)
    count = _create(client, [{"product": str(product.id), "counted_milli": 1_000}])
    other = make_product(tenant, name="Sut")
    response = client.patch(
        f"{COUNTS}{count['id']}/",
        {"items": [{"product": str(other.id), "counted_milli": 2_000}]},
        format="json",
    )
    assert [i["product"] for i in response.json()["items"]] == [str(other.id)]
    assert client.delete(f"{COUNTS}{count['id']}/").status_code == 204


def test_cashier_has_no_access(client_as, cashier):
    assert client_as(cashier).get(COUNTS).status_code == 403
    assert client_as(cashier).post(COUNTS, {}, format="json").status_code == 403


def test_other_tenant_isolated(client_as, manager, product, make_user, other_tenant):
    count = _create(client_as(manager), [{"product": str(product.id), "counted_milli": 1}])
    stranger = client_as(make_user(other_tenant, role="manager"))
    assert stranger.get(COUNTS).json()["count"] == 0
    assert stranger.get(f"{COUNTS}{count['id']}/").status_code == 404
    assert stranger.post(f"{COUNTS}{count['id']}/post/").status_code == 404
    items = [{"product": str(product.id), "counted_milli": 1}]
    assert stranger.post(COUNTS, {"items": items}, format="json").status_code == 400
