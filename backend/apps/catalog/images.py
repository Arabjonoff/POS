"""Tovar rasmi (T-105): tekshirish, qayta kodlash, tovarga biriktirish.

Rasm o'zgarmas obyekt (kassada yaratilgan UUIDv7). Tovar hech qachon rasmini kutmaydi:
`product.upserted` rasmga tegmaydi, rasm alohida endpoint orqali biriktiriladi."""

import hashlib
import io

from django.core.files.base import ContentFile
from django.db import transaction
from django.utils import timezone
from PIL import Image, ImageOps, UnidentifiedImageError

from apps.core.exceptions import DomainError

from .models import Product, ProductImage

# Dekompressiya "bombasi"dan himoya.
Image.MAX_IMAGE_PIXELS = 40_000_000

MAX_UPLOAD_BYTES = 5 * 1024 * 1024
MAX_SIDE = 4096
FULL_SIDE = 800
THUMB_SIDE = 200
ALLOWED_FORMATS = {"JPEG", "PNG", "WEBP"}


def _invalid(message: str) -> DomainError:
    return DomainError("invalid_image", message, status_code=400)


def process_image(data: bytes) -> tuple[bytes, bytes, int, int]:
    """Rasmni tekshiradi va JPEG ga qayta kodlaydi: to'liq (≤ 800 px) va kichik (≤ 200 px).
    EXIF (joylashuv va h.k.) olib tashlanadi, burilish to'g'rilanadi."""
    if len(data) > MAX_UPLOAD_BYTES:
        raise DomainError("image_too_large", "Image is larger than 5 MB.", status_code=400)
    try:
        with Image.open(io.BytesIO(data)) as probe:
            if probe.format not in ALLOWED_FORMATS:
                raise _invalid("Only JPEG, PNG or WebP images are accepted.")
            probe.verify()
        image = Image.open(io.BytesIO(data))
        if max(image.size) > MAX_SIDE:
            raise _invalid("Image is too big (max 4096 px).")
        image = ImageOps.exif_transpose(image)
        if image.mode in ("RGBA", "LA", "P"):
            image = image.convert("RGBA")
            background = Image.new("RGB", image.size, (255, 255, 255))
            background.paste(image, mask=image.getchannel("A"))
            image = background
        else:
            image = image.convert("RGB")
    except (UnidentifiedImageError, OSError, Image.DecompressionBombError):
        raise _invalid("File is not a readable image.") from None

    def encode(side: int) -> tuple[bytes, int, int]:
        copy = image.copy()
        copy.thumbnail((side, side))
        out = io.BytesIO()
        copy.save(out, format="JPEG", quality=80, optimize=True)
        return out.getvalue(), copy.width, copy.height

    full, width, height = encode(FULL_SIDE)
    thumb, _, _ = encode(THUMB_SIDE)
    return full, thumb, width, height


@transaction.atomic
def attach_image(
    *, tenant_id, product_id, image_id, data: bytes, user
) -> tuple[ProductImage, bool]:
    """Rasmni saqlab, tovarning joriy rasmi qiladi. Qaytaradi: (rasm, yangi_mi).
    Shu id qayta kelsa (kassa javobni olmagan) — o'zgarishsiz (takroriy)."""
    existing = ProductImage.objects.filter(pk=image_id).first()
    if existing is not None:
        if existing.tenant_id != tenant_id:
            raise DomainError("id_conflict", "Image id is already used.", 409)
        return existing, False
    product = Product.objects.select_for_update().filter(tenant_id=tenant_id, pk=product_id).first()
    if product is None:
        # Tovar kassada yaratilgan, hodisasi hali qo'llanmagan — kassa keyin qayta yuboradi.
        raise DomainError("product_missing", "Product is not on the server yet.", 409)
    full, thumb, width, height = process_image(data)
    image = ProductImage(
        id=image_id,
        tenant_id=tenant_id,
        product=product,
        sha256=hashlib.sha256(full).hexdigest(),
        width=width,
        height=height,
        bytes=len(full),
        uploaded_by=user,
    )
    image.file.save(f"{image_id}.jpg", ContentFile(full), save=False)
    image.thumb.save(f"{image_id}_t.jpg", ContentFile(thumb), save=False)
    image.save(force_insert=True)
    product.image = image
    product.save(update_fields=["image", "updated_at"])
    return image, True


@transaction.atomic
def remove_image(*, tenant_id, image_id) -> None:
    """Rasmni olib tashlash (yumshoq). Tovarning joriy rasmi bo'lsa — tovar rasmsiz qoladi."""
    image = ProductImage.objects.filter(tenant_id=tenant_id, pk=image_id).first()
    if image is None:
        return
    if image.deleted_at is None:
        image.deleted_at = timezone.now()
        image.save(update_fields=["deleted_at", "updated_at"])
    product = Product.objects.select_for_update().get(pk=image.product_id)
    if product.image_id == image.pk:
        product.image = None
        product.save(update_fields=["image", "updated_at"])
