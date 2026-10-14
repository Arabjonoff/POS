from django.contrib import admin

from .models import Category, PriceHistory, Product, ProductBarcode, Unit


class BarcodeInline(admin.TabularInline):
    model = ProductBarcode
    extra = 0
    fields = ["barcode", "is_primary", "deleted_at"]
    readonly_fields = ["deleted_at"]


@admin.register(Product)
class ProductAdmin(admin.ModelAdmin):
    list_display = ["name", "tenant", "sell_price_tiyin", "is_weighted", "is_active"]
    list_filter = ["is_active", "is_weighted"]
    list_select_related = ["tenant"]
    search_fields = ["name", "barcodes__barcode", "plu_code", "tenant__name"]
    readonly_fields = ["id", "created_at", "updated_at"]
    raw_id_fields = ["tenant", "category", "unit"]
    inlines = [BarcodeInline]


@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    list_display = ["name", "tenant", "parent", "sort", "deleted_at"]
    list_select_related = ["tenant", "parent"]
    search_fields = ["name", "tenant__name"]
    raw_id_fields = ["tenant", "parent"]


@admin.register(Unit)
class UnitAdmin(admin.ModelAdmin):
    list_display = ["code", "name", "tenant", "is_fractional", "deleted_at"]
    list_select_related = ["tenant"]
    search_fields = ["code", "name", "tenant__name"]
    raw_id_fields = ["tenant"]


@admin.register(PriceHistory)
class PriceHistoryAdmin(admin.ModelAdmin):
    list_display = ["product", "sell_price_tiyin", "cost_price_tiyin", "changed_by", "at"]
    list_select_related = ["product", "changed_by"]

    def has_add_permission(self, request):
        return False

    def has_change_permission(self, request, obj=None):
        return False

    def has_delete_permission(self, request, obj=None):
        return False
