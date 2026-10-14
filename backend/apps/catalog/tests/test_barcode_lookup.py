import pytest

pytestmark = pytest.mark.django_db

PRODUCTS = "/api/v1/products/"


def _lookup(client, code):
    return client.get(f"{PRODUCTS}by-barcode/{code}/")


@pytest.fixture
def product(client_as, manager, product_payload):
    payload = product_payload(barcodes=["0012345678905", "ABC-123"])
    return client_as(manager).post(PRODUCTS, payload, format="json").json()


def test_lookup_by_barcode(client_as, cashier, product):
    response = _lookup(client_as(cashier), "0012345678905")
    assert response.status_code == 200
    assert response.json()["id"] == product["id"]
    assert _lookup(client_as(cashier), "ABC-123").json()["id"] == product["id"]


def test_leading_zeros_matter(client_as, cashier, product):
    assert _lookup(client_as(cashier), "12345678905").status_code == 404


def test_unknown_barcode_404(client_as, cashier, product):
    assert _lookup(client_as(cashier), "4780000000014").status_code == 404


def test_inactive_product_still_found(client_as, manager, product):
    client = client_as(manager)
    client.delete(f"{PRODUCTS}{product['id']}/")
    response = _lookup(client, "ABC-123")
    assert response.status_code == 200
    assert response.json()["is_active"] is False


def test_removed_barcode_not_found(client_as, manager, product):
    client = client_as(manager)
    client.patch(f"{PRODUCTS}{product['id']}/", {"barcodes": ["ABC-123"]}, format="json")
    assert _lookup(client, "0012345678905").status_code == 404


def test_other_tenant_barcode_not_found(client_as, make_user, other_tenant, product):
    other = make_user(other_tenant, role="cashier")
    assert _lookup(client_as(other), "ABC-123").status_code == 404


def test_lookup_requires_auth(api_client, product):
    assert _lookup(api_client, "ABC-123").status_code == 401
