from django.contrib import admin

from .models import Device


@admin.register(Device)
class DeviceAdmin(admin.ModelAdmin):
    list_display = [
        "__str__",
        "tenant",
        "platform",
        "app_version",
        "is_blocked",
        "last_sync_at",
        "last_seen_at",
    ]
    list_filter = ["is_blocked", "platform"]
    list_select_related = ["tenant"]
    search_fields = ["name", "tenant__name"]
    list_editable = ["is_blocked"]
    # Token hash va raqam tahrirlanmaydi; bloklash — `is_blocked`.
    readonly_fields = [
        "id",
        "tenant",
        "store",
        "number",
        "token_hash",
        "registered_by",
        "last_sync_at",
        "last_seen_at",
        "last_ip",
        "created_at",
        "updated_at",
    ]

    def has_add_permission(self, request):
        return False
