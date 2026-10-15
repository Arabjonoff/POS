from drf_spectacular.utils import extend_schema_field
from rest_framework import serializers

from apps.core.exceptions import DomainError
from apps.core.fields import StrictIntegerField, money_field
from apps.core.money import mul_div_half_up
from apps.core.serializers import TenantPKField
from apps.core.text import clean_line

from .barcodes import BarcodeError, normalize_barcode
from .models import STANDARD_UNITS, Category, PriceHistory, Product, ProductBarcode, Unit

STANDARD_UNIT_CODES = frozenset(code for code, _ in STANDARD_UNITS)


class UnitSerializer(serializers.ModelSerializer):
    class Meta:
        model = Unit
        fields = ["id", "code", "name", "is_fractional"]
        read_only_fields = ["id"]

    def validate_code(self, code):
        tenant_id = self.context["request"].user.tenant_id
        taken = Unit.objects.filter(tenant_id=tenant_id, code=code, deleted_at__isnull=True)
        if self.instance is not None:
            taken = taken.exclude(pk=self.instance.pk)
        if taken.exists():
            raise serializers.ValidationError("Unit code already exists.", code="unique")
        return code

    def validate(self, attrs):
        code = attrs.get("code", getattr(self.instance, "code", None))
        name = attrs.get("name", getattr(self.instance, "name", ""))
        if code not in STANDARD_UNIT_CODES and not name:
            raise serializers.ValidationError({"name": "Name is required for a custom unit."})
        return attrs


class CategorySerializer(serializers.ModelSerializer):
    parent = TenantPKField(queryset=Category.objects.all(), allow_null=True, required=False)

    class Meta:
        model = Category
        fields = ["id", "name", "parent", "sort", "color"]
        read_only_fields = ["id"]

    def validate_parent(self, parent):
        node = parent
        while node is not None and self.instance is not None:
            if node.pk == self.instance.pk:
                raise serializers.ValidationError("Category cannot be its own ancestor.")
            node = node.parent
        return parent


class BarcodeListField(serializers.ListField):
    """Yozish — satrlar ro'yxati; o'qish — tovarning o'chirilmagan kodlari (asosiysi birinchi)."""

    def to_representation(self, manager):
        return [b.barcode for b in manager.all() if b.deleted_at is None]


def _barcode_taken(barcode, product):
    return DomainError(
        "barcode_taken",
        "Barcode already belongs to another product.",
        status_code=409,
        details={"barcode": barcode, "product": {"id": str(product.id), "name": product.name}},
    )


class ProductImageRefSerializer(serializers.Serializer):
    id = serializers.UUIDField()
    sha256 = serializers.CharField()
    width = serializers.IntegerField()
    height = serializers.IntegerField()


class ProductSerializer(serializers.ModelSerializer):
    id = serializers.UUIDField(required=False)
    category = TenantPKField(queryset=Category.objects.all(), allow_null=True, required=False)
    unit = TenantPKField(queryset=Unit.objects.all())
    sell_price_tiyin = money_field()
    cost_price_tiyin = money_field(required=False)
    min_stock_milli = StrictIntegerField(min_value=0, required=False)
    barcodes = BarcodeListField(
        child=serializers.CharField(trim_whitespace=False), required=False, max_length=20
    )
    markup_bp = serializers.SerializerMethodField()
    # Faqat o'qish (T-105): rasm alohida endpoint orqali biriktiriladi.
    image = serializers.SerializerMethodField()

    class Meta:
        model = Product
        fields = [
            "id",
            "name",
            "category",
            "unit",
            "sell_price_tiyin",
            "cost_price_tiyin",
            "is_weighted",
            "plu_code",
            "min_stock_milli",
            "ikpu_code",
            "quick_button",
            "is_active",
            "barcodes",
            "markup_bp",
            "image",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["created_at", "updated_at"]

    @extend_schema_field(ProductImageRefSerializer(allow_null=True))
    def get_image(self, product):
        image = product.image
        if image is None or image.deleted_at is not None:
            return None
        return {
            "id": str(image.pk),
            "sha256": image.sha256,
            "width": image.width,
            "height": image.height,
        }

    def get_markup_bp(self, product) -> int | None:
        if not product.cost_price_tiyin:
            return None
        return mul_div_half_up(
            product.sell_price_tiyin - product.cost_price_tiyin, 10_000, product.cost_price_tiyin
        )

    def validate_id(self, value):
        if self.instance is not None and value != self.instance.pk:
            raise serializers.ValidationError("Id cannot be changed.")
        if self.instance is None and Product.objects.filter(pk=value).exists():
            raise serializers.ValidationError("Product with this id already exists.", code="unique")
        return value

    def validate_name(self, value):
        # Import/REST'dan yangi qator va tab kelishi mumkin — chekda va qidiruvda
        # buziladi (audit P2-12).
        value = clean_line(value)
        if not value:
            raise serializers.ValidationError("This field may not be blank.", code="blank")
        return value

    def validate_barcodes(self, codes):
        normalized = []
        for raw in codes:
            try:
                code = normalize_barcode(raw)
            except BarcodeError as exc:
                raise serializers.ValidationError(str(exc), code=exc.code) from None
            if code in normalized:
                raise serializers.ValidationError(f"Duplicate barcode {code}.", code="duplicate")
            normalized.append(code)
        return normalized

    def validate(self, attrs):
        tenant_id = self.context["request"].user.tenant_id
        instance = self.instance

        def final(field, default=None):
            return attrs.get(field, getattr(instance, field, default) if instance else default)

        unit = final("unit")
        if final("is_weighted", False) and unit is not None and not unit.is_fractional:
            raise serializers.ValidationError({"unit": "Weighted product needs a fractional unit."})

        plu = final("plu_code")
        if plu and final("is_active", True):
            clash = Product.objects.filter(
                tenant_id=tenant_id, plu_code=plu, is_active=True, deleted_at__isnull=True
            )
            if instance is not None:
                clash = clash.exclude(pk=instance.pk)
            if clash.exists():
                raise DomainError("plu_taken", "PLU code is used by another product.", 409)

        codes = attrs.get("barcodes")
        if codes:
            taken = ProductBarcode.objects.select_related("product").filter(
                tenant_id=tenant_id, barcode__in=codes, deleted_at__isnull=True
            )
            if instance is not None:
                taken = taken.exclude(product=instance)
            first = taken.first()
            if first is not None:
                raise _barcode_taken(first.barcode, first.product)
        return attrs

    def create(self, validated_data):
        from .services import save_product

        return save_product(None, validated_data, user=self.context["request"].user)

    def update(self, instance, validated_data):
        from .services import save_product

        return save_product(instance, validated_data, user=self.context["request"].user)


class PriceHistorySerializer(serializers.ModelSerializer):
    """Narx o'zgarishi (faqat o'qish): kim va qachon."""

    changed_by_name = serializers.CharField(
        source="changed_by.full_name", default=None, read_only=True, allow_null=True
    )

    class Meta:
        model = PriceHistory
        fields = [
            "id",
            "sell_price_tiyin",
            "cost_price_tiyin",
            "changed_by",
            "changed_by_name",
            "at",
        ]
        read_only_fields = fields
