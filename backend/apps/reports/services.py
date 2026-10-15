"""Do'kon egasi hisobotlari (reports-api.md). Formulalar kassa hisobotlari bilan bir xil."""

from dataclasses import dataclass
from datetime import date, datetime, time, timedelta
from decimal import Decimal
from zoneinfo import ZoneInfo

from django.db.models import Count, DecimalField, F, Func, Sum, Value
from django.db.models.functions import Cast, Coalesce, ExtractHour, TruncDate

from apps.catalog.models import Product
from apps.core.money import line_total, mul_div_half_up
from apps.customers.models import Customer, DebtEntry
from apps.inventory.models import ProductStock
from apps.sales.models import Refund, RefundItem, Sale, SaleItem, SalePayment

MAX_DAYS = 366
NUMERIC = DecimalField(max_digits=30, decimal_places=0)
ZERO = Value(0)


class RoundHalfUp(Func):
    """PostgreSQL `ROUND(numeric)`: yarim noldan uzoqqa — musbatda `money.py` bilan bir xil."""

    function = "ROUND"
    output_field = NUMERIC


def cogs(cost_field: str, qty_field: str):
    """Qator tannarxi = `line_total(cost, qty)` (SQL'da)."""
    product = Cast(F(cost_field), NUMERIC) * F(qty_field)
    return RoundHalfUp(product / Value(Decimal(1000)))


def _int(value) -> int:
    return int(value or 0)


@dataclass(frozen=True)
class Period:
    date_from: date
    date_to: date
    tz: ZoneInfo

    @classmethod
    def for_tenant(cls, tenant, date_from: date | None, date_to: date | None) -> "Period":
        tz = ZoneInfo(tenant.timezone)
        today = datetime.now(tz).date()
        date_from = date_from or date_to or today
        date_to = date_to or date_from
        if date_from > date_to:
            raise ValueError("date_from must not be after date_to")
        if (date_to - date_from).days + 1 > MAX_DAYS:
            raise ValueError(f"period must not exceed {MAX_DAYS} days")
        return cls(date_from, date_to, tz)

    @property
    def start(self) -> datetime:
        return datetime.combine(self.date_from, time.min, self.tz)

    @property
    def end(self) -> datetime:
        """Oxirgi kundan keyingi yarim tun (kirmaydi)."""
        return datetime.combine(self.date_to + timedelta(days=1), time.min, self.tz)

    @property
    def days(self) -> list[date]:
        return [
            self.date_from + timedelta(days=i)
            for i in range((self.date_to - self.date_from).days + 1)
        ]

    def previous(self) -> "Period":
        length = timedelta(days=len(self.days))
        return Period(self.date_from - length, self.date_to - length, self.tz)

    def as_dict(self) -> dict:
        return {"date_from": self.date_from, "date_to": self.date_to}


def _sales(tenant_id, period: Period):
    return Sale.objects.filter(
        tenant_id=tenant_id, sold_at__gte=period.start, sold_at__lt=period.end
    )


def _refunds(tenant_id, period: Period):
    return Refund.objects.filter(tenant_id=tenant_id, at__gte=period.start, at__lt=period.end)


def _totals(tenant_id, period: Period) -> dict:
    sales = _sales(tenant_id, period)
    refunds = _refunds(tenant_id, period)
    sale_agg = sales.aggregate(total=Coalesce(Sum("total_tiyin"), ZERO), count=Count("id"))
    refunds_total = _int(refunds.aggregate(s=Sum("total_tiyin"))["s"])
    sold_cost = _int(
        SaleItem.objects.filter(sale__in=sales).aggregate(s=Sum(cogs("cost_tiyin", "qty_milli")))[
            "s"
        ]
    )
    returned_cost = _int(
        RefundItem.objects.filter(refund__in=refunds).aggregate(
            s=Sum(cogs("sale_item__cost_tiyin", "qty_milli"))
        )["s"]
    )
    revenue = sale_agg["total"] - refunds_total
    return {
        "sales_total_tiyin": sale_agg["total"],
        "refunds_total_tiyin": refunds_total,
        "sales_count": sale_agg["count"],
        "revenue_tiyin": revenue,
        # Q-004: chek chegirmasi va qaytarishlar bilan.
        "profit_tiyin": revenue - sold_cost + returned_cost,
    }


def _change_bp(current: int, previous: int) -> int | None:
    return None if previous == 0 else mul_div_half_up(current - previous, 10_000, previous)


def summary(tenant, period: Period) -> dict:
    current = _totals(tenant.pk, period)
    previous = _totals(tenant.pk, period.previous())
    payments = SalePayment.objects.filter(sale__in=_sales(tenant.pk, period))
    refunds = _refunds(tenant.pk, period)
    count = current["sales_count"]
    return {
        "period": period.as_dict(),
        **current,
        "average_check_tiyin": mul_div_half_up(current["sales_total_tiyin"], 1, count)
        if count
        else 0,
        "payments_tiyin": {
            m: _int(payments.filter(method=m).aggregate(s=Sum("amount_tiyin"))["s"])
            for m in ("cash", "card", "debt")
        },
        "refunds_tiyin": {
            m: _int(refunds.filter(method=m).aggregate(s=Sum("total_tiyin"))["s"])
            for m in ("cash", "debt")
        },
        "previous": {
            "revenue_tiyin": previous["revenue_tiyin"],
            "profit_tiyin": previous["profit_tiyin"],
            "sales_count": previous["sales_count"],
        },
        "revenue_change_bp": _change_bp(current["revenue_tiyin"], previous["revenue_tiyin"]),
        "profit_change_bp": _change_bp(current["profit_tiyin"], previous["profit_tiyin"]),
    }


def _grouped(queryset, key, **aggregates) -> dict:
    return {
        row.pop("k"): row for row in queryset.annotate(k=key).values("k").annotate(**aggregates)
    }


def by_day(tenant, period: Period) -> list[dict]:
    tz = period.tz
    sales = _sales(tenant.pk, period)
    refunds = _refunds(tenant.pk, period)
    sold = _grouped(
        sales, TruncDate("sold_at", tzinfo=tz), total=Sum("total_tiyin"), count=Count("id")
    )
    returned = _grouped(refunds, TruncDate("at", tzinfo=tz), total=Sum("total_tiyin"))
    sold_cost = _grouped(
        SaleItem.objects.filter(sale__in=sales),
        TruncDate("sale__sold_at", tzinfo=tz),
        cost=Sum(cogs("cost_tiyin", "qty_milli")),
    )
    returned_cost = _grouped(
        RefundItem.objects.filter(refund__in=refunds),
        TruncDate("refund__at", tzinfo=tz),
        cost=Sum(cogs("sale_item__cost_tiyin", "qty_milli")),
    )
    rows = []
    for day in period.days:
        revenue = _int(sold.get(day, {}).get("total")) - _int(returned.get(day, {}).get("total"))
        cost = _int(sold_cost.get(day, {}).get("cost")) - _int(
            returned_cost.get(day, {}).get("cost")
        )
        rows.append(
            {
                "date": day,
                "revenue_tiyin": revenue,
                "sales_count": _int(sold.get(day, {}).get("count")),
                "profit_tiyin": revenue - cost,
            }
        )
    return rows


def by_hour(tenant, period: Period) -> list[dict]:
    tz = period.tz
    sold = _grouped(
        _sales(tenant.pk, period),
        ExtractHour("sold_at", tzinfo=tz),
        total=Sum("total_tiyin"),
        count=Count("id"),
    )
    returned = _grouped(
        _refunds(tenant.pk, period), ExtractHour("at", tzinfo=tz), total=Sum("total_tiyin")
    )
    return [
        {
            "hour": hour,
            "revenue_tiyin": _int(sold.get(hour, {}).get("total"))
            - _int(returned.get(hour, {}).get("total")),
            "sales_count": _int(sold.get(hour, {}).get("count")),
        }
        for hour in range(24)
    ]


TOP_ORDERS = {"revenue": "revenue_tiyin", "qty": "qty_milli", "profit": "profit_tiyin"}


def top_products(tenant, period: Period, *, order="revenue", direction="desc", limit=20):
    sold = (
        SaleItem.objects.filter(sale__in=_sales(tenant.pk, period))
        .values("product")
        .annotate(
            qty=Sum("qty_milli"),
            total=Sum("total_tiyin"),
            cost=Sum(cogs("cost_tiyin", "qty_milli")),
        )
    )
    returned = {
        row["sale_item__product"]: row
        for row in RefundItem.objects.filter(refund__in=_refunds(tenant.pk, period))
        .values("sale_item__product")
        .annotate(
            qty=Sum("qty_milli"),
            total=Sum("total_tiyin"),
            cost=Sum(cogs("sale_item__cost_tiyin", "qty_milli")),
        )
    }
    names = dict(
        Product.objects.filter(pk__in=[row["product"] for row in sold]).values_list("pk", "name")
    )
    rows = []
    for row in sold:
        back = returned.get(row["product"], {})
        revenue = _int(row["total"]) - _int(back.get("total"))
        rows.append(
            {
                "product": row["product"],
                "name": names.get(row["product"], ""),
                "qty_milli": _int(row["qty"]) - _int(back.get("qty")),
                "revenue_tiyin": revenue,
                "profit_tiyin": revenue - (_int(row["cost"]) - _int(back.get("cost"))),
            }
        )
    key = TOP_ORDERS[order]
    rows.sort(key=lambda r: (r[key], r["name"]), reverse=direction == "desc")
    return rows[:limit]


def cashiers(tenant, period: Period) -> list[dict]:
    sold = {
        row["cashier"]: row
        for row in _sales(tenant.pk, period)
        .values("cashier", "cashier__full_name")
        .annotate(count=Count("id"), total=Sum("total_tiyin"))
    }
    returned = {
        row["cashier"]: row
        for row in _refunds(tenant.pk, period)
        .values("cashier", "cashier__full_name")
        .annotate(count=Count("id"), total=Sum("total_tiyin"))
    }
    rows = []
    for cashier_id in sold.keys() | returned.keys():
        s, r = sold.get(cashier_id, {}), returned.get(cashier_id, {})
        rows.append(
            {
                "cashier": cashier_id,
                "full_name": s.get("cashier__full_name") or r.get("cashier__full_name") or "",
                "sales_count": _int(s.get("count")),
                "sales_total_tiyin": _int(s.get("total")),
                "refunds_count": _int(r.get("count")),
                "refunds_total_tiyin": _int(r.get("total")),
            }
        )
    rows.sort(key=lambda r: (-r["sales_total_tiyin"], r["full_name"]))
    return rows


def debts(tenant, *, limit=20) -> dict:
    per_customer = (
        DebtEntry.objects.filter(tenant_id=tenant.pk, customer__deleted_at__isnull=True)
        .values("customer")
        .annotate(balance=Sum("amount_tiyin"))
    )
    rows = list(per_customer.filter(balance__gt=0).order_by("-balance", "customer"))
    # Avans (do'kon mijozga qarzdor, T-103) — qarzdorlar ro'yxatiga aralashtirilmaydi.
    credits = [row["balance"] for row in per_customer.filter(balance__lt=0)]
    customers = Customer.objects.in_bulk([row["customer"] for row in rows[:limit]])
    return {
        "total_debt_tiyin": sum(row["balance"] for row in rows),
        "debtors_count": len(rows),
        "total_credit_tiyin": -sum(credits),
        "creditors_count": len(credits),
        "top": [
            {
                "customer": row["customer"],
                "full_name": customers[row["customer"]].full_name,
                "phone": customers[row["customer"]].phone,
                "balance_tiyin": row["balance"],
            }
            for row in rows[:limit]
        ],
    }


def stock(tenant) -> dict:
    stocks = ProductStock.objects.filter(tenant_id=tenant.pk).select_related("product")
    value = sum(
        line_total(s.product.cost_price_tiyin, s.qty_milli) for s in stocks if s.qty_milli > 0
    )
    products = Product.objects.filter(
        tenant_id=tenant.pk, deleted_at__isnull=True, is_active=True
    ).annotate(qty=Coalesce(Sum("stock__qty_milli"), ZERO))

    def row(product):
        return {
            "product": product.pk,
            "name": product.name,
            "qty_milli": product.qty,
            "min_stock_milli": product.min_stock_milli,
        }

    low = products.filter(min_stock_milli__gt=0, qty__lt=F("min_stock_milli")).order_by("name")
    negative = products.filter(qty__lt=0).order_by("qty", "name")
    return {
        "stock_value_tiyin": value,
        "low": [row(p) for p in low],
        "negative": [row(p) for p in negative],
    }
