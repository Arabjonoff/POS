"""Smena, savdo, qaytarish, kassa puli (sales-api.md). Savdolar kassadan sinxron orqali keladi."""

from django.conf import settings
from django.db import models
from django.db.models import Q
from django.utils.translation import gettext_lazy as _

from apps.core.models import AppendOnlyModel, ImmutableRecordError, TenantScopedModel


def _user_fk(verbose_name, *, null=False):
    return models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.PROTECT,
        null=null,
        blank=null,
        related_name="+",
        verbose_name=verbose_name,
    )


class Shift(TenantScopedModel):
    """Bitta qurilma + kassir sessiyasi. Yopilguncha faqat yopish maydonlari o'zgaradi."""

    tenant = models.ForeignKey(
        "tenants.Tenant", on_delete=models.PROTECT, related_name="shifts", verbose_name=_("tenant")
    )
    store = models.ForeignKey(
        "tenants.Store", on_delete=models.PROTECT, related_name="+", verbose_name=_("do'kon")
    )
    device = models.ForeignKey(
        "devices.Device", on_delete=models.PROTECT, related_name="shifts", verbose_name=_("qurilma")
    )
    opened_by = _user_fk(_("ochgan"))
    opened_at = models.DateTimeField(_("ochilgan vaqt"))
    opening_cash_tiyin = models.BigIntegerField(_("boshlang'ich naqd (tiyin)"))
    closed_by = _user_fk(_("yopgan"), null=True)
    closed_at = models.DateTimeField(_("yopilgan vaqt"), null=True, blank=True)
    counted_cash_tiyin = models.BigIntegerField(_("sanalgan naqd (tiyin)"), null=True, blank=True)
    expected_cash_tiyin = models.BigIntegerField(_("kutilgan naqd (tiyin)"), null=True, blank=True)

    class Meta:
        verbose_name = _("smena")
        verbose_name_plural = _("smenalar")
        ordering = ["-opened_at", "-id"]
        constraints = [
            models.UniqueConstraint(
                fields=["device"],
                condition=Q(closed_at__isnull=True),
                name="one_open_shift_per_device",
            ),
            models.CheckConstraint(
                name="shift_opening_cash_not_negative", condition=Q(opening_cash_tiyin__gte=0)
            ),
            models.CheckConstraint(
                name="shift_closed_fields_together",
                condition=Q(closed_at__isnull=True, closed_by__isnull=True)
                | Q(closed_at__isnull=False, closed_by__isnull=False),
            ),
        ]

    @property
    def is_open(self) -> bool:
        return self.closed_at is None

    def __str__(self):
        return f"{self.device_id} {self.opened_at:%Y-%m-%d %H:%M}"


class SaleStatus(models.TextChoices):
    COMPLETED = "completed", _("yakunlangan")
    PARTIALLY_REFUNDED = "partially_refunded", _("qisman qaytarilgan")
    REFUNDED = "refunded", _("qaytarilgan")


class Sale(TenantScopedModel):
    """O'zgarmas; faqat `status` qaytarishda servis orqali yangilanadi."""

    tenant = models.ForeignKey(
        "tenants.Tenant", on_delete=models.PROTECT, related_name="sales", verbose_name=_("tenant")
    )
    store = models.ForeignKey(
        "tenants.Store", on_delete=models.PROTECT, related_name="+", verbose_name=_("do'kon")
    )
    shift = models.ForeignKey(
        Shift, on_delete=models.PROTECT, related_name="sales", verbose_name=_("smena")
    )
    device = models.ForeignKey(
        "devices.Device", on_delete=models.PROTECT, related_name="+", verbose_name=_("qurilma")
    )
    cashier = _user_fk(_("kassir"))
    approved_by = _user_fk(_("tasdiqlagan"), null=True)
    customer = models.ForeignKey(
        "customers.Customer",
        on_delete=models.PROTECT,
        null=True,
        blank=True,
        related_name="sales",
        verbose_name=_("mijoz"),
    )
    number = models.CharField(_("raqam"), max_length=32)
    subtotal_tiyin = models.BigIntegerField(_("oraliq jami (tiyin)"))
    discount_tiyin = models.BigIntegerField(_("chek chegirmasi (tiyin)"), default=0)
    total_tiyin = models.BigIntegerField(_("jami (tiyin)"))
    status = models.CharField(
        _("holat"), max_length=20, choices=SaleStatus.choices, default=SaleStatus.COMPLETED
    )
    sold_at = models.DateTimeField(_("sotilgan vaqt"), db_index=True)

    class Meta:
        verbose_name = _("savdo")
        verbose_name_plural = _("savdolar")
        ordering = ["-sold_at", "-id"]
        constraints = [
            models.UniqueConstraint(fields=["tenant", "number"], name="sale_number_per_tenant"),
            models.CheckConstraint(
                name="sale_amounts_valid",
                condition=Q(discount_tiyin__gte=0)
                & Q(discount_tiyin__lte=models.F("subtotal_tiyin"))
                & Q(total_tiyin=models.F("subtotal_tiyin") - models.F("discount_tiyin")),
            ),
        ]

    def save(self, *args, **kwargs):
        if not self._state.adding:
            fields = set(kwargs.get("update_fields") or ())
            if not fields or not fields <= {"status", "updated_at"}:
                raise ImmutableRecordError("Sale is immutable; only status may change")
        super().save(*args, **kwargs)

    def delete(self, *args, **kwargs):
        raise ImmutableRecordError("Sale cannot be deleted; create a refund")

    def __str__(self):
        return self.number


class SaleItem(AppendOnlyModel, TenantScopedModel):
    tenant = models.ForeignKey(
        "tenants.Tenant", on_delete=models.PROTECT, related_name="+", verbose_name=_("tenant")
    )
    sale = models.ForeignKey(
        Sale, on_delete=models.PROTECT, related_name="items", verbose_name=_("savdo")
    )
    product = models.ForeignKey(
        "catalog.Product", on_delete=models.PROTECT, related_name="+", verbose_name=_("tovar")
    )
    name_snapshot = models.CharField(_("nomi (savdo paytida)"), max_length=200)
    barcode_snapshot = models.CharField(_("shtrix-kod (savdo paytida)"), max_length=32, blank=True)
    qty_milli = models.BigIntegerField(_("miqdor (milli)"))
    price_tiyin = models.BigIntegerField(_("narx (tiyin)"))
    cost_tiyin = models.BigIntegerField(_("tannarx (tiyin)"))
    discount_tiyin = models.BigIntegerField(_("chegirma (tiyin)"), default=0)
    total_tiyin = models.BigIntegerField(_("jami (tiyin)"))

    class Meta:
        verbose_name = _("savdo qatori")
        verbose_name_plural = _("savdo qatorlari")
        ordering = ["created_at", "id"]
        constraints = [
            models.CheckConstraint(
                name="sale_item_values_valid",
                condition=Q(qty_milli__gt=0)
                & Q(price_tiyin__gte=0)
                & Q(cost_tiyin__gte=0)
                & Q(discount_tiyin__gte=0)
                & Q(total_tiyin__gte=0),
            ),
        ]


class PaymentMethod(models.TextChoices):
    CASH = "cash", _("naqd")
    CARD = "card", _("karta")
    DEBT = "debt", _("nasiya")


class SalePayment(AppendOnlyModel, TenantScopedModel):
    tenant = models.ForeignKey(
        "tenants.Tenant", on_delete=models.PROTECT, related_name="+", verbose_name=_("tenant")
    )
    sale = models.ForeignKey(
        Sale, on_delete=models.PROTECT, related_name="payments", verbose_name=_("savdo")
    )
    method = models.CharField(_("usul"), max_length=8, choices=PaymentMethod.choices)
    amount_tiyin = models.BigIntegerField(_("summa (tiyin)"))
    received_tiyin = models.BigIntegerField(_("olingan (tiyin)"), null=True, blank=True)
    change_tiyin = models.BigIntegerField(_("qaytim (tiyin)"), default=0)

    class Meta:
        verbose_name = _("savdo to'lovi")
        verbose_name_plural = _("savdo to'lovlari")
        ordering = ["created_at", "id"]
        constraints = [
            models.CheckConstraint(
                name="sale_payment_values_valid",
                condition=Q(amount_tiyin__gt=0)
                & (
                    Q(method="cash", received_tiyin__isnull=True, change_tiyin=0)
                    | Q(
                        method="cash",
                        received_tiyin__gte=models.F("amount_tiyin"),
                        change_tiyin=models.F("received_tiyin") - models.F("amount_tiyin"),
                    )
                    | Q(method__in=["card", "debt"], received_tiyin__isnull=True, change_tiyin=0)
                ),
            ),
        ]


class RefundMethod(models.TextChoices):
    CASH = "cash", _("naqd")
    DEBT = "debt", _("nasiyadan ayirish")


class Refund(AppendOnlyModel, TenantScopedModel):
    tenant = models.ForeignKey(
        "tenants.Tenant", on_delete=models.PROTECT, related_name="refunds", verbose_name=_("tenant")
    )
    sale = models.ForeignKey(
        Sale, on_delete=models.PROTECT, related_name="refunds", verbose_name=_("savdo")
    )
    shift = models.ForeignKey(
        Shift, on_delete=models.PROTECT, related_name="refunds", verbose_name=_("smena")
    )
    device = models.ForeignKey(
        "devices.Device", on_delete=models.PROTECT, related_name="+", verbose_name=_("qurilma")
    )
    cashier = _user_fk(_("kassir"))
    approved_by = _user_fk(_("tasdiqlagan"), null=True)
    reason = models.TextField(_("sabab"), blank=True)
    method = models.CharField(_("usul"), max_length=8, choices=RefundMethod.choices)
    total_tiyin = models.BigIntegerField(_("jami (tiyin)"))
    at = models.DateTimeField(_("vaqt"), db_index=True)

    class Meta:
        verbose_name = _("qaytarish")
        verbose_name_plural = _("qaytarishlar")
        ordering = ["-at", "-id"]
        constraints = [
            models.CheckConstraint(
                name="refund_total_not_negative", condition=Q(total_tiyin__gte=0)
            ),
        ]


class RefundItem(AppendOnlyModel, TenantScopedModel):
    tenant = models.ForeignKey(
        "tenants.Tenant", on_delete=models.PROTECT, related_name="+", verbose_name=_("tenant")
    )
    refund = models.ForeignKey(
        Refund, on_delete=models.PROTECT, related_name="items", verbose_name=_("qaytarish")
    )
    sale_item = models.ForeignKey(
        SaleItem, on_delete=models.PROTECT, related_name="refund_items", verbose_name=_("qator")
    )
    qty_milli = models.BigIntegerField(_("miqdor (milli)"))
    total_tiyin = models.BigIntegerField(_("jami (tiyin)"))

    class Meta:
        verbose_name = _("qaytarish qatori")
        verbose_name_plural = _("qaytarish qatorlari")
        ordering = ["created_at", "id"]
        constraints = [
            models.CheckConstraint(
                name="refund_item_values_valid",
                condition=Q(qty_milli__gt=0) & Q(total_tiyin__gte=0),
            ),
        ]


class CashMovementType(models.TextChoices):
    IN = "in", _("kiritish")
    OUT = "out", _("chiqarish")


class CashMovement(AppendOnlyModel, TenantScopedModel):
    tenant = models.ForeignKey(
        "tenants.Tenant", on_delete=models.PROTECT, related_name="+", verbose_name=_("tenant")
    )
    shift = models.ForeignKey(
        Shift, on_delete=models.PROTECT, related_name="cash_movements", verbose_name=_("smena")
    )
    type = models.CharField(_("turi"), max_length=4, choices=CashMovementType.choices)
    amount_tiyin = models.BigIntegerField(_("summa (tiyin)"))
    reason = models.TextField(_("sabab"), blank=True)
    created_by = _user_fk(_("kim"))
    at = models.DateTimeField(_("vaqt"), db_index=True)

    class Meta:
        verbose_name = _("kassa puli harakati")
        verbose_name_plural = _("kassa puli harakatlari")
        ordering = ["-at", "-id"]
        constraints = [
            models.CheckConstraint(name="cash_movement_positive", condition=Q(amount_tiyin__gt=0)),
        ]
