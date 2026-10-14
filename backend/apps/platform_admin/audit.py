"""Audit yozuvi va obyekt "surati" (sirlar kirmaydi)."""

import json

from django.core.serializers.json import DjangoJSONEncoder

from .models import AdminAuditLog

SECRET_FIELDS = frozenset({"password", "pin_hash", "token_hash"})


def snapshot(obj) -> dict | None:
    """Modelning oddiy maydonlari JSON ko'rinishida (FK — id)."""
    if obj is None:
        return None
    data = {
        field.attname: field.value_from_object(obj)
        for field in obj._meta.concrete_fields
        if field.name not in SECRET_FIELDS
    }
    return json.loads(json.dumps(data, cls=DjangoJSONEncoder))


def audit(actor, action: str, target, *, before=None, after=None, tenant_id=None, reason=""):
    """O'zgarish bilan bitta tranzaksiyada chaqiriladi. `before`/`after` — `snapshot()` natijasi."""
    return AdminAuditLog.objects.create(
        actor=actor,
        action=action,
        target_type=target._meta.model_name,
        target_id=str(target.pk),
        tenant_id=tenant_id if tenant_id is not None else getattr(target, "tenant_id", None),
        before=before,
        after=after,
        reason=reason,
    )
