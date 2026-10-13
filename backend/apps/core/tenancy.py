"""So'rov qaysi tenantga tegishli ekanini aniqlash va querysetni cheklash."""

from rest_framework import viewsets
from rest_framework.exceptions import PermissionDenied


def get_request_tenant_id(request):
    """Qurilma tokeni (`request.tenant_id`) yoki foydalanuvchi tenanti; topilmasa `None`."""
    tenant_id = getattr(request, "tenant_id", None)
    if tenant_id:
        return tenant_id
    user = getattr(request, "user", None)
    if user is None or not user.is_authenticated:
        return None
    return getattr(user, "tenant_id", None)


class TenantScopedMixin:
    """Queryset faqat joriy tenant yozuvlari; yaratishda tenant avtomatik qo'yiladi."""

    def get_tenant_id(self):
        return get_request_tenant_id(self.request)

    def get_queryset(self):
        queryset = super().get_queryset()
        tenant_id = self.get_tenant_id()
        if tenant_id is None:
            return queryset.none()
        return queryset.filter(tenant_id=tenant_id)

    def perform_create(self, serializer):
        tenant_id = self.get_tenant_id()
        if tenant_id is None:
            raise PermissionDenied("Tenant is required.")
        serializer.save(tenant_id=tenant_id)


class TenantScopedViewSet(TenantScopedMixin, viewsets.ModelViewSet):
    pass


class TenantScopedReadOnlyViewSet(TenantScopedMixin, viewsets.ReadOnlyModelViewSet):
    pass
