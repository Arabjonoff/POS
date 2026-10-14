from django.utils.translation import gettext_lazy as _
from drf_spectacular.extensions import OpenApiAuthenticationExtension
from rest_framework import authentication, exceptions

from .models import Device, DevicePrincipal
from .tokens import TOKEN_PREFIX, hash_token

KEYWORD = "Device"


class DeviceBlocked(exceptions.PermissionDenied):
    default_detail = _("Device is blocked.")
    default_code = "device_blocked"


class DeviceTokenAuthentication(authentication.BaseAuthentication):
    """`Authorization: Device <token>` — kassa qurilmasi (devices.md)."""

    def authenticate(self, request):
        header = authentication.get_authorization_header(request).split()
        if not header or header[0].decode(errors="replace") != KEYWORD:
            return None
        if len(header) != 2:
            raise exceptions.AuthenticationFailed(_("Invalid device token header."))
        token = header[1].decode(errors="replace")
        if not token.startswith(TOKEN_PREFIX):
            raise exceptions.AuthenticationFailed(_("Invalid device token."))
        device = (
            Device.objects.select_related("tenant").filter(token_hash=hash_token(token)).first()
        )
        if device is None:
            raise exceptions.AuthenticationFailed(_("Invalid device token."))
        if device.is_blocked:
            raise DeviceBlocked()
        return DevicePrincipal(device), device

    def authenticate_header(self, request):
        return f'{KEYWORD} realm="api"'


class DeviceTokenScheme(OpenApiAuthenticationExtension):
    target_class = "apps.devices.authentication.DeviceTokenAuthentication"
    name = "deviceToken"

    def get_security_definition(self, auto_schema):
        return {
            "type": "apiKey",
            "in": "header",
            "name": "Authorization",
            "description": "`Device <token>` — qurilma tokeni (`/devices/register/` javobidan).",
        }
