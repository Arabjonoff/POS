"""`sale.completed` hodisasi: savdoni tekshirish va bitta tranzaksiyada yozish."""

from django.db import IntegrityError, transaction

from apps.catalog.models import Product
from apps.core.money import line_total
from apps.customers.models import Customer
from apps.customers.services import record_sale_debt
from apps.inventory.models import MovementType
from apps.inventory.services import record_movement

from ..models import PaymentMethod, Sale, SaleItem, SalePayment
from .common import (
    MissingDependency,
    as_datetime,
    as_int,
    as_uuid,
    device_shift,
    invalid,
    tenant_user,
)

CODE = "invalid_sale"


def _items(tenant_id, raw_items) -> list[dict]:
    if not isinstance(raw_items, list) or not raw_items:
        raise invalid(CODE, "Sale must have at least one item.", field="items")
    product_ids = {as_uuid(item, "product", code=CODE) for item in raw_items}
    products = Product.objects.filter(tenant_id=tenant_id, pk__in=product_ids).in_bulk()
    items = []
    for index, raw in enumerate(raw_items):
        product = products.get(as_uuid(raw, "product", code=CODE))
        if product is None:
            raise invalid(CODE, "Unknown product.", item=index, field="product")
        item = {
            "id": as_uuid(raw, "id", code=CODE),
            "product": product,
            "name_snapshot": str(raw.get("name_snapshot") or product.name)[:200],
            "barcode_snapshot": str(raw.get("barcode_snapshot") or "")[:32],
            "qty_milli": as_int(raw, "qty_milli", code=CODE, min_value=1),
            "price_tiyin": as_int(raw, "price_tiyin", code=CODE, min_value=0),
            "cost_tiyin": as_int(raw, "cost_tiyin", code=CODE, min_value=0),
            "discount_tiyin": as_int(raw, "discount_tiyin", code=CODE, min_value=0, default=0),
            "total_tiyin": as_int(raw, "total_tiyin", code=CODE, min_value=0),
        }
        expected = line_total(item["price_tiyin"], item["qty_milli"]) - item["discount_tiyin"]
        if expected < 0 or item["total_tiyin"] != expected:
            raise invalid(CODE, "Item total does not match.", item=index, expected=expected)
        items.append(item)
    return items


def _payments(raw_payments, total: int) -> list[dict]:
    if not isinstance(raw_payments, list):
        raise invalid(CODE, "payments must be a list.", field="payments")
    payments = []
    for index, raw in enumerate(raw_payments):
        method = raw.get("method")
        if method not in PaymentMethod.values:
            raise invalid(CODE, "Unknown payment method.", payment=index, field="method")
        payment = {
            "id": as_uuid(raw, "id", code=CODE),
            "method": method,
            "amount_tiyin": as_int(raw, "amount_tiyin", code=CODE, min_value=1),
            "received_tiyin": None,
            "change_tiyin": as_int(raw, "change_tiyin", code=CODE, min_value=0, default=0),
        }
        if method == PaymentMethod.CASH and raw.get("received_tiyin") is not None:
            received = as_int(raw, "received_tiyin", code=CODE)
            if received - payment["amount_tiyin"] != payment["change_tiyin"] or received < 0:
                raise invalid(CODE, "Change does not match.", payment=index)
            payment["received_tiyin"] = received
        elif payment["change_tiyin"] or raw.get("received_tiyin") is not None:
            raise invalid(CODE, "Only cash payments have received/change.", payment=index)
        payments.append(payment)
    paid = sum(p["amount_tiyin"] for p in payments)
    if paid != total:
        raise invalid(CODE, "Payments do not add up to the total.", paid=paid, total=total)
    return payments


@transaction.atomic
def record_sale(device, payload: dict) -> Sale:
    tenant_id = device.tenant_id
    shift = device_shift(device, as_uuid(payload, "shift", code=CODE), lock=True)
    cashier = tenant_user(tenant_id, as_uuid(payload, "cashier", code=CODE), code=CODE)
    approved_id = as_uuid(payload, "approved_by", code=CODE, required=False)
    approved_by = (
        tenant_user(tenant_id, approved_id, code=CODE, managers_only=True) if approved_id else None
    )
    customer = None
    if (customer_id := as_uuid(payload, "customer", code=CODE, required=False)) is not None:
        customer = Customer.objects.filter(tenant_id=tenant_id, pk=customer_id).first()
        if customer is None:
            # Mijoz kassada oflayn yaratilgan va uning hodisasi hali qo'llanmagan
            # bo'lishi mumkin — rad etmaymiz, keyinroq qayta urinamiz (pending).
            raise MissingDependency("customer", customer_id)

    items = _items(tenant_id, payload.get("items"))
    subtotal = as_int(payload, "subtotal_tiyin", code=CODE, min_value=0)
    discount = as_int(payload, "discount_tiyin", code=CODE, min_value=0, default=0)
    total = as_int(payload, "total_tiyin", code=CODE, min_value=0)
    if subtotal != sum(i["total_tiyin"] for i in items):
        raise invalid(CODE, "Subtotal does not match items.", field="subtotal_tiyin")
    if discount > subtotal or total != subtotal - discount:
        raise invalid(CODE, "Total does not match subtotal and discount.", field="total_tiyin")
    payments = _payments(payload.get("payments"), total)
    debt_amount = sum(p["amount_tiyin"] for p in payments if p["method"] == PaymentMethod.DEBT)
    if debt_amount and customer is None:
        raise invalid(CODE, "Debt payment requires a customer.", field="customer")

    number = str(payload.get("number") or "").strip()
    if not number:
        raise invalid(CODE, "number is required.", field="number")
    sold_at = as_datetime(payload, "sold_at", code=CODE)
    sale_id = as_uuid(payload, "id", code=CODE)
    if Sale.objects.filter(pk=sale_id).exists():
        raise invalid("duplicate_sale", "Sale with this id already exists.", sale=str(sale_id))
    try:
        with transaction.atomic():
            sale = Sale.objects.create(
                id=sale_id,
                tenant_id=tenant_id,
                store_id=shift.store_id,
                shift=shift,
                device=device,
                cashier=cashier,
                approved_by=approved_by,
                customer=customer,
                number=number[:32],
                subtotal_tiyin=subtotal,
                discount_tiyin=discount,
                total_tiyin=total,
                sold_at=sold_at,
            )
    except IntegrityError:
        raise invalid("duplicate_number", "Sale number is already used.", number=number) from None

    SaleItem.objects.bulk_create(SaleItem(tenant_id=tenant_id, sale=sale, **i) for i in items)
    SalePayment.objects.bulk_create(
        SalePayment(tenant_id=tenant_id, sale=sale, **p) for p in payments
    )
    for item in items:
        record_movement(
            product=item["product"],
            store=shift.store,
            qty_milli=-item["qty_milli"],
            type=MovementType.SALE,
            ref_type="sale",
            ref_id=sale.pk,
            user=cashier,
            at=sold_at,
        )
    if debt_amount:
        record_sale_debt(
            customer,
            amount_tiyin=debt_amount,
            sale_id=sale.pk,
            user=cashier,
            at=sold_at,
            id=as_uuid(payload, "debt_entry_id", code=CODE, required=False),
            shift=shift,
        )
    return sale
