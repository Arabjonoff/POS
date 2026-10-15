"""Do'kon chek rekvizitlari — kassadan `store.upserted` (T-104b)."""

import base64

import pytest

from apps.tenants.models import Store

from .helpers import PULL, event, push, statuses

pytestmark = pytest.mark.django_db

PNG = base64.b64encode(b"\x89PNG\r\n\x1a\n" + b"\x00" * 64).decode()


def upserted(user, store, **fields):
    return event("store.upserted", {"id": str(store.id), "by": str(user.id), **fields})


def test_owner_or_manager_sets_requisites(kassa, manager, tenant):
    _, client = kassa
    store = tenant.stores.get()
    result = push(
        client,
        upserted(
            manager,
            store,
            name="  Baraka   market ",
            legal_name='"Baraka" MChJ',
            tin="123456789",
            phone="71 200 00 00",
            receipt_footer="Rahmat!\nYana keling",
            receipt_logo=PNG,
            receipt_options={"show_tin": False, "unknown": True, "show_logo": "yes"},
        ),
    )
    assert statuses(result) == ["applied"], result
    store.refresh_from_db()
    assert store.name == "Baraka market"
    assert (store.legal_name, store.tin, store.phone) == (
        '"Baraka" MChJ',
        "123456789",
        "+998712000000",
    )
    assert store.receipt_logo == PNG
    # Noma'lum kalit va mantiqiy bo'lmagan qiymat tashlanadi.
    assert store.receipt_options == {"show_tin": False}

    # Pull'da kassalarga yetadi.
    body = client.get(PULL, {"cursor": "0"}).json()
    rows = [c for c in body["changes"] if c["entity"] == "store"]
    assert rows[-1]["data"]["tin"] == "123456789"
    assert rows[-1]["data"]["receipt_options"] == {"show_tin": False}


def test_cashier_cannot_change_requisites(kassa, cashier, tenant):
    _, client = kassa
    store = tenant.stores.get()
    result = push(client, upserted(cashier, store, tin="123456789"))[0]
    assert (result["status"], result["error"]["code"]) == ("rejected", "permission_denied")
    store.refresh_from_db()
    assert store.tin == ""


@pytest.mark.parametrize(
    "fields",
    [
        {"tin": "12345"},
        {"tin": "12345678a"},
        {"receipt_logo": "not base64!"},
        {"receipt_logo": base64.b64encode(b"GIF89a....").decode()},
        {"receipt_logo": base64.b64encode(b"\x89PNG\r\n\x1a\n" + b"0" * 200_000).decode()},
        {"name": "   "},
        {"phone": "12"},
    ],
)
def test_invalid_requisites_rejected(kassa, manager, tenant, fields):
    _, client = kassa
    store = tenant.stores.get()
    result = push(client, upserted(manager, store, **fields))[0]
    assert result["status"] == "rejected"


def test_other_tenant_store_cannot_be_touched(make_device, other_tenant, make_user, tenant):
    _, stranger_client = make_device(other_tenant)
    stranger = make_user(other_tenant, role="owner")
    ours = tenant.stores.get()
    result = push(stranger_client, upserted(stranger, ours, name="Begona"))[0]
    assert result["status"] == "rejected"
    ours.refresh_from_db()
    assert ours.name != "Begona"
    assert Store.objects.filter(name="Begona").count() == 0


def test_pull_advertises_store_settings(kassa):
    _, client = kassa
    assert "store_settings" in client.get(PULL, {"cursor": "0"}).json()["features"]
