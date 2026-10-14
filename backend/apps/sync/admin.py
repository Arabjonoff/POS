from django.contrib import admin

from .models import ChangeLog, SyncEvent


class ReadOnlyAdmin(admin.ModelAdmin):
    def has_add_permission(self, request):
        return False

    def has_change_permission(self, request, obj=None):
        return False

    def has_delete_permission(self, request, obj=None):
        return False


@admin.register(SyncEvent)
class SyncEventAdmin(ReadOnlyAdmin):
    """Rad etilgan va kutilayotgan hodisalarni ko'rish (sync.md: "admin ko'radi")."""

    list_display = ["type", "tenant", "device", "status", "client_created_at", "attempts"]
    list_filter = ["status", "type"]
    list_select_related = ["tenant", "device"]
    search_fields = ["id"]


@admin.register(ChangeLog)
class ChangeLogAdmin(ReadOnlyAdmin):
    list_display = ["seq", "tenant", "entity", "entity_id", "op", "at"]
    list_filter = ["entity", "op"]
    list_select_related = ["tenant"]
