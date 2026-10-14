from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from django.contrib.auth.forms import AdminUserCreationForm, UserChangeForm
from django.utils.translation import gettext_lazy as _

from .models import User


class UserCreationForm(AdminUserCreationForm):
    class Meta:
        model = User
        fields = ("phone", "full_name", "role", "tenant")


class UserEditForm(UserChangeForm):
    class Meta:
        model = User
        fields = "__all__"


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    form = UserEditForm
    add_form = UserCreationForm
    list_display = ["full_name", "phone", "role", "tenant", "is_active", "created_at"]
    list_filter = ["role", "is_active"]
    list_select_related = ["tenant"]
    search_fields = ["full_name", "phone", "tenant__name"]
    ordering = ["-created_at"]
    autocomplete_fields = ["tenant"]
    readonly_fields = ["id", "pin_hash", "last_login", "created_at", "updated_at"]
    fieldsets = (
        (None, {"fields": ("id", "phone", "password")}),
        (_("Profil"), {"fields": ("full_name", "role", "tenant", "is_active", "pin_hash")}),
        (_("Huquqlar"), {"fields": ("is_superuser", "groups", "user_permissions")}),
        (_("Sanalar"), {"fields": ("last_login", "created_at", "updated_at")}),
    )
    add_fieldsets = (
        (
            None,
            {
                "classes": ("wide",),
                "fields": (
                    "phone",
                    "full_name",
                    "role",
                    "tenant",
                    "usable_password",
                    "password1",
                    "password2",
                ),
            },
        ),
    )
