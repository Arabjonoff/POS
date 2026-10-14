import pytest
from django.core.exceptions import ValidationError
from django.db.models import ProtectedError

from apps.tenants.models import DEFAULT_TIMEZONE, Locale, Store, Tenant
from apps.tenants.signals import create_default_store

pytestmark = pytest.mark.django_db


def test_tenant_defaults(tenant):
    assert tenant.timezone == DEFAULT_TIMEZONE
    assert tenant.default_locale == Locale.UZ_LATN
    assert tenant.is_blocked is False
    assert tenant.id.version == 7


def test_new_tenant_gets_one_store():
    tenant = Tenant.objects.create(
        name="Baraka", owner_phone="+998901112233", address="Chilonzor 5"
    )
    stores = list(Store.objects.filter(tenant=tenant))
    assert len(stores) == 1
    assert stores[0].name == "Baraka"
    assert stores[0].address == "Chilonzor 5"
    assert stores[0].tenant_id == tenant.id


def test_saving_existing_tenant_does_not_add_store(tenant):
    tenant.name = "Yangi nom"
    tenant.save()
    assert tenant.stores.count() == 1


def test_raw_save_does_not_create_store(tenant):
    create_default_store(sender=Tenant, instance=tenant, created=True, raw=True)
    assert tenant.stores.count() == 1


def test_owner_phone_must_be_normalized():
    tenant = Tenant(name="X", owner_phone="90 123 45 67")
    with pytest.raises(ValidationError) as exc:
        tenant.full_clean()
    assert "owner_phone" in exc.value.message_dict


def test_store_phone_optional_but_validated(tenant):
    store = tenant.stores.get()
    store.full_clean()
    store.phone = "12345"
    with pytest.raises(ValidationError) as exc:
        store.full_clean()
    assert "phone" in exc.value.message_dict


def test_store_for_tenant_filters(tenant, other_tenant):
    own = Store.objects.for_tenant(tenant.id)
    assert list(own) == list(tenant.stores.all())
    assert not own.filter(tenant=other_tenant).exists()


def test_tenant_with_store_cannot_be_deleted(tenant):
    # Ma'lumot hech qachon o'chirilmaydi (subscription-billing.md).
    with pytest.raises(ProtectedError):
        tenant.delete()
