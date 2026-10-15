"""Katalog: birliklar, kategoriyalar, tovarlar, shtrix-kodlar (data-model.md, catalog-api.md).

Pul — `*_tiyin` (bigint), miqdor — `*_milli` (bigint). Float yo'q.
"""

from django.conf import settings
from django.core.validators import MinValueValidator, RegexValidator
from django.db import models
from django.db.models import Q
from django.utils import timezone
from django.utils.translation import gettext_lazy as _

from apps.core.models import SoftDeleteModel, TenantScopedModel

PLU_LENGTH = 5
plu_validator = RegexValidator(rf"^[0-9]{{{PLU_LENGTH}}}$", _("PLU kodi 5 raqam bo'lishi kerak."))
ikpu_validator = RegexValidator(r"^[0-9]{17}$", _("IKPU kodi 17 raqam bo'lishi kerak."))

# Yangi tenantga avtomatik birliklar: (code, is_fractional). Nomi — klient tarjima faylida.
STANDARD_UNITS = (
    ("pcs", False),
    ("kg", True),
    ("g", False),
    ("l", True),
    ("m", True),
    ("pack", False),
)


class Unit(TenantScopedModel, SoftDeleteModel):
    tenant = models.ForeignKey(
        "tenants.Tenant", on_delete=models.PROTECT, related_name="units", verbose_name=_("tenant")
    )
    code = models.CharField(_("kod"), max_length=16)
    name = models.CharField(_("nomi"), max_length=50, blank=True)
    is_fractional = models.BooleanField(_("kasrli"), default=False)

    class Meta:
        verbose_name = _("birlik")
        verbose_name_plural = _("birliklar")
        ordering = ["created_at"]
        constraints = [
            models.UniqueConstraint(
                fields=["tenant", "code"],
                condition=Q(deleted_at__isnull=True),
                name="unit_code_per_tenant",
            ),
        ]

    def __str__(self):
        return self.name or self.code


class Category(TenantScopedModel, SoftDeleteModel):
    tenant = models.ForeignKey(
        "tenants.Tenant",
        on_delete=models.PROTECT,
        related_name="categories",
        verbose_name=_("tenant"),
    )
    name = models.CharField(_("nomi"), max_length=100)
    parent = models.ForeignKey(
        "self",
        on_delete=models.PROTECT,
        null=True,
        blank=True,
        related_name="children",
        verbose_name=_("yuqori kategoriya"),
    )
    sort = models.IntegerField(_("tartib"), default=0)
    color = models.CharField(_("rang (palitra kaliti)"), max_length=16, blank=True)

    class Meta:
        verbose_name = _("kategoriya")
        verbose_name_plural = _("kategoriyalar")
        ordering = ["sort", "name"]

    def __str__(self):
        return self.name


class Product(TenantScopedModel, SoftDeleteModel):
    tenant = models.ForeignKey(
        "tenants.Tenant",
        on_delete=models.PROTECT,
        related_name="products",
        verbose_name=_("tenant"),
    )
    name = models.CharField(_("nomi"), max_length=200)
    category = models.ForeignKey(
        Category,
        on_delete=models.PROTECT,
        null=True,
        blank=True,
        related_name="products",
        verbose_name=_("kategoriya"),
    )
    unit = models.ForeignKey(
        Unit, on_delete=models.PROTECT, related_name="products", verbose_name=_("birlik")
    )
    sell_price_tiyin = models.BigIntegerField(
        _("sotish narxi (tiyin)"), validators=[MinValueValidator(0)]
    )
    cost_price_tiyin = models.BigIntegerField(
        _("tannarx (tiyin)"), default=0, validators=[MinValueValidator(0)]
    )
    is_weighted = models.BooleanField(_("vaznli"), default=False)
    # null (bo'sh satr emas): unique cheklov NULL'larni e'tiborsiz qoldiradi.
    plu_code = models.CharField(  # noqa: DJ001
        _("PLU"), max_length=PLU_LENGTH, null=True, blank=True, validators=[plu_validator]
    )
    min_stock_milli = models.BigIntegerField(
        _("minimal qoldiq (milli)"), default=0, validators=[MinValueValidator(0)]
    )
    ikpu_code = models.CharField(_("IKPU"), max_length=17, blank=True, validators=[ikpu_validator])
    quick_button = models.BooleanField(_("tez tugma"), default=False)
    # Joriy rasm (T-105): faqat rasm yuklash endpoint'i o'zgartiradi — tovar
    # hodisasi (`product.upserted`) unga tegmaydi, eski snapshot rasmni o'chirmaydi.
    image = models.ForeignKey(
        "ProductImage",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="+",
        verbose_name=_("rasm"),
    )
    is_active = models.BooleanField(_("faol"), default=True)

    class Meta:
        verbose_name = _("tovar")
        verbose_name_plural = _("tovarlar")
        ordering = ["name"]
        indexes = [models.Index(fields=["tenant", "name"])]
        constraints = [
            models.CheckConstraint(
                name="product_prices_not_negative",
                condition=Q(sell_price_tiyin__gte=0) & Q(cost_price_tiyin__gte=0),
            ),
            models.UniqueConstraint(
                fields=["tenant", "plu_code"],
                condition=Q(plu_code__isnull=False, is_active=True, deleted_at__isnull=True),
                name="product_plu_per_tenant",
            ),
        ]

    def __str__(self):
        return self.name


class ProductBarcode(TenantScopedModel, SoftDeleteModel):
    tenant = models.ForeignKey(
        "tenants.Tenant", on_delete=models.PROTECT, related_name="+", verbose_name=_("tenant")
    )
    product = models.ForeignKey(
        Product, on_delete=models.PROTECT, related_name="barcodes", verbose_name=_("tovar")
    )
    barcode = models.CharField(_("shtrix-kod"), max_length=64)
    is_primary = models.BooleanField(_("asosiy"), default=False)

    class Meta:
        verbose_name = _("shtrix-kod")
        verbose_name_plural = _("shtrix-kodlar")
        ordering = ["-is_primary", "created_at"]
        constraints = [
            models.UniqueConstraint(
                fields=["tenant", "barcode"],
                condition=Q(deleted_at__isnull=True),
                name="barcode_per_tenant",
            ),
        ]

    def __str__(self):
        return self.barcode


class PriceHistory(TenantScopedModel):
    """Narx o'zgarishlari jurnali (o'zgarmas)."""

    tenant = models.ForeignKey(
        "tenants.Tenant", on_delete=models.PROTECT, related_name="+", verbose_name=_("tenant")
    )
    product = models.ForeignKey(
        Product, on_delete=models.PROTECT, related_name="price_history", verbose_name=_("tovar")
    )
    sell_price_tiyin = models.BigIntegerField(_("sotish narxi (tiyin)"))
    cost_price_tiyin = models.BigIntegerField(_("tannarx (tiyin)"))
    changed_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.PROTECT,
        null=True,
        related_name="+",
        verbose_name=_("o'zgartirgan"),
    )
    at = models.DateTimeField(_("vaqt"), default=timezone.now)

    class Meta:
        verbose_name = _("narx tarixi")
        verbose_name_plural = _("narx tarixi")
        ordering = ["-at"]


class ProductImport(TenantScopedModel):
    """Excel/CSV import (T-051, `product-import.md`): o'qilgan jadval va natija.

    Fayl o'zi saqlanmaydi — faqat matn katakchalari (`rows`, sarlavha bilan).
    """

    class Status(models.TextChoices):
        UPLOADED = "uploaded", _("yuklangan")
        APPLIED = "applied", _("qo'llangan")

    tenant = models.ForeignKey(
        "tenants.Tenant", on_delete=models.CASCADE, related_name="+", verbose_name=_("tenant")
    )
    device = models.ForeignKey(
        "devices.Device", on_delete=models.CASCADE, related_name="+", verbose_name=_("qurilma")
    )
    filename = models.CharField(_("fayl nomi"), max_length=255, blank=True)
    rows = models.JSONField(_("qatorlar"), default=list)
    status = models.CharField(
        _("holat"), max_length=16, choices=Status.choices, default=Status.UPLOADED
    )
    result = models.JSONField(_("natija"), default=dict, blank=True)

    class Meta:
        verbose_name = _("tovar importi")
        verbose_name_plural = _("tovar importlari")


def _image_path(instance, filename: str) -> str:
    return f"t/{instance.tenant_id}/p/{instance.pk}.jpg"


def _thumb_path(instance, filename: str) -> str:
    return f"t/{instance.tenant_id}/p/{instance.pk}_t.jpg"


class ProductImage(TenantScopedModel, SoftDeleteModel):
    """Mahsulot rasmi (T-105). O'zgarmas obyekt: almashtirish — yangi id (kassada
    yaratilgan UUIDv7), shuning uchun fayl va keshni abadiy saqlash mumkin."""

    tenant = models.ForeignKey(
        "tenants.Tenant", on_delete=models.PROTECT, related_name="+", verbose_name=_("tenant")
    )
    product = models.ForeignKey(
        Product, on_delete=models.PROTECT, related_name="images", verbose_name=_("tovar")
    )
    file = models.ImageField(_("rasm"), upload_to=_image_path)
    thumb = models.ImageField(_("kichik rasm"), upload_to=_thumb_path)
    sha256 = models.CharField(_("sha256"), max_length=64)
    width = models.PositiveIntegerField(_("kenglik"))
    height = models.PositiveIntegerField(_("balandlik"))
    bytes = models.PositiveIntegerField(_("hajm"))
    uploaded_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.PROTECT,
        null=True,
        blank=True,
        related_name="+",
        verbose_name=_("yuklagan"),
    )

    class Meta:
        verbose_name = _("tovar rasmi")
        verbose_name_plural = _("tovar rasmlari")
