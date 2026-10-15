"""Mijozlar va nasiya daftari (customers-api.md). Balans = DebtEntry yig'indisi."""

from django.conf import settings
from django.db import models
from django.db.models import Q
from django.utils import timezone
from django.utils.translation import gettext_lazy as _

from apps.core.models import AppendOnlyModel, SoftDeleteModel, TenantScopedModel
from apps.core.phone import validate_phone


class Customer(TenantScopedModel, SoftDeleteModel):
    tenant = models.ForeignKey(
        "tenants.Tenant",
        on_delete=models.PROTECT,
        related_name="customers",
        verbose_name=_("tenant"),
    )
    full_name = models.CharField(_("ism"), max_length=200)
    phone = models.CharField(
        _("telefon"), max_length=13, blank=True, validators=[validate_phone], db_index=True
    )
    note = models.TextField(_("izoh"), blank=True)
    # null — cheklovsiz, 0 — nasiya berilmaydi.
    debt_limit_tiyin = models.BigIntegerField(_("qarz limiti (tiyin)"), null=True, blank=True)

    class Meta:
        verbose_name = _("mijoz")
        verbose_name_plural = _("mijozlar")
        ordering = ["full_name"]
        constraints = [
            models.CheckConstraint(
                name="customer_debt_limit_not_negative",
                condition=Q(debt_limit_tiyin__isnull=True) | Q(debt_limit_tiyin__gte=0),
            ),
        ]

    def __str__(self):
        return self.full_name


class DebtType(models.TextChoices):
    SALE = "sale", _("savdo")
    PAYMENT = "payment", _("to'lov")
    REFUND = "refund", _("qaytarish")
    ADJUSTMENT = "adjustment", _("tuzatish")
    # Mijoz tizimga qo'shilgandagi mavjud qarz (+) yoki avans (−) — T-103.
    OPENING = "opening", _("boshlang'ich balans")


class PaymentMethod(models.TextChoices):
    CASH = "cash", _("naqd")
    CARD = "card", _("karta")


class DebtEntry(AppendOnlyModel, TenantScopedModel):
    """Qarz harakati: + qarz oshdi, − kamaydi. Faqat qo'shiladi; xato — teskari yozuv bilan."""

    tenant = models.ForeignKey(
        "tenants.Tenant", on_delete=models.PROTECT, related_name="+", verbose_name=_("tenant")
    )
    customer = models.ForeignKey(
        Customer, on_delete=models.PROTECT, related_name="debt_entries", verbose_name=_("mijoz")
    )
    amount_tiyin = models.BigIntegerField(_("summa (tiyin, ±)"))
    type = models.CharField(_("turi"), max_length=16, choices=DebtType.choices)
    method = models.CharField(
        _("to'lov usuli"), max_length=8, choices=PaymentMethod.choices, blank=True
    )
    # Savdo T-017 da; sinxronda savdo keyinroq kelishi mumkin, shuning uchun FK emas.
    sale_id = models.UUIDField(_("savdo id"), null=True, blank=True, db_index=True)
    # Kassada qabul qilingan to'lov qaysi smenada — naqd bo'lsa kutilgan naqdga qo'shiladi.
    shift = models.ForeignKey(
        "sales.Shift",
        on_delete=models.PROTECT,
        null=True,
        blank=True,
        related_name="debt_entries",
        verbose_name=_("smena"),
    )
    note = models.TextField(_("izoh"), blank=True)
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.PROTECT,
        null=True,
        blank=True,
        related_name="+",
        verbose_name=_("kim"),
    )
    at = models.DateTimeField(_("vaqt"), default=timezone.now, db_index=True)

    class Meta:
        verbose_name = _("qarz yozuvi")
        verbose_name_plural = _("qarz yozuvlari")
        ordering = ["-at", "-id"]
        indexes = [models.Index(fields=["tenant", "customer"])]
        constraints = [
            models.CheckConstraint(name="debt_amount_not_zero", condition=~Q(amount_tiyin=0)),
            models.CheckConstraint(
                name="debt_sign_matches_type",
                condition=Q(type="sale", amount_tiyin__gt=0)
                | Q(type__in=["payment", "refund"], amount_tiyin__lt=0)
                | Q(type__in=["adjustment", "opening"]),
            ),
            models.CheckConstraint(
                name="debt_method_only_for_payment",
                condition=Q(type="payment", method__in=["cash", "card"])
                | (~Q(type="payment") & Q(method="")),
            ),
            models.CheckConstraint(
                name="debt_sale_id_for_sale_and_refund",
                condition=Q(type__in=["sale", "refund"], sale_id__isnull=False)
                | Q(type__in=["payment", "adjustment", "opening"]),
            ),
            # Boshlang'ich balans savdo ham, smena puli ham emas (Z-hisobot va tushumga kirmaydi).
            models.CheckConstraint(
                name="debt_opening_no_sale_no_shift",
                condition=~Q(type="opening") | Q(sale_id__isnull=True, shift__isnull=True),
            ),
            # Bitta mijozga bitta boshlang'ich balans — tahrirda ikki marta qo'shilmaydi.
            models.UniqueConstraint(
                fields=["customer"],
                condition=Q(type="opening"),
                name="debt_one_opening_per_customer",
            ),
        ]

    def __str__(self):
        return f"{self.customer_id} {self.amount_tiyin:+d} ({self.type})"
