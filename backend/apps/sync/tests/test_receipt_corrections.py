"""Kirimni tahrirlash va bekor qilish (T-102, stock-receipt.md "Tuzatish").

Asosiy talab: tahrirdan keyin qoldiq ikki marta oshmaydi, har harakat bir marta."""

import pytest
from django.db.models import Sum

from apps.catalog.models import Product
from apps.core.ids import new_id
from apps.inventory.models import ProductStock, StockMovement, StockReceipt
from apps.inventory.services import current_stock

from .helpers import PULL, event, push, statuses, tick

pytestmark = pytest.mark.django_db


def posted(manager, product, qty, cost=300_000, receipt_id=None, **extra):
    return event(
        "receipt.posted",
        {
            "id": str(receipt_id or new_id()),
            "items": [{"product": str(product.id), "qty_milli": qty, "cost_price_tiyin": cost}],
            "by": str(manager.id),
            "at": tick(),
            **extra,
        },
    )


def corrected(manager, original_id, items, *, version_id=None, reversal_id=None, by=None):
    return event(
        "receipt.corrected",
        {
            "id": str(version_id or new_id()),
            "corrects": str(original_id),
            "reversal_id": str(reversal_id or new_id()),
            "supplier": None,
            "note": "",
            "items": [
                {"product": str(p.id), "qty_milli": qty, "cost_price_tiyin": cost}
                for p, qty, cost in items
            ],
            "by": str((by or manager).id),
            "at": tick(),
        },
    )


def reversed_(manager, original_id, reversal_id=None):
    return event(
        "receipt.reversed",
        {
            "id": str(reversal_id or new_id()),
            "reverses": str(original_id),
            "note": "",
            "by": str(manager.id),
            "at": tick(),
        },
    )


def ledger(product) -> int:
    return StockMovement.objects.filter(product=product).aggregate(s=Sum("qty_milli"))["s"] or 0


def assert_cache_matches_ledger(product, store):
    cached = ProductStock.objects.get(product=product, store=store).qty_milli
    assert cached == ledger(product) == current_stock(product, store)


def test_edit_10_to_7_changes_stock_by_minus_3_exactly_once(kassa, manager, product, tenant):
    _, client = kassa
    store = tenant.stores.get()
    original_id = new_id()
    assert statuses(push(client, posted(manager, product, 10_000, receipt_id=original_id))) == [
        "applied"
    ]
    assert current_stock(product, store) == 10_000

    version_id, reversal_id = new_id(), new_id()
    fix = corrected(
        manager,
        original_id,
        [(product, 7_000, 300_000)],
        version_id=version_id,
        reversal_id=reversal_id,
    )
    assert statuses(push(client, fix)) == ["applied"]
    assert current_stock(product, store) == 7_000
    assert_cache_matches_ledger(product, store)

    original = StockReceipt.objects.get(pk=original_id)
    version = StockReceipt.objects.get(pk=version_id)
    reversal = StockReceipt.objects.get(pk=reversal_id)
    # Asl hujjat o'zgarmagan; teskari yozuv va yangi versiya bog'langan.
    assert original.items.get().qty_milli == 10_000
    assert reversal.reverses_id == original.pk
    assert reversal.items.get().qty_milli == -10_000
    assert version.corrects_id == original.pk
    assert version.status == "posted"
    assert not version.conflict

    # Qayta yuborish — dublikat; boshqa hodisa id bilan qayta — o'zgarishsiz.
    assert statuses(push(client, fix)) == ["duplicate"]
    replay = dict(fix, id=str(new_id()))
    assert statuses(push(client, replay)) == ["applied"]
    assert current_stock(product, store) == 7_000
    assert StockReceipt.objects.filter(corrects__isnull=False).count() == 1


def test_sales_in_between_are_kept(kassa, manager, cashier, product, tenant):
    from .helpers import sale_completed, shift_opened

    _, client = kassa
    store = tenant.stores.get()
    original_id = new_id()
    shift_id = new_id()
    push(
        client,
        posted(manager, product, 10_000, receipt_id=original_id),
        shift_opened(cashier, shift_id),
        sale_completed(shift_id, cashier, product, qty=4_000),
    )
    assert current_stock(product, store) == 6_000
    push(client, corrected(manager, original_id, [(product, 7_000, 300_000)]))
    # 7 keldi, 4 sotildi.
    assert current_stock(product, store) == 3_000
    # 2 ga tushirilsa — manfiy qoldiq (bloklanmaydi, ogohlantiriladi).
    head = StockReceipt.objects.get(corrects_id=original_id)
    push(client, corrected(manager, head.pk, [(product, 2_000, 300_000)]))
    assert current_stock(product, store) == -2_000
    assert_cache_matches_ledger(product, store)


def test_correction_waits_for_its_original(kassa, manager, product, tenant):
    _, client = kassa
    original_id = new_id()
    original = posted(manager, product, 10_000, receipt_id=original_id)
    fix = corrected(manager, original_id, [(product, 7_000, 300_000)])
    # Asl kirim hodisasi hali yetib kelmagan.
    result = push(client, fix)[0]
    assert (result["status"], result["error"]["code"]) == ("pending", "missing_dependency")
    assert statuses(push(client, original)) == ["applied"]
    assert current_stock(product, tenant.stores.get()) == 7_000


def test_two_devices_edit_the_same_receipt_last_wins(kassa, make_device, manager, product, tenant):
    _, client = kassa
    _, other_client = make_device(tenant, number=2)
    store = tenant.stores.get()
    original_id = new_id()
    push(client, posted(manager, product, 10_000, receipt_id=original_id))

    push(client, corrected(manager, original_id, [(product, 7_000, 300_000)]))
    second_id = new_id()
    second = corrected(manager, original_id, [(product, 12_000, 300_000)], version_id=second_id)
    assert statuses(push(other_client, second)) == ["applied"]
    # Oxirgi kelgan versiya amalda, ziddiyat belgilandi; qoldiq faqat shu versiya.
    assert current_stock(product, store) == 12_000
    assert StockReceipt.objects.get(pk=second_id).conflict
    assert_cache_matches_ledger(product, store)


def test_cancel_once_and_cancel_after_correction(kassa, manager, product, tenant):
    _, client = kassa
    store = tenant.stores.get()
    first_id, second_id = new_id(), new_id()
    push(client, posted(manager, product, 10_000, receipt_id=first_id))
    push(client, posted(manager, product, 5_000, receipt_id=second_id))
    assert current_stock(product, store) == 15_000

    cancel = reversed_(manager, first_id)
    assert statuses(push(client, cancel)) == ["applied"]
    assert current_stock(product, store) == 5_000
    # Ikkinchi marta (boshqa kassa) — hech narsa.
    assert statuses(push(client, reversed_(manager, first_id))) == ["applied"]
    assert current_stock(product, store) == 5_000

    # Tuzatilgan kirimni bekor qilish — joriy versiya bekor qilinadi.
    push(client, corrected(manager, second_id, [(product, 8_000, 300_000)]))
    assert current_stock(product, store) == 8_000
    assert statuses(push(client, reversed_(manager, second_id))) == ["applied"]
    assert current_stock(product, store) == 0
    assert_cache_matches_ledger(product, store)

    # Bekor qilinganni tuzatish (boshqa kassa oflayn tuzatgan) — yangi versiya, ziddiyat.
    version_id = new_id()
    push(
        client,
        corrected(manager, first_id, [(product, 3_000, 300_000)], version_id=version_id),
    )
    assert current_stock(product, store) == 3_000
    assert StockReceipt.objects.get(pk=version_id).conflict


def test_old_receipt_correction_does_not_overwrite_newer_cost(kassa, manager, product, tenant):
    _, client = kassa
    old_id = new_id()
    push(client, posted(manager, product, 10_000, cost=300_000, receipt_id=old_id))
    push(client, posted(manager, product, 10_000, cost=350_000))
    # Eski kirimdagi tannarx xatosi tuzatildi, lekin undan keyin yangi kirim bor.
    push(client, corrected(manager, old_id, [(product, 10_000, 310_000)]))
    product.refresh_from_db()
    assert product.cost_price_tiyin == 350_000

    # Oxirgi kirimni tuzatish — tannarx yangilanadi.
    latest = Product.objects.get(pk=product.pk)
    last_receipt = (
        StockReceipt.objects.filter(
            items__product=latest, reverses__isnull=True, corrects__isnull=True
        )
        .order_by("-posted_at")
        .first()
    )
    push(client, corrected(manager, last_receipt.pk, [(product, 10_000, 360_000)]))
    product.refresh_from_db()
    assert product.cost_price_tiyin == 360_000


def test_cashier_cannot_edit_or_cancel(kassa, manager, cashier, product):
    _, client = kassa
    original_id = new_id()
    push(client, posted(manager, product, 10_000, receipt_id=original_id))
    fix = corrected(manager, original_id, [(product, 7_000, 1)], by=cashier)
    result = push(client, fix)[0]
    assert (result["status"], result["error"]["code"]) == ("rejected", "permission_denied")
    cancel = reversed_(manager, original_id)
    cancel["payload"]["by"] = str(cashier.id)
    assert statuses(push(client, cancel)) == ["rejected"]


def test_other_tenant_receipt_cannot_be_touched(
    make_device, other_tenant, make_user, kassa, manager, product
):
    _, client = kassa
    original_id = new_id()
    push(client, posted(manager, product, 10_000, receipt_id=original_id))
    _, stranger_client = make_device(other_tenant)
    stranger = make_user(other_tenant, role="owner")
    fix = corrected(stranger, original_id, [(product, 1_000, 1)])
    result = push(stranger_client, fix)[0]
    assert result["status"] == "rejected"
    cancel = reversed_(stranger, original_id)
    assert statuses(push(stranger_client, cancel)) == ["rejected"]
    assert not StockReceipt.objects.filter(reverses_id=original_id).exists()


def test_reversal_document_cannot_be_corrected(kassa, manager, product):
    _, client = kassa
    original_id, reversal_id = new_id(), new_id()
    push(client, posted(manager, product, 10_000, receipt_id=original_id))
    push(client, reversed_(manager, original_id, reversal_id=reversal_id))
    result = push(client, corrected(manager, reversal_id, [(product, 1_000, 1)]))[0]
    assert (result["status"], result["error"]["code"]) == ("rejected", "cannot_correct_reversal")


def test_pull_advertises_receipt_corrections(kassa):
    _, client = kassa
    body = client.get(PULL, {"cursor": "0"}).json()
    assert "receipt_corrections" in body["features"]
