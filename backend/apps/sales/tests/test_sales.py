import pytest
from django.utils import timezone

from apps.core.exceptions import DomainError
from apps.core.ids import new_id
from apps.core.models import ImmutableRecordError
from apps.customers.models import DebtEntry
from apps.customers.services import customer_balance
from apps.inventory.models import StockMovement
from apps.inventory.services import current_stock
from apps.sales.models import Sale, SaleItem, SalePayment
from apps.sales.services import MissingDependency, close_shift, record_sale

pytestmark = pytest.mark.django_db


def _error(payload, device):
    with pytest.raises(DomainError) as exc:
        record_sale(device, payload)
    return exc.value


def test_sale_writes_items_payments_and_stock(
    device, shift, cashier, product, make_product, tenant, sale_payload
):
    milk = make_product(tenant, name="Sut", cost_price_tiyin=900_000)
    payload = sale_payload(shift, cashier, [(product, 2_000, 400_000), (milk, 500, 1_200_000)])
    sale = record_sale(device, payload)

    assert str(sale.id) == payload["id"]
    assert sale.total_tiyin == 800_000 + 600_000
    assert sale.store_id == device.store_id
    assert sale.status == "completed"
    assert [i.qty_milli for i in sale.items.all()] == [2_000, 500]
    assert sale.payments.get().amount_tiyin == sale.total_tiyin

    store = tenant.stores.get()
    assert current_stock(product, store) == -2_000  # manfiy qoldiq savdoni bloklamaydi
    assert current_stock(milk, store) == -500
    movement = StockMovement.objects.get(product=product)
    assert (movement.type, movement.ref_type, movement.ref_id) == ("sale", "sale", sale.id)
    assert movement.created_by == cashier


def test_debt_sale_creates_debt_entry(device, shift, cashier, product, customer, sale_payload):
    payload = sale_payload(
        shift,
        cashier,
        [(product, 3_000, 400_000)],
        payments=[("cash", 200_000), ("debt", 1_000_000)],
        customer=customer,
        debt_entry_id=str(new_id()),
    )
    sale = record_sale(device, payload)
    entry = DebtEntry.objects.get(customer=customer)
    assert str(entry.id) == payload["debt_entry_id"]
    assert (entry.type, entry.amount_tiyin, entry.sale_id) == ("sale", 1_000_000, sale.id)
    assert entry.shift_id == shift.id
    assert customer_balance(customer) == 1_000_000


def test_debt_over_limit_is_recorded(
    device, shift, cashier, manager, product, customer, sale_payload
):
    customer.debt_limit_tiyin = 100
    customer.save()
    payload = sale_payload(
        shift,
        cashier,
        [(product, 1_000, 400_000)],
        payments=[("debt", 400_000)],
        customer=customer,
        approved_by=str(manager.id),
    )
    sale = record_sale(device, payload)
    assert sale.approved_by == manager
    assert customer_balance(customer) == 400_000


def test_cash_received_and_change(device, shift, cashier, product, sale_payload):
    payload = sale_payload(shift, cashier, [(product, 1_000, 400_000)])
    payload["payments"][0] |= {"received_tiyin": 500_000, "change_tiyin": 100_000}
    payment = record_sale(device, payload).payments.get()
    assert (payment.received_tiyin, payment.change_tiyin) == (500_000, 100_000)


def test_discounts(device, shift, cashier, product, sale_payload):
    payload = sale_payload(shift, cashier, [(product, 2_000, 400_000, 50_000)], discount=30_000)
    sale = record_sale(device, payload)
    assert (sale.subtotal_tiyin, sale.discount_tiyin, sale.total_tiyin) == (
        750_000,
        30_000,
        720_000,
    )


def test_weighted_item_rounds_half_up(device, shift, cashier, product, sale_payload):
    # 0,250 kg × 1 002 tiyin = 250,5 → 251
    payload = sale_payload(shift, cashier, [(product, 250, 1_002)])
    assert record_sale(device, payload).total_tiyin == 251


def _mutations():
    def item(field, value):
        def apply(p):
            p["items"][0][field] = value

        return apply

    def top(field, value):
        def apply(p):
            p[field] = value

        return apply

    def payment(**fields):
        def apply(p):
            p["payments"][0] |= fields

        return apply

    return {
        "no_items": top("items", []),
        "zero_qty": item("qty_milli", 0),
        "float_qty": item("qty_milli", 1000.0),
        "string_price": item("price_tiyin", "400000"),
        "negative_cost": item("cost_tiyin", -1),
        "item_total_mismatch": item("total_tiyin", 1),
        "subtotal_mismatch": top("subtotal_tiyin", 1),
        "total_mismatch": top("total_tiyin", 1),
        "discount_over_subtotal": top("discount_tiyin", 10**9),
        "payments_short": payment(amount_tiyin=1),
        "unknown_method": payment(method="crypto"),
        "change_mismatch": payment(received_tiyin=500_000, change_tiyin=1),
        "card_with_change": payment(method="card", change_tiyin=10),
        "debt_without_customer": payment(method="debt"),
        "unknown_product": item("product", str(new_id())),
        "bad_uuid": top("cashier", "abc"),
        "unknown_cashier": top("cashier", str(new_id())),
        "naive_datetime": top("sold_at", "2026-10-14T10:00:00"),
        "no_number": top("number", ""),
    }


@pytest.mark.parametrize("case", list(_mutations()))
def test_invalid_sale_rejected(device, shift, cashier, product, sale_payload, case):
    payload = sale_payload(shift, cashier, [(product, 1_000, 400_000)])
    _mutations()[case](payload)
    error = _error(payload, device)
    assert error.code == "invalid_sale"
    assert not Sale.objects.exists()
    assert not StockMovement.objects.exists()


def test_foreign_objects_rejected(
    device, shift, cashier, sale_payload, make_product, make_user, other_tenant
):
    foreign_product = make_product(other_tenant)
    payload = sale_payload(shift, cashier, [(foreign_product, 1_000, 400_000)])
    assert _error(payload, device).code == "invalid_sale"

    foreign_cashier = make_user(other_tenant, role="cashier")
    payload = sale_payload(shift, foreign_cashier, [(foreign_product, 1_000, 400_000)])
    assert _error(payload, device).code == "invalid_sale"


def test_cashier_cannot_approve(device, shift, cashier, product, sale_payload):
    payload = sale_payload(shift, cashier, [(product, 1_000, 400_000)], approved_by=str(cashier.id))
    assert _error(payload, device).code == "invalid_sale"


def test_unknown_shift_is_missing_dependency(device, cashier, product, sale_payload, shift):
    payload = sale_payload(shift, cashier, [(product, 1_000, 400_000)])
    payload["shift"] = str(new_id())
    with pytest.raises(MissingDependency) as exc:
        record_sale(device, payload)
    assert exc.value.entity == "shift"


def test_other_device_or_tenant_shift_rejected(
    device, shift, cashier, product, make_device, tenant, other_tenant, sale_payload
):
    payload = sale_payload(shift, cashier, [(product, 1_000, 400_000)])
    assert _error(payload, make_device(tenant, number=2)).code == "foreign_shift"
    with pytest.raises(MissingDependency):
        record_sale(make_device(other_tenant), payload)


def test_closed_shift_rejected(device, shift, cashier, product, sale_payload):
    close_shift(
        device,
        {
            "id": str(shift.id),
            "closed_by": str(cashier.id),
            "counted_cash_tiyin": 0,
            "closed_at": timezone.now().isoformat(),
        },
    )
    payload = sale_payload(shift, cashier, [(product, 1_000, 400_000)])
    assert _error(payload, device).code == "shift_closed"


def test_duplicate_id_and_number(device, shift, cashier, product, sale_payload):
    payload = sale_payload(shift, cashier, [(product, 1_000, 400_000)])
    record_sale(device, payload)
    assert _error(payload, device).code == "duplicate_sale"
    again = sale_payload(shift, cashier, [(product, 1_000, 400_000)], number=payload["number"])
    assert _error(again, device).code == "duplicate_number"
    assert Sale.objects.count() == 1
    assert StockMovement.objects.count() == 1


def test_sale_records_are_immutable(device, shift, cashier, product, sale_payload):
    sale = record_sale(device, sale_payload(shift, cashier, [(product, 1_000, 400_000)]))
    sale.total_tiyin = 1
    with pytest.raises(ImmutableRecordError):
        sale.save()
    with pytest.raises(ImmutableRecordError):
        sale.save(update_fields=["total_tiyin"])
    with pytest.raises(ImmutableRecordError):
        sale.delete()
    item = SaleItem.objects.get(sale=sale)
    with pytest.raises(ImmutableRecordError):
        item.save()
    with pytest.raises(ImmutableRecordError):
        SalePayment.objects.get(sale=sale).delete()
