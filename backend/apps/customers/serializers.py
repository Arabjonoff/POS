from datetime import UTC, datetime, timedelta

from django.db import transaction
from django.utils import timezone
from rest_framework import serializers
from rest_framework.exceptions import PermissionDenied

from apps.accounts.models import Role
from apps.core.fields import StrictIntegerField
from apps.core.phone import normalize_phone
from apps.core.serializers import ClientIdMixin
from apps.core.text import clean_line

from .models import Customer, DebtEntry, PaymentMethod
from .services import OpeningDirection, customer_balance, record_opening_balance

_EARLIEST_OPENING = datetime(2000, 1, 1, tzinfo=UTC)
_CLOCK_SKEW = timedelta(minutes=5)


class OpeningBalanceSerializer(serializers.Serializer):
    """Mijoz yaratishda boshlang'ich balans (T-103): yo'nalish aniq, summa musbat."""

    id = serializers.UUIDField(required=False)
    direction = serializers.ChoiceField(
        choices=[(OpeningDirection.DEBT, "debt"), (OpeningDirection.CREDIT, "credit")]
    )
    amount_tiyin = StrictIntegerField(min_value=1)
    at = serializers.DateTimeField(required=False)
    note = serializers.CharField(required=False, allow_blank=True, max_length=500, default="")

    def validate_id(self, value):
        if DebtEntry.objects.filter(pk=value).exists():
            raise serializers.ValidationError("Object with this id already exists.", code="unique")
        return value

    def validate_at(self, value):
        if value > timezone.now() + _CLOCK_SKEW:
            raise serializers.ValidationError("Opening date cannot be in the future.")
        if value < _EARLIEST_OPENING:
            raise serializers.ValidationError("Opening date is too early.")
        return value


class CustomerSerializer(ClientIdMixin, serializers.ModelSerializer):
    id = serializers.UUIDField(required=False)
    debt_limit_tiyin = StrictIntegerField(min_value=0, allow_null=True, required=False)
    # Model validatori faqat `+998XXXXXXXXX` ni qabul qiladi; `validate_phone` avval keltiradi.
    phone = serializers.CharField(required=False, allow_blank=True, max_length=32, label="Telefon")
    balance_tiyin = serializers.SerializerMethodField()
    # Faqat yaratishda; tahrirda rad etiladi (balans ikki marta qo'shilmasin).
    opening_balance = OpeningBalanceSerializer(write_only=True, required=False, allow_null=True)

    class Meta:
        model = Customer
        fields = [
            "id",
            "full_name",
            "phone",
            "note",
            "debt_limit_tiyin",
            "opening_balance",
            "balance_tiyin",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["created_at", "updated_at"]

    def get_balance_tiyin(self, customer) -> int:
        balance = getattr(customer, "balance_tiyin", None)
        return balance if balance is not None else customer_balance(customer)

    def validate_opening_balance(self, value):
        if value is None:
            return None
        if self.instance is not None:
            raise serializers.ValidationError(
                "Opening balance can only be set when the customer is created.",
                code="opening_create_only",
            )
        # Soxta avans bilan nasiyaga tovar olib ketish mumkin — faqat ega/menejer.
        if (
            value["direction"] == OpeningDirection.CREDIT
            and self.context["request"].user.role == Role.CASHIER
        ):
            raise PermissionDenied("Only owner or manager can record a customer credit.")
        return value

    def create(self, validated_data):
        opening = validated_data.pop("opening_balance", None)
        with transaction.atomic():
            customer = super().create(validated_data)
            if opening:
                record_opening_balance(customer, user=self.context["request"].user, **opening)
        return customer

    def update(self, instance, validated_data):
        validated_data.pop("opening_balance", None)
        return super().update(instance, validated_data)

    def validate_full_name(self, value):
        value = clean_line(value)
        if not value:
            raise serializers.ValidationError("This field may not be blank.", code="blank")
        return value

    def validate_phone(self, value):
        # Kassa raqamni yozilganicha yuboradi ("90 123 45 67"): rad etilsa mijoz va
        # uning nasiya savdolari serverga yetmay qoladi — bir ko'rinishga keltiramiz.
        if not value or not value.strip():
            return ""
        try:
            return normalize_phone(value)
        except ValueError as exc:
            raise serializers.ValidationError(str(exc)) from None

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
