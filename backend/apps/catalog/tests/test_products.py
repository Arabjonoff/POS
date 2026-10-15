import pytest

from apps.catalog.models import Category, PriceHistory, Product, ProductBarcode
from apps.core.ids import new_id

pytestmark = pytest.mark.django_db

PRODUCTS = "/api/v1/products/"


def _code(response):
    return response.json()["error"]["code"]


def test_create_product_with_barcodes(client_as, manager, tenant, product_payload, unit_pcs):
    response = client_as(manager).post(
        PRODUCTS, product_payload(barcodes=[" 4780000000014 ", "ABC-123"]), format="json"
    )
    assert response.status_code == 201, response.json()
    body = response.json()
    assert body["barcodes"] == ["4780000000014", "ABC-123"]
    assert body["markup_bp"] == 2500  # (4000 − 3200) / 3200 = 25%
    product = Product.objects.get(pk=body["id"])
    assert product.tenant_id == tenant.id
    assert product.unit == unit_pcs
    primary = ProductBarcode.objects.get(product=product, is_primary=True)
    assert primary.barcode == "4780000000014"


def test_client_generated_id(client_as, manager, product_payload):
    product_id = str(new_id())
    response = client_as(manager).post(PRODUCTS, product_payload(id=product_id), format="json")
    assert response.status_code == 201
    assert response.json()["id"] == product_id
    again = client_as(manager).post(PRODUCTS, product_payload(id=product_id), format="json")
    assert again.status_code == 400


def test_cashier_reads_but_cannot_write(client_as, cashier, manager, product_payload):
    created = client_as(manager).post(PRODUCTS, product_payload(), format="json").json()
    client = client_as(cashier)
    assert client.get(PRODUCTS).status_code == 200
    assert client.get(f"{PRODUCTS}{created['id']}/").status_code == 200
    assert client.post(PRODUCTS, product_payload(), format="json").status_code == 403
    patch = client.patch(f"{PRODUCTS}{created['id']}/", {"name": "X"}, format="json")
    assert patch.status_code == 403
    assert client.delete(f"{PRODUCTS}{created['id']}/").status_code == 403


@pytest.mark.parametrize("price", [400_000.5, 400_000.0, "400000", True, -1, None])
def test_money_must_be_integer(client_as, manager, product_payload, price):
    response = client_as(manager).post(
        PRODUCTS, product_payload(sell_price_tiyin=price), format="json"
    )
    assert response.status_code == 400
    assert "sell_price_tiyin" in response.json()["error"]["details"]


def test_duplicate_barcode_rejected(client_as, manager, product_payload):
    client = client_as(manager)
    first = client.post(PRODUCTS, product_payload(barcodes=["4780000000014"]), format="json")
    response = client.post(
        PRODUCTS, product_payload(name="Boshqa", barcodes=["4780000000014"]), format="json"
    )
    assert response.status_code == 409
    error = response.json()["error"]
    assert error["code"] == "barcode_taken"
    assert error["details"] == {
        "barcode": "4780000000014",
        "product": {"id": first.json()["id"], "name": "Non"},
    }
    assert Product.objects.count() == 1


def test_duplicate_barcode_in_one_request(client_as, manager, product_payload):
    response = client_as(manager).post(
        PRODUCTS, product_payload(barcodes=["ABC-123", " ABC-123"]), format="json"
    )
    assert response.status_code == 400
    assert "barcodes" in response.json()["error"]["details"]


def test_bad_check_digit_rejected(client_as, manager, product_payload):
    response = client_as(manager).post(
        PRODUCTS, product_payload(barcodes=["4780000000013"]), format="json"
    )
    assert response.status_code == 400
    assert "barcodes" in response.json()["error"]["details"]


def test_same_barcode_in_other_tenant_allowed(
    client_as, manager, make_user, other_tenant, product_payload
):
    client_as(manager).post(PRODUCTS, product_payload(barcodes=["4780000000014"]), format="json")
    other = make_user(other_tenant, role="manager")
    payload = product_payload(
        unit=str(other_tenant.units.get(code="pcs").id), barcodes=["4780000000014"]
    )
    assert client_as(other).post(PRODUCTS, payload, format="json").status_code == 201


def test_update_replaces_barcodes_and_frees_old(client_as, manager, product_payload):
    client = client_as(manager)
    first = client.post(PRODUCTS, product_payload(barcodes=["AAA-1", "BBB-2"]), format="json")
    pid = first.json()["id"]
    response = client.patch(f"{PRODUCTS}{pid}/", {"barcodes": ["BBB-2", "CCC-3"]}, format="json")
    assert response.status_code == 200
    assert response.json()["barcodes"] == ["BBB-2", "CCC-3"]
    assert ProductBarcode.objects.get(barcode="BBB-2", deleted_at__isnull=True).is_primary
    # Bo'shatilgan kodni boshqa tovar olishi mumkin.
    other = client.post(PRODUCTS, product_payload(name="Y", barcodes=["AAA-1"]), format="json")
    assert other.status_code == 201


def test_patch_keeping_own_barcode_ok(client_as, manager, product_payload):
    client = client_as(manager)
    pid = client.post(PRODUCTS, product_payload(barcodes=["AAA-1"]), format="json").json()["id"]
    response = client.patch(f"{PRODUCTS}{pid}/", {"barcodes": ["AAA-1"]}, format="json")
    assert response.status_code == 200


def test_delete_deactivates(client_as, manager, product_payload):
    client = client_as(manager)
    pid = client.post(PRODUCTS, product_payload(barcodes=["AAA-1"]), format="json").json()["id"]
    assert client.delete(f"{PRODUCTS}{pid}/").status_code == 204
    product = Product.objects.get(pk=pid)
    assert product.is_active is False
    assert not product.is_deleted
    assert client.get(f"{PRODUCTS}{pid}/").json()["is_active"] is False
    assert client.get(f"{PRODUCTS}?is_active=true").json()["count"] == 0
    assert client.get(f"{PRODUCTS}?is_active=false").json()["count"] == 1


def test_weighted_needs_fractional_unit(client_as, manager, product_payload, unit_kg):
    client = client_as(manager)
    bad = client.post(PRODUCTS, product_payload(is_weighted=True), format="json")
    assert bad.status_code == 400
    assert "unit" in bad.json()["error"]["details"]
    ok = client.post(
        PRODUCTS,
        product_payload(name="Kartoshka", is_weighted=True, unit=str(unit_kg.id), plu_code="00123"),
        format="json",
    )
    assert ok.status_code == 201


@pytest.mark.parametrize("plu", ["123", "123456", "12a45"])
def test_plu_format(client_as, manager, product_payload, unit_kg, plu):
    response = client_as(manager).post(
        PRODUCTS,
        product_payload(is_weighted=True, unit=str(unit_kg.id), plu_code=plu),
        format="json",
    )
    assert response.status_code == 400


def test_plu_unique_among_active(client_as, manager, product_payload, unit_kg):
    client = client_as(manager)
    payload = product_payload(is_weighted=True, unit=str(unit_kg.id), plu_code="00123")
    first = client.post(PRODUCTS, payload, format="json").json()["id"]
    response = client.post(PRODUCTS, payload, format="json")
    assert response.status_code == 409
    assert _code(response) == "plu_taken"
    client.delete(f"{PRODUCTS}{first}/")  # nofaol — PLU bo'shaydi
    assert client.post(PRODUCTS, payload, format="json").status_code == 201


def test_blank_plu_is_no_plu(client_as, manager, product_payload):
    """Audit P2-13: REST/import'dan `plu_code: ""` ikki marta — ikkinchisi 409 olmasin."""
    client = client_as(manager)
    for name in ("Non", "Sut"):
        response = client.post(PRODUCTS, product_payload(name=name, plu_code=""), format="json")
        assert response.status_code == 201
        assert response.json()["plu_code"] is None


def test_foreign_unit_and_category_rejected(client_as, manager, product_payload, other_tenant):
    foreign_unit = other_tenant.units.get(code="pcs")
    foreign_cat = Category.objects.create(tenant=other_tenant, name="Begona")
    response = client_as(manager).post(
        PRODUCTS,
        product_payload(unit=str(foreign_unit.id), category=str(foreign_cat.id)),
        format="json",
    )
    assert response.status_code == 400
    details = response.json()["error"]["details"]
    assert "unit" in details
    assert "category" in details


def test_other_tenant_product_invisible(
    client_as, manager, make_user, other_tenant, product_payload
):
    other = make_user(other_tenant, role="manager")
    payload = product_payload(unit=str(other_tenant.units.get(code="pcs").id))
    foreign = client_as(other).post(PRODUCTS, payload, format="json").json()["id"]
    client = client_as(manager)
    assert client.get(PRODUCTS).json()["count"] == 0
    assert client.get(f"{PRODUCTS}{foreign}/").status_code == 404
    assert client.patch(f"{PRODUCTS}{foreign}/", {"name": "X"}, format="json").status_code == 404
    assert client.delete(f"{PRODUCTS}{foreign}/").status_code == 404
    assert Product.objects.get(pk=foreign).is_active


def test_search_and_filters(client_as, manager, tenant, product_payload):
    client = client_as(manager)
    cat = Category.objects.create(tenant=tenant, name="Sut")
    client.post(PRODUCTS, product_payload(name="Non oq", barcodes=["AAA-1"]), format="json")
    client.post(
        PRODUCTS,
        product_payload(name="Sut 1L", category=str(cat.id), quick_button=True),
        format="json",
    )

    def names(query):
        return sorted(p["name"] for p in client.get(f"{PRODUCTS}?{query}").json()["results"])

    assert names("search=non") == ["Non oq"]
    assert names("search=AAA-1") == ["Non oq"]
    assert names(f"category={cat.id}") == ["Sut 1L"]
    assert names("quick_button=true") == ["Sut 1L"]
    assert names("") == ["Non oq", "Sut 1L"]


def test_price_history(client_as, manager, product_payload):
    client = client_as(manager)
    pid = client.post(PRODUCTS, product_payload(), format="json").json()["id"]
    client.patch(f"{PRODUCTS}{pid}/", {"name": "Non yangi"}, format="json")
    client.patch(f"{PRODUCTS}{pid}/", {"sell_price_tiyin": 450_000}, format="json")
    history = list(PriceHistory.objects.filter(product_id=pid).order_by("at"))
    assert [h.sell_price_tiyin for h in history] == [400_000, 450_000]
    assert all(h.changed_by == manager for h in history)


def test_markup_null_without_cost(client_as, manager, product_payload):
    body = (
        client_as(manager).post(PRODUCTS, product_payload(cost_price_tiyin=0), format="json").json()
    )
    assert body["markup_bp"] is None


@pytest.mark.parametrize(
    ("raw", "saved"),
    [
        ("  Yog'  1 l ", "Yog' 1 l"),
        ("Non\nissiq", "Non issiq"),
        ("Sut\t\x1b2%", "Sut 2%"),
        ("Oʻrik «Samarqand»", "Oʻrik «Samarqand»"),  # noqa: RUF001 (o'zbek harfi ataylab)
    ],
)
def test_name_is_cleaned_but_unicode_kept(client_as, manager, product_payload, raw, saved):
    # Audit P2-12: boshqaruv belgilari chekda printer buyrug'iga aylanadi.
    response = client_as(manager).post(PRODUCTS, product_payload(name=raw), format="json")
    assert response.status_code == 201, response.json()
    assert response.json()["name"] == saved


def test_name_of_only_control_chars_rejected(client_as, manager, product_payload):
    response = client_as(manager).post(PRODUCTS, product_payload(name="\n\t "), format="json")
    assert response.status_code == 400
