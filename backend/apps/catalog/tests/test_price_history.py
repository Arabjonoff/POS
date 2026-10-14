import pytest

pytestmark = pytest.mark.django_db

PRODUCTS = "/api/v1/products/"


def _history(client, product_id):
    return client.get(f"{PRODUCTS}{product_id}/price-history/")


@pytest.fixture
def product(client_as, manager, product_payload):
    return client_as(manager).post(PRODUCTS, product_payload(), format="json").json()


def test_history_newest_first_with_author(client_as, manager, owner, product):
    client_as(owner).patch(
        f"{PRODUCTS}{product['id']}/", {"sell_price_tiyin": 450_000}, format="json"
    )
    response = _history(client_as(manager), product["id"])
    assert response.status_code == 200
    rows = response.json()
    assert [(r["sell_price_tiyin"], r["cost_price_tiyin"]) for r in rows] == [
        (450_000, 320_000),
        (400_000, 320_000),
    ]
    assert rows[0]["changed_by"] == str(owner.id)
    assert rows[0]["changed_by_name"] == owner.full_name
    assert rows[1]["changed_by_name"] == manager.full_name


def test_unchanged_price_adds_no_row(client_as, manager, product):
    client_as(manager).patch(f"{PRODUCTS}{product['id']}/", {"name": "Patir"}, format="json")
    assert len(_history(client_as(manager), product["id"]).json()) == 1


def test_cashier_cannot_see_history(client_as, cashier, product):
    assert _history(client_as(cashier), product["id"]).status_code == 403


def test_other_tenant_cannot_see_history(client_as, make_user, other_tenant, product):
    other = make_user(other_tenant, role="manager")
    assert _history(client_as(other), product["id"]).status_code == 404


def test_history_requires_auth(api_client, product):
    assert _history(api_client, product["id"]).status_code == 401
