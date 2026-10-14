"""Platforma admin amallari. Har biri audit yozuvi bilan bitta tranzaksiyada (platform-api.md)."""

import secrets
import string

from django.db import IntegrityError, transaction

from apps.accounts.models import Role, User
from apps.billing.models import Plan, Subscription
from apps.billing.services import (
    record_payment,
    refresh_status,
    reverse_payment,
    start_subscription,
)
from apps.core.exceptions import DomainError
from apps.devices.models import Device
from apps.tenants.models import Tenant

from .audit import audit, snapshot

PASSWORD_ALPHABET = string.ascii_letters + string.digits
PASSWORD_ROLES = (Role.OWNER, Role.MANAGER)


def temporary_password(length: int = 10) -> str:
    """O'qish oson, kamida bitta harf va raqam bilan."""
    while True:
        password = "".join(secrets.choice(PASSWORD_ALPHABET) for _ in range(length))
        if any(c.isdigit() for c in password) and any(c.isalpha() for c in password):
            return password


@transaction.atomic
def onboard_tenant(*, actor, data: dict) -> tuple[Tenant, User, str | None]:
    """Tenant (+ do'kon, birliklar) + ega + sinov obunasi. Parol generatsiya qilinsa qaytariladi."""
    owner_data = data.pop("owner")
    plan, trial_days = data.pop("plan"), data.pop("trial_days")
    password = owner_data.get("password") or None
    generated = None if password else temporary_password()
    tenant = Tenant.objects.create(owner_phone=owner_data["phone"], **data)
    try:
        with transaction.atomic():
            owner = User.objects.create_user(
                phone=owner_data["phone"],
                password=password or generated,
                full_name=owner_data["full_name"],
                role=Role.OWNER,
                tenant=tenant,
            )
    except IntegrityError:
        raise DomainError("phone_taken", "This phone is already registered.", 409) from None
    subscription = start_subscription(tenant, plan, trial_days=trial_days)
    audit(actor, "tenant.create", tenant, after=snapshot(tenant))
    audit(actor, "user.create", owner, after=snapshot(owner))
    audit(
        actor,
        "subscription.create",
        subscription,
        after=snapshot(subscription),
        tenant_id=tenant.pk,
    )
    return tenant, owner, generated


@transaction.atomic
def update_tenant(tenant: Tenant, *, actor, data: dict) -> Tenant:
    tenant = Tenant.objects.select_for_update().get(pk=tenant.pk)
    before = snapshot(tenant)
    for field, value in data.items():
        setattr(tenant, field, value)
    tenant.save()
    audit(
        actor, "tenant.update", tenant, before=before, after=snapshot(tenant), tenant_id=tenant.pk
    )
    return tenant


@transaction.atomic
def set_tenant_blocked(tenant: Tenant, *, actor, blocked: bool, reason: str = "") -> Tenant:
    tenant = Tenant.objects.select_for_update().get(pk=tenant.pk)
    before = snapshot(tenant)
    tenant.is_blocked = blocked
    tenant.blocked_reason = reason if blocked else ""
    tenant.save(update_fields=["is_blocked", "blocked_reason", "updated_at"])
    sub = Subscription.objects.filter(tenant=tenant).first()
    if sub is not None:
        refresh_status(sub)
    action = "tenant.block" if blocked else "tenant.unblock"
    audit(actor, action, tenant, before=before, after=snapshot(tenant), tenant_id=tenant.pk,
          reason=reason)  # fmt: skip
    return tenant


@transaction.atomic
def update_subscription(tenant: Tenant, *, actor, data: dict) -> Subscription:
    sub = Subscription.objects.select_for_update().filter(tenant=tenant).first()
    if sub is None:
        raise DomainError("no_subscription", "Tenant has no subscription.", status_code=409)
    before = snapshot(sub)
    for field, value in data.items():
        setattr(sub, field, value)
    sub.save()
    refresh_status(sub)
    audit(
        actor, "subscription.update", sub, before=before, after=snapshot(sub), tenant_id=tenant.pk
    )
    return sub


@transaction.atomic
def reset_password(user: User, *, actor) -> str:
    if user.role not in PASSWORD_ROLES:
        raise DomainError("no_password_role", "Only owners and managers have passwords.", 409)
    password = temporary_password()
    user.set_password(password)
    user.save(update_fields=["password", "updated_at"])
    audit(actor, "user.reset_password", user, tenant_id=user.tenant_id)
    return password


@transaction.atomic
def save_plan(plan: Plan | None, *, actor, data: dict) -> Plan:
    before = snapshot(plan)
    if plan is None:
        plan = Plan.objects.create(**data)
        action = "plan.create"
    else:
        plan = Plan.objects.select_for_update().get(pk=plan.pk)
        for field, value in data.items():
            setattr(plan, field, value)
        plan.save()
        action = "plan.deactivate" if data == {"is_active": False} else "plan.update"
    audit(actor, action, plan, before=before, after=snapshot(plan))
    return plan


@transaction.atomic
def add_payment(tenant: Tenant, *, actor, data: dict):
    payment = record_payment(tenant, recorded_by=actor, **data)
    audit(actor, "payment.create", payment, after=snapshot(payment), tenant_id=tenant.pk)
    return payment


@transaction.atomic
def cancel_payment(payment, *, actor, note: str):
    reversal = reverse_payment(payment, recorded_by=actor, note=note)
    audit(actor, "payment.reverse", reversal, before=snapshot(payment), after=snapshot(reversal),
          tenant_id=payment.tenant_id, reason=note)  # fmt: skip
    return reversal


@transaction.atomic
def set_device_blocked(device: Device, *, actor, blocked: bool, reason: str = "") -> Device:
    device = Device.objects.select_for_update().get(pk=device.pk)
    before = snapshot(device)
    device.is_blocked = blocked
    device.save(update_fields=["is_blocked", "updated_at"])
    action = "device.block" if blocked else "device.unblock"
    audit(actor, action, device, before=before, after=snapshot(device), reason=reason)
    return device
