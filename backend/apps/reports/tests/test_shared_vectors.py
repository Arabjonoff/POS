"""Umumiy vektorlar (`testdata/report_vectors.json`): kassa hisobotlari
(`apps/pos/test/data/local_reports_test.dart`) ham shu raqamlarni beradi."""

import json
from datetime import date
from pathlib import Path

import pytest
from rest_framework.test import APIClient

from apps.accounts.models import Role
from apps.catalog.models import Product
from apps.devices.models import Device
from apps.devices.tokens import hash_token, new_token
from apps.reports import services
from apps.sales.services import open_shift, record_refund, record_sale

pytestmark = pytest.mark.django_db

VECTORS = json.loads(
    (Path(__file__).resolve().parents[4] / "testdata" / "report_vectors.json").read_text("utf-8")
)
URL = "/api/v1/sync/reports/"


@pytest.fixture
def make_device():
    """`(device, client)` — client `Authorization: Device <token>` bilan."""

    def factory(tenant, number=1):
        token = new_token()
        device = Device.objects.create(
            tenant=tenant,
            store=tenant.stores.get(),
            number=number,
            name=f"Kassa {number}",
            platform="windows",
            token_hash=hash_token(token),
        )
        return device, APIClient(HTTP_AUTHORIZATION=f"Device {token}")

    return factory


@pytest.fixture
def vector_world(tenant, make_user, make_device):
    store = tenant.stores.get()
    users = {
        c["id"]: make_user(tenant, role=Role.CASHIER, full_name=c["name"], id=c["id"])
        for c in VECTORS["cashiers"]
    }
    for p in VECTORS["products"]:
        Product.objects.create(
            id=p["id"],
            tenant=tenant,
            name=p["name"],
            unit=tenant.units.get(code=p["unit"]),
            sell_price_tiyin=p["price"],
            cost_price_tiyin=p["cost"],
        )
    device = Device.objects.create(
        tenant=tenant, store=store, number=1, name="Kassa", platform="windows", token_hash="v" * 64
    )
    first = VECTORS["cashiers"][0]["id"]
    shift = open_shift(
        device,
        {
            "id": "01890000-0000-7000-8000-0000000000aa",
            "cashier": first,
            "opening_cash_tiyin": 0,
            "opened_at": "2026-10-14T01:00:00Z",
        },
    )
    for s in VECTORS["sales"]:
        record_sale(
            device,
            {
                "id": s["id"],
                "shift": str(shift.id),
                "number": s["number"],
                "cashier": s["cashier"],
                "sold_at": s["sold_at"],
                "subtotal_tiyin": s["subtotal"],
                "discount_tiyin": s["discount"],
                "total_tiyin": s["total"],
                "items": [
                    {
                        "id": i["id"],
                        "product": i["product"],
                        "name_snapshot": i["name"],
                        "barcode_snapshot": "",
                        "qty_milli": i["qty"],
                        "price_tiyin": i["price"],
                        "cost_tiyin": i["cost"],
                        "discount_tiyin": i["discount"],
                        "total_tiyin": i["total"],
                    }
                    for i in s["items"]
                ],
                "payments": [
                    {
                        "id": p["id"],
                        "method": p["method"],
                        "amount_tiyin": p["amount"],
                        "change_tiyin": 0,
                        **({"received_tiyin": p["amount"]} if p["method"] == "cash" else {}),
                    }
                    for p in s["payments"]
                ],
            },
        )
    for r in VECTORS["refunds"]:
        record_refund(
            device,
            {
                "id": r["id"],
                "sale": r["sale"],
                "shift": str(shift.id),
                "cashier": r["cashier"],
                "reason": "test",
                "method": r["method"],
                "total_tiyin": r["total"],
                "at": r["at"],
                "items": [
                    {
                        "id": i["id"],
                        "sale_item": i["sale_item"],
                        "qty_milli": i["qty"],
                        "total_tiyin": i["total"],
                    }
                    for i in r["items"]
                ],
            },
        )
    return users, make_device(tenant, number=2)


def _period(tenant):
    p = VECTORS["period"]
    return services.Period.for_tenant(
        tenant, date.fromisoformat(p["date_from"]), date.fromisoformat(p["date_to"])
    )


def test_services_match_vectors(tenant, vector_world):
    expected = VECTORS["expected"]
    period = _period(tenant)
    summary = services.summary(tenant, period)
    for key, value in expected["summary"].items():
        assert summary[key] == value, key
    days = services.by_day(tenant, period)
    assert [{**d, "date": d["date"].isoformat()} for d in days] == expected["by_day"]
    hours = [h for h in services.by_hour(tenant, period) if h["revenue_tiyin"] or h["sales_count"]]
    assert hours == expected["by_hour_nonzero"]
    top = [
        {k: row[k] for k in ("name", "qty_milli", "revenue_tiyin", "profit_tiyin")}
        for row in services.top_products(tenant, period)
    ]
    assert top == expected["top_products"]
    cashiers = [
        {k: v for k, v in row.items() if k != "cashier"}
        for row in services.cashiers(tenant, period)
    ]
    assert cashiers == expected["cashiers"]


def test_device_endpoint_returns_all_reports(tenant, vector_world):
    _, (_, client) = vector_world
    p = VECTORS["period"]
    response = client.get(URL, {"date_from": p["date_from"], "date_to": p["date_to"]})
    assert response.status_code == 200, response.json()
    body = response.json()
    assert body["summary"]["revenue_tiyin"] == VECTORS["expected"]["summary"]["revenue_tiyin"]
    assert body["summary"]["profit_tiyin"] == VECTORS["expected"]["summary"]["profit_tiyin"]
    assert [r["name"] for r in body["top_products"]] == ["Olma", "Non", "Sut"]
    assert len(body["by_hour"]) == 24
    assert set(body) == {
        "summary",
        "by_day",
        "by_hour",
        "top_products",
        "cashiers",
        "debts",
        "stock",
    }


def test_device_endpoint_is_tenant_scoped(make_device, other_tenant, tenant, vector_world):
    _, client = make_device(other_tenant)
    p = VECTORS["period"]
    body = client.get(URL, {"date_from": p["date_from"], "date_to": p["date_to"]}).json()
    assert body["summary"]["sales_count"] == 0
    assert body["top_products"] == []


def test_device_endpoint_validates_period(make_device, tenant):
    _, client = make_device(tenant)
    assert client.get(URL, {"date_from": "2026-10-15", "date_to": "2026-10-01"}).status_code == 400


def test_user_jwt_is_not_enough(client_as, make_user, tenant):
    manager = make_user(tenant, role=Role.MANAGER)
    assert client_as(manager).get(URL).status_code in (401, 403)
