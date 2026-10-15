"""Hisobot raqamlari qo'lda hisoblangan qiymatlar bilan solishtiriladi (ma'lumot — conftest.py).

Davr D = 2026-10-10:
- savdolar: 1 900 000 + 1 800 000 = 3 700 000 (2 chek); qaytarish 380 000 → tushum 3 320 000;
- tannarx: non 2 × 300 000 + sut 900 000 + guruch 1,5 × 1 000 333 = 1 500 499,5 → 1 500 500
  ⇒ 3 000 500; qaytarilgan non tannarxi 300 000;
- foyda = 3 320 000 − 3 000 500 + 300 000 = 619 500; o'rtacha chek = 3 700 000 / 2 = 1 850 000.
Oldingi kun D−1: 400 000 tushum, foyda 100 000, 1 chek.
"""

from datetime import UTC, datetime

import pytest

from apps.core.money import line_total
from apps.customers.models import Customer
from apps.customers.services import record_opening_balance

pytestmark = pytest.mark.django_db

BASE = "/api/v1/reports/"
DAY = {"date_from": "2026-10-10", "date_to": "2026-10-10"}


def world_day_noon():
    return datetime(2026, 10, 10, 7, tzinfo=UTC)  # 12:00 Toshkent


def _get(client, path, **params):
    response = client.get(f"{BASE}{path}/", params)
    assert response.status_code == 200, response.json()
    return response.json()


def test_weighted_cost_rounding_matches_money_py():
    assert line_total(1_000_333, 1_500) == 1_500_500


def test_summary(client_as, manager, world):
    data = _get(client_as(manager), "summary", **DAY)
    assert data["period"] == DAY
    assert data["sales_total_tiyin"] == 3_700_000
    assert data["refunds_total_tiyin"] == 380_000
    assert data["revenue_tiyin"] == 3_320_000
    assert data["sales_count"] == 2
    assert data["average_check_tiyin"] == 1_850_000
    assert data["profit_tiyin"] == 619_500
    assert data["payments_tiyin"] == {"cash": 1_900_000, "card": 800_000, "debt": 1_000_000}
    assert data["refunds_tiyin"] == {"cash": 380_000, "debt": 0}
    assert data["previous"] == {"revenue_tiyin": 400_000, "profit_tiyin": 100_000, "sales_count": 1}
    # (3 320 000 − 400 000) / 400 000 = +730%; (619 500 − 100 000) / 100 000 = +519,5%
    assert data["revenue_change_bp"] == 73_000
    assert data["profit_change_bp"] == 51_950


def test_summary_empty_day(client_as, manager, world):
    data = _get(client_as(manager), "summary", date_from="2026-10-01")
    assert data["period"] == {"date_from": "2026-10-01", "date_to": "2026-10-01"}
    assert (data["sales_count"], data["average_check_tiyin"], data["revenue_tiyin"]) == (0, 0, 0)
    assert data["revenue_change_bp"] is None


def test_by_day(client_as, manager, world):
    rows = _get(client_as(manager), "by-day", date_from="2026-10-08", date_to="2026-10-11")
    assert rows == [
        {"date": "2026-10-08", "revenue_tiyin": 0, "sales_count": 0, "profit_tiyin": 0},
        {"date": "2026-10-09", "revenue_tiyin": 400_000, "sales_count": 1, "profit_tiyin": 100_000},
        {
            "date": "2026-10-10",
            "revenue_tiyin": 3_320_000,
            "sales_count": 2,
            "profit_tiyin": 619_500,
        },
        # D+1 00:10 mahalliy vaqt (UTC'da hali D) — o'z kunida.
        {"date": "2026-10-11", "revenue_tiyin": 400_000, "sales_count": 1, "profit_tiyin": 100_000},
    ]


def test_by_hour(client_as, manager, world):
    rows = _get(client_as(manager), "by-hour", **DAY)
    assert len(rows) == 24
    busy = {r["hour"]: (r["revenue_tiyin"], r["sales_count"]) for r in rows if r["revenue_tiyin"]}
    assert busy == {9: (1_900_000, 1), 18: (1_800_000, 1), 20: (-380_000, 0)}


def test_top_products(client_as, manager, world):
    client = client_as(manager)
    rows = _get(client, "top-products", **DAY)
    assert [(r["name"], r["qty_milli"], r["revenue_tiyin"], r["profit_tiyin"]) for r in rows] == [
        ("Guruch", 1_500, 1_800_000, 299_500),
        ("Sut", 1_000, 1_200_000, 300_000),
        # 2 sotildi, 1 qaytdi; qator summasi (chek chegirmasigacha).
        ("Non", 1_000, 400_000, 100_000),
    ]
    by_profit = _get(client, "top-products", order="profit", **DAY)
    assert [r["name"] for r in by_profit] == ["Sut", "Guruch", "Non"]
    least = _get(client, "top-products", order="revenue", direction="asc", limit=1, **DAY)
    assert [r["name"] for r in least] == ["Non"]


def test_cashiers(client_as, manager, world):
    rows = _get(client_as(manager), "cashiers", **DAY)
    assert [
        (r["full_name"], r["sales_count"], r["sales_total_tiyin"], r["refunds_count"],
         r["refunds_total_tiyin"])
        for r in rows
    ] == [("Aziza", 1, 1_900_000, 1, 380_000), ("Bobur", 1, 1_800_000, 0, 0)]  # fmt: skip


def test_debts(client_as, manager, world):
    data = _get(client_as(manager), "debts")
    assert data["total_debt_tiyin"] == 1_030_000
    assert data["debtors_count"] == 2
    assert [(r["full_name"], r["balance_tiyin"]) for r in data["top"]] == [
        ("Anvar aka", 1_000_000),
        ("Dilnoza", 30_000),
    ]
    assert data["top"][0]["phone"] == "+998901112233"
    assert len(_get(client_as(manager), "debts", limit=1)["top"]) == 1


def test_stock(client_as, manager, world):
    data = _get(client_as(manager), "stock")
    # Non: 10 000 − 2 000 − 1 000 − 1 000 + 1 000 = 7 000 → 7 × 300 000. Manfiylar kirmaydi.
    assert data["stock_value_tiyin"] == 2_100_000
    assert [(r["name"], r["qty_milli"]) for r in data["low"]] == [("Non", 7_000), ("Tuz", 0)]
    assert [(r["name"], r["qty_milli"]) for r in data["negative"]] == [
        ("Guruch", -1_500),
        ("Sut", -1_000),
    ]


@pytest.mark.parametrize(
    "params",
    [
        {"date_from": "2026-10-11", "date_to": "2026-10-10"},
        {"date_from": "2025-01-01", "date_to": "2026-10-10"},
        {"date_from": "10.10.2026"},
    ],
)
def test_bad_period(client_as, manager, params):
    assert client_as(manager).get(f"{BASE}summary/", params).status_code == 400


def test_bad_top_query(client_as, manager):
    client = client_as(manager)
    assert client.get(f"{BASE}top-products/", {"order": "name"}).status_code == 400
    assert client.get(f"{BASE}top-products/", {"limit": 0}).status_code == 400


@pytest.mark.parametrize(
    "path", ["summary", "by-day", "by-hour", "top-products", "cashiers", "debts", "stock"]
)
def test_permissions(client_as, owner, cashier, api_client, path):
    assert client_as(owner).get(f"{BASE}{path}/").status_code == 200
    assert client_as(cashier).get(f"{BASE}{path}/").status_code == 403
    assert api_client.get(f"{BASE}{path}/").status_code == 401


def test_other_tenant_sees_nothing(client_as, make_user, other_tenant, world):
    stranger = client_as(make_user(other_tenant, role="owner"))
    assert _get(stranger, "summary", **DAY)["sales_count"] == 0
    assert _get(stranger, "top-products", **DAY) == []
    assert _get(stranger, "cashiers", **DAY) == []
    assert _get(stranger, "debts")["debtors_count"] == 0
    stock = _get(stranger, "stock")
    assert (stock["stock_value_tiyin"], stock["low"], stock["negative"]) == (0, [], [])


def test_opening_balance_is_not_revenue_but_counts_in_debts(client_as, manager, world, tenant):
    """T-103: boshlang'ich qarz — real debitorlik (qarzlarda), lekin tushum ham, naqd ham emas;
    avans qarzdorlarga aralashmaydi, alohida ko'rsatiladi."""
    before = _get(client_as(manager), "summary", **DAY)
    debts_before = _get(client_as(manager), "debts")
    debtor = Customer.objects.create(tenant=tenant, full_name="Eski qarzdor")
    creditor = Customer.objects.create(tenant=tenant, full_name="Avansli")
    record_opening_balance(debtor, direction="debt", amount_tiyin=2_000_000, at=world_day_noon())
    record_opening_balance(creditor, direction="credit", amount_tiyin=700_000, at=world_day_noon())

    assert _get(client_as(manager), "summary", **DAY) == before
    data = _get(client_as(manager), "debts")
    assert data["total_debt_tiyin"] == debts_before["total_debt_tiyin"] + 2_000_000
    assert data["debtors_count"] == debts_before["debtors_count"] + 1
    assert data["total_credit_tiyin"] == debts_before["total_credit_tiyin"] + 700_000
    assert data["creditors_count"] == debts_before["creditors_count"] + 1
    assert "Avansli" not in [r["full_name"] for r in data["top"]]
