"""Rol bo'yicha ruxsatlar (auth-roles.md). Tenant cheklovi — `TenantScopedMixin` da."""

from rest_framework.permissions import BasePermission

from .models import Role


class HasRole(BasePermission):
    roles: frozenset[str] = frozenset()
    tenant_required = True

    def has_permission(self, request, view):
        user = request.user
        if not (user and user.is_authenticated and user.is_active):
            return False
        if getattr(user, "role", None) not in self.roles:
            return False
        return not self.tenant_required or getattr(user, "tenant_id", None) is not None


class IsPlatformAdmin(HasRole):
    roles = frozenset({Role.PLATFORM_ADMIN})
    tenant_required = False


class IsOwner(HasRole):
    roles = frozenset({Role.OWNER})


class IsManagerOrOwner(HasRole):
    roles = frozenset({Role.OWNER, Role.MANAGER})


class IsTenantMember(HasRole):
    """Do'konning istalgan xodimi (kassir ham)."""

    roles = frozenset({Role.OWNER, Role.MANAGER, Role.CASHIER})
