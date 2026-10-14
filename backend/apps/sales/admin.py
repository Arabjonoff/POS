from django.contrib import admin

from .models import CashMovement, Refund, RefundItem, Sale, SaleItem, SalePayment, Shift


class ReadOnlyAdmin(admin.ModelAdmin):
    """Savdo ma'lumotlari faqat sinxron orqali keladi; admin — faqat ko'rish."""

    def has_add_permission(self, request):
        return False

    def has_change_permission(self, request, obj=None):
        return False

    def has_delete_permission(self, request, obj=None):
        return False


class ReadOnlyInline(admin.TabularInline):
    extra = 0

    def has_add_permission(self, request, obj=None):
        return False

    def has_change_permission(self, request, obj=None):
        return False

    def has_delete_permission(self, request, obj=None):
        return False


@admin.register(Shift)
class ShiftAdmin(ReadOnlyAdmin):
    list_display = ["device", "tenant", "opened_by", "opened_at", "closed_at"]
    list_select_related = ["device", "tenant", "opened_by"]


class SaleItemInline(ReadOnlyInline):
    model = SaleItem
    fields = ["name_snapshot", "qty_milli", "price_tiyin", "discount_tiyin", "total_tiyin"]
    readonly_fields = fields


class SalePaymentInline(ReadOnlyInline):
    model = SalePayment
    fields = ["method", "amount_tiyin", "received_tiyin", "change_tiyin"]
    readonly_fields = fields


@admin.register(Sale)
class SaleAdmin(ReadOnlyAdmin):
    list_display = ["number", "tenant", "total_tiyin", "status", "sold_at"]
    list_filter = ["status"]
    list_select_related = ["tenant"]
    search_fields = ["number"]
    inlines = [SaleItemInline, SalePaymentInline]


class RefundItemInline(ReadOnlyInline):
    model = RefundItem
    fields = ["sale_item", "qty_milli", "total_tiyin"]
    readonly_fields = fields


@admin.register(Refund)
class RefundAdmin(ReadOnlyAdmin):
    list_display = ["sale", "tenant", "method", "total_tiyin", "at"]
    list_select_related = ["sale", "tenant"]
    inlines = [RefundItemInline]


@admin.register(CashMovement)
class CashMovementAdmin(ReadOnlyAdmin):
    list_display = ["shift", "type", "amount_tiyin", "reason", "at"]
    list_select_related = ["shift"]
