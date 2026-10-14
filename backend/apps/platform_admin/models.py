"""Platforma admin amallari jurnali (platform-api.md "Audit qoidasi")."""

from django.conf import settings
from django.db import models
from django.utils import timezone
from django.utils.translation import gettext_lazy as _

from apps.core.models import AppendOnlyModel, UUIDModel


class AdminAuditLog(AppendOnlyModel, UUIDModel):
    """Kim, nima, qachon, oldin/keyin. Faqat qo'shiladi."""

    actor = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.PROTECT,
        related_name="+",
        verbose_name=_("kim"),
    )
    action = models.CharField(_("amal"), max_length=64, db_index=True)
    target_type = models.CharField(_("obyekt turi"), max_length=64)
    target_id = models.CharField(_("obyekt id"), max_length=64)
    tenant = models.ForeignKey(
        "tenants.Tenant",
        on_delete=models.PROTECT,
        null=True,
        blank=True,
        related_name="+",
        verbose_name=_("tenant"),
    )
    before = models.JSONField(_("oldin"), null=True, blank=True)
    after = models.JSONField(_("keyin"), null=True, blank=True)
    reason = models.TextField(_("sabab"), blank=True)
    at = models.DateTimeField(_("vaqt"), default=timezone.now, db_index=True)

    class Meta:
        verbose_name = _("audit yozuvi")
        verbose_name_plural = _("audit jurnali")
        ordering = ["-at", "-id"]
        indexes = [models.Index(fields=["target_type", "target_id"])]

    def __str__(self):
        return f"{self.action} {self.target_type}:{self.target_id}"
