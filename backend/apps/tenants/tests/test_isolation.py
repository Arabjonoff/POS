"""TenantScopedViewSet haqiqiy model (Store) bilan: boshqa tenant ma'lumoti ko'rinmaydi."""

from types import SimpleNamespace

import pytest
from rest_framework import serializers
from rest_framework.test import APIRequestFactory, force_authenticate

from apps.core.tenancy import TenantScopedViewSet
from apps.tenants.models import Store

pytestmark = pytest.mark.django_db


class StoreSerializer(serializers.ModelSerializer):
    class Meta:
        model = Store
        fields = ["id", "tenant", "name"]
        read_only_fields = ["id", "tenant"]


class StoreViewSet(TenantScopedViewSet):
    queryset = Store.objects.all()
    serializer_class = StoreSerializer


factory = APIRequestFactory()
list_view = StoreViewSet.as_view({"get": "list", "post": "create"})
detail_view = StoreViewSet.as_view({"get": "retrieve", "patch": "partial_update"})


def _user(tenant):
    return SimpleNamespace(is_authenticated=True, tenant_id=tenant.id)


def _call(view, request, tenant, **kwargs):
    force_authenticate(request, user=_user(tenant))
    return view(request, **kwargs)


def test_list_shows_only_own_stores(tenant, other_tenant):
    response = _call(list_view, factory.get("/stores/"), tenant)
    assert response.status_code == 200
    ids = {row["id"] for row in response.data["results"]}
    assert ids == {str(s.id) for s in tenant.stores.all()}


def test_other_tenant_store_is_not_found(tenant, other_tenant):
    foreign = other_tenant.stores.get()
    response = _call(detail_view, factory.get("/"), tenant, pk=foreign.pk)
    assert response.status_code == 404


def test_other_tenant_store_cannot_be_updated(tenant, other_tenant):
    foreign = other_tenant.stores.get()
    request = factory.patch("/", {"name": "Buzildi"}, format="json")
    response = _call(detail_view, request, tenant, pk=foreign.pk)
    assert response.status_code == 404
    foreign.refresh_from_db()
    assert foreign.name != "Buzildi"


def test_create_uses_request_tenant_not_payload(tenant, other_tenant):
    request = factory.post(
        "/stores/", {"name": "Ikkinchi", "tenant": str(other_tenant.id)}, format="json"
    )
    response = _call(list_view, request, tenant)
    assert response.status_code == 201
    created = Store.objects.get(pk=response.data["id"])
    assert created.tenant_id == tenant.id
