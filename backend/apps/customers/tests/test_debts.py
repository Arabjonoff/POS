import uuid

import pytest
from django.db import IntegrityError, transaction

from apps.core.models import ImmutableRecordError
from apps.customers.models import DebtEntry
from apps.customers.services import (
    adjust_debt,
    check_debt_limit,
    customer_balance,
    pay_debt,
    record_refund_debt,
    record_sale_debt,
)

pytestmark = pytest.mark.django_db

CUSTOMERS = "/api/v1/customers/"


def _sale(customer, amount):
    return record_sale_debt(customer, amount_tiyin=amount, sale_id=uuid.uuid4())


def _pay(client, customer, amount, **extra):
    payload = {"amount_tiyin": amount, "method": "cash"} | extra
    return client.post(f"{CUSTOMERS}{customer.id}/payments/", payload, format="json")


def test_debt_sale_and_partial_payments(client_as, cashier, customer):
    _sale(customer, 120_000_00)
    _sale(customer, 30_000_00)
    client = client_as(cashier)

    response = _pay(client, customer, 50_000_00)
    assert response.status_code == 201
    data = response.json()
    assert data["balance_tiyin"] == 100_000_00
    assert data["entry"]["amount_tiyin"] == -50_000_00
    assert data["entry"]["type"] == "payment"
    assert data["entry"]["method"] == "cash"
    assert data["entry"]["created_by"] == str(cashier.id)

    response = _pay(client, customer, 100_000_00, method="card", note="to'liq")
    assert response.json()["balance_tiyin"] == 0
    assert customer_balance(customer) == 0


def test_payment_exceeding_debt_rejected(client_as, cashier, customer):
    _sale(customer, 10_000_00)
    response = _pay(client_as(cashier), customer, 10_000_01)
    assert response.status_code == 409
    error = response.json()["error"]
    assert error["code"] == "payment_exceeds_debt"
    assert error["details"] == {"balance_tiyin": 10_000_00}
    assert customer_balance(customer) == 10_000_00


def test_payment_without_debt_rejected(client_as, cashier, customer):
    assert _pay(client_as(cashier), customer, 1).status_code == 409


def test_offline_payment_not_rejected(customer):
    # Sinxron (T-018): oflaynda bo'lgan to'lov rad etilmaydi.
    pay_debt(customer, amount_tiyin=5_000_00, method="cash", enforce_balance=False)
    assert customer_balance(customer) == -5_000_00


@pytest.mark.parametrize(
    "payload",
    [
        {"amount_tiyin": 0, "method": "cash"},
        {"amount_tiyin": -100, "method": "cash"},
        {"amount_tiyin": 100.0, "method": "cash"},
        {"amount_tiyin": "100", "method": "cash"},
        {"amount_tiyin": 100, "method": "debt"},
        {"amount_tiyin": 100},
    ],
)
def test_invalid_payment_rejected(client_as, cashier, customer, payload):
    _sale(customer, 10_000_00)
    url = f"{CUSTOMERS}{customer.id}/payments/"
    assert client_as(cashier).post(url, payload, format="json").status_code == 400


def test_payment_client_id_is_single_use(client_as, cashier, customer):
    _sale(customer, 10_000_00)
    entry_id = "01920000-0000-7000-8000-0000000000d1"
    client = client_as(cashier)
    response = _pay(client, customer, 1_000_00, id=entry_id)
    assert response.json()["entry"]["id"] == entry_id
    assert _pay(client, customer, 1_000_00, id=entry_id).status_code == 400
    assert customer_balance(customer) == 9_000_00


def test_refund_reduces_debt(customer):
    sale_id = uuid.uuid4()
    record_sale_debt(customer, amount_tiyin=40_000_00, sale_id=sale_id)
    record_refund_debt(customer, amount_tiyin=15_000_00, sale_id=sale_id)
    assert customer_balance(customer) == 25_000_00


def test_adjustment_owner_only(client_as, owner, manager, cashier, customer):
    _sale(customer, 10_000_00)
    url = f"{CUSTOMERS}{customer.id}/adjustments/"
    payload = {"amount_tiyin": -2_000_00, "note": "Chegirma kelishildi"}
    assert client_as(cashier).post(url, payload, format="json").status_code == 403
    assert client_as(manager).post(url, payload, format="json").status_code == 403

    response = client_as(owner).post(url, payload, format="json")
    assert response.status_code == 201
    assert response.json()["balance_tiyin"] == 8_000_00
    assert response.json()["entry"]["type"] == "adjustment"

    response = client_as(owner).post(url, {"amount_tiyin": 500_00, "note": "x"}, format="json")
    assert response.json()["balance_tiyin"] == 8_500_00


@pytest.mark.parametrize(
    "payload",
    [
        {"amount_tiyin": 0, "note": "x"},
        {"amount_tiyin": 100, "note": ""},
        {"amount_tiyin": 100, "note": "   "},
        {"amount_tiyin": 100},
        {"amount_tiyin": 1.5, "note": "x"},
    ],
)
def test_invalid_adjustment_rejected(client_as, owner, customer, payload):
    url = f"{CUSTOMERS}{customer.id}/adjustments/"
    assert client_as(owner).post(url, payload, format="json").status_code == 400


def test_history_newest_first(client_as, cashier, customer):
    sale = _sale(customer, 10_000_00)
    response = _pay(client_as(cashier), customer, 4_000_00)
    rows = client_as(cashier).get(f"{CUSTOMERS}{customer.id}/debt-entries/").json()["results"]
    assert [r["id"] for r in rows] == [response.json()["entry"]["id"], str(sale.id)]
    assert rows[1]["sale_id"] == str(sale.sale_id)


def test_debt_limit_check(make_customer, tenant):
    unlimited = make_customer(tenant)
    assert check_debt_limit(unlimited, 10**12)

    no_credit = make_customer(tenant, debt_limit_tiyin=0)
    assert not check_debt_limit(no_credit, 1)

    limited = make_customer(tenant, debt_limit_tiyin=100_000_00)
    _sale(limited, 60_000_00)
    assert check_debt_limit(limited, 40_000_00)
    assert not check_debt_limit(limited, 40_000_01)


def test_sale_over_limit_is_still_recorded(make_customer, tenant):
    # Savdo kassada (menejer ruxsati bilan) bo'lgan — server rad etmaydi.
    limited = make_customer(tenant, debt_limit_tiyin=1_000_00)
    _sale(limited, 5_000_00)
    assert customer_balance(limited) == 5_000_00


def test_entry_is_immutable(customer):
    entry = _sale(customer, 1_000_00)
    entry.amount_tiyin = 1
    with pytest.raises(ImmutableRecordError):
        entry.save()
    with pytest.raises(ImmutableRecordError):
        entry.delete()
    assert DebtEntry.objects.get(pk=entry.pk).amount_tiyin == 1_000_00


@pytest.mark.parametrize(
    "fields",
    [
        {"type": "sale", "amount_tiyin": -1, "sale_id": uuid.uuid4()},
        {"type": "payment", "amount_tiyin": 1, "method": "cash"},
        {"type": "payment", "amount_tiyin": -1},
        {"type": "sale", "amount_tiyin": 1},
        {"type": "adjustment", "amount_tiyin": 1, "method": "cash"},
        {"type": "adjustment", "amount_tiyin": 0},
    ],
)
def test_db_constraints(customer, fields):
    with pytest.raises(IntegrityError), transaction.atomic():
        DebtEntry.objects.create(tenant_id=customer.tenant_id, customer=customer, **fields)


@pytest.mark.parametrize("amount", [0, -1, 1.0, True])
def test_services_reject_bad_amounts(customer, amount):
    with pytest.raises(ValueError, match="positive int"):
        pay_debt(customer, amount_tiyin=amount, method="cash")
    with pytest.raises(ValueError, match="positive int"):
        record_sale_debt(customer, amount_tiyin=amount, sale_id=uuid.uuid4())


def test_adjust_requires_note(customer, owner):
    with pytest.raises(ValueError, match="note"):
        adjust_debt(customer, amount_tiyin=100, note=" ", user=owner)
