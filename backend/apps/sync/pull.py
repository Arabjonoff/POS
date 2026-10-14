"""Pull: ChangeLog bo'yicha o'zgargan obyektlarning hozirgi holati (sync-api.md)."""

from django.db.models import F, Prefetch, Q
from rest_framework import serializers

from apps.accounts.models import User
from apps.catalog.models import Category, Product, ProductBarcode, Unit
from apps.catalog.serializers import CategorySerializer, ProductSerializer, UnitSerializer
from apps.customers.models import Customer, DebtEntry
from apps.customers.serializers import CustomerSerializer, DebtEntrySerializer
from apps.customers.services import with_balance
from apps.inventory.models import ProductStock, Supplier
from apps.inventory.serializers import StockSerializer, SupplierSerializer
from apps.tenants.models import Store

from .db import OwnTxid, SnapshotXmin
from .models import ChangeLog, ChangeOp

DEFAULT_LIMIT = 500


class SyncUserSerializer(serializers.ModelSerializer):
    """Kassada oflayn PIN tekshiruvi uchun (sync.md: User pin_hash bilan)."""

    class Meta:
        model = User
        fields = ["id", "phone", "full_name", "role", "is_active", "pin_hash"]


class SyncStoreSerializer(serializers.ModelSerializer):
    class Meta:
        model = Store
        fields = ["id", "name", "address", "phone", "receipt_header", "receipt_footer"]


def _products():
    barcodes = ProductBarcode.objects.filter(deleted_at__isnull=True)
    return Product.objects.prefetch_related(Prefetch("barcodes", queryset=barcodes))


# entity → (queryset yasovchi, serializer, qidiruv maydoni)
ENTITIES = {
    "unit": (Unit.objects.all, UnitSerializer, "pk"),
    "category": (Category.objects.all, CategorySerializer, "pk"),
    "product": (_products, ProductSerializer, "pk"),
    "supplier": (Supplier.objects.all, SupplierSerializer, "pk"),
    "customer": (lambda: with_balance(Customer.objects.all()), CustomerSerializer, "pk"),
    "user": (User.objects.all, SyncUserSerializer, "pk"),
    "store": (Store.objects.all, SyncStoreSerializer, "pk"),
    "debt_entry": (DebtEntry.objects.all, DebtEntrySerializer, "pk"),
    "stock": (ProductStock.objects.all, StockSerializer, "product_id"),
}


def _load(tenant_id, entity: str, ids) -> dict:
    queryset_factory, serializer_class, key = ENTITIES[entity]
    objects = queryset_factory().filter(tenant_id=tenant_id, **{f"{key}__in": ids})
    return {getattr(obj, key): serializer_class(obj).data for obj in objects}


def parse_cursor(cursor: str) -> tuple[int, int]:
    """`"<txid>:<seq>"` yoki boshlang'ich `"0"`."""
    if cursor in ("", "0"):
        return (0, 0)
    txid, sep, seq = cursor.partition(":")
    if not sep or not txid.isdigit() or not seq.isdigit():
        raise ValueError("cursor must be '0' or '<txid>:<seq>'")
    return (int(txid), int(seq))


def format_cursor(txid: int, seq: int) -> str:
    return "0" if (txid, seq) == (0, 0) else f"{txid}:{seq}"


def pull(device, cursor: str, limit: int = DEFAULT_LIMIT) -> dict:
    after_txid, after_seq = parse_cursor(cursor)
    # Faqat tugagan tranzaksiyalar (yoki o'zimizniki): keyin ularning orasiga yozuv tushmaydi.
    visible = ChangeLog.objects.annotate(xmin=SnapshotXmin(), own=OwnTxid()).filter(
        Q(txid__lt=F("xmin")) | Q(txid=F("own")),
        Q(txid__gt=after_txid) | Q(txid=after_txid, seq__gt=after_seq),
        tenant_id=device.tenant_id,
    )
    rows = list(visible.order_by("txid", "seq")[: limit + 1])
    has_more = len(rows) > limit
    rows = rows[:limit]
    next_cursor = format_cursor(rows[-1].txid, rows[-1].seq) if rows else cursor or "0"

    # Sahifa ichida har obyekt bir marta — eng oxirgi o'zgarishi o'rnida.
    latest = {}
    for row in rows:
        latest.pop((row.entity, row.entity_id), None)
        latest[(row.entity, row.entity_id)] = row
    wanted = {}
    for (entity, entity_id), row in latest.items():
        if row.op == ChangeOp.UPSERT and entity in ENTITIES:
            wanted.setdefault(entity, []).append(entity_id)
    loaded = {entity: _load(device.tenant_id, entity, ids) for entity, ids in wanted.items()}

    changes = []
    for (entity, entity_id), row in latest.items():
        if entity not in ENTITIES:
            continue
        data = loaded.get(entity, {}).get(entity_id) if row.op == ChangeOp.UPSERT else None
        # Obyekt butunlay o'chirilgan bo'lsa — `delete`.
        op = ChangeOp.UPSERT if data is not None else ChangeOp.DELETE
        changes.append({"entity": entity, "op": op, "id": entity_id, "data": data})
    return {"changes": changes, "next_cursor": next_cursor, "has_more": has_more}
