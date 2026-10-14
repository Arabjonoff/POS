from django.db import IntegrityError, transaction
from django.utils import timezone

from apps.core.exceptions import DomainError

from .models import Category, PriceHistory, Product, ProductBarcode

PRICE_FIELDS = ("sell_price_tiyin", "cost_price_tiyin")


def set_barcodes(product: Product, codes: list[str]) -> None:
    """Tovar shtrix-kodlarini ro'yxat bilan almashtiradi; yo'qlari yumshoq o'chiriladi."""
    now = timezone.now()
    current = {b.barcode: b for b in product.barcodes.filter(deleted_at__isnull=True)}
    for code, barcode in current.items():
        if code not in codes:
            barcode.deleted_at = now
            barcode.save(update_fields=["deleted_at", "updated_at"])
    for index, code in enumerate(codes):
        is_primary = index == 0
        barcode = current.get(code)
        if barcode is None:
            ProductBarcode.objects.create(
                tenant_id=product.tenant_id, product=product, barcode=code, is_primary=is_primary
            )
        elif barcode.is_primary != is_primary:
            barcode.is_primary = is_primary
            barcode.save(update_fields=["is_primary", "updated_at"])


def save_product(instance: Product | None, data: dict, *, user) -> Product:
    data = dict(data)
    codes = data.pop("barcodes", None)
    try:
        with transaction.atomic():
            if instance is None:
                product = Product.objects.create(**data)
                price_changed = True
            else:
                product = instance
                old_prices = tuple(getattr(product, f) for f in PRICE_FIELDS)
                for field, value in data.items():
                    setattr(product, field, value)
                product.save()
                price_changed = tuple(getattr(product, f) for f in PRICE_FIELDS) != old_prices
            if codes is not None:
                set_barcodes(product, codes)
            if price_changed:
                PriceHistory.objects.create(
                    tenant_id=product.tenant_id,
                    product=product,
                    sell_price_tiyin=product.sell_price_tiyin,
                    cost_price_tiyin=product.cost_price_tiyin,
                    changed_by=user,
                )
    except IntegrityError as exc:
        # Bir vaqtdagi so'rovlar: validatsiyadan o'tib, DB cheklovida to'qnashgan.
        message = str(exc)
        if "barcode_per_tenant" in message:
            raise DomainError(
                "barcode_taken", "Barcode already belongs to another product.", 409
            ) from None
        if "product_plu_per_tenant" in message:
            raise DomainError("plu_taken", "PLU code is used by another product.", 409) from None
        raise
    return product


@transaction.atomic
def soft_delete_category(category: Category) -> None:
    """Kategoriya va ichkilari o'chiriladi; ulardagi tovarlar kategoriyasiz qoladi."""
    now = timezone.now()
    ids, frontier = [], [category.pk]
    while frontier:
        ids.extend(frontier)
        frontier = list(
            Category.objects.filter(parent_id__in=frontier, deleted_at__isnull=True).values_list(
                "pk", flat=True
            )
        )
    Product.objects.filter(category_id__in=ids).update(category=None, updated_at=now)
    Category.objects.filter(pk__in=ids).update(deleted_at=now, updated_at=now)
