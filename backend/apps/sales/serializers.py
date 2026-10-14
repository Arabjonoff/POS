from rest_framework import serializers

from .models import CashMovement, Refund, RefundItem, Sale, SaleItem, SalePayment, Shift


class ShiftSerializer(serializers.ModelSerializer):
    is_open = serializers.BooleanField(read_only=True)

    class Meta:
        model = Shift
        fields = [
            "id",
            "store",
            "device",
            "opened_by",
            "opened_at",
            "opening_cash_tiyin",
            "closed_by",
            "closed_at",
            "counted_cash_tiyin",
            "expected_cash_tiyin",
            "is_open",
        ]


class ByCashCardDebtSerializer(serializers.Serializer):
    cash = serializers.IntegerField()
    card = serializers.IntegerField()
    debt = serializers.IntegerField()


class ByCashDebtSerializer(serializers.Serializer):
    cash = serializers.IntegerField()
    debt = serializers.IntegerField()


class ByCashCardSerializer(serializers.Serializer):
    cash = serializers.IntegerField()
    card = serializers.IntegerField()


class ShiftReportSerializer(serializers.Serializer):
    shift = serializers.UUIDField()
    is_open = serializers.BooleanField()
    opening_cash_tiyin = serializers.IntegerField()
    sales_count = serializers.IntegerField()
    sales_total_tiyin = serializers.IntegerField()
    payments_tiyin = ByCashCardDebtSerializer()
    refunds_count = serializers.IntegerField()
    refunds_tiyin = ByCashDebtSerializer()
    cash_in_tiyin = serializers.IntegerField()
    cash_out_tiyin = serializers.IntegerField()
    debt_payments_tiyin = ByCashCardSerializer()
    expected_cash_tiyin = serializers.IntegerField()
    counted_cash_tiyin = serializers.IntegerField(allow_null=True)
    difference_tiyin = serializers.IntegerField(allow_null=True)


class SaleItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = SaleItem
        fields = [
            "id",
            "product",
            "name_snapshot",
            "barcode_snapshot",
            "qty_milli",
            "price_tiyin",
            "cost_tiyin",
            "discount_tiyin",
            "total_tiyin",
        ]


class SalePaymentSerializer(serializers.ModelSerializer):
    class Meta:
        model = SalePayment
        fields = ["id", "method", "amount_tiyin", "received_tiyin", "change_tiyin"]


class SaleSerializer(serializers.ModelSerializer):
    items = SaleItemSerializer(many=True, read_only=True)
    payments = SalePaymentSerializer(many=True, read_only=True)

    class Meta:
        model = Sale
        fields = [
            "id",
            "number",
            "store",
            "shift",
            "device",
            "cashier",
            "approved_by",
            "customer",
            "subtotal_tiyin",
            "discount_tiyin",
            "total_tiyin",
            "status",
            "sold_at",
            "items",
            "payments",
        ]


class RefundItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = RefundItem
        fields = ["id", "sale_item", "qty_milli", "total_tiyin"]


class RefundSerializer(serializers.ModelSerializer):
    items = RefundItemSerializer(many=True, read_only=True)

    class Meta:
        model = Refund
        fields = [
            "id",
            "sale",
            "shift",
            "device",
            "cashier",
            "approved_by",
            "reason",
            "method",
            "total_tiyin",
            "at",
            "items",
        ]


class CashMovementSerializer(serializers.ModelSerializer):
    class Meta:
        model = CashMovement
        fields = ["id", "shift", "type", "amount_tiyin", "reason", "created_by", "at"]
