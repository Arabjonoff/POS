"""Hodisa turi → uni qo'llovchi servis (sync-api.md "Hodisa → servis")."""

from types import SimpleNamespace

from apps.accounts.models import Role
from apps.catalog.models import Product
from apps.catalog.serializers import ProductSerializer
from apps.customers.models import Customer, PaymentMethod
from apps.customers.serializers import CustomerSerializer
from apps.customers.services import pay_debt
from apps.inventory.models import Supplier
from apps.inventory.serializers import (
    InventoryCountSerializer,
    StockReceiptSerializer,
    SupplierSerializer,
)
from apps.inventory.services import post_inventory, post_receipt
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


def product_upserted(device, payload):
    return _upsert(device, payload, Product, ProductSerializer, managers_only=True)


def _post_document(device, payload, serializer_class, post):
    user = _actor(device, payload, managers_only=True)
    context = {"request": SimpleNamespace(user=user)}
    serializer = serializer_class(data=_data(payload), context=context)
    serializer.is_valid(raise_exception=True)
    return post(serializer.save(), user=user)


def receipt_posted(device, payload):
    return _post_document(device, payload, StockReceiptSerializer, post_receipt)


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
    "inventory.posted": inventory_posted,
}
