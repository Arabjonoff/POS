"""Hisobot testlari uchun ma'lumot: barcha raqamlar `test_reports.py` da qo'lda hisoblangan.

Do'kon vaqt zonasi Asia/Tashkent (+05:00). Hisobot kuni D = 2026-10-10.
"""

from datetime import datetime
from zoneinfo import ZoneInfo

import pytest

from apps.accounts.models import Role
from apps.catalog.models import Product
from apps.core.ids import new_id
from apps.core.money import line_total
from apps.customers.models import Customer
from apps.customers.services import pay_debt, record_sale_debt
from apps.devices.models import Device
from apps.inventory.models import MovementType
from apps.inventory.services import record_movement
from apps.sales.services import open_shift, record_refund, record_sale

TZ = ZoneInfo("Asia/Tashkent")


def local(day, hour, minute=0):
    return datetime(2026, 10, day, hour, minute, tzinfo=TZ)


@pytest.fixture
def manager(make_user, tenant):
    return make_user(tenant, role=Role.MANAGER, full_name="Menejer")


@pytest.fixture
def cashier(make_user, tenant):
    return make_user(tenant, role=Role.CASHIER, full_name="Aziza")


@pytest.fixture
def world(tenant, manager, cashier, make_user):
    """Hisobotlar uchun bitta to'liq kun va uning atrofi."""
    assert tenant.timezone == "Asia/Tashkent"
    store = tenant.stores.get()
    other_cashier = make_user(tenant, role=Role.CASHIER, full_name="Bobur")
    pcs, kg = tenant.units.get(code="pcs"), tenant.units.get(code="kg")
    non = Product.objects.create(
        tenant=tenant,
        name="Non",
        unit=pcs,
        sell_price_tiyin=400_000,
        cost_price_tiyin=300_000,
        min_stock_milli=8_000,
    )
    sut = Product.objects.create(
        tenant=tenant, name="Sut", unit=pcs, sell_price_tiyin=1_200_000, cost_price_tiyin=900_000
    )
    guruch = Product.objects.create(
        tenant=tenant,
        name="Guruch",
        unit=kg,
        is_weighted=True,
        sell_price_tiyin=1_200_000,
        cost_price_tiyin=1_000_333,
    )
    tuz = Product.objects.create(
        tenant=tenant, name="Tuz", unit=pcs, sell_price_tiyin=1, min_stock_milli=1_000
    )
    record_movement(product=non, store=store, qty_milli=10_000, type=MovementType.RECEIPT)

    device = Device.objects.create(
        tenant=tenant, store=store, number=1, name="Kassa", platform="windows", token_hash="x" * 64
    )
    shift = open_shift(
        device,
        {
            "id": str(new_id()),
            "cashier": str(cashier.id),
            "opening_cash_tiyin": 0,
            "opened_at": local(8, 8).isoformat(),
        },
    )
    debtor = Customer.objects.create(tenant=tenant, full_name="Anvar aka", phone="+998901112233")
    numbers = iter(range(1, 100))

    def sell(when, who, lines, payments, *, discount=0, customer=None):
        items = [
            {
                "id": str(new_id()),
                "product": str(product.id),
                "name_snapshot": product.name,
                "qty_milli": qty,
                "price_tiyin": product.sell_price_tiyin,
                "cost_tiyin": product.cost_price_tiyin,
                "discount_tiyin": 0,
                "total_tiyin": line_total(product.sell_price_tiyin, qty),
            }
            for product, qty in lines
        ]
        subtotal = sum(i["total_tiyin"] for i in items)
        return record_sale(
            device,
            {
                "id": str(new_id()),
                "shift": str(shift.id),
                "number": f"D1-{next(numbers):06d}",
                "cashier": str(who.id),
                "customer": str(customer.id) if customer else None,
                "sold_at": when.isoformat(),
                "subtotal_tiyin": subtotal,
                "discount_tiyin": discount,
                "total_tiyin": subtotal - discount,
                "items": items,
                "payments": [
                    {"id": str(new_id()), "method": m, "amount_tiyin": a, "change_tiyin": 0}
                    for m, a in payments
                ],
            },
        )

    # D, 09:30 — Aziza: 2 non + 1 sut = 2 000 000, chek chegirmasi 100 000 → 1 900 000 naqd.
    s1 = sell(local(10, 9, 30), cashier, [(non, 2_000), (sut, 1_000)], [("cash", 1_900_000)],
              discount=100_000)  # fmt: skip
    # D, 18:15 — Bobur: 1,5 kg guruch = 1 800 000; karta 800 000 + nasiya 1 000 000.
    sell(local(10, 18, 15), other_cashier, [(guruch, 1_500)],
         [("card", 800_000), ("debt", 1_000_000)], customer=debtor)  # fmt: skip
    # D−1, 23:30 (UTC'da ham D−1) — oldingi kun.
    sell(local(9, 23, 30), cashier, [(non, 1_000)], [("cash", 400_000)])
    # D+1, 00:10 (UTC'da hali D!) — davrga kirmaydi.
    sell(local(11, 0, 10), cashier, [(non, 1_000)], [("cash", 400_000)])

    # D, 20:00 — S1 dan 1 non qaytarildi: 400 000 − chegirma ulushi 20 000 = 380 000 naqd.
    record_refund(
        device,
        {
            "id": str(new_id()),
            "sale": str(s1.id),
            "shift": str(shift.id),
            "cashier": str(cashier.id),
            "method": "cash",
            "total_tiyin": 380_000,
            "at": local(10, 20).isoformat(),
            "items": [
                {
                    "id": str(new_id()),
                    "sale_item": str(s1.items.get(product=non).id),
                    "qty_milli": 1_000,
                    "total_tiyin": 400_000,
                }
            ],
        },
    )

    # Qarzlar: Anvar 1 000 000 (savdodan); Dilnoza 50 000 − 20 000 = 30 000;
    # Javlon to'liq to'lagan (0); Kamola ortiqcha to'lagan (−5 000) — qarzdor emas.
    dilnoza = Customer.objects.create(tenant=tenant, full_name="Dilnoza")
    record_sale_debt(dilnoza, amount_tiyin=50_000, sale_id=new_id())
    pay_debt(dilnoza, amount_tiyin=20_000, method="cash")
    javlon = Customer.objects.create(tenant=tenant, full_name="Javlon")
    record_sale_debt(javlon, amount_tiyin=10_000, sale_id=new_id())
    pay_debt(javlon, amount_tiyin=10_000, method="card")
    kamola = Customer.objects.create(tenant=tenant, full_name="Kamola")
    pay_debt(kamola, amount_tiyin=5_000, method="cash", enforce_balance=False)

    return {
        "non": non,
        "sut": sut,
        "guruch": guruch,
        "tuz": tuz,
        "cashier": cashier,
        "other_cashier": other_cashier,
        "debtor": debtor,
        "dilnoza": dilnoza,
    }
