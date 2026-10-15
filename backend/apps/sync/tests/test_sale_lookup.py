import pytest
from django.utils import timezone

from apps.core.ids import new_id
from apps.customers.models import Customer
from apps.sales.services import open_shift, record_refund, record_sale

from .helpers import sale_completed

pytestmark = pytest.mark.django_db

URL = "/api/v1/sync/sales/"


@pytest.fixture
def other_kassa_sale(make_device, tenant, cashier, product):
    """2-kassada sotilgan chek (3 dona), bittasi qaytarilgan; nasiya bilan."""
    device, _ = make_device(tenant, number=2)
    shift = open_shift(
        device,
        {
            "id": str(new_id()),
            "cashier": str(cashier.id),
            "opening_cash_tiyin": 0,
            "opened_at": timezone.now().isoformat(),
        },
    )
    customer = Customer.objects.create(tenant=tenant, full_name="Anvar aka")
    payload = sale_completed(shift.id, cashier, product, qty=3_000)["payload"]
    payload["customer"] = str(customer.id)
    payload["payments"] = [
        {"id": str(new_id()), "method": "cash", "amount_tiyin": 800_000, "change_tiyin": 0},
        {"id": str(new_id()), "method": "debt", "amount_tiyin": 400_000, "change_tiyin": 0},
    ]
    sale = record_sale(device, payload)
    item = sale.items.get()
    record_refund(
        device,
        {
            "id": str(new_id()),
            "sale": str(sale.id),
            "shift": str(shift.id),
            "cashier": str(cashier.id),
            "reason": "yaroqsiz",
            "method": "cash",
            "total_tiyin": 400_000,
            "at": timezone.now().isoformat(),
            "items": [
                {
                    "id": str(new_id()),
                    "sale_item": str(item.id),
                    "qty_milli": 1_000,
                    "total_tiyin": 400_000,
                }
            ],
        },
    )
    return sale


def test_other_kassa_receipt_by_number(kassa, other_kassa_sale, cashier):
    _, client = kassa
    response = client.get(URL, {"number": other_kassa_sale.number.lower() + " "})
    assert response.status_code == 200
    data = response.json()
    assert data["id"] == str(other_kassa_sale.id)
    assert data["device_number"] == 2
    assert data["cashier_name"] == cashier.full_name
    assert data["customer_name"] == "Anvar aka"
    assert data["status"] == "partially_refunded"
    item = data["items"][0]
    assert (item["name_snapshot"], item["qty_milli"], item["total_tiyin"]) == (
        "Non",
        3_000,
        1_200_000,
    )
    assert (item["refunded_qty_milli"], item["refunded_tiyin"]) == (1_000, 400_000)
    assert [p["method"] for p in data["payments"]] == ["cash", "debt"]
    refund = data["refunds"][0]
    assert (refund["method"], refund["total_tiyin"], refund["reason"]) == (
        "cash",
        400_000,
        "yaroqsiz",
    )


def test_not_refunded_item_has_zero(kassa, make_device, tenant, cashier, product):
    device, _ = make_device(tenant, number=2)
    shift = open_shift(
        device,
        {
            "id": str(new_id()),
            "cashier": str(cashier.id),
            "opening_cash_tiyin": 0,
            "opened_at": timezone.now().isoformat(),
        },
    )
    sale = record_sale(device, sale_completed(shift.id, cashier, product)["payload"])
    _, client = kassa
    data = client.get(URL, {"number": sale.number}).json()
    assert (data["items"][0]["refunded_qty_milli"], data["refunds"]) == (0, [])
    assert data["customer"] is None
    assert data["customer_name"] is None


def test_other_tenant_cannot_see_the_receipt(make_device, other_tenant, other_kassa_sale):
    _, client = make_device(other_tenant)
    assert client.get(URL, {"number": other_kassa_sale.number}).status_code == 404


def test_unknown_or_missing_number(kassa):
    _, client = kassa
    assert client.get(URL, {"number": "D9-999999"}).status_code == 404
    assert client.get(URL).status_code == 400


def test_user_jwt_is_not_enough(client_as, manager, other_kassa_sale):
    response = client_as(manager).get(URL, {"number": other_kassa_sale.number})
    assert response.status_code in (401, 403)
