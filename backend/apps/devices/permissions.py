from rest_framework.permissions import BasePermission

from .models import Device


class IsDevice(BasePermission):
    """Faqat qurilma tokeni bilan (foydalanuvchi JWT'si emas)."""

    def has_permission(self, request, view):
        return isinstance(request.auth, Device)
