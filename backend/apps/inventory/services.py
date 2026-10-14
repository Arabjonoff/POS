"""Ombor amallari. Qoldiq faqat `record_movement` orqali o'zgaradi (harakat + kesh birga)."""

from django.db import IntegrityError, transaction
from django.db.models import F, Max, Sum
from django.utils import timezone

from apps.catalog.models import PriceHistory, Product
from apps.core.exceptions import DomainError
from apps.core.money import line_total
from apps.tenants.models import Store, Tenant

from .models import (
    DocumentStatus,
    InventoryCount,
    InventoryCountItem,
    MovementType,
    ProductStock,
    StockMovement,
    StockReceipt,
    StockReceiptItem,
)


def _bump_cache(movement: StockMovement) -> None:
    updated = ProductStock.objects.filter(
        product_id=movement.product_id, store_id=movement.store_id
    ).update(qty_milli=F("qty_milli") + movement.qty_milli, updated_at=timezone.now())
    if updated:
        return
    try:
        with transaction.atomic():
            ProductStock.objects.create(
                tenant_id=movement.tenant_id,
                product_id=movement.product_id,
                store_id=movement.store_id,
                qty_milli=movement.qty_milli,
            )
    except IntegrityError:
        # Parallel tranzaksiya qatorni yaratib ulgurdi — endi yangilaymiz.
        ProductStock.objects.filter(
            product_id=movement.product_id, store_id=movement.store_id
        ).update(qty_milli=F("qty_milli") + movement.qty_milli, updated_at=timezone.now())


@transaction.atomic
def record_movement(
    *,
    product,
    store,
    qty_milli: int,
    type: str,
    ref_type: str = "",
    ref_id=None,
    user=None,
    at=None,
) -> StockMovement:
    if not isinstance(qty_milli, int) or isinstance(qty_milli, bool) or qty_milli == 0:
        raise ValueError("qty_milli must be a non-zero int")
    if product.tenant_id != store.tenant_id:
        raise ValueError("product and store belong to different tenants")
    movement = StockMovement.objects.create(
        tenant_id=product.tenant_id,
        product=product,
        store=store,
        qty_milli=qty_milli,
        type=type,
        ref_type=ref_type,
        ref_id=ref_id,
        created_by=user,
        at=at or timezone.now(),
    )
    _bump_cache(movement)
    return movement


def current_stock(product, store) -> int:
    row = ProductStock.objects.filter(product=product, store=store).first()
    return row.qty_milli if row else 0


def stock_from_movements(product, store) -> int:
    total = StockMovement.objects.filter(product=product, store=store).aggregate(s=Sum("qty_milli"))
    return total["s"] or 0


def rebuild_stock(tenant_id=None) -> int:
    """Keshni harakatlardan qayta hisoblaydi; tuzatilgan qatorlar soni."""
    movements = StockMovement.objects.all()
    if tenant_id is not None:
        movements = movements.filter(tenant_id=tenant_id)
    totals = movements.values("tenant_id", "product_id", "store_id").annotate(s=Sum("qty_milli"))
    fixed = 0
    with transaction.atomic():
        seen = set()
        for row in totals:
            key = (row["product_id"], row["store_id"])
            seen.add(key)
            stock, created = ProductStock.objects.select_for_update().get_or_create(
                product_id=key[0],
                store_id=key[1],
                defaults={"tenant_id": row["tenant_id"], "qty_milli": row["s"]},
            )
            if not created and stock.qty_milli != row["s"]:
                stock.qty_milli = row["s"]
                stock.save(update_fields=["qty_milli", "updated_at"])
                fixed += 1
            elif created:
                fixed += 1
        stale = ProductStock.objects.exclude(qty_milli=0)
        if tenant_id is not None:
            stale = stale.filter(tenant_id=tenant_id)
        for stock in stale.select_for_update():
            if (stock.product_id, stock.store_id) not in seen:
                stock.qty_milli = 0
                stock.save(update_fields=["qty_milli", "updated_at"])
                fixed += 1
    return fixed


# --- Kirim ---


def next_receipt_number(tenant_id) -> int:
    """Tranzaksiya ichida chaqiriladi: tenant qatori qulflanadi, raqamlar takrorlanmaydi."""
    Tenant.objects.select_for_update().filter(pk=tenant_id).first()
    last = StockReceipt.objects.filter(tenant_id=tenant_id).aggregate(n=Max("number"))["n"]
    return (last or 0) + 1


def default_store(tenant_id) -> Store:
    return Store.objects.filter(tenant_id=tenant_id).order_by("created_at").first()


@transaction.atomic
def create_receipt(*, tenant_id, user, data: dict) -> StockReceipt:
    items = data.pop("items", [])
    receipt = StockReceipt.objects.create(
        tenant_id=tenant_id,
        store=data.pop("store", None) or default_store(tenant_id),
        number=next_receipt_number(tenant_id),
        created_by=user,
        **data,
    )
    replace_receipt_items(receipt, items)
    return receipt


@transaction.atomic
def update_receipt(receipt: StockReceipt, data: dict) -> StockReceipt:
    receipt = _lock(StockReceipt, receipt.pk)
    _ensure_draft(receipt)
    items = data.pop("items", None)
    for field, value in data.items():
        setattr(receipt, field, value)
    receipt.save()
    if items is not None:
        replace_receipt_items(receipt, items)
    return receipt


@transaction.atomic
def delete_receipt(receipt: StockReceipt) -> None:
    receipt = _lock(StockReceipt, receipt.pk)
    _ensure_draft(receipt)
    receipt.delete()


def _ensure_draft(receipt: StockReceipt) -> None:
    if receipt.status != DocumentStatus.DRAFT:
        raise DomainError("receipt_not_draft", "Receipt is already posted.", status_code=409)


def replace_receipt_items(receipt: StockReceipt, items: list[dict]) -> None:
    receipt.items.all().delete()
    total = 0
    for item in items:
        line = line_total(item["cost_price_tiyin"], item["qty_milli"])
        total += line
        StockReceiptItem.objects.create(
            tenant_id=receipt.tenant_id,
            receipt=receipt,
            product=item["product"],
            qty_milli=item["qty_milli"],
            cost_price_tiyin=item["cost_price_tiyin"],
            new_sell_price_tiyin=item.get("new_sell_price_tiyin"),
            line_total_tiyin=line,
        )
    receipt.total_cost_tiyin = total
    receipt.save(update_fields=["total_cost_tiyin", "updated_at"])


def _lock(model, pk):
    return model.objects.select_for_update().get(pk=pk)


@transaction.atomic
def post_receipt(receipt: StockReceipt, *, user) -> StockReceipt:
    receipt = _lock(StockReceipt, receipt.pk)
    _ensure_draft(receipt)
    items = list(receipt.items.select_related("product"))
    if not items:
        raise DomainError("receipt_empty", "Receipt has no items.")
    for item in items:
        record_movement(
            product=item.product,
            store=receipt.store,
            qty_milli=item.qty_milli,
            type=MovementType.RECEIPT,
            ref_type="stock_receipt",
            ref_id=receipt.pk,
            user=user,
        )
        product = Product.objects.select_for_update().get(pk=item.product_id)
        old = (product.sell_price_tiyin, product.cost_price_tiyin)
        product.cost_price_tiyin = item.cost_price_tiyin
        if item.new_sell_price_tiyin is not None:
            product.sell_price_tiyin = item.new_sell_price_tiyin
        if (product.sell_price_tiyin, product.cost_price_tiyin) != old:
            product.save(update_fields=["sell_price_tiyin", "cost_price_tiyin", "updated_at"])
            PriceHistory.objects.create(
                tenant_id=product.tenant_id,
                product=product,
                sell_price_tiyin=product.sell_price_tiyin,
                cost_price_tiyin=product.cost_price_tiyin,
                changed_by=user,
            )
    receipt.status = DocumentStatus.POSTED
    receipt.posted_at = timezone.now()
    receipt.posted_by = user
    receipt.save(update_fields=["status", "posted_at", "posted_by", "updated_at"])
    return receipt


@transaction.atomic
def reverse_receipt(receipt: StockReceipt, *, user, note: str = "") -> StockReceipt:
    """Teskari kirim: manfiy harakatlar bilan yangi tasdiqlangan hujjat. Narxlar qaytarilmaydi."""
    receipt = _lock(StockReceipt, receipt.pk)
    if receipt.reverses_id is not None:
        raise DomainError("cannot_reverse_reversal", "A reversal cannot be reversed.", 409)
    if receipt.status != DocumentStatus.POSTED:
        raise DomainError("receipt_not_posted", "Only a posted receipt can be reversed.", 409)
    if StockReceipt.objects.filter(reverses=receipt).exists():
        raise DomainError("already_reversed", "Receipt is already reversed.", status_code=409)
    now = timezone.now()
    reversal = StockReceipt.objects.create(
        tenant_id=receipt.tenant_id,
        store=receipt.store,
        supplier=receipt.supplier,
        number=next_receipt_number(receipt.tenant_id),
        status=DocumentStatus.POSTED,
        total_cost_tiyin=-receipt.total_cost_tiyin,
        note=note,
        reverses=receipt,
        created_by=user,
        posted_at=now,
        posted_by=user,
    )
    for item in receipt.items.select_related("product"):
        StockReceiptItem.objects.create(
            tenant_id=receipt.tenant_id,
            receipt=reversal,
            product=item.product,
            qty_milli=-item.qty_milli,
            cost_price_tiyin=item.cost_price_tiyin,
            line_total_tiyin=-item.line_total_tiyin,
        )
        record_movement(
            product=item.product,
            store=receipt.store,
            qty_milli=-item.qty_milli,
            type=MovementType.RECEIPT,
            ref_type="stock_receipt",
            ref_id=reversal.pk,
            user=user,
            at=now,
        )
    return reversal


# --- Inventarizatsiya ---


def _ensure_count_draft(count: InventoryCount) -> None:
    if count.status != DocumentStatus.DRAFT:
        raise DomainError("count_not_draft", "Inventory count is already posted.", 409)


def replace_count_items(count: InventoryCount, items: list[dict]) -> None:
    count.items.all().delete()
    InventoryCountItem.objects.bulk_create(
        InventoryCountItem(
            tenant_id=count.tenant_id,
            count=count,
            product=item["product"],
            counted_milli=item["counted_milli"],
        )
        for item in items
    )


@transaction.atomic
def create_count(*, tenant_id, user, data: dict) -> InventoryCount:
    items = data.pop("items", [])
    count = InventoryCount.objects.create(
        tenant_id=tenant_id,
        store=data.pop("store", None) or default_store(tenant_id),
        created_by=user,
        **data,
    )
    replace_count_items(count, items)
    return count


@transaction.atomic
def update_count(count: InventoryCount, data: dict) -> InventoryCount:
    count = _lock(InventoryCount, count.pk)
    _ensure_count_draft(count)
    items = data.pop("items", None)
    for field, value in data.items():
        setattr(count, field, value)
    count.save()
    if items is not None:
        replace_count_items(count, items)
    return count


@transaction.atomic
def delete_count(count: InventoryCount) -> None:
    count = _lock(InventoryCount, count.pk)
    _ensure_count_draft(count)
    count.delete()


@transaction.atomic
def post_inventory(count: InventoryCount, *, user) -> InventoryCount:
    count = _lock(InventoryCount, count.pk)
    _ensure_count_draft(count)
    items = list(count.items.select_related("product"))
    if not items:
        raise DomainError("count_empty", "Inventory count has no items.")
    now = timezone.now()
    for item in items:
        # Qoldiq qatorini qulflab o'qiymiz: parallel savdo farqni buzmasin.
        stock = (
            ProductStock.objects.select_for_update()
            .filter(product_id=item.product_id, store_id=count.store_id)
            .first()
        )
        expected = stock.qty_milli if stock else 0
        item.expected_milli = expected
        item.save(update_fields=["expected_milli", "updated_at"])
        diff = item.counted_milli - expected
        if diff:
            record_movement(
                product=item.product,
                store=count.store,
                qty_milli=diff,
                type=MovementType.INVENTORY,
                ref_type="inventory_count",
                ref_id=count.pk,
                user=user,
                at=now,
            )
    count.status = DocumentStatus.POSTED
    count.posted_at = now
    count.posted_by = user
    count.save(update_fields=["status", "posted_at", "posted_by", "updated_at"])
    return count
