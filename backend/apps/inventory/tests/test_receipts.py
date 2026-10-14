import pytest

from apps.catalog.models import PriceHistory
from apps.inventory.models import StockMovement, StockReceipt
from apps.inventory.services import current_stock

pytestmark = pytest.mark.django_db

RECEIPTS = "/api/v1/stock-receipts/"


def _payload(product, **extra):
    item = {"product": str(product.id), "qty_milli": 10_000, "cost_price_tiyin": 250_000}
    return {"note": "", "items": [item]} | extra


def _create(client, product, **extra):
    response = client.post(RECEIPTS, _payload(product, **extra), format="json")
    assert response.status_code == 201, response.json()
    return response.json()


def test_create_draft_numbers_and_total(client_as, manager, product, store):
    client = client_as(manager)
    first = _create(client, product)
    second = _create(client, product)
    assert (first["number"], second["number"]) == (1, 2)
    assert first["status"] == "draft"
    assert first["store"] == str(store.id)
    assert first["total_cost_tiyin"] == 2_500_000
    assert first["items"][0]["line_total_tiyin"] == 2_500_000
    assert current_stock(product, store) == 0


def test_line_total_rounds_half_up(client_as, manager, product):
    item = {"product": str(product.id), "qty_milli": 250, "cost_price_tiyin": 1_002}
    response = client_as(manager).post(RECEIPTS, {"items": [item]}, format="json")
    # 1002 * 0.25 = 250.5 → 251
    assert response.json()["total_cost_tiyin"] == 251


def test_client_id_accepted(client_as, manager, product):
    receipt_id = "01920000-0000-7000-8000-000000000001"
    data = _create(client_as(manager), product, id=receipt_id)
    assert data["id"] == receipt_id
    response = client_as(manager).post(RECEIPTS, _payload(product, id=receipt_id), format="json")
    assert response.status_code == 400


@pytest.mark.parametrize(
    "item",
    [
        {"qty_milli": 0, "cost_price_tiyin": 1},
        {"qty_milli": -1, "cost_price_tiyin": 1},
        {"qty_milli": 1.0, "cost_price_tiyin": 1},
        {"qty_milli": 1000, "cost_price_tiyin": -1},
        {"qty_milli": 1000, "cost_price_tiyin": "100"},
        {"qty_milli": 1000, "cost_price_tiyin": 1, "new_sell_price_tiyin": 1.5},
    ],
)
def test_invalid_items_rejected(client_as, manager, product, item):
    payload = {"items": [{"product": str(product.id)} | item]}
    assert client_as(manager).post(RECEIPTS, payload, format="json").status_code == 400


def test_post_receipt_adds_stock_and_prices(client_as, manager, product, store):
    client = client_as(manager)
    item = {
        "product": str(product.id),
        "qty_milli": 12_000,
        "cost_price_tiyin": 320_000,
        "new_sell_price_tiyin": 450_000,
    }
    receipt = client.post(RECEIPTS, {"items": [item]}, format="json").json()
    response = client.post(f"{RECEIPTS}{receipt['id']}/post/")
    assert response.status_code == 200
    assert response.json()["status"] == "posted"
    assert response.json()["posted_at"]

    assert current_stock(product, store) == 12_000
    movement = StockMovement.objects.get(product=product)
    assert (movement.type, movement.qty_milli, movement.ref_type) == (
        "receipt",
        12_000,
        "stock_receipt",
    )
    assert str(movement.ref_id) == receipt["id"]
    assert movement.created_by == manager
    product.refresh_from_db()
    assert (product.cost_price_tiyin, product.sell_price_tiyin) == (320_000, 450_000)
    history = PriceHistory.objects.filter(product=product).latest("created_at")
    assert (history.sell_price_tiyin, history.cost_price_tiyin) == (450_000, 320_000)


def test_post_without_price_change_skips_history(client_as, manager, product):
    item = {"product": str(product.id), "qty_milli": 1000, "cost_price_tiyin": 300_000}
    receipt = client_as(manager).post(RECEIPTS, {"items": [item]}, format="json").json()
    before = PriceHistory.objects.filter(product=product).count()
    client_as(manager).post(f"{RECEIPTS}{receipt['id']}/post/")
    assert PriceHistory.objects.filter(product=product).count() == before


def test_post_twice_conflicts(client_as, manager, product):
    client = client_as(manager)
    receipt = _create(client, product)
    assert client.post(f"{RECEIPTS}{receipt['id']}/post/").status_code == 200
    response = client.post(f"{RECEIPTS}{receipt['id']}/post/")
    assert response.status_code == 409
    assert response.json()["error"]["code"] == "receipt_not_draft"
    assert StockMovement.objects.count() == 1


def test_post_empty_receipt_rejected(client_as, manager):
    client = client_as(manager)
    receipt = client.post(RECEIPTS, {"note": "bo'sh"}, format="json").json()
    response = client.post(f"{RECEIPTS}{receipt['id']}/post/")
    assert response.status_code == 400
    assert response.json()["error"]["code"] == "receipt_empty"


def test_patch_replaces_items_only_in_draft(client_as, manager, product, make_product, tenant):
    client = client_as(manager)
    receipt = _create(client, product)
    other = make_product(tenant, name="Sut")
    item = {"product": str(other.id), "qty_milli": 2000, "cost_price_tiyin": 100_000}
    response = client.patch(f"{RECEIPTS}{receipt['id']}/", {"items": [item]}, format="json")
    assert response.status_code == 200
    data = response.json()
    assert [i["product"] for i in data["items"]] == [str(other.id)]
    assert data["total_cost_tiyin"] == 200_000

    response = client.patch(f"{RECEIPTS}{receipt['id']}/", {"note": "x"}, format="json")
    assert response.json()["items"][0]["product"] == str(other.id)

    client.post(f"{RECEIPTS}{receipt['id']}/post/")
    response = client.patch(f"{RECEIPTS}{receipt['id']}/", {"note": "y"}, format="json")
    assert response.status_code == 409
    assert response.json()["error"]["code"] == "receipt_not_draft"


def test_put_and_detail_post_not_allowed(client_as, manager, product):
    client = client_as(manager)
    receipt = _create(client, product)
    url = f"{RECEIPTS}{receipt['id']}/"
    assert client.put(url, _payload(product), format="json").status_code == 405
    assert client.post(url, {}, format="json").status_code == 405
    assert StockReceipt.objects.get(pk=receipt["id"]).status == "draft"


def test_delete_only_draft(client_as, manager, product):
    client = client_as(manager)
    draft = _create(client, product)
    assert client.delete(f"{RECEIPTS}{draft['id']}/").status_code == 204
    assert not StockReceipt.objects.filter(pk=draft["id"]).exists()

    posted = _create(client, product)
    client.post(f"{RECEIPTS}{posted['id']}/post/")
    response = client.delete(f"{RECEIPTS}{posted['id']}/")
    assert response.status_code == 409
    assert response.json()["error"]["code"] == "receipt_not_draft"


def test_reverse_receipt(client_as, manager, product, store):
    client = client_as(manager)
    receipt = _create(client, product)
    client.post(f"{RECEIPTS}{receipt['id']}/post/")
    product.refresh_from_db()
    prices = (product.sell_price_tiyin, product.cost_price_tiyin)

    response = client.post(f"{RECEIPTS}{receipt['id']}/reverse/", {"note": "xato"}, format="json")
    assert response.status_code == 201
    reversal = response.json()
    assert reversal["reverses"] == receipt["id"]
    assert reversal["status"] == "posted"
    assert reversal["number"] == 2
    assert reversal["note"] == "xato"
    assert reversal["total_cost_tiyin"] == -receipt["total_cost_tiyin"]
    assert reversal["items"][0]["qty_milli"] == -10_000

    assert current_stock(product, store) == 0
    assert StockMovement.objects.filter(product=product).count() == 2
    product.refresh_from_db()
    assert (product.sell_price_tiyin, product.cost_price_tiyin) == prices


def test_reverse_errors(client_as, manager, product):
    client = client_as(manager)
    draft = _create(client, product)
    response = client.post(f"{RECEIPTS}{draft['id']}/reverse/")
    assert (response.status_code, response.json()["error"]["code"]) == (409, "receipt_not_posted")

    client.post(f"{RECEIPTS}{draft['id']}/post/")
    reversal = client.post(f"{RECEIPTS}{draft['id']}/reverse/").json()
    response = client.post(f"{RECEIPTS}{draft['id']}/reverse/")
    assert (response.status_code, response.json()["error"]["code"]) == (409, "already_reversed")

    response = client.post(f"{RECEIPTS}{reversal['id']}/reverse/")
    assert response.status_code == 409
    assert response.json()["error"]["code"] == "cannot_reverse_reversal"


def test_status_filter(client_as, manager, product):
    client = client_as(manager)
    draft = _create(client, product)
    posted = _create(client, product)
    client.post(f"{RECEIPTS}{posted['id']}/post/")
    ids = [r["id"] for r in client.get(f"{RECEIPTS}?status=draft").json()["results"]]
    assert ids == [draft["id"]]


def test_cashier_has_no_access(client_as, cashier, product):
    client = client_as(cashier)
    assert client.get(RECEIPTS).status_code == 403
    assert client.post(RECEIPTS, _payload(product), format="json").status_code == 403


def test_owner_can_manage(client_as, owner, product):
    _create(client_as(owner), product)


def test_other_tenant_isolated(client_as, manager, product, make_user, other_tenant, make_product):
    receipt = _create(client_as(manager), product)
    stranger = client_as(make_user(other_tenant, role="manager"))
    assert stranger.get(RECEIPTS).json()["count"] == 0
    assert stranger.get(f"{RECEIPTS}{receipt['id']}/").status_code == 404
    assert stranger.patch(f"{RECEIPTS}{receipt['id']}/", {}, format="json").status_code == 404
    assert stranger.post(f"{RECEIPTS}{receipt['id']}/post/").status_code == 404
    assert stranger.post(f"{RECEIPTS}{receipt['id']}/reverse/").status_code == 404
    assert stranger.delete(f"{RECEIPTS}{receipt['id']}/").status_code == 404
    # Begona tovar va do'kon payload'da — 400.
    assert stranger.post(RECEIPTS, _payload(product), format="json").status_code == 400
    own = client_as(manager)
    foreign = make_product(other_tenant)
    assert own.post(RECEIPTS, _payload(foreign), format="json").status_code == 400
    other_store = str(other_tenant.stores.get().id)
    response = own.post(RECEIPTS, _payload(product, store=other_store), format="json")
    assert response.status_code == 400
