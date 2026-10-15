"""Hodisa turi → uni qo'llovchi servis (sync-api.md "Hodisa → servis")."""

import logging
from types import SimpleNamespace

from django.core.exceptions import ValidationError as DjangoValidationError

from apps.accounts.models import Role
from apps.catalog.barcodes import BarcodeError, normalize_barcode
from apps.catalog.models import Category, Product, ProductBarcode
from apps.catalog.serializers import ProductSerializer
from apps.customers.models import Customer, PaymentMethod
from apps.customers.serializers import CustomerSerializer
from apps.customers.services import pay_debt
from apps.inventory.models import StockReceipt, Supplier
from apps.inventory.serializers import (
    InventoryCountSerializer,
    StockReceiptSerializer,
    SupplierSerializer,
)
from apps.inventory.services import (
    cancel_receipt,
    correct_receipt,
    post_inventory,
    post_receipt,
)
from apps.sales import services as sales
from apps.sales.services import refresh_closed_shift
from apps.sales.services.common import (
    MissingDependency,
    as_datetime,
    as_int,
    as_uuid,
    device_shift,
    invalid,
    tenant_user,
)

logger = logging.getLogger(__name__)

MANAGERS = (Role.OWNER, Role.MANAGER)


def _actor(device, payload, *, managers_only=False):
    code = "invalid_event"
    user = tenant_user(device.tenant_id, as_uuid(payload, "by", code=code), code=code)
    if managers_only and user.role not in MANAGERS:
        raise invalid("permission_denied", "Only owner or manager can do this.")
    return user


def _data(payload) -> dict:
    return {key: value for key, value in payload.items() if key != "by"}


def _upsert(device, payload, model, serializer_class, *, managers_only):
    """`id` bo'yicha yangilash yoki yaratish — REST serializeri va huquqlari bilan."""
    user = _actor(device, payload, managers_only=managers_only)
    context = {"request": SimpleNamespace(user=user)}
    object_id = as_uuid(payload, "id", code="invalid_event")
    instance = model.objects.filter(tenant_id=device.tenant_id, pk=object_id).first()
    serializer = serializer_class(
        instance, data=_data(payload), context=context, partial=instance is not None
    )
    serializer.is_valid(raise_exception=True)
    if instance is None:
        return serializer.save(id=object_id, tenant_id=device.tenant_id)
    return serializer.save()


def debt_paid(device, payload):
    code = "invalid_debt_payment"
    customer_id = as_uuid(payload, "customer", code=code)
    customer = Customer.objects.filter(tenant_id=device.tenant_id, pk=customer_id).first()
    if customer is None:
        raise MissingDependency("customer", customer_id)
    method = payload.get("method")
    if method not in PaymentMethod.values:
        raise invalid(code, "method must be cash or card.", field="method")
    shift_id = as_uuid(payload, "shift", code=code, required=False)
    at = as_datetime(payload, "at", code=code)
    shift = device_shift(device, shift_id, at=at) if shift_id else None
    entry = pay_debt(
        customer,
        amount_tiyin=as_int(payload, "amount_tiyin", code=code, min_value=1),
        method=method,
        user=tenant_user(device.tenant_id, as_uuid(payload, "by", code=code), code=code),
        note=str(payload.get("note") or ""),
        at=at,
        id=as_uuid(payload, "id", code=code),
        shift=shift,
        # Oflaynda bo'lgan to'lov rad etilmaydi (customers-api.md).
        enforce_balance=False,
    )
    if shift is not None:
        refresh_closed_shift(shift)
    return entry


def customer_upserted(device, payload):
    return _upsert(device, payload, Customer, CustomerSerializer, managers_only=False)


def supplier_upserted(device, payload):
    return _upsert(device, payload, Supplier, SupplierSerializer, managers_only=True)


def _clean_product(tenant_id, payload) -> dict:
    """Sinxronda tovar butunlay rad etilmasin (audit PR-P0-1): rad etilsa, u bilan bo'lgan
    savdo va kirimlar ham serverga yetmay qolardi. Boshqa tovarga tegishli shtrix-kod va PLU,
    o'chirilgan kategoriya tushirib qoldiriladi; server holati keyingi pull'da kassaga qaytadi."""
    payload = dict(payload)
    object_id = payload.get("id")
    category = payload.get("category")
    if (
        category
        and not Category.objects.filter(
            tenant_id=tenant_id, pk=category, deleted_at__isnull=True
        ).exists()
    ):
        logger.warning("product %s: deleted category %s dropped", object_id, category)
        payload["category"] = None
    codes = payload.get("barcodes")
    if isinstance(codes, list) and codes:
        normalized = {}
        for raw in codes:
            try:
                normalized[raw] = normalize_barcode(raw)
            except (BarcodeError, TypeError):
                normalized[raw] = None
        taken = set(
            ProductBarcode.objects.filter(
                tenant_id=tenant_id,
                barcode__in=[code for code in normalized.values() if code],
                deleted_at__isnull=True,
            )
            .exclude(product_id=object_id)
            .values_list("barcode", flat=True)
        )
        if taken:
            logger.warning("product %s: barcodes %s belong to other products", object_id, taken)
            payload["barcodes"] = [raw for raw in codes if normalized[raw] not in taken]
    plu = payload.get("plu_code")
    if (
        plu
        and payload.get("is_active", True)
        and Product.objects.filter(
            tenant_id=tenant_id, plu_code=plu, is_active=True, deleted_at__isnull=True
        )
        .exclude(pk=object_id)
        .exists()
    ):
        logger.warning("product %s: PLU %s belongs to another product", object_id, plu)
        payload["plu_code"] = None
    return payload


def product_upserted(device, payload):
    payload = _clean_product(device.tenant_id, payload)
    return _upsert(device, payload, Product, ProductSerializer, managers_only=True)


def _require_products(tenant_id, payload) -> None:
    """Hujjatdagi tovar hali serverda yo'q bo'lsa — kutamiz (rad etmaymiz)."""
    items = payload.get("items")
    if not isinstance(items, list):
        return
    ids = {item.get("product") for item in items if isinstance(item, dict) and item.get("product")}
    if not ids:
        return
    try:
        known = {
            str(pk)
            for pk in Product.objects.filter(tenant_id=tenant_id, pk__in=ids).values_list(
                "pk", flat=True
            )
        }
    except (ValueError, DjangoValidationError):
        return  # noto'g'ri id — serializer tushunarli xato beradi
    missing = sorted(str(i) for i in ids if str(i) not in known)
    # Boshqa tenant tovari — kutmaymiz, serializer "topilmadi" deb rad etadi.
    foreign = {
        str(pk) for pk in Product.objects.filter(pk__in=missing).values_list("pk", flat=True)
    }
    missing = [i for i in missing if i not in foreign]
    if missing:
        raise MissingDependency("product", missing[0])


def _document(device, payload, serializer_class, user):
    _require_products(device.tenant_id, payload)
    # Oflayn hujjat o'shanda mavjud bo'lgan (endi o'chirilgan) tovar/yetkazib beruvchiga
    # tayanishi mumkin — rad etilsa, kassa qoldig'i server bilan abadiy farq qiladi (RC-B1).
    context = {"request": SimpleNamespace(user=user), "allow_deleted": True}
    serializer = serializer_class(data=_data(payload), context=context)
    serializer.is_valid(raise_exception=True)
    return serializer


def _post_document(device, payload, serializer_class, post, **kwargs):
    user = _actor(device, payload, managers_only=True)
    serializer = _document(device, payload, serializer_class, user)
    return post(serializer.save(), user=user, **kwargs)


def _event_time(payload, code):
    """Ixtiyoriy `at` — kassadagi vaqt (eski kassa yubormaydi → server vaqti)."""
    return as_datetime(payload, "at", code=code) if payload.get("at") else None


def receipt_posted(device, payload):
    return _post_document(
        device,
        payload,
        StockReceiptSerializer,
        post_receipt,
        at=_event_time(payload, "invalid_receipt"),
    )


def _original_receipt(device, payload, key):
    receipt_id = as_uuid(payload, key, code="invalid_receipt")
    receipt = StockReceipt.objects.filter(tenant_id=device.tenant_id, pk=receipt_id).first()
    if receipt is None:
        if StockReceipt.objects.filter(pk=receipt_id).exists():  # boshqa tenant
            raise invalid("invalid_receipt", "Unknown receipt.", field=key)
        # Asl kirim hodisasi hali qo'llanmagan — tuzatish kutadi.
        raise MissingDependency("stock_receipt", receipt_id)
    return receipt


def receipt_corrected(device, payload):
    """Kirimni tahrirlash (stock-receipt.md "Tuzatish"): teskari yozuv + yangi versiya."""
    user = _actor(device, payload, managers_only=True)
    original = _original_receipt(device, payload, "corrects")
    version_id = as_uuid(payload, "id", code="invalid_receipt")
    if StockReceipt.objects.filter(pk=version_id, corrects__isnull=False).exists():
        return None  # takroriy (boshqa hodisa id bilan qayta yuborilgan)
    data = {key: payload.get(key) for key in ("id", "supplier", "note", "items")}
    data["note"] = data["note"] or ""
    serializer = _document(device, data, StockReceiptSerializer, user)
    values = serializer.validated_data
    return correct_receipt(
        original,
        user=user,
        id=version_id,
        items=values.get("items") or [],
        supplier=values.get("supplier"),
        note=values.get("note", ""),
        reversal_id=as_uuid(payload, "reversal_id", code="invalid_receipt", required=False),
        at=_event_time(payload, "invalid_receipt"),
    )


def receipt_reversed(device, payload):
    """Kirimni bekor qilish (kassadan). Allaqachon bekor qilingan — hech narsa."""
    user = _actor(device, payload, managers_only=True)
    original = _original_receipt(device, payload, "reverses")
    return cancel_receipt(
        original,
        user=user,
        id=as_uuid(payload, "id", code="invalid_receipt"),
        note=str(payload.get("note") or ""),
        at=_event_time(payload, "invalid_receipt"),
    )


def inventory_posted(device, payload):
    return _post_document(device, payload, InventoryCountSerializer, post_inventory)


HANDLERS = {
    "shift.opened": sales.open_shift,
    "shift.closed": sales.close_shift,
    "cash.moved": sales.record_cash_movement,
    "sale.completed": sales.record_sale,
    "refund.created": sales.record_refund,
    "debt.paid": debt_paid,
    "customer.upserted": customer_upserted,
    "supplier.upserted": supplier_upserted,
    "product.upserted": product_upserted,
    "receipt.posted": receipt_posted,
    "receipt.corrected": receipt_corrected,
    "receipt.reversed": receipt_reversed,
    "inventory.posted": inventory_posted,
}
