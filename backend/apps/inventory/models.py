"""Ombor: qoldiq harakatlari (manba), qoldiq keshi, kirim, inventarizatsiya (inventory-api.md)."""

from django.conf import settings
from django.core.validators import MinValueValidator
from django.db import models
from django.db.models import Q
from django.utils import timezone
from django.utils.translation import gettext_lazy as _

from apps.core.models import AppendOnlyModel, SoftDeleteModel, TenantScopedModel


class Supplier(TenantScopedModel, SoftDeleteModel):
    tenant = models.ForeignKey(
        "tenants.Tenant",
        on_delete=models.PROTECT,
        related_name="suppliers",
        verbose_name=_("tenant"),
    )
    name = models.CharField(_("nomi"), max_length=200)
    phone = models.CharField(_("telefon"), max_length=32, blank=True)
    note = models.TextField(_("izoh"), blank=True)

    class Meta:
        verbose_name = _("yetkazib beruvchi")
        verbose_name_plural = _("yetkazib beruvchilar")
        ordering = ["name"]

    def __str__(self):
        return self.name


class MovementType(models.TextChoices):
    RECEIPT = "receipt", _("kirim")
    SALE = "sale", _("savdo")
    REFUND = "refund", _("qaytarish")
    ADJUSTMENT = "adjustment", _("tuzatish")
    INVENTORY = "inventory", _("inventarizatsiya")


class StockMovement(AppendOnlyModel, TenantScopedModel):
    """Qoldiqning yagona manbasi. Faqat qo'shiladi; xato — teskari harakat bilan tuzatiladi."""

    tenant = models.ForeignKey(
        "tenants.Tenant", on_delete=models.PROTECT, related_name="+", verbose_name=_("tenant")
    )
    product = models.ForeignKey(
        "catalog.Product",
        on_delete=models.PROTECT,
        related_name="stock_movements",
        verbose_name=_("tovar"),
    )
    store = models.ForeignKey(
        "tenants.Store", on_delete=models.PROTECT, related_name="+", verbose_name=_("do'kon")
    )
    qty_milli = models.BigIntegerField(_("miqdor (milli, ±)"))
    type = models.CharField(_("turi"), max_length=16, choices=MovementType.choices)
    ref_type = models.CharField(_("hujjat turi"), max_length=32, blank=True)
    ref_id = models.UUIDField(_("hujjat id"), null=True, blank=True)
    at = models.DateTimeField(_("vaqt"), default=timezone.now, db_index=True)
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.PROTECT,
        null=True,
        related_name="+",
        verbose_name=_("kim"),
    )

    class Meta:
        verbose_name = _("qoldiq harakati")
        verbose_name_plural = _("qoldiq harakatlari")
        ordering = ["-at", "-id"]
        indexes = [models.Index(fields=["tenant", "product", "store"])]
        constraints = [
            models.CheckConstraint(name="movement_qty_not_zero", condition=~Q(qty_milli=0)),
        ]

    def __str__(self):
        return f"{self.product_id} {self.qty_milli:+d} ({self.type})"


class ProductStock(models.Model):
    """Qoldiq keshi. Har harakat bilan bir tranzaksiyada yangilanadi; manba — StockMovement."""

    tenant = models.ForeignKey(
        "tenants.Tenant", on_delete=models.PROTECT, related_name="+", verbose_name=_("tenant")
    )
    product = models.ForeignKey(
        "catalog.Product", on_delete=models.PROTECT, related_name="stock", verbose_name=_("tovar")
    )
    store = models.ForeignKey(
        "tenants.Store", on_delete=models.PROTECT, related_name="+", verbose_name=_("do'kon")
    )
    qty_milli = models.BigIntegerField(_("qoldiq (milli)"), default=0)
    updated_at = models.DateTimeField(_("yangilangan"), auto_now=True)

    class Meta:
        verbose_name = _("qoldiq")
        verbose_name_plural = _("qoldiqlar")
        constraints = [
            models.UniqueConstraint(fields=["product", "store"], name="stock_product_store"),
        ]
        indexes = [models.Index(fields=["tenant", "store"])]

    def __str__(self):
        return f"{self.product_id}: {self.qty_milli}"


class DocumentStatus(models.TextChoices):
    DRAFT = "draft", _("qoralama")
    POSTED = "posted", _("tasdiqlangan")


class StockReceipt(TenantScopedModel):
    tenant = models.ForeignKey(
        "tenants.Tenant",
        on_delete=models.PROTECT,
        related_name="stock_receipts",
        verbose_name=_("tenant"),
    )
    store = models.ForeignKey(
        "tenants.Store", on_delete=models.PROTECT, related_name="+", verbose_name=_("do'kon")
    )
    supplier = models.ForeignKey(
        Supplier,
        on_delete=models.PROTECT,
        null=True,
        blank=True,
        related_name="receipts",
        verbose_name=_("yetkazib beruvchi"),
    )
    number = models.PositiveIntegerField(_("raqam"))
    status = models.CharField(
        _("holat"), max_length=16, choices=DocumentStatus.choices, default=DocumentStatus.DRAFT
    )
    total_cost_tiyin = models.BigIntegerField(_("jami tannarx (tiyin)"), default=0)
    note = models.TextField(_("izoh"), blank=True)
    reverses = models.OneToOneField(
        "self",
        on_delete=models.PROTECT,
        null=True,
        blank=True,
        related_name="reversal",
        verbose_name=_("teskari qilingan kirim"),
    )
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.PROTECT,
        null=True,
        related_name="+",
        verbose_name=_("yaratgan"),
    )
    posted_at = models.DateTimeField(_("tasdiqlangan vaqt"), null=True, blank=True)
    posted_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.PROTECT,
        null=True,
        blank=True,
        related_name="+",
        verbose_name=_("tasdiqlagan"),
    )

    class Meta:
        verbose_name = _("kirim")
        verbose_name_plural = _("kirimlar")
        ordering = ["-number"]
        constraints = [
            models.UniqueConstraint(fields=["tenant", "number"], name="receipt_number_per_tenant"),
        ]

    def __str__(self):
        return f"K-{self.number}"


class StockReceiptItem(TenantScopedModel):
    tenant = models.ForeignKey(
        "tenants.Tenant", on_delete=models.PROTECT, related_name="+", verbose_name=_("tenant")
    )
    receipt = models.ForeignKey(
        StockReceipt, on_delete=models.CASCADE, related_name="items", verbose_name=_("kirim")
    )
    product = models.ForeignKey(
        "catalog.Product", on_delete=models.PROTECT, related_name="+", verbose_name=_("tovar")
    )
    # Teskari kirimda manfiy.
    qty_milli = models.BigIntegerField(_("miqdor (milli)"))
    cost_price_tiyin = models.BigIntegerField(
        _("tannarx (tiyin)"), validators=[MinValueValidator(0)]
    )
    new_sell_price_tiyin = models.BigIntegerField(
        _("yangi sotish narxi (tiyin)"), null=True, blank=True, validators=[MinValueValidator(0)]
    )
    line_total_tiyin = models.BigIntegerField(_("qator jami (tiyin)"), default=0)

    class Meta:
        verbose_name = _("kirim qatori")
        verbose_name_plural = _("kirim qatorlari")
        ordering = ["created_at"]


class InventoryScope(models.TextChoices):
    ALL = "all", _("hammasi")
    CATEGORY = "category", _("kategoriya")


class InventoryCount(TenantScopedModel):
    tenant = models.ForeignKey(
        "tenants.Tenant",
        on_delete=models.PROTECT,
        related_name="inventory_counts",
        verbose_name=_("tenant"),
    )
    store = models.ForeignKey(
        "tenants.Store", on_delete=models.PROTECT, related_name="+", verbose_name=_("do'kon")
    )
    status = models.CharField(
        _("holat"), max_length=16, choices=DocumentStatus.choices, default=DocumentStatus.DRAFT
    )
    scope = models.CharField(
        _("qamrov"), max_length=16, choices=InventoryScope.choices, default=InventoryScope.ALL
    )
    category = models.ForeignKey(
        "catalog.Category",
        on_delete=models.PROTECT,
        null=True,
        blank=True,
        related_name="+",
        verbose_name=_("kategoriya"),
    )
    note = models.TextField(_("izoh"), blank=True)
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.PROTECT,
        null=True,
        related_name="+",
        verbose_name=_("yaratgan"),
    )
    posted_at = models.DateTimeField(_("tasdiqlangan vaqt"), null=True, blank=True)
    posted_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.PROTECT,
        null=True,
        blank=True,
        related_name="+",
        verbose_name=_("tasdiqlagan"),
    )

    class Meta:
        verbose_name = _("inventarizatsiya")
        verbose_name_plural = _("inventarizatsiyalar")
        ordering = ["-created_at"]


class InventoryCountItem(TenantScopedModel):
    tenant = models.ForeignKey(
        "tenants.Tenant", on_delete=models.PROTECT, related_name="+", verbose_name=_("tenant")
    )
    count = models.ForeignKey(
        InventoryCount,
        on_delete=models.CASCADE,
        related_name="items",
        verbose_name=_("inventarizatsiya"),
    )
    product = models.ForeignKey(
        "catalog.Product", on_delete=models.PROTECT, related_name="+", verbose_name=_("tovar")
    )
    # Tasdiqlash paytidagi qoldiq (keshdan); qoralamada null.
    expected_milli = models.BigIntegerField(_("kutilgan (milli)"), null=True, blank=True)
    counted_milli = models.BigIntegerField(_("sanalgan (milli)"), validators=[MinValueValidator(0)])

    class Meta:
        verbose_name = _("inventarizatsiya qatori")
        verbose_name_plural = _("inventarizatsiya qatorlari")
        ordering = ["created_at"]
        constraints = [
            models.UniqueConstraint(fields=["count", "product"], name="inventory_item_unique"),
        ]
