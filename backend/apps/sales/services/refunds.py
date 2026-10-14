"""`refund.created` hodisasi: qaytarishni tekshirish va teskari yozuvlar bilan saqlash."""

from django.db import transaction
from django.db.models import Sum

from apps.core.money import mul_div_half_up
from apps.customers.services import record_refund_debt
from apps.inventory.models import MovementType
from apps.inventory.services import record_movement

from ..models import (
    PaymentMethod,
    Refund,
    RefundItem,
    RefundMethod,
    Sale,
    SaleStatus,
)
from .common import (
    MissingDependency,
    as_datetime,
    as_int,
    as_uuid,
    device_shift,
    invalid,
    tenant_user,
)

CODE = "invalid_refund"


def _refunded_by_item(sale) -> dict:
    rows = (
        RefundItem.objects.filter(refund__sale=sale)
        .values("sale_item_id")
        .annotate(qty=Sum("qty_milli"), total=Sum("total_tiyin"))
    )
    return {row["sale_item_id"]: row for row in rows}


def _items(sale, raw_items) -> tuple[list[dict], bool]:
    """Qatorlar va qaytarish savdoni to'liq yopadimi."""
    if not isinstance(raw_items, list) or not raw_items:
        raise invalid(CODE, "Refund must have at least one item.", field="items")
    sale_items = {item.pk: item for item in sale.items.all()}
    refunded = _refunded_by_item(sale)
    remaining = {
        pk: item.qty_milli - (refunded.get(pk) or {}).get("qty", 0)
        for pk, item in sale_items.items()
    }
    items, seen = [], set()
    for index, raw in enumerate(raw_items):
        sale_item = sale_items.get(as_uuid(raw, "sale_item", code=CODE))
        if sale_item is None:
            raise invalid(CODE, "Item does not belong to this sale.", item=index)
        if sale_item.pk in seen:
            raise invalid(CODE, "Sale item is listed twice.", item=index)
        seen.add(sale_item.pk)
        qty = as_int(raw, "qty_milli", code=CODE, min_value=1)
        if qty > remaining[sale_item.pk]:
            raise invalid(
                CODE, "Quantity exceeds what is left.", item=index, left=remaining[sale_item.pk]
            )
        if qty == remaining[sale_item.pk]:
            # Qatorning oxirgi qismi — yaxlitlash qoldig'i shu yerda yopiladi.
            previous = (refunded.get(sale_item.pk) or {}).get("total", 0)
            expected = sale_item.total_tiyin - previous
        else:
            expected = mul_div_half_up(sale_item.total_tiyin, qty, sale_item.qty_milli)
        total = as_int(raw, "total_tiyin", code=CODE, min_value=0)
        if total != expected:
            raise invalid(CODE, "Item total does not match.", item=index, expected=expected)
        remaining[sale_item.pk] -= qty
        item_id = as_uuid(raw, "id", code=CODE)
        items.append({"id": item_id, "sale_item": sale_item, "qty": qty, "total": total})
    return items, not any(remaining.values())


def _expected_total(sale, items_sum: int, closes_sale: bool) -> int:
    if closes_sale:
        previous = sale.refunds.aggregate(s=Sum("total_tiyin"))["s"] or 0
        return sale.total_tiyin - previous
    if not sale.subtotal_tiyin:
        return items_sum
    return items_sum - mul_div_half_up(sale.discount_tiyin, items_sum, sale.subtotal_tiyin)


def _debt_left(sale) -> int:
    sold = sale.payments.filter(method=PaymentMethod.DEBT).aggregate(s=Sum("amount_tiyin"))["s"]
    refunded = sale.refunds.filter(method=RefundMethod.DEBT).aggregate(s=Sum("total_tiyin"))["s"]
    return (sold or 0) - (refunded or 0)


@transaction.atomic
def record_refund(device, payload: dict) -> Refund:
    tenant_id = device.tenant_id
    sale_id = as_uuid(payload, "sale", code=CODE)
    sale = Sale.objects.select_for_update().filter(tenant_id=tenant_id, pk=sale_id).first()
    if sale is None:
        raise MissingDependency("sale", sale_id)
    shift = device_shift(device, as_uuid(payload, "shift", code=CODE), lock=True)
    cashier = tenant_user(tenant_id, as_uuid(payload, "cashier", code=CODE), code=CODE)
    approved_id = as_uuid(payload, "approved_by", code=CODE, required=False)
    approved_by = (
        tenant_user(tenant_id, approved_id, code=CODE, managers_only=True) if approved_id else None
    )
    method = payload.get("method")
    if method not in RefundMethod.values:
        raise invalid(CODE, "method must be cash or debt.", field="method")

    items, closes_sale = _items(sale, payload.get("items"))
    total = as_int(payload, "total_tiyin", code=CODE, min_value=0)
    expected = _expected_total(sale, sum(i["total"] for i in items), closes_sale)
    if total != expected:
        raise invalid(CODE, "Refund total does not match.", expected=expected)
    if method == RefundMethod.DEBT and total > _debt_left(sale):
        raise invalid(CODE, "Debt refund exceeds the debt part of the sale.", field="method")

    refund_id = as_uuid(payload, "id", code=CODE)
    if Refund.objects.filter(pk=refund_id).exists():
        raise invalid("duplicate_refund", "Refund with this id already exists.")
    at = as_datetime(payload, "at", code=CODE)
    refund = Refund.objects.create(
        id=refund_id,
        tenant_id=tenant_id,
        sale=sale,
        shift=shift,
        device=device,
        cashier=cashier,
        approved_by=approved_by,
        reason=str(payload.get("reason") or ""),
        method=method,
        total_tiyin=total,
        at=at,
    )
    RefundItem.objects.bulk_create(
        RefundItem(
            id=item["id"],
            tenant_id=tenant_id,
            refund=refund,
            sale_item=item["sale_item"],
            qty_milli=item["qty"],
            total_tiyin=item["total"],
        )
        for item in items
    )
    for item in items:
        record_movement(
            product=item["sale_item"].product,
            store=sale.store,
            qty_milli=item["qty"],
            type=MovementType.REFUND,
            ref_type="refund",
            ref_id=refund.pk,
            user=cashier,
            at=at,
        )
    if method == RefundMethod.DEBT and total:
        record_refund_debt(
            sale.customer,
            amount_tiyin=total,
            sale_id=sale.pk,
            user=cashier,
            at=at,
            id=as_uuid(payload, "debt_entry_id", code=CODE, required=False),
            shift=shift,
        )
    sale.status = SaleStatus.REFUNDED if closes_sale else SaleStatus.PARTIALLY_REFUNDED
    sale.save(update_fields=["status", "updated_at"])
    return refund
