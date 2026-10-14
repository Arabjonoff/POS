from django.db import transaction
from django.db.models import Max

from apps.billing.models import Subscription
from apps.core.exceptions import DomainError
from apps.tenants.models import Tenant

from .authentication import DeviceBlocked
from .models import Device
from .tokens import hash_token, new_token


@transaction.atomic
def register_device(
    *, user, name: str, platform: str, app_version: str = "", store=None, device_id=None
) -> tuple[Device, str, bool]:
    """Qurilmani ro'yxatdan o'tkazadi → `(device, token, created)`. Token faqat shu yerda ochiq."""
    # Tenant qatorini qulflash: chegara va raqam bir vaqtdagi so'rovlarda buzilmasin.
    tenant = Tenant.objects.select_for_update().get(pk=user.tenant_id)
    token = new_token()

    if device_id is not None:
        existing = Device.objects.filter(pk=device_id).first()
        if existing is not None:
            if existing.tenant_id != tenant.pk:
                raise DomainError(
                    "device_id_conflict", "Device id belongs to another tenant.", status_code=409
                )
            if existing.is_blocked:
                raise DeviceBlocked()
            existing.name = name
            existing.platform = platform
            existing.app_version = app_version
            existing.token_hash = hash_token(token)
            existing.save(
                update_fields=["name", "platform", "app_version", "token_hash", "updated_at"]
            )
            return existing, token, False

    subscription = Subscription.objects.select_related("plan").filter(tenant=tenant).first()
    if subscription is None:
        raise DomainError("no_subscription", "Tenant has no subscription.", status_code=409)
    max_devices = subscription.plan.max_devices
    active = Device.objects.filter(tenant=tenant, is_blocked=False).count()
    if active >= max_devices:
        raise DomainError(
            "device_limit_reached",
            "Device limit of the plan is reached.",
            status_code=409,
            details={"max_devices": max_devices},
        )

    if store is None:
        store = tenant.stores.order_by("created_at").first()
    number = (Device.objects.filter(tenant=tenant).aggregate(n=Max("number"))["n"] or 0) + 1
    extra = {"id": device_id} if device_id is not None else {}
    device = Device.objects.create(
        tenant=tenant,
        store=store,
        number=number,
        name=name,
        platform=platform,
        app_version=app_version,
        token_hash=hash_token(token),
        registered_by=user,
        **extra,
    )
    return device, token, True
