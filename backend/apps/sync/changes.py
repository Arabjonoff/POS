"""ChangeLog yozish: qaysi obyekt o'zgargani (pull uchun, sync-api.md)."""

from .models import ChangeLog, ChangeOp


def log_change(tenant_id, entity: str, entity_id, op: str = ChangeOp.UPSERT) -> None:
    if tenant_id is None:
        return
    ChangeLog.objects.create(tenant_id=tenant_id, entity=entity, entity_id=entity_id, op=op)


def op_for(instance) -> str:
    """Yumshoq o'chirilgan obyekt — `delete`, aks holda `upsert`."""
    return ChangeOp.DELETE if getattr(instance, "deleted_at", None) else ChangeOp.UPSERT
