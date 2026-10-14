"""Kassa qurilmasi (devices.md). Token serverda faqat hash ko'rinishida."""

from django.conf import settings
from django.db import models
from django.utils.translation import gettext_lazy as _

from apps.core.models import TenantScopedModel


class Platform(models.TextChoices):
    WINDOWS = "windows", "Windows"
    ANDROID = "android", "Android"
    IOS = "ios", "iOS"


class Device(TenantScopedModel):
    tenant = models.ForeignKey(
        "tenants.Tenant",
        on_delete=models.PROTECT,
        related_name="devices",
        verbose_name=_("tenant"),
    )
    store = models.ForeignKey(
        "tenants.Store",
        on_delete=models.PROTECT,
        related_name="devices",
        verbose_name=_("do'kon"),
    )
    # Tenant ichida tartib raqami: chek raqami prefiksi `D{number}-`. Qayta ishlatilmaydi.
    number = models.PositiveIntegerField(_("raqam"))
    name = models.CharField(_("nomi"), max_length=100)
    platform = models.CharField(_("platforma"), max_length=16, choices=Platform.choices)
    app_version = models.CharField(_("ilova versiyasi"), max_length=32, blank=True)
    last_sync_at = models.DateTimeField(_("oxirgi sinxron"), null=True, blank=True)
    last_seen_at = models.DateTimeField(_("oxirgi ulanish"), null=True, blank=True)
    last_ip = models.GenericIPAddressField(_("oxirgi IP"), null=True, blank=True)
    is_blocked = models.BooleanField(_("bloklangan"), default=False)
    token_hash = models.CharField(_("token hash"), max_length=64, unique=True)
    registered_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.PROTECT,
        null=True,
        related_name="+",
        verbose_name=_("ro'yxatdan o'tkazgan"),
    )

    class Meta:
        verbose_name = _("qurilma")
        verbose_name_plural = _("qurilmalar")
        ordering = ["tenant", "number"]
        constraints = [
            models.UniqueConstraint(fields=["tenant", "number"], name="device_number_per_tenant"),
        ]

    def __str__(self):
        return f"D{self.number} {self.name}"

    @property
    def code(self) -> str:
        return f"D{self.number}"


class DevicePrincipal:
    """Qurilma tokeni bilan kirgan so'rovning `request.user` i (odam emas)."""

    is_authenticated = True
    is_anonymous = False
    is_active = True
    role = None

    def __init__(self, device: Device):
        self.device = device
        self.tenant_id = device.tenant_id
        self.pk = None

    def __str__(self):
        return f"device:{self.device.pk}"
