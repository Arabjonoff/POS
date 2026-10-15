from rest_framework import serializers

from .services import MAX_DAYS, TOP_ORDERS


class PeriodQuerySerializer(serializers.Serializer):
    date_from = serializers.DateField(required=False, help_text="Do'kon vaqt zonasida")
    date_to = serializers.DateField(
        required=False, help_text=f"Shu kun ham kiradi; ≤ {MAX_DAYS} kun"
    )


class TopProductsQuerySerializer(PeriodQuerySerializer):
    order = serializers.ChoiceField(choices=list(TOP_ORDERS), default="revenue")
    direction = serializers.ChoiceField(choices=["desc", "asc"], default="desc")
    limit = serializers.IntegerField(min_value=1, max_value=100, default=20)


class LimitQuerySerializer(serializers.Serializer):
    limit = serializers.IntegerField(min_value=1, max_value=100, default=20)


class PeriodSerializer(serializers.Serializer):
    date_from = serializers.DateField()
    date_to = serializers.DateField()


class PaymentsSerializer(serializers.Serializer):
    cash = serializers.IntegerField()
    card = serializers.IntegerField()
    debt = serializers.IntegerField()


class RefundsByMethodSerializer(serializers.Serializer):
    cash = serializers.IntegerField()
    debt = serializers.IntegerField()


class PreviousSerializer(serializers.Serializer):
    revenue_tiyin = serializers.IntegerField()
    profit_tiyin = serializers.IntegerField()
    sales_count = serializers.IntegerField()


class SummarySerializer(serializers.Serializer):
    period = PeriodSerializer()
    revenue_tiyin = serializers.IntegerField()
    sales_total_tiyin = serializers.IntegerField()
    refunds_total_tiyin = serializers.IntegerField()
    sales_count = serializers.IntegerField()
    average_check_tiyin = serializers.IntegerField()
    profit_tiyin = serializers.IntegerField()
    payments_tiyin = PaymentsSerializer()
    refunds_tiyin = RefundsByMethodSerializer()
    previous = PreviousSerializer()
    revenue_change_bp = serializers.IntegerField(allow_null=True)
    profit_change_bp = serializers.IntegerField(allow_null=True)


class DayRowSerializer(serializers.Serializer):
    date = serializers.DateField()
    revenue_tiyin = serializers.IntegerField()
    sales_count = serializers.IntegerField()
    profit_tiyin = serializers.IntegerField()


class HourRowSerializer(serializers.Serializer):
    hour = serializers.IntegerField()
    revenue_tiyin = serializers.IntegerField()
    sales_count = serializers.IntegerField()


class ProductRowSerializer(serializers.Serializer):
    product = serializers.UUIDField()
    name = serializers.CharField()
    qty_milli = serializers.IntegerField()
    revenue_tiyin = serializers.IntegerField()
    profit_tiyin = serializers.IntegerField()


class CashierRowSerializer(serializers.Serializer):
    cashier = serializers.UUIDField()
    full_name = serializers.CharField()
    sales_count = serializers.IntegerField()
    sales_total_tiyin = serializers.IntegerField()
    refunds_count = serializers.IntegerField()
    refunds_total_tiyin = serializers.IntegerField()


class DebtorSerializer(serializers.Serializer):
    customer = serializers.UUIDField()
    full_name = serializers.CharField()
    phone = serializers.CharField()
    balance_tiyin = serializers.IntegerField()


class DebtsSerializer(serializers.Serializer):
    total_debt_tiyin = serializers.IntegerField()
    debtors_count = serializers.IntegerField()
    # Mijozlar avansi (musbat son) — do'konning mijozlar oldidagi qarzi.
    total_credit_tiyin = serializers.IntegerField()
    creditors_count = serializers.IntegerField()
    top = DebtorSerializer(many=True)


class StockRowSerializer(serializers.Serializer):
    product = serializers.UUIDField()
    name = serializers.CharField()
    qty_milli = serializers.IntegerField()
    min_stock_milli = serializers.IntegerField()


class StockReportSerializer(serializers.Serializer):
    stock_value_tiyin = serializers.IntegerField()
    low = StockRowSerializer(many=True)
    negative = StockRowSerializer(many=True)


class DeviceReportSerializer(serializers.Serializer):
    """Kassa uchun bitta so'rovda hamma hisobotlar (T-070)."""

    summary = SummarySerializer()
    by_day = DayRowSerializer(many=True)
    by_hour = HourRowSerializer(many=True)
    top_products = ProductRowSerializer(many=True)
    cashiers = CashierRowSerializer(many=True)
    debts = DebtsSerializer()
    stock = StockReportSerializer()
