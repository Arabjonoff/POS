from django.contrib import admin

from .models import Plan, Subscription, SubscriptionPayment


@admin.register(Plan)
class PlanAdmin(admin.ModelAdmin):
    list_display = [
        "name",
        "price_tiyin_per_month",
        "max_devices",
        "max_users",
        "is_active",
        "sort",
    ]
    list_filter = ["is_active"]
    readonly_fields = ["id", "created_at", "updated_at"]


@admin.register(Subscription)
class SubscriptionAdmin(admin.ModelAdmin):
    list_display = ["tenant", "plan", "status", "trial_ends_at", "paid_until", "status_changed_at"]
    list_filter = ["status", "plan"]
    list_select_related = ["tenant", "plan"]
    search_fields = ["tenant__name", "tenant__owner_phone"]
    autocomplete_fields = ["tenant"]
    # `paid_until` va holat faqat to'lov orqali o'zgaradi (services.record_payment).
    readonly_fields = [
        "id",
        "paid_until",
        "status",
        "status_changed_at",
        "created_at",
        "updated_at",
    ]


@admin.register(SubscriptionPayment)
class SubscriptionPaymentAdmin(admin.ModelAdmin):
    """Faqat ko'rish: to'lov va bekor qilish servis orqali (T-020 platforma admin API)."""

    list_display = [
        "tenant",
        "amount_tiyin",
        "months",
        "method",
        "period_from",
        "period_to",
        "paid_at",
    ]
    list_filter = ["method"]
    list_select_related = ["tenant"]
    search_fields = ["tenant__name"]

    def has_add_permission(self, request):
        return False

    def has_change_permission(self, request, obj=None):
        return False

    def has_delete_permission(self, request, obj=None):
        return False
