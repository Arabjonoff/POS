import itertools

import pytest
from django.utils import timezone

from apps.accounts.models import Role
from apps.catalog.models import Product
from apps.core.ids import new_id
from apps.core.money import line_total
from apps.customers.models import Customer
from apps.devices.models import Device
from apps.sales.services import open_shift

_numbers = itertools.count(1)


@pytest.fixture
def manager(make_user, tenant):
    return make_user(tenant, role=Role.MANAGER)


@pytest.fixture
def cashier(make_user, tenant):
    return make_user(tenant, role=Role.CASHIER)


@pytest.fixture
def make_device():
    def factory(tenant, number=1):
        return Device.objects.create(
            tenant=tenant,
            store=tenant.stores.get(),
            number=number,
            name=f"Kassa {number}",
            platform="windows",
            token_hash=new_id().hex + new_id().hex,
        )

    return factory


@pytest.fixture
def device(make_device, tenant):
    return make_device(tenant)


@pytest.fixture
def make_product():
    def factory(tenant, **kwargs):
        kwargs.setdefault("name", "Non")
        kwargs.setdefault("sell_price_tiyin", 400_000)
        kwargs.setdefault("cost_price_tiyin", 300_000)
        return Product.objects.create(tenant=tenant, unit=tenant.units.get(code="pcs"), **kwargs)

    return factory


@pytest.fixture
def product(make_product, tenant):
    return make_product(tenant)


@pytest.fixture
def customer(tenant):
    return Customer.objects.create(tenant=tenant, full_name="Anvar aka")


@pytest.fixture
def make_shift():
    def factory(device, cashier, opening_cash=100_000_00):
        return open_shift(
            device,
            {
                "id": str(new_id()),
                "cashier": str(cashier.id),
                "opening_cash_tiyin": opening_cash,
                "opened_at": timezone.now().isoformat(),
            },
        )

    return factory


@pytest.fixture
def shift(make_shift, device, cashier):
    return make_shift(device, cashier)


@pytest.fixture
def sale_payload():
    """`sale_payload(shift, cashier, [(product, qty_milli, price, discount)], payments=...)`.

    `payments` berilmasa — butun summa naqd, qaytimsiz.
    """

    def factory(shift, cashier, lines, *, payments=None, discount=0, customer=None, **extra):
        items = []
        for product, qty, price, *rest in lines:
            item_discount = rest[0] if rest else 0
            items.append(
                {
                    "id": str(new_id()),
                    "product": str(product.id),
                    "name_snapshot": product.name,
                    "barcode_snapshot": "",
                    "qty_milli": qty,
                    "price_tiyin": price,
                    "cost_tiyin": product.cost_price_tiyin,
                    "discount_tiyin": item_discount,
                    "total_tiyin": line_total(price, qty) - item_discount,
                }
            )
        subtotal = sum(i["total_tiyin"] for i in items)
        total = subtotal - discount
        if payments is None:
            payments = [("cash", total)] if total else []
        return {
            "id": str(new_id()),
            "shift": str(shift.id),
            "number": f"D1-{next(_numbers):06d}",
            "cashier": str(cashier.id),
            "customer": str(customer.id) if customer else None,
            "sold_at": timezone.now().isoformat(),
            "subtotal_tiyin": subtotal,
            "discount_tiyin": discount,
            "total_tiyin": total,
            "items": items,
            "payments": [
                {"id": str(new_id()), "method": method, "amount_tiyin": amount, "change_tiyin": 0}
                for method, amount in payments
            ],
        } | extra

    return factory
