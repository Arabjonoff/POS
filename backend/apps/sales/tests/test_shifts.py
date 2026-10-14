from datetime import timedelta

import pytest
from django.db import IntegrityError, transaction
from django.utils import timezone

from apps.core.exceptions import DomainError
from apps.core.ids import new_id
from apps.customers.services import pay_debt, record_sale_debt
from apps.sales.models import Shift
from apps.sales.services import (
    MissingDependency,
    close_shift,
    expected_cash,
    open_shift,
    record_cash_movement,
    record_refund,
    record_sale,
    shift_report,
)

pytestmark = pytest.mark.django_db


def _close(device, shift, user, counted, **extra):
    return close_shift(
        device,
        {
            "id": str(shift.id),
            "closed_by": str(user.id),
            "counted_cash_tiyin": counted,
            "closed_at": timezone.now().isoformat(),
        }
        | extra,
    )


def _cash(device, shift, user, kind, amount):
    return record_cash_movement(
        device,
        {
            "id": str(new_id()),
            "shift": str(shift.id),
            "type": kind,
            "amount_tiyin": amount,
            "reason": "inkassatsiya",
            "by": str(user.id),
            "at": timezone.now().isoformat(),
        },
    )


def test_open_shift(device, cashier, shift):
    assert shift.device == device
    assert shift.store_id == device.store_id
    assert shift.opened_by == cashier
    assert shift.is_open


def test_one_open_shift_per_device(device, cashier, shift, make_shift, make_device, tenant):
    with pytest.raises(DomainError) as exc:
        make_shift(device, cashier)
    assert exc.value.code == "shift_already_open"
    # Boshqa qurilmada ochsa bo'ladi.
    assert make_shift(make_device(tenant, number=2), cashier).is_open
    # DB ham himoyalaydi.
    with pytest.raises(IntegrityError), transaction.atomic():
        Shift.objects.create(
            tenant=shift.tenant,
            store=shift.store,
            device=device,
            opened_by=cashier,
            opened_at=timezone.now(),
            opening_cash_tiyin=0,
        )


@pytest.mark.parametrize(
    "fields",
    [
        {"opening_cash_tiyin": -1},
        {"opening_cash_tiyin": 1.5},
        {"cashier": None},
        {"opened_at": "kecha"},
    ],
)
def test_invalid_open_rejected(device, cashier, fields):
    payload = {
        "id": str(new_id()),
        "cashier": str(cashier.id),
        "opening_cash_tiyin": 0,
        "opened_at": timezone.now().isoformat(),
    } | fields
    with pytest.raises(DomainError):
        open_shift(device, payload)
    assert not Shift.objects.exists()


def test_foreign_cashier_rejected(device, make_user, other_tenant):
    payload = {
        "id": str(new_id()),
        "cashier": str(make_user(other_tenant, role="cashier").id),
        "opening_cash_tiyin": 0,
        "opened_at": timezone.now().isoformat(),
    }
    with pytest.raises(DomainError):
        open_shift(device, payload)


def test_expected_cash_and_report(device, shift, cashier, manager, product, customer, sale_payload):
    # Boshlang'ich 100 000 so'm.
    cash_sale = record_sale(device, sale_payload(shift, cashier, [(product, 2_000, 400_000)]))
    record_sale(
        device,
        sale_payload(shift, cashier, [(product, 1_000, 400_000)], payments=[("card", 400_000)]),
    )
    record_sale(
        device,
        sale_payload(
            shift,
            cashier,
            [(product, 1_000, 400_000)],
            payments=[("debt", 400_000)],
            customer=customer,
        ),
    )
    record_refund(
        device,
        {
            "id": str(new_id()),
            "sale": str(cash_sale.id),
            "shift": str(shift.id),
            "cashier": str(cashier.id),
            "approved_by": str(manager.id),
            "method": "cash",
            "total_tiyin": 400_000,
            "at": timezone.now().isoformat(),
            "items": [
                {
                    "id": str(new_id()),
                    "sale_item": str(cash_sale.items.get().id),
                    "qty_milli": 1_000,
                    "total_tiyin": 400_000,
                }
            ],
        },
    )
    _cash(device, shift, cashier, "in", 50_000)
    _cash(device, shift, cashier, "out", 2_000_000)
    pay_debt(customer, amount_tiyin=150_000, method="cash", shift=shift)
    pay_debt(customer, amount_tiyin=50_000, method="card", shift=shift)
    # Boshqa smenadagi to'lov hisobga kirmaydi.
    pay_debt(customer, amount_tiyin=10_000, method="cash")

    expected = 100_000_00 + 800_000 - 400_000 + 50_000 - 2_000_000 + 150_000
    assert expected_cash(shift) == expected

    report = shift_report(shift)
    assert report["is_open"]
    assert report["sales_count"] == 3
    assert report["sales_total_tiyin"] == 1_600_000
    assert report["payments_tiyin"] == {"cash": 800_000, "card": 400_000, "debt": 400_000}
    assert report["refunds_count"] == 1
    assert report["refunds_tiyin"] == {"cash": 400_000, "debt": 0}
    assert (report["cash_in_tiyin"], report["cash_out_tiyin"]) == (50_000, 2_000_000)
    assert report["debt_payments_tiyin"] == {"cash": 150_000, "card": 50_000}
    assert report["expected_cash_tiyin"] == expected
    assert report["difference_tiyin"] is None

    closed = _close(device, shift, cashier, expected - 5_000)
    assert closed.expected_cash_tiyin == expected
    report = shift_report(closed)
    assert not report["is_open"]
    assert report["difference_tiyin"] == -5_000


def test_close_errors(device, shift, cashier, make_device, tenant):
    with pytest.raises(DomainError) as exc:
        _close(make_device(tenant, number=2), shift, cashier, 0)
    assert exc.value.code == "foreign_shift"

    before = (timezone.now() - timedelta(days=1)).isoformat()
    with pytest.raises(DomainError):
        _close(device, shift, cashier, 0, closed_at=before)

    _close(device, shift, cashier, 0)
    with pytest.raises(DomainError) as exc:
        _close(device, shift, cashier, 0)
    assert exc.value.code == "shift_closed"


def test_close_unknown_shift_is_missing_dependency(device, cashier):
    with pytest.raises(MissingDependency):
        close_shift(
            device,
            {
                "id": str(new_id()),
                "closed_by": str(cashier.id),
                "counted_cash_tiyin": 0,
                "closed_at": timezone.now().isoformat(),
            },
        )


@pytest.mark.parametrize("fields", [{"type": "steal"}, {"amount_tiyin": 0}, {"amount_tiyin": "5"}])
def test_invalid_cash_movement(device, shift, cashier, fields):
    payload = {
        "id": str(new_id()),
        "shift": str(shift.id),
        "type": "in",
        "amount_tiyin": 100,
        "reason": "",
        "by": str(cashier.id),
        "at": timezone.now().isoformat(),
    } | fields
    with pytest.raises(DomainError):
        record_cash_movement(device, payload)


def test_cash_movement_on_closed_shift_rejected(device, shift, cashier):
    _close(device, shift, cashier, 0)
    with pytest.raises(DomainError) as exc:
        _cash(device, shift, cashier, "in", 100)
    assert exc.value.code == "shift_closed"


def test_debt_sale_in_shift_does_not_change_cash(device, shift, customer):
    before = expected_cash(shift)
    record_sale_debt(customer, amount_tiyin=100, sale_id=new_id(), shift=shift)
    assert expected_cash(shift) == before
