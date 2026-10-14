from django.db.models.signals import post_save
from django.dispatch import receiver

from apps.tenants.models import Tenant

from .models import STANDARD_UNITS, Unit


def create_standard_units(tenant) -> None:
    existing = set(Unit.objects.filter(tenant=tenant).values_list("code", flat=True))
    Unit.objects.bulk_create(
        Unit(tenant=tenant, code=code, is_fractional=fractional)
        for code, fractional in STANDARD_UNITS
        if code not in existing
    )


@receiver(post_save, sender=Tenant, dispatch_uid="catalog.create_standard_units")
def on_tenant_created(sender, instance, created, raw=False, **kwargs):
    if created and not raw:
        create_standard_units(instance)
