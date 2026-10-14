from django.contrib import admin

from .models import (
    InventoryCount,
    InventoryCountItem,
    ProductStock,
    StockMovement,
    StockReceipt,
    StockReceiptItem,
    Supplier,
)


class ReadOnlyAdmin(admin.ModelAdmin):
    """Hujjat va harakatlar faqat API/servis orqali o'zgaradi."""

    def has_add_permission(self, request):
        return False

    def has_change_permission(self, request, obj=None):
        return False

    def has_delete_permission(self, request, obj=None):
        return False


@admin.register(Supplier)
class SupplierAdmin(admin.ModelAdmin):
    list_display = ["name", "tenant", "phone", "deleted_at"]
    list_select_related = ["tenant"]
    search_fields = ["name", "phone", "tenant__name"]
    raw_id_fields = ["tenant"]


@admin.register(StockMovement)
class StockMovementAdmin(ReadOnlyAdmin):
    list_display = ["product", "qty_milli", "type", "store", "at"]
    list_filter = ["type"]
    list_select_related = ["product", "store"]


@admin.register(ProductStock)
class ProductStockAdmin(ReadOnlyAdmin):
    list_display = ["product", "store", "qty_milli", "updated_at"]
    list_select_related = ["product", "store"]


class ReceiptItemInline(admin.TabularInline):
    model = StockReceiptItem
    extra = 0
    fields = [
        "product",
        "qty_milli",
        "cost_price_tiyin",
        "new_sell_price_tiyin",
        "line_total_tiyin",
    ]
    readonly_fields = fields

    def has_add_permission(self, request, obj=None):
        return False


@admin.register(StockReceipt)
class StockReceiptAdmin(ReadOnlyAdmin):
    list_display = ["__str__", "tenant", "status", "total_cost_tiyin", "posted_at"]
    list_filter = ["status"]
    list_select_related = ["tenant"]
    inlines = [ReceiptItemInline]


class CountItemInline(admin.TabularInline):
    model = InventoryCountItem
    extra = 0
    fields = ["product", "expected_milli", "counted_milli"]
    readonly_fields = fields

    def has_add_permission(self, request, obj=None):
        return False


@admin.register(InventoryCount)
class InventoryCountAdmin(ReadOnlyAdmin):
    list_display = ["__str__", "tenant", "status", "scope", "posted_at"]
    list_filter = ["status"]
    list_select_related = ["tenant"]
    inlines = [CountItemInline]
