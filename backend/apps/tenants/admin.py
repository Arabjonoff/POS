from django.contrib import admin

from .models import Store, Tenant


class StoreInline(admin.StackedInline):
    model = Store
    extra = 0
    fields = [
        "name",
        "legal_name",
        "tin",
        "address",
        "phone",
        "receipt_header",
        "receipt_footer",
    ]


@admin.register(Tenant)
class TenantAdmin(admin.ModelAdmin):
    list_display = ["name", "owner_phone", "default_locale", "is_blocked", "created_at"]
    list_filter = ["is_blocked", "default_locale"]
    search_fields = ["name", "owner_phone", "address"]
    readonly_fields = ["id", "created_at", "updated_at"]
    inlines = [StoreInline]


@admin.register(Store)
class StoreAdmin(admin.ModelAdmin):
    list_display = ["name", "tenant", "phone", "created_at"]
    search_fields = ["name", "tenant__name", "phone"]
    list_select_related = ["tenant"]
    readonly_fields = ["id", "created_at", "updated_at"]
    autocomplete_fields = ["tenant"]
