from rest_framework import serializers
from rest_framework.exceptions import PermissionDenied

from apps.accounts.models import Role
from apps.core.fields import StrictIntegerField
from apps.core.serializers import ClientIdMixin

from .models import Customer, DebtEntry, PaymentMethod
from .services import customer_balance


class CustomerSerializer(ClientIdMixin, serializers.ModelSerializer):
    id = serializers.UUIDField(required=False)
    debt_limit_tiyin = StrictIntegerField(min_value=0, allow_null=True, required=False)
    balance_tiyin = serializers.SerializerMethodField()

    class Meta:
        model = Customer
        fields = [
            "id",
            "full_name",
            "phone",
            "note",
            "debt_limit_tiyin",
            "balance_tiyin",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["created_at", "updated_at"]

    def get_balance_tiyin(self, customer) -> int:
        balance = getattr(customer, "balance_tiyin", None)
        return balance if balance is not None else customer_balance(customer)

    def validate_debt_limit_tiyin(self, value):
        # Limitni faqat ega va menejer o'rnatadi (kassir — mijozni tez yaratadi, xolos).
        current = self.instance.debt_limit_tiyin if self.instance is not None else None
        if value != current and self.context["request"].user.role == Role.CASHIER:
            raise PermissionDenied("Only owner or manager can set the debt limit.")
        return value


class DebtEntrySerializer(serializers.ModelSerializer):
    class Meta:
        model = DebtEntry
        fields = [
            "id",
            "customer",
            "amount_tiyin",
            "type",
            "method",
            "sale_id",
            "note",
            "created_by",
            "at",
        ]


class _EntryInputSerializer(serializers.Serializer):
    id = serializers.UUIDField(required=False)

    def validate_id(self, value):
        if DebtEntry.objects.filter(pk=value).exists():
            raise serializers.ValidationError("Object with this id already exists.", code="unique")
        return value


class PaymentSerializer(_EntryInputSerializer):
    amount_tiyin = StrictIntegerField(min_value=1)
    method = serializers.ChoiceField(choices=PaymentMethod.choices)
    note = serializers.CharField(required=False, allow_blank=True, default="")


class AdjustmentSerializer(_EntryInputSerializer):
    amount_tiyin = StrictIntegerField()
    note = serializers.CharField()

    def validate_amount_tiyin(self, value):
        if value == 0:
            raise serializers.ValidationError("Amount must not be zero.")
        return value


class DebtEntryResultSerializer(serializers.Serializer):
    entry = DebtEntrySerializer()
    balance_tiyin = serializers.IntegerField()
