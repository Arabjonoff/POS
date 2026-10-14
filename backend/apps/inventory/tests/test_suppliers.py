import pytest

from apps.inventory.models import Supplier

pytestmark = pytest.mark.django_db

SUPPLIERS = "/api/v1/suppliers/"
RECEIPTS = "/api/v1/stock-receipts/"


def test_manager_crud_with_soft_delete(client_as, manager, tenant):
    client = client_as(manager)
    payload = {"name": "Coca-Cola", "phone": "+998901234567"}
    response = client.post(SUPPLIERS, payload, format="json")
    assert response.status_code == 201
    supplier_id = response.json()["id"]
    assert Supplier.objects.get(pk=supplier_id).tenant_id == tenant.id

    response = client.patch(f"{SUPPLIERS}{supplier_id}/", {"note": "dushanba"}, format="json")
    assert response.json()["note"] == "dushanba"

    assert client.delete(f"{SUPPLIERS}{supplier_id}/").status_code == 204
    assert Supplier.objects.get(pk=supplier_id).deleted_at is not None
    assert client.get(SUPPLIERS).json()["count"] == 0


def test_cashier_reads_but_cannot_write(client_as, cashier, tenant):
    Supplier.objects.create(tenant=tenant, name="Nestle")
    client = client_as(cashier)
    assert client.get(SUPPLIERS).json()["count"] == 1
    assert client.post(SUPPLIERS, {"name": "X"}, format="json").status_code == 403


def test_deleted_supplier_rejected_in_receipt(client_as, manager, tenant):
    supplier = Supplier.objects.create(tenant=tenant, name="Eski")
    client = client_as(manager)
    client.delete(f"{SUPPLIERS}{supplier.id}/")
    payload = {"supplier": str(supplier.id), "items": []}
    assert client.post(RECEIPTS, payload, format="json").status_code == 400


def test_other_tenant_isolated(client_as, manager, other_tenant):
    supplier = Supplier.objects.create(tenant=other_tenant, name="Begona")
    client = client_as(manager)
    assert client.get(SUPPLIERS).json()["count"] == 0
    assert client.get(f"{SUPPLIERS}{supplier.id}/").status_code == 404
    assert client.delete(f"{SUPPLIERS}{supplier.id}/").status_code == 404
    payload = {"supplier": str(supplier.id), "items": []}
    assert client.post(RECEIPTS, payload, format="json").status_code == 400
