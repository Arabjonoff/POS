"""Model o'zgarganda ChangeLog yozuvi. `update()` signal bermaydi — `ProductStock` uchun
yozuv `apps.inventory.services.record_movement` ichida."""

from django.db.models.signals import post_delete, post_save
from django.dispatch import receiver

from apps.accounts.models import User
from apps.catalog.models import Category, Product, ProductBarcode, Unit
from apps.customers.models import Customer, DebtEntry
from apps.inventory.models import ProductStock, Supplier
from apps.tenants.models import Store

from .changes import log_change, op_for
from .models import ChangeOp

ENTITY_BY_MODEL = {
    Unit: "unit",
    Category: "category",
    Product: "product",
    Supplier: "supplier",
    Customer: "customer",
    Store: "store",
    DebtEntry: "debt_entry",
}


def _saved(sender, instance, raw=False, **kwargs):
    if raw:
        return
    log_change(instance.tenant_id, ENTITY_BY_MODEL[sender], instance.pk, op_for(instance))


def _deleted(sender, instance, **kwargs):
    log_change(instance.tenant_id, ENTITY_BY_MODEL[sender], instance.pk, ChangeOp.DELETE)


for _model in ENTITY_BY_MODEL:
    post_save.connect(_saved, sender=_model, dispatch_uid=f"sync-save-{_model.__name__}")
    post_delete.connect(_deleted, sender=_model, dispatch_uid=f"sync-delete-{_model.__name__}")


@receiver(post_save, sender=User, dispatch_uid="sync-save-User")
def _user_saved(sender, instance, raw=False, update_fields=None, **kwargs):
    # Kirishdagi `last_login` yangilanishi kassaga kerak emas.
    if raw or (update_fields and set(update_fields) <= {"last_login"}):
        return
    log_change(instance.tenant_id, "user", instance.pk)


@receiver(post_save, sender=ProductBarcode, dispatch_uid="sync-save-ProductBarcode")
@receiver(post_delete, sender=ProductBarcode, dispatch_uid="sync-delete-ProductBarcode")
def _barcode_changed(sender, instance, raw=False, **kwargs):
    # Shtrix-kodlar tovar ichida keladi.
    if not raw:
        log_change(instance.tenant_id, "product", instance.product_id)


@receiver(post_save, sender=ProductStock, dispatch_uid="sync-save-ProductStock")
def _stock_saved(sender, instance, raw=False, **kwargs):
    if not raw:
        log_change(instance.tenant_id, "stock", instance.product_id)
