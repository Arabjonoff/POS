from types import SimpleNamespace

import pytest
from rest_framework.exceptions import PermissionDenied

from apps.core.tenancy import TenantScopedMixin, get_request_tenant_id


def _user(tenant_id=None, authenticated=True):
    return SimpleNamespace(is_authenticated=authenticated, tenant_id=tenant_id)


class FakeQuerySet:
    def __init__(self):
        self.calls = []

    def filter(self, **kwargs):
        self.calls.append(("filter", kwargs))
        return self

    def none(self):
        self.calls.append(("none", {}))
        return self


class Base:
    queryset = None

    def get_queryset(self):
        return self.queryset


class View(TenantScopedMixin, Base):
    def __init__(self, request):
        self.request = request
        self.queryset = FakeQuerySet()


def test_tenant_from_user():
    request = SimpleNamespace(user=_user("t1"))
    assert get_request_tenant_id(request) == "t1"


def test_tenant_from_device_token_wins():
    request = SimpleNamespace(user=_user("t1"), tenant_id="t2")
    assert get_request_tenant_id(request) == "t2"


def test_anonymous_has_no_tenant():
    request = SimpleNamespace(user=_user("t1", authenticated=False))
    assert get_request_tenant_id(request) is None


def test_queryset_filtered_by_tenant():
    view = View(SimpleNamespace(user=_user("t1")))
    queryset = view.get_queryset()
    assert queryset.calls == [("filter", {"tenant_id": "t1"})]


def test_queryset_empty_without_tenant():
    view = View(SimpleNamespace(user=_user(None)))
    queryset = view.get_queryset()
    assert queryset.calls == [("none", {})]


def test_create_sets_tenant():
    saved = {}
    serializer = SimpleNamespace(save=lambda **kwargs: saved.update(kwargs))
    View(SimpleNamespace(user=_user("t1"))).perform_create(serializer)
    assert saved == {"tenant_id": "t1"}


def test_create_without_tenant_denied():
    serializer = SimpleNamespace(save=lambda **kwargs: None)
    with pytest.raises(PermissionDenied):
        View(SimpleNamespace(user=_user(None))).perform_create(serializer)
