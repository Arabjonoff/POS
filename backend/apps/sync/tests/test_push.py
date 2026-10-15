from datetime import timedelta

import pytest
from django.utils import timezone
from rest_framework.test import APIClient
from rest_framework_simplejwt.tokens import RefreshToken

from apps.catalog.models import Category, Product, ProductBarcode
from apps.core.ids import new_id
from apps.customers.models import Customer
from apps.customers.services import customer_balance, record_sale_debt
from apps.inventory.models import MovementType, StockReceipt, Supplier
from apps.inventory.services import current_stock, record_movement
from apps.sales.models import Sale, Shift
from apps.sync import handlers
from apps.sync.models import SyncEvent

from .helpers import PUSH, event, push, sale_completed, shift_opened, statuses, tick

pytestmark = pytest.mark.django_db


def _opened(client, cashier):
    shift_id = new_id()
    assert statuses(push(client, shift_opened(cashier, shift_id))) == ["applied"]
    return shift_id


# --- sync.md server qabul mezonlari ---


def test_same_batch_twice_is_duplicate(kassa, cashier, product, tenant):
    _, client = kassa
    shift_id = new_id()
    batch = [shift_opened(cashier, shift_id), sale_completed(shift_id, cashier, product)]
    assert statuses(push(client, *batch)) == ["applied", "applied"]
    assert statuses(push(client, *batch)) == ["duplicate", "duplicate"]
    assert Sale.objects.count() == 1
    assert current_stock(product, tenant.stores.get()) == -1_000


def test_sale_before_shift_is_pending_then_applied(kassa, cashier, product):
    _, client = kassa
    shift_id = new_id()
    sale = sale_completed(shift_id, cashier, product)
    result = push(client, sale)[0]
    assert result["status"] == "pending"
    assert result["error"]["code"] == "missing_dependency"
    assert not Sale.objects.exists()

    # Smena keyingi push'da keladi — kutilgan savdo qo'llanadi.
    assert statuses(push(client, shift_opened(cashier, shift_id))) == ["applied"]
    assert SyncEvent.objects.get(pk=sale["id"]).status == "applied"
    assert Sale.objects.filter(pk=sale["payload"]["id"]).exists()
    # Kassa qayta yuborsa — dublikat.
    assert statuses(push(client, sale)) == ["duplicate"]


def test_out_of_order_in_one_batch(kassa, cashier, product):
    _, client = kassa
    shift_id = new_id()
    later = tick()
    sale = sale_completed(shift_id, cashier, product, created_at=later)
    shift = shift_opened(cashier, shift_id)
    # Smena hodisasi oldinroq yaratilgan — paket ichidagi tartibdan qat'i nazar oldin qo'llanadi.
    assert statuses(push(client, sale, shift)) == ["applied", "applied"]


def test_pending_applied_in_same_push_after_dependency(kassa, cashier, product):
    _, client = kassa
    shift_id = new_id()
    first = sale_completed(shift_id, cashier, product, created_at="2026-10-14T08:00:00+05:00")
    second = shift_opened(cashier, shift_id, created_at="2026-10-14T09:00:00+05:00")
    # Savdo `created_at` bo'yicha oldin — avval pending, smenadan keyin yakunda qo'llanadi.
    assert statuses(push(client, first, second)) == ["applied", "applied"]


def test_two_devices_sell_same_product_offline(make_device, tenant, cashier, product):
    store = tenant.stores.get()
    record_movement(product=product, store=store, qty_milli=10_000, type=MovementType.RECEIPT)
    (_, first), (_, second) = make_device(tenant, 1), make_device(tenant, 2)
    for client, qty in ((first, 3_000), (second, 4_500)):
        shift_id = new_id()
        batch = [shift_opened(cashier, shift_id), sale_completed(shift_id, cashier, product, qty)]
        assert statuses(push(client, *batch)) == ["applied", "applied"]
    assert current_stock(product, store) == 10_000 - 3_000 - 4_500


def test_other_tenant_device_cannot_touch_our_data(make_device, other_tenant, make_user, product):
    _, client = make_device(other_tenant)
    stranger = make_user(other_tenant, role="cashier")
    shift_id = new_id()
    results = push(
        client, shift_opened(stranger, shift_id), sale_completed(shift_id, stranger, product)
    )
    assert statuses(results) == ["applied", "rejected"]
    assert results[1]["error"]["code"] == "invalid_sale"
    assert not Sale.objects.exists()


# --- statuslar va xatolar ---


def test_invalid_event_rejected_with_error(kassa, cashier, product):
    _, client = kassa
    shift_id = _opened(client, cashier)
    bad = sale_completed(shift_id, cashier, product)
    bad["payload"]["total_tiyin"] = 1
    result = push(client, bad)[0]
    assert result["status"] == "rejected"
    assert result["error"]["code"] == "invalid_sale"
    stored = SyncEvent.objects.get(pk=bad["id"])
    assert (stored.status, stored.error["code"]) == ("rejected", "invalid_sale")
    # Qayta yuborilsa ham dublikat — qayta qo'llanmaydi.
    assert statuses(push(client, bad)) == ["duplicate"]


def test_one_bad_event_does_not_block_others(kassa, cashier, product):
    _, client = kassa
    shift_id = _opened(client, cashier)
    bad = sale_completed(shift_id, cashier, product)
    bad["payload"]["items"] = []
    good = sale_completed(shift_id, cashier, product)
    assert statuses(push(client, bad, good)) == ["rejected", "applied"]


def test_unknown_event_type(kassa):
    _, client = kassa
    result = push(client, event("pizza.ordered", {}))[0]
    assert (result["status"], result["error"]["code"]) == ("rejected", "unknown_event")


def test_event_id_used_by_other_device(make_device, tenant, cashier):
    (_, first), (_, second) = make_device(tenant, 1), make_device(tenant, 2)
    opened = shift_opened(cashier)
    push(first, opened)
    result = push(second, opened)[0]
    assert (result["status"], result["error"]["code"]) == ("rejected", "id_conflict")
    assert Shift.objects.count() == 1


def test_duplicate_id_inside_one_batch(kassa, cashier):
    _, client = kassa
    opened = shift_opened(cashier)
    assert statuses(push(client, opened, opened)) == ["applied", "duplicate"]


def test_server_error_is_retried(kassa, cashier, monkeypatch):
    _, client = kassa

    def broken(device, payload):
        raise RuntimeError("bug")

    monkeypatch.setitem(handlers.HANDLERS, "shift.opened", broken)
    opened = shift_opened(cashier)
    result = push(client, opened)[0]
    assert (result["status"], result["error"]["code"]) == ("pending", "server_error")

    monkeypatch.undo()
    push(client, event("pizza.ordered", {}))  # har qanday keyingi push qayta urinadi
    assert SyncEvent.objects.get(pk=opened["id"]).status == "applied"


def test_pending_expires_after_ttl(kassa, cashier, product):
    _, client = kassa
    sale = sale_completed(new_id(), cashier, product)
    push(client, sale)
    SyncEvent.objects.filter(pk=sale["id"]).update(received_at=timezone.now() - timedelta(days=8))
    push(client, event("pizza.ordered", {}))
    stored = SyncEvent.objects.get(pk=sale["id"])
    assert (stored.status, stored.error["code"]) == ("rejected", "missing_dependency")
    assert stored.attempts == 2


def test_device_sync_time_updated(kassa, cashier):
    device, client = kassa
    push(client, shift_opened(cashier))
    device.refresh_from_db()
    assert device.last_sync_at is not None


# --- hodisa turlari ---


def test_debt_paid(kassa, cashier, tenant):
    _, client = kassa
    customer = Customer.objects.create(tenant=tenant, full_name="Anvar")
    record_sale_debt(customer, amount_tiyin=50_000, sale_id=new_id())
    shift_id = _opened(client, cashier)
    payment = event(
        "debt.paid",
        {
            "id": str(new_id()),
            "customer": str(customer.id),
            "amount_tiyin": 80_000,
            "method": "cash",
            "shift": str(shift_id),
            "by": str(cashier.id),
            "at": tick(),
        },
    )
    assert statuses(push(client, payment)) == ["applied"]
    # Oflayn to'lov qarzdan ko'p bo'lsa ham rad etilmaydi.
    assert customer_balance(customer) == -30_000
    assert customer.debt_entries.get(type="payment").shift_id == shift_id


def test_waiting_debt_sale_and_payment_survive_shift_close(kassa, cashier, product):
    """Audit CU-B2/B3: mijoz hodisasi kechiksa, uning nasiya savdosi va to'lovi kutadi
    va smena yopilgandan keyin ham qo'llanadi (rad etilmaydi), Z-hisobot yangilanadi."""
    _, client = kassa
    shift_id = _opened(client, cashier)
    customer_id = str(new_id())
    sale = sale_completed(shift_id, cashier, product)
    sale["payload"]["customer"] = customer_id
    sale["payload"]["debt_entry_id"] = str(new_id())
    sale["payload"]["payments"] = [
        {"id": str(new_id()), "method": "debt", "amount_tiyin": 400_000, "change_tiyin": 0}
    ]
    payment = event(
        "debt.paid",
        {
            "id": str(new_id()),
            "customer": customer_id,
            "amount_tiyin": 100_000,
            "method": "cash",
            "shift": str(shift_id),
            "by": str(cashier.id),
            "at": tick(),
        },
    )
    closed = event(
        "shift.closed",
        {
            "id": str(shift_id),
            "closed_by": str(cashier.id),
            "counted_cash_tiyin": 100_000,
            "closed_at": tick(),
        },
    )
    assert statuses(push(client, sale, payment, closed)) == ["pending", "pending", "applied"]

    upserted = event(
        "customer.upserted", {"id": customer_id, "full_name": "Kech", "by": str(cashier.id)}
    )
    assert statuses(push(client, upserted)) == ["applied"]
    assert SyncEvent.objects.get(pk=sale["id"]).status == "applied"
    assert SyncEvent.objects.get(pk=payment["id"]).status == "applied"
    customer = Customer.objects.get(pk=customer_id)
    assert customer_balance(customer) == 300_000
    shift = Shift.objects.get(pk=shift_id)
    assert not shift.is_open
    assert shift.expected_cash_tiyin == 100_000


def test_nul_character_does_not_block_the_queue(kassa, cashier, tenant):
    """Audit PR-P0-2: `\\u0000` push'ni 500 bilan yiqitib, navbatni to'xtatardi."""
    _, client = kassa
    customer_id = str(new_id())
    upserted = event(
        "customer.upserted",
        {"id": customer_id, "full_name": "Ali\u0000 aka", "note": "\u0000", "by": str(cashier.id)},
    )
    assert statuses(push(client, upserted)) == ["applied"]
    assert Customer.objects.get(pk=customer_id).full_name == "Ali aka"


def test_event_after_shift_close_time_still_rejected(kassa, cashier, product):
    _, client = kassa
    shift_id = _opened(client, cashier)
    closed = event(
        "shift.closed",
        {
            "id": str(shift_id),
            "closed_by": str(cashier.id),
            "counted_cash_tiyin": 0,
            "closed_at": tick(),
        },
    )
    assert statuses(push(client, closed)) == ["applied"]
    result = push(client, sale_completed(shift_id, cashier, product))[0]
    assert result["status"] == "rejected"
    assert result["error"]["code"] == "shift_closed"


def test_debt_paid_for_unknown_customer_is_pending(kassa, cashier):
    _, client = kassa
    payment = event(
        "debt.paid",
        {
            "id": str(new_id()),
            "customer": str(new_id()),
            "amount_tiyin": 1,
            "method": "cash",
            "by": str(cashier.id),
            "at": tick(),
        },
    )
    assert statuses(push(client, payment)) == ["pending"]


def test_customer_upserted_create_and_update(kassa, cashier, manager, tenant):
    _, client = kassa
    customer_id = str(new_id())
    created = event(
        "customer.upserted", {"id": customer_id, "full_name": "Dilnoza", "by": str(cashier.id)}
    )
    assert statuses(push(client, created)) == ["applied"]
    customer = Customer.objects.get(pk=customer_id)
    assert customer.tenant_id == tenant.id

    renamed = event(
        "customer.upserted",
        {"id": customer_id, "full_name": "Dilnoza opa", "phone": "", "by": str(cashier.id)},
    )
    assert statuses(push(client, renamed)) == ["applied"]
    customer.refresh_from_db()
    assert customer.full_name == "Dilnoza opa"

    limit = event(
        "customer.upserted",
        {"id": customer_id, "full_name": "X", "debt_limit_tiyin": 100, "by": str(cashier.id)},
    )
    result = push(client, limit)[0]
    assert (result["status"], result["error"]["code"]) == ("rejected", "permission_denied")

    limit["id"] = str(new_id())
    limit["payload"]["by"] = str(manager.id)
    assert statuses(push(client, limit)) == ["applied"]
    customer.refresh_from_db()
    assert customer.debt_limit_tiyin == 100


def test_product_upserted_requires_manager(kassa, cashier, manager, tenant):
    _, client = kassa
    payload = {
        "id": str(new_id()),
        "name": "Sut",
        "unit": str(tenant.units.get(code="pcs").id),
        "sell_price_tiyin": 1_200_000,
        "barcodes": ["4780000000007"],
    }
    result = push(client, event("product.upserted", payload | {"by": str(cashier.id)}))[0]
    assert (result["status"], result["error"]["code"]) == ("rejected", "permission_denied")

    result = push(client, event("product.upserted", payload | {"by": str(manager.id)}))[0]
    assert result["status"] == "applied"
    product = Product.objects.get(pk=payload["id"], tenant=tenant)
    assert product.barcodes.get().barcode == "4780000000007"


def test_product_upserted_validation_error(kassa, manager):
    _, client = kassa
    payload = {"id": str(new_id()), "name": "", "by": str(manager.id)}
    result = push(client, event("product.upserted", payload))[0]
    assert (result["status"], result["error"]["code"]) == ("rejected", "validation_error")
    assert "name" in result["error"]["details"]


def test_supplier_upserted(kassa, manager, tenant):
    _, client = kassa
    supplier_id = str(new_id())
    payload = {"id": supplier_id, "name": "Coca-Cola", "by": str(manager.id)}
    assert statuses(push(client, event("supplier.upserted", payload))) == ["applied"]
    assert Supplier.objects.get(pk=supplier_id).tenant_id == tenant.id


def test_receipt_and_inventory_posted(kassa, manager, product, tenant):
    _, client = kassa
    store = tenant.stores.get()
    receipt_id = str(new_id())
    receipt = event(
        "receipt.posted",
        {
            "id": receipt_id,
            "items": [{"product": str(product.id), "qty_milli": 20_000, "cost_price_tiyin": 1}],
            "by": str(manager.id),
        },
    )
    assert statuses(push(client, receipt)) == ["applied"]
    assert StockReceipt.objects.get(pk=receipt_id).status == "posted"
    assert current_stock(product, store) == 20_000

    count = event(
        "inventory.posted",
        {
            "id": str(new_id()),
            "items": [{"product": str(product.id), "counted_milli": 18_000}],
            "by": str(manager.id),
        },
    )
    assert statuses(push(client, count)) == ["applied"]
    assert current_stock(product, store) == 18_000


def test_product_with_taken_barcode_is_kept_and_its_sale_applied(
    kassa, manager, cashier, product, tenant
):
    """Audit PR-P0-1: ikki kassa bir shtrix-kodni berdi — ikkinchi tovar rad etilsa,
    uning savdolari ham yo'qolardi. Endi tovar qo'llanadi, band kod tushiriladi."""
    _, client = kassa
    ProductBarcode.objects.create(tenant=tenant, product=product, barcode="4780000000007")
    category = Category.objects.create(tenant=tenant, name="Eski")
    category.deleted_at = timezone.now()
    category.save()
    other = Product.objects.create(
        tenant=tenant,
        name="PLU egasi",
        unit=tenant.units.get(code="kg"),
        sell_price_tiyin=1,
        is_weighted=True,
        plu_code="12",
    )
    new_product_id = str(new_id())
    upsert = event(
        "product.upserted",
        {
            "id": new_product_id,
            "name": "Sut 1 l",
            "unit": str(tenant.units.get(code="kg").id),
            "is_weighted": True,
            "plu_code": "12",
            "category": str(category.id),
            "sell_price_tiyin": 1_200_000,
            "barcodes": ["4780000000007", "4780000000014"],
            "by": str(manager.id),
        },
    )
    shift_id = new_id()
    new_product = Product(id=new_product_id, name="Sut 1 l", cost_price_tiyin=0)
    sale = sale_completed(shift_id, cashier, new_product, price=1_200_000)
    results = push(client, upsert, shift_opened(cashier, shift_id), sale)
    assert statuses(results) == ["applied", "applied", "applied"]
    created = Product.objects.get(pk=new_product_id)
    assert [b.barcode for b in created.barcodes.all()] == ["4780000000014"]
    assert created.plu_code is None
    assert created.category is None
    assert other.plu_code == "12"
    assert Sale.objects.filter(pk=sale["payload"]["id"]).exists()


def test_document_waits_for_product_and_accepts_deleted_ones(kassa, manager, product, tenant):
    """Audit RC-B1: oflayn kirim o'chirilgan tovar/yetkazib beruvchiga — qabul;
    hali kelmagan tovar — kutadi."""
    _, client = kassa
    store = tenant.stores.get()
    supplier = Supplier.objects.create(tenant=tenant, name="Eski ta'minotchi")
    supplier.deleted_at = timezone.now()
    supplier.save()
    product.deleted_at = timezone.now()
    product.save()
    receipt = event(
        "receipt.posted",
        {
            "id": str(new_id()),
            "supplier": str(supplier.id),
            "items": [{"product": str(product.id), "qty_milli": 5_000, "cost_price_tiyin": 1}],
            "by": str(manager.id),
        },
    )
    assert statuses(push(client, receipt)) == ["applied"]
    assert current_stock(product, store) == 5_000

    later_id = str(new_id())
    waiting = event(
        "receipt.posted",
        {
            "id": str(new_id()),
            "items": [{"product": later_id, "qty_milli": 1_000, "cost_price_tiyin": 1}],
            "by": str(manager.id),
        },
    )
    result = push(client, waiting)[0]
    assert (result["status"], result["error"]["code"]) == ("pending", "missing_dependency")
    upsert = event(
        "product.upserted",
        {
            "id": later_id,
            "name": "Keyin",
            "unit": str(tenant.units.get(code="pcs").id),
            "sell_price_tiyin": 1,
            "by": str(manager.id),
        },
    )
    assert statuses(push(client, upsert)) == ["applied"]
    assert SyncEvent.objects.get(pk=waiting["id"]).status == "applied"


def test_cashier_cannot_post_receipt(kassa, cashier, product):
    _, client = kassa
    receipt = event(
        "receipt.posted",
        {
            "id": str(new_id()),
            "items": [{"product": str(product.id), "qty_milli": 1, "cost_price_tiyin": 1}],
            "by": str(cashier.id),
        },
    )
    assert statuses(push(client, receipt)) == ["rejected"]
    assert not StockReceipt.objects.exists()


# --- envelope va autentifikatsiya ---


@pytest.mark.parametrize(
    "body",
    [
        {"events": []},
        {"events": [{"id": "x", "type": "a", "payload": {}, "created_at": "2026-10-14T10:00Z"}]},
        {"events": [{"id": str(new_id()), "type": "a", "payload": [], "created_at": "x"}]},
        {},
    ],
)
def test_bad_envelope(kassa, body):
    _, client = kassa
    assert client.post(PUSH, body, format="json").status_code == 400


def test_too_many_events(kassa, cashier):
    _, client = kassa
    body = {"events": [shift_opened(cashier) for _ in range(101)]}
    assert client.post(PUSH, body, format="json").status_code == 400
    assert not SyncEvent.objects.exists()


def test_requires_device_token(owner):
    assert APIClient().post(PUSH, {"events": []}, format="json").status_code == 401
    jwt = str(RefreshToken.for_user(owner).access_token)
    client = APIClient(HTTP_AUTHORIZATION=f"Bearer {jwt}")
    assert client.post(PUSH, {"events": []}, format="json").status_code == 401


def test_blocked_device(kassa, cashier):
    device, client = kassa
    device.is_blocked = True
    device.save()
    response = client.post(PUSH, {"events": [shift_opened(cashier)]}, format="json")
    assert response.status_code == 403
