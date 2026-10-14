"""Sinxron testlari uchun hodisa yasovchilar."""

import itertools
from datetime import timedelta

from django.utils import timezone

from apps.core.ids import new_id
from apps.core.money import line_total

_clock = itertools.count()
_numbers = itertools.count(1)


def tick() -> str:
    """Har chaqiruvda keyingi soniya — hodisalar tartibi aniq bo'lsin."""
    return (timezone.now() + timedelta(seconds=next(_clock))).isoformat()


def event(type_, payload, *, created_at=None):
    return {
        "id": str(new_id()),
        "type": type_,
        "payload": payload,
        "created_at": created_at or tick(),
    }


def shift_opened(cashier, shift_id=None, **extra):
    return event(
        "shift.opened",
        {
            "id": str(shift_id or new_id()),
            "cashier": str(cashier.id),
            "opening_cash_tiyin": 0,
            "opened_at": tick(),
        },
        **extra,
    )


def sale_completed(shift_id, cashier, product, qty=1_000, price=400_000, **extra):
    total = line_total(price, qty)
    return event(
        "sale.completed",
        {
            "id": str(new_id()),
            "shift": str(shift_id),
            "number": f"D1-{next(_numbers):06d}",
            "cashier": str(cashier.id),
            "sold_at": tick(),
            "subtotal_tiyin": total,
            "discount_tiyin": 0,
            "total_tiyin": total,
            "items": [
                {
                    "id": str(new_id()),
                    "product": str(product.id),
                    "name_snapshot": product.name,
                    "qty_milli": qty,
                    "price_tiyin": price,
                    "cost_tiyin": product.cost_price_tiyin,
                    "discount_tiyin": 0,
                    "total_tiyin": total,
                }
            ],
            "payments": [
                {"id": str(new_id()), "method": "cash", "amount_tiyin": total, "change_tiyin": 0}
            ],
        },
        **extra,
    )


PUSH = "/api/v1/sync/push/"
PULL = "/api/v1/sync/pull/"


def push(client, *events):
    response = client.post(PUSH, {"events": list(events)}, format="json")
    assert response.status_code == 200, response.json()
    return response.json()["results"]


def statuses(results):
    return [r["status"] for r in results]
