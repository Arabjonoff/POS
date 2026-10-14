"""Barcha biznes modellari uchun abstrakt asoslar."""

from django.db import models
from django.utils import timezone

from .ids import new_id


class UUIDModel(models.Model):
    """UUIDv7 primary key. Kassadan kelgan yozuvlarda id klientda yaratiladi."""

    id = models.UUIDField(primary_key=True, default=new_id)

    class Meta:
        abstract = True


class TimeStampedModel(UUIDModel):
    created_at = models.DateTimeField(default=timezone.now, db_index=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        abstract = True


class TenantQuerySet(models.QuerySet):
    def for_tenant(self, tenant_id):
        return self.filter(tenant_id=tenant_id)


class TenantScopedModel(TimeStampedModel):
    """Bitta tenant (do'kon egasi) ga tegishli yozuv. Har so'rov shu maydon bo'yicha cheklanadi."""

    tenant = models.ForeignKey(
        "tenants.Tenant",
        on_delete=models.PROTECT,
        related_name="+",
    )

    objects = TenantQuerySet.as_manager()

    class Meta:
        abstract = True


class SoftDeleteModel(models.Model):
    """Katalog jadvallari uchun yumshoq o'chirish (`deleted_at`)."""

    deleted_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        abstract = True

    @property
    def is_deleted(self) -> bool:
        return self.deleted_at is not None


class ImmutableRecordError(Exception):
    """O'zgarmas yozuvni tahrirlash yoki o'chirishga urinish (qoida 3: faqat teskari yozuv)."""


class AppendOnlyModel(models.Model):
    """Faqat qo'shiladigan yozuv: `save()` faqat yangi obyekt uchun, `delete()` taqiqlangan."""

    class Meta:
        abstract = True

    def save(self, *args, **kwargs):
        if not self._state.adding:
            raise ImmutableRecordError(f"{type(self).__name__} is immutable; create a reversal")
        super().save(*args, **kwargs)

    def delete(self, *args, **kwargs):
        raise ImmutableRecordError(f"{type(self).__name__} cannot be deleted; create a reversal")
