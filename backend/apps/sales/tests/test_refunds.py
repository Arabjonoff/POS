import pytest
from django.utils import timezone

from apps.core.exceptions import DomainError
from apps.core.ids import new_id
from apps.core.money import mul_div_half_up
from apps.customers.services import customer_balance
from apps.inventory.models import StockMovement
from apps.inventory.services import current_stock
from apps.sales.models import Refund
from apps.sales.services import MissingDependency, record_refund, record_sale

pytestmark = pytest.mark.django_db


@pytest.fixture
def refund_payload(cashier):
    def factory(sale, shift, lines, *, method="cash", total=None, **extra):
        """`lines`: [(sale_item, qty_milli)] — summa proporsional hisoblanadi (oxirgi qism emas)."""
        items = [
            {
                "id": str(new_id()),
                "sale_item": str(item.id),
                "qty_milli": qty,
                "total_tiyin": mul_div_half_up(item.total_tiyin, qty, item.qty_milli),
            }
            for item, qty in lines
        ]
        items_sum = sum(i["total_tiyin"] for i in items)
        if total is None:
            total = items_sum - mul_div_half_up(sale.discount_tiyin, items_sum, sale.subtotal_tiyin)
        return {
            "id": str(new_id()),
            "sale": str(sale.id),
            "shift": str(shift.id),
            "cashier": str(cashier.id),
            "reason": "yaroqsiz",
            "method": method,
            "total_tiyin": total,
            "at": timezone.now().isoformat(),
            "items": items,
        } | extra

    return factory


def test_partial_then_full_refund(
    device, shift, cashier, product, tenant, sale_payload, refund_payload
):
    sale = record_sale(device, sale_payload(shift, cashier, [(product, 3_000, 400_000)]))
    item = sale.items.get()
    store = tenant.stores.get()

    first = record_refund(device, refund_payload(sale, shift, [(item, 1_000)]))
    assert first.total_tiyin == 400_000
    sale.refresh_from_db()
    assert sale.status == "partially_refunded"
    assert current_stock(product, store) == -2_000
    movement = StockMovement.objects.get(type="refund")
    assert (movement.qty_milli, movement.ref_type, movement.ref_id) == (1_000, "refund", first.id)

    payload = refund_payload(sale, shift, [(item, 2_000)], total=800_000)
    payload["items"][0]["total_tiyin"] = 800_000
    record_refund(device, payload)
    sale.refresh_from_db()
    assert sale.status == "refunded"
    assert current_stock(product, store) == 0


def test_rounding_remainder_closed_on_last_part(
    device, shift, cashier, product, sale_payload, refund_payload
):
    # 3 dona × 333 tiyin, chek chegirmasi 100 → qismlarda yaxlitlash qoldig'i yo'qolmasin.
    sale = record_sale(device, sale_payload(shift, cashier, [(product, 3_000, 333)], discount=100))
    item = sale.items.get()
    refunded = 0
    for _ in range(2):
        refund = record_refund(device, refund_payload(sale, shift, [(item, 1_000)]))
        refunded += refund.total_tiyin
    last = refund_payload(sale, shift, [(item, 1_000)])
    last["items"][0]["total_tiyin"] = item.total_tiyin - 2 * 333
    last["total_tiyin"] = sale.total_tiyin - refunded
    refunded += record_refund(device, last).total_tiyin
    assert refunded == sale.total_tiyin


def test_check_discount_share(
    device, shift, cashier, product, make_product, tenant, sale_payload, refund_payload
):
    milk = make_product(tenant, name="Sut")
    sale = record_sale(
        device,
        sale_payload(
            shift, cashier, [(product, 1_000, 600_000), (milk, 1_000, 400_000)], discount=100_000
        ),
    )
    bread = sale.items.get(product=product)
    refund = record_refund(device, refund_payload(sale, shift, [(bread, 1_000)]))
    # 600 000 − 100 000 × 600 000 / 1 000 000 = 540 000
    assert refund.total_tiyin == 540_000


def test_debt_refund_reduces_debt(
    device, shift, cashier, product, customer, sale_payload, refund_payload
):
    sale = record_sale(
        device,
        sale_payload(
            shift,
            cashier,
            [(product, 2_000, 400_000)],
            payments=[("debt", 800_000)],
            customer=customer,
        ),
    )
    refund = record_refund(
        device, refund_payload(sale, shift, [(sale.items.get(), 1_000)], method="debt")
    )
    assert customer_balance(customer) == 400_000
    entry = customer.debt_entries.get(type="refund")
    assert (entry.amount_tiyin, entry.sale_id, entry.shift_id) == (-400_000, sale.id, shift.id)
    assert refund.method == "debt"


def test_debt_refund_limited_to_debt_part(
    device, shift, cashier, product, customer, sale_payload, refund_payload
):
    sale = record_sale(
        device,
        sale_payload(
            shift,
            cashier,
            [(product, 2_000, 400_000)],
            payments=[("cash", 600_000), ("debt", 200_000)],
            customer=customer,
        ),
    )
    payload = refund_payload(sale, shift, [(sale.items.get(), 1_000)], method="debt")
    with pytest.raises(DomainError) as exc:
        record_refund(device, payload)
    assert exc.value.code == "invalid_refund"

    cash_sale = record_sale(device, sale_payload(shift, cashier, [(product, 1_000, 400_000)]))
    payload = refund_payload(cash_sale, shift, [(cash_sale.items.get(), 1_000)], method="debt")
    with pytest.raises(DomainError):
        record_refund(device, payload)


def _cases():
    def item(**fields):
        def apply(p):
            p["items"][0] |= fields

        return apply

    def top(**fields):
        def apply(p):
            p |= fields

        return apply

    return {
        "too_much_qty": item(qty_milli=5_000),
        "zero_qty": item(qty_milli=0),
        "item_total_mismatch": item(total_tiyin=1),
        "total_mismatch": top(total_tiyin=1),
        "foreign_item": item(sale_item=str(new_id())),
        "no_items": top(items=[]),
        "bad_method": top(method="card"),
        "cashier_approver": top(approved_by="CASHIER"),
    }


@pytest.mark.parametrize("case", list(_cases()))
def test_invalid_refund_rejected(
    device, shift, cashier, product, sale_payload, refund_payload, case
):
    sale = record_sale(device, sale_payload(shift, cashier, [(product, 2_000, 400_000)]))
    payload = refund_payload(sale, shift, [(sale.items.get(), 1_000)])
    _cases()[case](payload)
    if payload.get("approved_by") == "CASHIER":
        payload["approved_by"] = str(cashier.id)
    with pytest.raises(DomainError) as exc:
        record_refund(device, payload)
    assert exc.value.code == "invalid_refund"
    assert not Refund.objects.exists()
    sale.refresh_from_db()
    assert sale.status == "completed"


def test_item_listed_twice_rejected(device, shift, cashier, product, sale_payload, refund_payload):
    sale = record_sale(device, sale_payload(shift, cashier, [(product, 2_000, 400_000)]))
    item = sale.items.get()
    payload = refund_payload(sale, shift, [(item, 1_000), (item, 1_000)])
    with pytest.raises(DomainError):
        record_refund(device, payload)


def test_manager_approval_recorded(
    device, shift, cashier, manager, product, sale_payload, refund_payload
):
    sale = record_sale(device, sale_payload(shift, cashier, [(product, 1_000, 400_000)]))
    payload = refund_payload(sale, shift, [(sale.items.get(), 1_000)], approved_by=str(manager.id))
    assert record_refund(device, payload).approved_by == manager


def test_unknown_sale_is_missing_dependency(
    device, shift, cashier, product, sale_payload, refund_payload
):
    sale = record_sale(device, sale_payload(shift, cashier, [(product, 1_000, 400_000)]))
    payload = refund_payload(sale, shift, [(sale.items.get(), 1_000)])
    payload["sale"] = str(new_id())
    with pytest.raises(MissingDependency) as exc:
        record_refund(device, payload)
    assert exc.value.entity == "sale"


def test_other_tenant_sale_not_visible(
    device, shift, cashier, product, sale_payload, refund_payload, make_device, other_tenant
):
    sale = record_sale(device, sale_payload(shift, cashier, [(product, 1_000, 400_000)]))
    payload = refund_payload(sale, shift, [(sale.items.get(), 1_000)])
    with pytest.raises(MissingDependency):
        record_refund(make_device(other_tenant), payload)


def test_duplicate_refund_rejected(device, shift, cashier, product, sale_payload, refund_payload):
    sale = record_sale(device, sale_payload(shift, cashier, [(product, 2_000, 400_000)]))
    payload = refund_payload(sale, shift, [(sale.items.get(), 1_000)])
    record_refund(device, payload)
    with pytest.raises(DomainError) as exc:
        record_refund(device, payload)
    assert exc.value.code == "duplicate_refund"
