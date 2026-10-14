"""Sinxron jurnali: kassadan kelgan hodisalar va pull uchun o'zgarishlar (sync-api.md)."""

from django.db import models
from django.utils import timezone
from django.utils.translation import gettext_lazy as _

from .db import CurrentTxid


class EventStatus(models.TextChoices):
    APPLIED = "applied", _("qo'llangan")
    PENDING = "pending", _("kutilmoqda")
    REJECTED = "rejected", _("rad etilgan")


class SyncEvent(models.Model):
    """Kassa hodisasi. `id` — klient UUID'i, idempotentlik shu bo'yicha."""

    id = models.UUIDField(primary_key=True)
    tenant = models.ForeignKey(
        "tenants.Tenant", on_delete=models.PROTECT, related_name="+", verbose_name=_("tenant")
    )
    device = models.ForeignKey(
        "devices.Device",
        on_delete=models.PROTECT,
        related_name="sync_events",
        verbose_name=_("qurilma"),
    )
    type = models.CharField(_("turi"), max_length=32)
    payload = models.JSONField(_("ma'lumot"))
    client_created_at = models.DateTimeField(_("qurilmadagi vaqt"))
    received_at = models.DateTimeField(_("qabul qilingan"), default=timezone.now)
    status = models.CharField(_("holat"), max_length=16, choices=EventStatus.choices)
    error = models.JSONField(_("xato"), null=True, blank=True)
    attempts = models.PositiveIntegerField(_("urinishlar"), default=0)
    applied_at = models.DateTimeField(_("qo'llangan vaqt"), null=True, blank=True)

    class Meta:
        verbose_name = _("sinxron hodisasi")
        verbose_name_plural = _("sinxron hodisalari")
        ordering = ["-received_at"]
        indexes = [
            models.Index(fields=["device", "status", "client_created_at"]),
            models.Index(fields=["tenant", "status"]),
        ]

    def __str__(self):
        return f"{self.type} {self.id} ({self.status})"


class ChangeOp(models.TextChoices):
    UPSERT = "upsert", _("qo'shish/yangilash")
    DELETE = "delete", _("o'chirish")


class ChangeLog(models.Model):
    """Pull uchun: qaysi obyekt o'zgardi. Ma'lumot o'zi pull paytida o'qiladi."""

    seq = models.BigAutoField(primary_key=True)
    # Yozgan tranzaksiya ID'si — pull tartibi `(txid, seq)` (apps/sync/db.py).
    txid = models.BigIntegerField(_("tranzaksiya"), db_default=CurrentTxid(), editable=False)
    tenant = models.ForeignKey(
        "tenants.Tenant", on_delete=models.PROTECT, related_name="+", verbose_name=_("tenant")
    )
    entity = models.CharField(_("entity"), max_length=32)
    entity_id = models.UUIDField(_("entity id"))
    op = models.CharField(_("amal"), max_length=8, choices=ChangeOp.choices)
    at = models.DateTimeField(_("vaqt"), default=timezone.now)

    class Meta:
        verbose_name = _("o'zgarish")
        verbose_name_plural = _("o'zgarishlar")
        ordering = ["txid", "seq"]
        indexes = [models.Index(fields=["tenant", "txid", "seq"])]

    def __str__(self):
        return f"{self.seq} {self.entity} {self.entity_id} {self.op}"
