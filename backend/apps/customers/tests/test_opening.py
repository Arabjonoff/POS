"""Boshlang'ich balans (T-103): mavjud qarz yoki avans bilan yangi mijoz."""

import uuid
from datetime import timedelta

import pytest
from django.db import IntegrityError
from django.utils import timezone

from apps.core.exceptions import DomainError
from apps.customers.models import Customer, DebtEntry
from apps.customers.services import (
    customer_balance,
    pay_debt,
    record_opening_balance,
    record_refund_debt,
    record_sale_debt,
)

pytestmark = pytest.mark.django_db

CUSTOMERS = "/api/v1/customers/"


def _create(client, opening=None, **extra):
    payload = {"full_name": "Eski mijoz"} | extra
    if opening is not None:
        payload["opening_balance"] = opening
    return client.post(CUSTOMERS, payload, format="json")


def test_debt_opening_balance(client_as, cashier):
    at = (timezone.now() - timedelta(days=30)).replace(microsecond=0)
    response = _create(
        client_as(cashier),
        {"direction": "debt", "amount_tiyin": 15_000_000, "at": at.isoformat(), "note": "Daftar"},
    )
    assert response.status_code == 201, response.json()
    body = response.json()
    assert body["balance_tiyin"] == 15_000_000
    assert "opening_balance" not in body
    entry = DebtEntry.objects.get(customer_id=body["id"])
    assert (entry.type, entry.amount_tiyin, entry.at, entry.note) == (
        "opening",
        15_000_000,
        at,
        "Daftar",
    )
    # Smena va savdoga bog'lanmagan — kassa naqdi va tushumga kirmaydi.
    assert entry.shift_id is None
    assert entry.sale_id is None
    assert entry.method == ""


def test_credit_opening_needs_owner_or_manager(client_as, cashier, manager):
    opening = {"direction": "credit", "amount_tiyin": 5_000_000}
    assert _create(client_as(cashier), opening).status_code == 403
    assert not Customer.objects.exists()

    response = _create(client_as(manager), opening)
    assert response.status_code == 201
    assert response.json()["balance_tiyin"] == -5_000_000


@pytest.mark.parametrize("opening", [None, {}])
def test_without_opening_works_as_before(client_as, cashier, opening):
    payload = {"full_name": "Yangi"}
    if opening is not None:
        payload["opening_balance"] = None
    response = client_as(cashier).post(CUSTOMERS, payload, format="json")
    assert response.status_code == 201
    assert response.json()["balance_tiyin"] == 0
    assert not DebtEntry.objects.exists()


@pytest.mark.parametrize(
    "opening",
    [
        {"direction": "debt", "amount_tiyin": 0},
        {"direction": "debt", "amount_tiyin": -1},
        {"direction": "debt", "amount_tiyin": 1.5},
        {"direction": "debt", "amount_tiyin": "100"},
        {"direction": "x", "amount_tiyin": 100},
        {"amount_tiyin": 100},
        {
            "direction": "debt",
            "amount_tiyin": 100,
            "at": (timezone.now() + timedelta(days=2)).isoformat(),
        },
        {"direction": "debt", "amount_tiyin": 100, "at": "1990-01-01T00:00:00Z"},
    ],
)
def test_invalid_opening_rejected(client_as, manager, opening):
    assert _create(client_as(manager), opening).status_code == 400
    assert not Customer.objects.exists()


def test_edit_never_adds_opening_twice(client_as, manager):
    created = _create(client_as(manager), {"direction": "debt", "amount_tiyin": 100_000}).json()
    url = f"{CUSTOMERS}{created['id']}/"
    # Tahrirda boshlang'ich balans rad etiladi.
    again = {"opening_balance": {"direction": "debt", "amount_tiyin": 100_000}}
    assert client_as(manager).patch(url, again, format="json").status_code == 400
    # Oddiy tahrir balansni o'zgartirmaydi.
    response = client_as(manager).patch(url, {"full_name": "Yangi ism"}, format="json")
    assert response.status_code == 200
    assert response.json()["balance_tiyin"] == 100_000
    assert DebtEntry.objects.filter(customer_id=created["id"]).count() == 1


def test_one_opening_per_customer_in_service_and_db(customer):
    record_opening_balance(customer, direction="debt", amount_tiyin=100)
    with pytest.raises(DomainError):
        record_opening_balance(customer, direction="credit", amount_tiyin=100)
    with pytest.raises(IntegrityError):
        DebtEntry.objects.create(
            tenant_id=customer.tenant_id, customer=customer, amount_tiyin=1, type="opening"
        )


def test_later_movements_keep_the_sum(customer):
    # Avans 50 000 → nasiya 30 000 → qaytarish 10 000 → balans −30 000 (do'kon qarzdor).
    record_opening_balance(customer, direction="credit", amount_tiyin=5_000_000)
    sale = uuid.uuid4()
    record_sale_debt(customer, amount_tiyin=3_000_000, sale_id=sale)
    assert customer_balance(customer) == -2_000_000
    record_refund_debt(customer, amount_tiyin=1_000_000, sale_id=sale)
    assert customer_balance(customer) == -3_000_000
    # Avans bor — kassada to'lov qabul qilinmaydi (Q-003: ortiqcha to'lov yo'q).
    with pytest.raises(DomainError):
        pay_debt(customer, amount_tiyin=1, method="cash")


def test_debt_opening_then_payment(customer):
    record_opening_balance(customer, direction="debt", amount_tiyin=10_000_000)
    pay_debt(customer, amount_tiyin=4_000_000, method="cash")
    assert customer_balance(customer) == 6_000_000


def test_other_tenant_cannot_see_opening(client_as, manager, make_user, other_tenant):
    created = _create(client_as(manager), {"direction": "debt", "amount_tiyin": 100}).json()
    stranger = make_user(other_tenant, role="owner")
    response = client_as(stranger).get(f"{CUSTOMERS}{created['id']}/")
    assert response.status_code == 404
