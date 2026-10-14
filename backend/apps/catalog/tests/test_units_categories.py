import pytest

from apps.catalog.models import STANDARD_UNITS, Category, Product, Unit
from apps.tenants.models import Tenant

pytestmark = pytest.mark.django_db

UNITS = "/api/v1/units/"
CATEGORIES = "/api/v1/categories/"


def test_new_tenant_gets_standard_units(tenant):
    units = {u.code: u for u in tenant.units.all()}
    assert set(units) == {code for code, _ in STANDARD_UNITS}
    assert units["kg"].is_fractional
    assert not units["pcs"].is_fractional
    assert all(u.name == "" for u in units.values())


def test_raw_tenant_save_skips_units():
    from apps.catalog.signals import on_tenant_created

    tenant = Tenant.objects.create(name="X", owner_phone="+998901112299")
    on_tenant_created(Tenant, tenant, created=True, raw=True)
    assert tenant.units.count() == len(STANDARD_UNITS)


def test_cashier_reads_units(client_as, cashier):
    response = client_as(cashier).get(UNITS)
    assert response.status_code == 200
    assert response.json()["count"] == len(STANDARD_UNITS)


def test_cashier_cannot_create_unit(client_as, cashier):
    response = client_as(cashier).post(UNITS, {"code": "box", "name": "Quti"}, format="json")
    assert response.status_code == 403


def test_manager_creates_custom_unit(client_as, manager, tenant):
    response = client_as(manager).post(
        UNITS, {"code": "box", "name": "Quti", "is_fractional": False}, format="json"
    )
    assert response.status_code == 201
    assert Unit.objects.get(pk=response.json()["id"]).tenant_id == tenant.id


def test_custom_unit_requires_name(client_as, manager):
    response = client_as(manager).post(UNITS, {"code": "box"}, format="json")
    assert response.status_code == 400
    assert "name" in response.json()["error"]["details"]


def test_unit_code_unique_per_tenant(client_as, manager, make_user, other_tenant):
    assert client_as(manager).post(UNITS, {"code": "kg"}, format="json").status_code == 400
    other = make_user(other_tenant, role="manager")
    payload = {"code": "box", "name": "Quti"}
    assert client_as(manager).post(UNITS, payload, format="json").status_code == 201
    assert client_as(other).post(UNITS, payload, format="json").status_code == 201


def test_unit_in_use_cannot_be_deleted(client_as, manager, tenant, unit_pcs):
    Product.objects.create(tenant=tenant, name="Non", unit=unit_pcs, sell_price_tiyin=1)
    response = client_as(manager).delete(f"{UNITS}{unit_pcs.id}/")
    assert response.status_code == 409
    assert response.json()["error"]["code"] == "unit_in_use"


def test_unused_unit_soft_deleted(client_as, manager, tenant):
    unit = tenant.units.get(code="m")
    assert client_as(manager).delete(f"{UNITS}{unit.id}/").status_code == 204
    unit.refresh_from_db()
    assert unit.is_deleted
    assert client_as(manager).get(f"{UNITS}{unit.id}/").status_code == 404


def test_other_tenant_unit_not_visible(client_as, manager, other_tenant):
    foreign = other_tenant.units.get(code="kg")
    assert client_as(manager).get(f"{UNITS}{foreign.id}/").status_code == 404
    assert client_as(manager).delete(f"{UNITS}{foreign.id}/").status_code == 404


def test_category_crud(client_as, manager, tenant):
    client = client_as(manager)
    response = client.post(CATEGORIES, {"name": "Ichimliklar", "color": "blue"}, format="json")
    assert response.status_code == 201
    parent_id = response.json()["id"]
    child = client.post(CATEGORIES, {"name": "Sharbat", "parent": parent_id}, format="json")
    assert child.status_code == 201
    patch = client.patch(f"{CATEGORIES}{parent_id}/", {"sort": 5}, format="json")
    assert patch.status_code == 200
    assert patch.json()["sort"] == 5
    names = [c["name"] for c in client.get(CATEGORIES).json()["results"]]
    assert set(names) == {"Ichimliklar", "Sharbat"}


def test_category_cannot_be_own_ancestor(client_as, manager, tenant):
    parent = Category.objects.create(tenant=tenant, name="A")
    child = Category.objects.create(tenant=tenant, name="B", parent=parent)
    response = client_as(manager).patch(
        f"{CATEGORIES}{parent.id}/", {"parent": str(child.id)}, format="json"
    )
    assert response.status_code == 400


def test_category_parent_from_other_tenant_rejected(client_as, manager, other_tenant):
    foreign = Category.objects.create(tenant=other_tenant, name="Begona")
    response = client_as(manager).post(
        CATEGORIES, {"name": "X", "parent": str(foreign.id)}, format="json"
    )
    assert response.status_code == 400
    assert "parent" in response.json()["error"]["details"]


def test_delete_category_cascades_softly(client_as, manager, tenant, unit_pcs):
    parent = Category.objects.create(tenant=tenant, name="A")
    child = Category.objects.create(tenant=tenant, name="B", parent=parent)
    product = Product.objects.create(
        tenant=tenant, name="Non", unit=unit_pcs, sell_price_tiyin=1, category=child
    )
    assert client_as(manager).delete(f"{CATEGORIES}{parent.id}/").status_code == 204
    parent.refresh_from_db()
    child.refresh_from_db()
    product.refresh_from_db()
    assert parent.is_deleted
    assert child.is_deleted
    assert product.category_id is None
    assert client_as(manager).get(CATEGORIES).json()["count"] == 0


def test_categories_isolated(client_as, manager, other_tenant):
    Category.objects.create(tenant=other_tenant, name="Begona")
    assert client_as(manager).get(CATEGORIES).json()["count"] == 0
