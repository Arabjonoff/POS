"""Kassa hodisalarini qo'llashda umumiy yordamchilar (sales-api.md)."""

import uuid
from datetime import datetime

from django.utils import timezone
from django.utils.dateparse import parse_datetime

from apps.accounts.models import Role, User
from apps.core.exceptions import DomainError

from ..models import Shift


class MissingDependency(Exception):
    """Bog'liq obyekt (smena, savdo, ...) hali serverda yo'q — sinxron hodisani `pending` qiladi."""

    def __init__(self, entity: str, entity_id):
        super().__init__(f"{entity} {entity_id} not found")
        self.entity = entity
        self.entity_id = entity_id


def invalid(code: str, message: str, **details) -> DomainError:
    return DomainError(code, message, details=details)


def as_int(payload: dict, key: str, *, code: str, min_value: int | None = None, default=None):
    value = payload.get(key, default)
    if not isinstance(value, int) or isinstance(value, bool):
        raise invalid(code, f"{key} must be an integer.", field=key)
    if min_value is not None and value < min_value:
        raise invalid(code, f"{key} must be >= {min_value}.", field=key)
    return value


def as_uuid(payload: dict, key: str, *, code: str, required: bool = True):
    value = payload.get(key)
    if value is None and not required:
        return None
    try:
        return value if isinstance(value, uuid.UUID) else uuid.UUID(str(value))
    except (TypeError, ValueError):
        raise invalid(code, f"{key} must be a UUID.", field=key) from None


def as_datetime(payload: dict, key: str, *, code: str) -> datetime:
    value = payload.get(key)
    parsed = value if isinstance(value, datetime) else parse_datetime(str(value or ""))
    if parsed is None:
        raise invalid(code, f"{key} must be an ISO datetime.", field=key)
    if timezone.is_naive(parsed):
        raise invalid(code, f"{key} must include a time zone.", field=key)
    return parsed


def tenant_user(tenant_id, user_id, *, code: str, managers_only: bool = False) -> User:
    user = User.objects.filter(pk=user_id, tenant_id=tenant_id).first()
    if user is None:
        raise invalid(code, "User does not belong to this store.", user=str(user_id))
    if managers_only and user.role not in (Role.OWNER, Role.MANAGER):
        raise invalid(code, "Approver must be an owner or manager.", user=str(user_id))
    return user


def device_shift(
    device, shift_id, *, lock: bool = False, must_be_open: bool = True, at=None
) -> Shift:
    """Qurilma smenasi. Yopiq smena faqat [at] smena yopilishidan oldin bo'lsa qabul qilinadi:
    kassada smena ochiq paytda bo'lgan, lekin kechikib kelgan (pending, qayta yuborilgan)
    hodisa rad etilmasin. Bunday holda smenaning kutilgan naqdi qayta hisoblanadi
    (`refresh_closed_shift`)."""
    queryset = Shift.objects.filter(tenant_id=device.tenant_id)
    if lock:
        queryset = queryset.select_for_update()
    shift = queryset.filter(pk=shift_id).first()
    if shift is None:
        raise MissingDependency("shift", shift_id)
    if shift.device_id != device.pk:
        raise invalid("foreign_shift", "Shift belongs to another device.", shift=str(shift_id))
    late_but_inside = at is not None and shift.closed_at is not None and at <= shift.closed_at
    if must_be_open and not shift.is_open and not late_but_inside:
        raise invalid("shift_closed", "Shift is already closed.", shift=str(shift_id))
    return shift
