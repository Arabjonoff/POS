import uuid

import pytest

from apps.customers.models import Customer
from apps.customers.services import record_sale_debt

pytestmark = pytest.mark.django_db

CUSTOMERS = "/api/v1/customers/"


def _sale(customer, amount):
    return record_sale_debt(customer, amount_tiyin=amount, sale_id=uuid.uuid4())


def test_cashier_quick_creates_customer(client_as, cashier, tenant):
    response = client_as(cashier).post(
        CUSTOMERS, {"full_name": "Dilnoza", "phone": "+998901234567"}, format="json"
    )
    assert response.status_code == 201
    data = response.json()
    assert data["balance_tiyin"] == 0
    assert data["debt_limit_tiyin"] is None
    assert Customer.objects.get(pk=data["id"]).tenant_id == tenant.id


def test_client_id_accepted(client_as, cashier):
    customer_id = "01920000-0000-7000-8000-0000000000c1"
    payload = {"id": customer_id, "full_name": "Oflayn mijoz"}
    response = client_as(cashier).post(CUSTOMERS, payload, format="json")
    assert response.json()["id"] == customer_id
    assert client_as(cashier).post(CUSTOMERS, payload, format="json").status_code == 400


@pytest.mark.parametrize(
    "payload",
    [
        {"phone": "+99890"},
        {"phone": "12345"},
        {"phone": "+7 901 234 56 78"},
        {"full_name": ""},
        {"debt_limit_tiyin": -1},
        {"debt_limit_tiyin": 100.0},
        {"debt_limit_tiyin": "100"},
    ],
)
def test_invalid_payload_rejected(client_as, manager, payload):
    body = {"full_name": "Ali"} | payload
    assert client_as(manager).post(CUSTOMERS, body, format="json").status_code == 400


@pytest.mark.parametrize(
    "raw", ["90 123 45 67", "901234567", "+998 (90) 123-45-67", "998901234567"]
)
def test_phone_is_normalized(client_as, cashier, raw):
    # Kassa raqamni yozilganicha yuboradi — server bir ko'rinishga keltiradi (audit B1).
    payload = {"full_name": "Ali", "phone": raw}
    response = client_as(cashier).post(CUSTOMERS, payload, format="json")
    assert response.status_code == 201, response.json()
    assert response.json()["phone"] == "+998901234567"


def test_blank_phone_allowed(client_as, cashier):
    payload = {"full_name": "Ali", "phone": "  "}
    response = client_as(cashier).post(CUSTOMERS, payload, format="json")
    assert response.status_code == 201
    assert response.json()["phone"] == ""


def test_phone_not_unique(client_as, manager):
    client = client_as(manager)
    for name in ("Ali", "Vali"):
        payload = {"full_name": name, "phone": "+998901112233"}
        assert client.post(CUSTOMERS, payload, format="json").status_code == 201


def test_debt_limit_only_by_manager_or_owner(client_as, cashier, manager, customer):
    url = f"{CUSTOMERS}{customer.id}/"
    response = client_as(cashier).post(
        CUSTOMERS, {"full_name": "X", "debt_limit_tiyin": 100}, format="json"
    )
    assert response.status_code == 403
    assert (
        client_as(cashier).patch(url, {"debt_limit_tiyin": 100}, format="json").status_code == 403
    )

    # Kassir ism/izohni o'zgartira oladi (limitni o'sha qiymatda yuborsa ham).
    response = client_as(cashier).patch(
        url, {"note": "qo'shni", "debt_limit_tiyin": None}, format="json"
    )
    assert response.status_code == 200

    response = client_as(manager).patch(url, {"debt_limit_tiyin": 500_000_00}, format="json")
    assert response.json()["debt_limit_tiyin"] == 500_000_00
    response = client_as(manager).patch(url, {"debt_limit_tiyin": None}, format="json")
    assert response.json()["debt_limit_tiyin"] is None


def test_list_debtors_first_with_balance(client_as, cashier, make_customer, tenant):
    zero = make_customer(tenant, full_name="Aziz")
    small = make_customer(tenant, full_name="Bobur")
    big = make_customer(tenant, full_name="Sardor")
    _sale(small, 10_000_00)
    _sale(big, 25_000_00)
    _sale(big, 5_000_00)

    rows = client_as(cashier).get(CUSTOMERS).json()["results"]
    assert [(r["id"], r["balance_tiyin"]) for r in rows] == [
        (str(big.id), 30_000_00),
        (str(small.id), 10_000_00),
        (str(zero.id), 0),
    ]
    rows = client_as(cashier).get(f"{CUSTOMERS}?has_debt=true").json()["results"]
    assert [r["id"] for r in rows] == [str(big.id), str(small.id)]


def test_search_by_name_or_phone(client_as, cashier, make_customer, tenant):
    anvar = make_customer(tenant, full_name="Anvar aka", phone="+998901112233")
    make_customer(tenant, full_name="Dilnoza")
    client = client_as(cashier)

    def ids(term):
        return [r["id"] for r in client.get(f"{CUSTOMERS}?search={term}").json()["results"]]

    assert ids("anvar") == [str(anvar.id)]
    assert ids("112233") == [str(anvar.id)]


def test_retrieve_shows_balance(client_as, cashier, customer):
    _sale(customer, 7_500_00)
    data = client_as(cashier).get(f"{CUSTOMERS}{customer.id}/").json()
    assert data["balance_tiyin"] == 7_500_00


def test_delete_requires_zero_balance(client_as, manager, cashier, customer, make_customer, tenant):
    client = client_as(manager)
    assert client_as(cashier).delete(f"{CUSTOMERS}{customer.id}/").status_code == 403

    _sale(customer, 1_000_00)
    response = client.delete(f"{CUSTOMERS}{customer.id}/")
    assert (response.status_code, response.json()["error"]["code"]) == (409, "customer_has_debt")

    clean = make_customer(tenant, full_name="Qarzsiz")
    assert client.delete(f"{CUSTOMERS}{clean.id}/").status_code == 204
    clean.refresh_from_db()
    assert clean.deleted_at is not None
    assert client.get(f"{CUSTOMERS}{clean.id}/").status_code == 404


def test_requires_auth(api_client):
    assert api_client.get(CUSTOMERS).status_code == 401


def test_other_tenant_isolated(client_as, manager, customer, make_user, other_tenant):
    _sale(customer, 1_000_00)
    stranger = client_as(make_user(other_tenant, role="owner"))
    assert stranger.get(CUSTOMERS).json()["count"] == 0
    url = f"{CUSTOMERS}{customer.id}/"
    assert stranger.get(url).status_code == 404
    assert stranger.patch(url, {"full_name": "X"}, format="json").status_code == 404
    assert stranger.delete(url).status_code == 404
    assert stranger.get(f"{url}debt-entries/").status_code == 404
    payment = {"amount_tiyin": 100, "method": "cash"}
    assert stranger.post(f"{url}payments/", payment, format="json").status_code == 404
    adjustment = {"amount_tiyin": -100, "note": "x"}
    assert stranger.post(f"{url}adjustments/", adjustment, format="json").status_code == 404
