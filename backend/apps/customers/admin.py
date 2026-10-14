from django.contrib import admin

from .models import Customer, DebtEntry


@admin.register(Customer)
class CustomerAdmin(admin.ModelAdmin):
    list_display = ["full_name", "tenant", "phone", "debt_limit_tiyin", "deleted_at"]
    list_select_related = ["tenant"]
    search_fields = ["full_name", "phone", "tenant__name"]
    raw_id_fields = ["tenant"]


@admin.register(DebtEntry)
class DebtEntryAdmin(admin.ModelAdmin):
    """Qarz yozuvlari faqat API/servis orqali; admin — faqat ko'rish."""

    list_display = ["customer", "amount_tiyin", "type", "method", "at"]
    list_filter = ["type"]
    list_select_related = ["customer"]

    def has_add_permission(self, request):
        return False

    def has_change_permission(self, request, obj=None):
        return False

    def has_delete_permission(self, request, obj=None):
        return False
