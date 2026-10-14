import pytest
from django.core.exceptions import ValidationError
from django.db import IntegrityError, transaction

from apps.accounts.models import Role, User

pytestmark = pytest.mark.django_db


def test_owner_has_password_and_uuid7(owner):
    assert owner.id.version == 7
    assert owner.has_usable_password()
    assert owner.can_use_password
    assert not owner.is_staff


def test_create_user_normalizes_phone(tenant):
    user = User.objects.create_user(
        phone="90 765 43 21",
        password="x-secret-1",
        tenant=tenant,
        role=Role.MANAGER,
        full_name="Menejer",
    )
    assert user.phone == "+998907654321"


def test_cashier_without_phone_and_password(make_user, tenant):
    cashier = make_user(tenant, role=Role.CASHIER, pin="4321")
    assert cashier.phone is None
    assert not cashier.has_usable_password()
    assert cashier.check_pin("4321")
    assert not cashier.check_pin("1234")


def test_two_cashiers_without_phone_allowed(make_user, tenant):
    make_user(tenant, role=Role.CASHIER)
    make_user(tenant, role=Role.CASHIER)
    assert User.objects.filter(tenant=tenant, role=Role.CASHIER).count() == 2


def test_phone_is_unique(make_user, tenant, other_tenant):
    make_user(tenant, phone="+998901110000")
    with pytest.raises(ValidationError):
        make_user(other_tenant, phone="+998901110000")


@pytest.mark.parametrize("role", [Role.OWNER, Role.MANAGER])
def test_login_roles_require_phone(tenant, role):
    with pytest.raises(ValidationError) as exc:
        User.objects.create_user(tenant=tenant, role=role, full_name="X", password="p-123456")
    assert "phone" in exc.value.message_dict


def test_staff_requires_tenant():
    with pytest.raises(ValidationError) as exc:
        User.objects.create_user(phone="+998901110001", role=Role.OWNER, full_name="X")
    assert "tenant" in exc.value.message_dict


def test_platform_admin_has_no_tenant_and_is_staff(make_user, tenant):
    admin = make_user(role=Role.PLATFORM_ADMIN)
    assert admin.tenant_id is None
    assert admin.is_staff
    assert admin.is_superuser
    admin.tenant = tenant
    with pytest.raises(ValidationError):
        admin.full_clean()


def test_db_constraint_tenant_matches_role(owner):
    with transaction.atomic(), pytest.raises(IntegrityError):
        User.objects.filter(pk=owner.pk).update(tenant=None)


def test_db_constraint_phone_for_login_roles(owner):
    with transaction.atomic(), pytest.raises(IntegrityError):
        User.objects.filter(pk=owner.pk).update(phone=None)


def test_for_tenant(make_user, tenant, other_tenant, owner):
    make_user(other_tenant)
    assert list(User.objects.for_tenant(tenant.id)) == [owner]


def test_set_pin_rejects_bad_format(owner):
    with pytest.raises(ValueError, match="pin must"):
        owner.set_pin("12")
