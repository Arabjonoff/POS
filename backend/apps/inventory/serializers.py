from rest_framework import serializers

from apps.catalog.models import Category, Product
from apps.core.fields import StrictIntegerField, money_field
from apps.core.serializers import TenantPKField
from apps.tenants.models import Store

from . import services
from .models import (
    InventoryCount,
    InventoryCountItem,
    InventoryScope,
    ProductStock,
    StockMovement,
    StockReceipt,
    StockReceiptItem,
    Supplier,
)


class SupplierSerializer(serializers.ModelSerializer):
    class Meta:
        model = Supplier
        fields = ["id", "name", "phone", "note"]
        read_only_fields = ["id"]


class ClientIdMixin:
    """`id` klientda yaratilishi mumkin (UUIDv7); keyin o'zgarmaydi."""

    def validate_id(self, value):
        model = self.Meta.model
        if self.instance is not None and value != self.instance.pk:
            raise serializers.ValidationError("Id cannot be changed.")
        if self.instance is None and model.objects.filter(pk=value).exists():
            raise serializers.ValidationError("Object with this id already exists.", code="unique")
        return value


class StockReceiptItemSerializer(serializers.ModelSerializer):
    product = TenantPKField(queryset=Product.objects.all())
    qty_milli = StrictIntegerField(min_value=1)
    cost_price_tiyin = money_field()
    new_sell_price_tiyin = money_field(required=False, allow_null=True)

    class Meta:
        model = StockReceiptItem
        fields = [
            "id",
            "product",
            "qty_milli",
            "cost_price_tiyin",
            "new_sell_price_tiyin",
            "line_total_tiyin",
        ]
        read_only_fields = ["id", "line_total_tiyin"]


class StockReceiptSerializer(ClientIdMixin, serializers.ModelSerializer):
    id = serializers.UUIDField(required=False)
    store = TenantPKField(queryset=Store.objects.all(), required=False)
    supplier = TenantPKField(queryset=Supplier.objects.all(), allow_null=True, required=False)
    items = StockReceiptItemSerializer(many=True, required=False, max_length=1000)

    class Meta:
        model = StockReceipt
        fields = [
            "id",
            "number",
            "store",
            "supplier",
            "status",
            "note",
            "total_cost_tiyin",
            "reverses",
            "items",
            "created_at",
            "posted_at",
        ]
        read_only_fields = [
            "number",
            "status",
            "total_cost_tiyin",
            "reverses",
            "created_at",
            "posted_at",
        ]

    def create(self, validated_data):
        request = self.context["request"]
        return services.create_receipt(
            tenant_id=request.user.tenant_id, user=request.user, data=validated_data
        )

    def update(self, instance, validated_data):
        validated_data.pop("id", None)
        return services.update_receipt(instance, validated_data)


class ReverseReceiptSerializer(serializers.Serializer):
    note = serializers.CharField(required=False, allow_blank=True, default="")


class InventoryCountItemSerializer(serializers.ModelSerializer):
    product = TenantPKField(queryset=Product.objects.all())
    counted_milli = StrictIntegerField(min_value=0)
    diff_milli = serializers.SerializerMethodField()

    class Meta:
        model = InventoryCountItem
        fields = ["id", "product", "counted_milli", "expected_milli", "diff_milli"]
        read_only_fields = ["id", "expected_milli"]

    def get_diff_milli(self, item) -> int | None:
        if item.expected_milli is None:
            return None
        return item.counted_milli - item.expected_milli


class InventoryCountSerializer(ClientIdMixin, serializers.ModelSerializer):
    id = serializers.UUIDField(required=False)
    store = TenantPKField(queryset=Store.objects.all(), required=False)
    category = TenantPKField(queryset=Category.objects.all(), allow_null=True, required=False)
    items = InventoryCountItemSerializer(many=True, required=False, max_length=10000)

    class Meta:
        model = InventoryCount
        fields = [
            "id",
            "store",
            "status",
            "scope",
            "category",
            "note",
            "items",
            "created_at",
            "posted_at",
        ]
        read_only_fields = ["status", "created_at", "posted_at"]

    def validate_items(self, items):
        seen = set()
        for item in items:
            if item["product"].pk in seen:
                raise serializers.ValidationError(
                    f"Product {item['product'].pk} is listed twice.", code="duplicate"
                )
            seen.add(item["product"].pk)
        return items

    def validate(self, attrs):
        instance = self.instance
        scope = attrs.get("scope", getattr(instance, "scope", InventoryScope.ALL))
        category = attrs.get("category", getattr(instance, "category", None))
        if scope == InventoryScope.CATEGORY and category is None:
            raise serializers.ValidationError({"category": "Category is required for this scope."})
        if scope == InventoryScope.ALL:
            attrs["category"] = None
        return attrs

    def create(self, validated_data):
        request = self.context["request"]
        return services.create_count(
            tenant_id=request.user.tenant_id, user=request.user, data=validated_data
        )

    def update(self, instance, validated_data):
        validated_data.pop("id", None)
        return services.update_count(instance, validated_data)


class StockSerializer(serializers.ModelSerializer):
    class Meta:
        model = ProductStock
        fields = ["product", "store", "qty_milli", "updated_at"]


class StockMovementSerializer(serializers.ModelSerializer):
    class Meta:
        model = StockMovement
        fields = [
            "id",
            "product",
            "store",
            "qty_milli",
            "type",
            "ref_type",
            "ref_id",
            "at",
            "created_by",
        ]
