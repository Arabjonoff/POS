"""SaaS qatlami: Tenant (do'kon egasi / mijoz) va uning do'konlari (Store).

Obuna holati (trial/active/grace/readonly) saqlanmaydi — Subscription'dan hisoblanadi (T-013).
Bu yerda faqat platforma admini qo'lda qo'yadigan bloklash bor.
"""

from django.core.exceptions import ValidationError
from django.db import models
from django.utils.translation import gettext_lazy as _

from apps.core.models import TenantScopedModel, TimeStampedModel
from apps.core.phone import validate_phone

DEFAULT_TIMEZONE = "Asia/Tashkent"


class Locale(models.TextChoices):
    UZ_LATN = "uz", "O'zbekcha"
    UZ_CYRL = "uz-Cyrl", "Ўзбекча"
    RU = "ru", "Русский"


class Tenant(TimeStampedModel):
    name = models.CharField(_("nomi"), max_length=200)
    owner_phone = models.CharField(
        _("egasining telefoni"), max_length=13, validators=[validate_phone], db_index=True
    )
    address = models.CharField(_("manzil"), max_length=300, blank=True)
    timezone = models.CharField(_("vaqt zonasi"), max_length=64, default=DEFAULT_TIMEZONE)
    default_locale = models.CharField(
        _("til"), max_length=8, choices=Locale.choices, default=Locale.UZ_LATN
    )
    notes = models.TextField(_("izoh"), blank=True)
    is_blocked = models.BooleanField(_("bloklangan"), default=False)
    blocked_reason = models.CharField(_("bloklash sababi"), max_length=300, blank=True)

    class Meta:
        verbose_name = _("tenant")
        verbose_name_plural = _("tenantlar")
        ordering = ["-created_at"]

    def __str__(self):
        return self.name


def validate_tin(value: str) -> None:
    """STIR — 9 raqam (yuridik shaxs), JShShIR — 14 raqam (YaTT)."""
    if value and not (value.isascii() and value.isdigit() and len(value) in (9, 14)):
        raise ValidationError(_("STIR 9 raqam yoki JShShIR 14 raqam bo'lishi kerak."))


class Store(TenantScopedModel):
    """Do'kon. MVP'da har tenantda bittasi (qaror 0004), model kelajak filiallari uchun."""

    tenant = models.ForeignKey(
        Tenant,
        on_delete=models.PROTECT,
        related_name="stores",
        verbose_name=_("tenant"),
    )
    name = models.CharField(_("nomi"), max_length=200)
    address = models.CharField(_("manzil"), max_length=300, blank=True)
    phone = models.CharField(_("telefon"), max_length=13, blank=True, validators=[validate_phone])
    receipt_header = models.TextField(_("chek sarlavhasi"), blank=True)
    receipt_footer = models.TextField(_("chek pastki matni"), blank=True)
    # Chek rekvizitlari (T-104b). Faqat kiritilgani chekda chiqadi — soliq
    # raqami hech qachon taxmin qilinmaydi va o'zidan to'ldirilmaydi.
    legal_name = models.CharField(_("yuridik nomi"), max_length=200, blank=True)
    tin = models.CharField(
        _("STIR / JShShIR"), max_length=14, blank=True, validators=[validate_tin]
    )
    # Logotip: kichraytirilgan kulrang PNG (base64), kassada chop etish uchun.
    receipt_logo = models.TextField(_("chek logotipi"), blank=True)
    # Ko'rsat/yashir: {"show_logo": true, ...}. Noma'lum kalitlar e'tiborsiz,
    # yo'qlari — standart (migratsiyasiz kengayadi).
    receipt_options = models.JSONField(_("chek ko'rinishi"), default=dict, blank=True)

    class Meta:
        verbose_name = _("do'kon")
        verbose_name_plural = _("do'konlar")
        ordering = ["created_at"]

    def __str__(self):
        return self.name
