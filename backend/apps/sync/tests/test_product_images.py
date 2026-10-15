"""Tovar rasmlari (T-105): yuklash, takror, huquq, tekshiruv, tenant izolyatsiyasi."""

import io

import pytest
from PIL import Image

from apps.catalog.models import Product, ProductImage
from apps.core.ids import new_id

from .helpers import PULL, event, push, statuses

pytestmark = pytest.mark.django_db


def image_bytes(fmt="PNG", size=(1600, 1200), mode="RGB") -> bytes:
    out = io.BytesIO()
    Image.new(mode, size, (200, 30, 30) if mode == "RGB" else (200, 30, 30, 128)).save(
        out, format=fmt
    )
    return out.getvalue()


def url(image_id) -> str:
    return f"/api/v1/sync/product-images/{image_id}/"


def upload(client, image_id, product, by, data=None, name="olma.png"):
    return client.put(
        url(image_id),
        {
            "file": io.BytesIO(data if data is not None else image_bytes()),
            "product": str(product.id),
            "by": str(by.id),
        },
        format="multipart",
    )


def test_upload_resizes_and_pull_returns_the_image(kassa, manager, product):
    _, client = kassa
    image_id = new_id()
    response = upload(client, image_id, product, manager)
    assert response.status_code == 201, response.content
    body = response.json()
    assert (body["width"], body["height"]) == (800, 600)
    product.refresh_from_db()
    assert product.image_id == image_id

    # Kassalar pull'da rasm haqida bilib oladi.
    changes = client.get(PULL, {"cursor": "0"}).json()["changes"]
    row = [c for c in changes if c["entity"] == "product" and c["id"] == str(product.id)][-1]
    assert row["data"]["image"]["id"] == str(image_id)
    assert row["data"]["image"]["sha256"] == body["sha256"]

    # Yuklab olish: to'liq va kichik, abadiy kesh.
    full = client.get(url(image_id))
    assert full.status_code == 200
    assert full["Content-Type"] == "image/jpeg"
    assert "immutable" in full["Cache-Control"]
    thumb = client.get(url(image_id), {"size": "thumb"})
    with Image.open(io.BytesIO(b"".join(thumb.streaming_content))) as small:
        assert max(small.size) == 200


def test_repeated_upload_is_a_duplicate(kassa, manager, product):
    _, client = kassa
    image_id = new_id()
    assert upload(client, image_id, product, manager).status_code == 201
    assert upload(client, image_id, product, manager).status_code == 200
    assert ProductImage.objects.count() == 1


def test_transparent_png_gets_white_background(kassa, manager, product):
    _, client = kassa
    data = image_bytes(mode="RGBA", size=(100, 100))
    assert upload(client, new_id(), product, manager, data=data).status_code == 201


@pytest.mark.parametrize(
    "data",
    [b"not an image", image_bytes(fmt="GIF", size=(10, 10)), b"\x89PNG\r\n\x1a\nbroken"],
)
def test_bad_files_rejected(kassa, manager, product, data):
    _, client = kassa
    response = upload(client, new_id(), product, manager, data=data)
    assert response.status_code == 400
    assert not ProductImage.objects.exists()


def test_cashier_cannot_upload(kassa, cashier, product):
    _, client = kassa
    assert upload(client, new_id(), product, cashier).status_code == 400
    assert not ProductImage.objects.exists()


def test_unknown_product_asks_to_retry_later(kassa, manager, tenant):
    _, client = kassa
    missing = Product(id=new_id())
    response = upload(client, new_id(), missing, manager)
    assert response.status_code == 409
    assert response.json()["error"]["code"] == "product_missing"


def test_other_tenant_cannot_see_or_attach(
    kassa, manager, product, make_device, other_tenant, make_user
):
    _, client = kassa
    image_id = new_id()
    upload(client, image_id, product, manager)
    _, stranger = make_device(other_tenant)
    assert stranger.get(url(image_id)).status_code == 404
    # Begona tovarga ham biriktira olmaydi (tovar ko'rinmaydi).
    stranger_owner = make_user(other_tenant, role="owner")
    response = upload(stranger, new_id(), product, stranger_owner)
    assert response.status_code == 409


def test_product_upsert_never_clears_the_image(kassa, manager, product, tenant):
    _, client = kassa
    image_id = new_id()
    upload(client, image_id, product, manager)
    rename = event(
        "product.upserted",
        {
            "id": str(product.id),
            "name": "Non yangi",
            "unit": str(product.unit_id),
            "sell_price_tiyin": product.sell_price_tiyin,
            "image": None,
            "by": str(manager.id),
        },
    )
    assert statuses(push(client, rename)) == ["applied"]
    product.refresh_from_db()
    assert (product.name, product.image_id) == ("Non yangi", image_id)


def test_delete_clears_the_current_image(kassa, manager, product):
    _, client = kassa
    image_id = new_id()
    upload(client, image_id, product, manager)
    response = client.delete(url(image_id), {"by": str(manager.id)}, format="json")
    assert response.status_code == 204
    product.refresh_from_db()
    assert product.image_id is None
    assert client.get(url(image_id)).status_code == 404
