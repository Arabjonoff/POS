"""Push (kassa → server) va pull (server → kassa) — sync-api.md."""

import json
import logging
from datetime import timedelta

from django.db import transaction
from django.utils import timezone
from rest_framework.exceptions import PermissionDenied, ValidationError

from apps.core.exceptions import DomainError
from apps.devices.models import Device
from apps.sales.services import MissingDependency

from .handlers import HANDLERS
from .models import EventStatus, SyncEvent

logger = logging.getLogger(__name__)

PENDING_TTL = timedelta(days=7)
DUPLICATE = "duplicate"


def _json_safe(value):
    return json.loads(json.dumps(value, default=str))


def _error(code: str, message: str, details=None) -> dict:
    return {"code": code, "message": message, "details": _json_safe(details or {})}


def _apply(device, event: SyncEvent) -> None:
    """Hodisani savepoint ichida qo'llaydi va natijani `event` ga yozadi (saqlaydi)."""
    event.attempts += 1
    try:
        with transaction.atomic():
            HANDLERS[event.type](device, event.payload)
    except MissingDependency as exc:
        event.status = EventStatus.PENDING
        event.error = _error(
            "missing_dependency", str(exc), {"entity": exc.entity, "id": exc.entity_id}
        )
    except DomainError as exc:
        event.status = EventStatus.REJECTED
        event.error = _error(exc.code, str(exc.detail), exc.details)
    except ValidationError as exc:
        event.status = EventStatus.REJECTED
        event.error = _error("validation_error", "Invalid event payload.", exc.detail)
    except PermissionDenied as exc:
        event.status = EventStatus.REJECTED
        event.error = _error("permission_denied", str(exc.detail))
    except Exception:
        # Serverdagi xato tufayli kassa ma'lumoti yo'qolmasin — keyin qayta urinamiz.
        logger.exception("sync event %s (%s) failed", event.pk, event.type)
        event.status = EventStatus.PENDING
        event.error = _error("server_error", "Unexpected server error; will retry.")
    else:
        event.status = EventStatus.APPLIED
        event.error = None
        event.applied_at = timezone.now()
    if event.status == EventStatus.PENDING and timezone.now() - event.received_at > PENDING_TTL:
        event.status = EventStatus.REJECTED
    event.save(update_fields=["status", "error", "attempts", "applied_at"])


def retry_pending(device) -> None:
    pending = SyncEvent.objects.filter(device=device, status=EventStatus.PENDING).order_by(
        "client_created_at", "received_at"
    )
    for event in pending:
        _apply(device, event)


def _result(event_id, status, error=None) -> dict:
    result = {"id": event_id, "status": status}
    if error:
        result["error"] = error
    return result


@transaction.atomic
def push(device, events: list[dict]) -> list[dict]:
    """`events`: `[{id, type, payload, created_at}]` (tekshirilgan). Natijalar — kelgan tartibda."""
    # Bir qurilmaning parallel push'lari navbatma-navbat bajarilsin.
    device = Device.objects.select_for_update().get(pk=device.pk)
    retry_pending(device)

    # Indeks → tayyor natija (dublikat, konflikt) yoki saqlangan hodisa id'si.
    fixed, stored = {}, {}
    ordered = sorted(enumerate(events), key=lambda pair: (pair[1]["created_at"], pair[0]))
    for index, item in ordered:
        event_id = item["id"]
        existing = SyncEvent.objects.filter(pk=event_id).first()
        if existing is not None:
            if existing.device_id == device.pk:
                fixed[index] = _result(event_id, DUPLICATE)
            else:
                error = _error("id_conflict", "Event id is already used by another device.")
                fixed[index] = _result(event_id, EventStatus.REJECTED, error)
            continue
        event = SyncEvent(
            id=event_id,
            tenant_id=device.tenant_id,
            device=device,
            type=item["type"],
            payload=_json_safe(item["payload"]),
            client_created_at=item["created_at"],
            status=EventStatus.PENDING,
        )
        if item["type"] not in HANDLERS:
            event.status = EventStatus.REJECTED
            event.error = _error("unknown_event", f"Unknown event type {item['type']}.")
        event.save(force_insert=True)
        if event.status == EventStatus.PENDING:
            _apply(device, event)
        stored[index] = event_id

    # Yangi hodisalar kutilayotganlarning bog'liqligini yaratgan bo'lishi mumkin.
    retry_pending(device)
    final = SyncEvent.objects.filter(pk__in=stored.values()).in_bulk()
    now = timezone.now()
    device.last_sync_at = now
    device.last_seen_at = now
    device.save(update_fields=["last_sync_at", "last_seen_at"])
    results = []
    for index in range(len(events)):
        if index in fixed:
            results.append(fixed[index])
        else:
            event = final[stored[index]]
            results.append(_result(event.pk, event.status, event.error))
    return results
