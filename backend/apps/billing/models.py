"""Tariflar va obuna (SaaS qatlami, faqat serverda). Pul — tiyin (`int`)."""

from django.conf import settings
from django.core.validators import MinValueValidator
from django.db import models
from django.utils import timezone
from django.utils.translation import gettext_lazy as _

from apps.core.models import TimeStampedModel

from .status import Status


class Plan(TimeStampedModel):
    name = models.CharField(_("nomi"), max_length=100)
    price_tiyin_per_month = models.BigIntegerField(
        _("oylik narx (tiyin)"), validators=[MinValueValidator(0)]
    )
    max_devices = models.PositiveIntegerField(_("qurilmalar chegarasi"), default=1)
    max_users = models.PositiveIntegerField(_("xodimlar chegarasi"), default=3)
    features = models.JSONField(_("imkoniyatlar"), default=dict, blank=True)
    is_active = models.BooleanField(_("faol"), default=True)
    sort = models.PositiveIntegerField(_("tartib"), default=0)

    class Meta:
        verbose_name = _("tarif")
        verbose_name_plural = _("tariflar")
        ordering = ["sort", "price_tiyin_per_month"]
        constraints = [
            models.CheckConstraint(
                name="plan_price_not_negative", condition=models.Q(price_tiyin_per_month__gte=0)
            ),
        ]

    def __str__(self):
        return self.name


class Subscription(TimeStampedModel):
    tenant = models.OneToOneField(
        "tenants.Tenant",
        on_delete=models.PROTECT,
        related_name="subscription",
        verbose_name=_("tenant"),
    )
    plan = models.ForeignKey(Plan, on_delete=models.PROTECT, verbose_name=_("tarif"))
    trial_ends_at = models.DateField(_("sinov tugashi (birinchi to'lanmagan kun)"), null=True)
    paid_until = models.DateField(_("to'langan oxirgi kun"), null=True, blank=True)
    grace_days = models.PositiveSmallIntegerField(_("imtiyozli kunlar"), default=3)
    offline_days = models.PositiveSmallIntegerField(_("oflayn ishlash kunlari"), default=7)
    # Kesh: manba — status.compute_status. `update_subscriptions` kunlik yangilaydi.
    status = models.CharField(
        _("holat"), max_length=16, choices=Status.choices, default=Status.TRIAL, db_index=True
    )
    status_changed_at = models.DateTimeField(_("holat o'zgargan vaqt"), default=timezone.now)

    class Meta:
        verbose_name = _("obuna")
        verbose_name_plural = _("obunalar")

    def __str__(self):
        return f"{self.tenant} — {self.plan}"


class PaymentMethod(models.TextChoices):
    CASH = "cash", _("naqd")
    TRANSFER = "transfer", _("o'tkazma")
    CARD = "card", _("karta")
    OTHER = "other", _("boshqa")


class ImmutableRecordError(Exception):
    pass


class SubscriptionPayment(TimeStampedModel):
    """O'zgarmas yozuv. Bekor qilish — teskari yozuv (`reverses`), manfiy summa va oy bilan."""

    tenant = models.ForeignKey(
        "tenants.Tenant",
        on_delete=models.PROTECT,
        related_name="subscription_payments",
        verbose_name=_("tenant"),
    )
    amount_tiyin = models.BigIntegerField(_("summa (tiyin)"))
    months = models.SmallIntegerField(_("oylar"))
    paid_at = models.DateTimeField(_("to'langan vaqt"), default=timezone.now)
    period_from = models.DateField(_("davr boshi"))
    period_to = models.DateField(_("davr oxiri"))
    previous_paid_until = models.DateField(_("oldingi to'langan oxirgi kun"), null=True)
    method = models.CharField(_("usul"), max_length=16, choices=PaymentMethod.choices)
    note = models.CharField(_("izoh"), max_length=300, blank=True)
    recorded_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.PROTECT,
        null=True,
        related_name="+",
        verbose_name=_("kiritgan"),
    )
    reverses = models.OneToOneField(
        "self",
        on_delete=models.PROTECT,
        null=True,
        blank=True,
        related_name="reversal",
        verbose_name=_("bekor qilingan to'lov"),
    )

    class Meta:
        verbose_name = _("obuna to'lovi")
        verbose_name_plural = _("obuna to'lovlari")
        ordering = ["-paid_at"]

    def __str__(self):
        return f"{self.tenant}: {self.amount_tiyin} tiyin, {self.months} oy"

    def save(self, *args, **kwargs):
        if not self._state.adding:
            raise ImmutableRecordError("subscription payment is immutable; create a reversal")
        super().save(*args, **kwargs)

    def delete(self, *args, **kwargs):
        raise ImmutableRecordError("subscription payment cannot be deleted; create a reversal")
