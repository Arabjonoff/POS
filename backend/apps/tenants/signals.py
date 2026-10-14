from django.db.models.signals import post_save
from django.dispatch import receiver

from .models import Store, Tenant


@receiver(post_save, sender=Tenant, dispatch_uid="tenants.create_default_store")
def create_default_store(sender, instance, created, raw=False, **kwargs):
    """Yangi tenantga bitta do'kon (nomi va manzili tenantdan). Fixture yuklashda (raw) emas."""
    if not created or raw:
        return
    Store.objects.create(tenant=instance, name=instance.name, address=instance.address)
