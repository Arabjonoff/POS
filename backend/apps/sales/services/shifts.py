"""Smena: ochish, yopish, kassa puli, X/Z hisobot."""

from django.db import IntegrityError, transaction
from django.db.models import Count, Sum, Value
from django.db.models.functions import Coalesce

from apps.customers.models import DebtEntry, DebtType

from ..models import CashMovement, CashMovementType, Refund, SalePayment, Shift
from .common import as_datetime, as_int, as_uuid, device_shift, invalid, tenant_user

ZERO = Value(0)


def _sum(queryset, field="amount_tiyin", **filters) -> int:
    return queryset.filter(**filters).aggregate(s=Coalesce(Sum(field), ZERO))["s"]


@transaction.atomic
def open_shift(device, payload: dict) -> Shift:
    code = "invalid_shift"
    shift_id = as_uuid(payload, "id", code=code)
    cashier = tenant_user(device.tenant_id, as_uuid(payload, "cashier", code=code), code=code)
    if Shift.objects.filter(device=device, closed_at__isnull=True).exists():
        raise invalid("shift_already_open", "Device already has an open shift.")
    try:
        with transaction.atomic():
            return Shift.objects.create(
                id=shift_id,
                tenant_id=device.tenant_id,
                store_id=device.store_id,
                device=device,
                opened_by=cashier,
                opened_at=as_datetime(payload, "opened_at", code=code),
                opening_cash_tiyin=as_int(payload, "opening_cash_tiyin", code=code, min_value=0),
            )
    except IntegrityError:
        # Parallel so'rov xuddi shu qurilmada smena ochib ulgurdi.
        raise invalid("shift_already_open", "Device already has an open shift.") from None


def expected_cash(shift: Shift) -> int:
    payments = SalePayment.objects.filter(sale__shift=shift, method="cash")
    refunds = Refund.objects.filter(shift=shift, method="cash")
    movements = CashMovement.objects.filter(shift=shift)
    debt_paid = DebtEntry.objects.filter(shift=shift, type=DebtType.PAYMENT, method="cash")
    return (
        shift.opening_cash_tiyin
        + _sum(payments)
        - _sum(refunds, "total_tiyin")
        + _sum(movements, type=CashMovementType.IN)
        - _sum(movements, type=CashMovementType.OUT)
        - _sum(debt_paid)  # to'lov yozuvlari manfiy
    )


@transaction.atomic
def close_shift(device, payload: dict) -> Shift:
    code = "invalid_shift"
    shift = device_shift(device, as_uuid(payload, "id", code=code), lock=True)
    shift.closed_by = tenant_user(
        device.tenant_id, as_uuid(payload, "closed_by", code=code), code=code
    )
    shift.closed_at = as_datetime(payload, "closed_at", code=code)
    if shift.closed_at < shift.opened_at:
        raise invalid(code, "closed_at is before opened_at.", field="closed_at")
    shift.counted_cash_tiyin = as_int(payload, "counted_cash_tiyin", code=code, min_value=0)
    shift.expected_cash_tiyin = expected_cash(shift)
    shift.save(
        update_fields=[
            "closed_by",
            "closed_at",
            "counted_cash_tiyin",
            "expected_cash_tiyin",
            "updated_at",
        ]
    )
    return shift


@transaction.atomic
def record_cash_movement(device, payload: dict) -> CashMovement:
    code = "invalid_cash_movement"
    shift = device_shift(device, as_uuid(payload, "shift", code=code), lock=True)
    movement_type = payload.get("type")
    if movement_type not in CashMovementType.values:
        raise invalid(code, "type must be in or out.", field="type")
    return CashMovement.objects.create(
        id=as_uuid(payload, "id", code=code),
        tenant_id=device.tenant_id,
        shift=shift,
        type=movement_type,
        amount_tiyin=as_int(payload, "amount_tiyin", code=code, min_value=1),
        reason=str(payload.get("reason") or ""),
        created_by=tenant_user(device.tenant_id, as_uuid(payload, "by", code=code), code=code),
        at=as_datetime(payload, "at", code=code),
    )


def shift_report(shift: Shift) -> dict:
    """X hisobot (ochiq smena) yoki Z hisobot (yopilgan smena)."""
    sales = shift.sales.aggregate(count=Count("id"), total=Coalesce(Sum("total_tiyin"), ZERO))
    payments = SalePayment.objects.filter(sale__shift=shift)
    refunds = Refund.objects.filter(shift=shift)
    movements = CashMovement.objects.filter(shift=shift)
    debt_paid = DebtEntry.objects.filter(shift=shift, type=DebtType.PAYMENT)
    # Z hisobot — yopilgan paytdagi qiymat; X — hozirgi.
    expected = expected_cash(shift) if shift.is_open else shift.expected_cash_tiyin
    counted = shift.counted_cash_tiyin
    return {
        "shift": shift.pk,
        "is_open": shift.is_open,
        "opening_cash_tiyin": shift.opening_cash_tiyin,
        "sales_count": sales["count"],
        "sales_total_tiyin": sales["total"],
        "payments_tiyin": {m: _sum(payments, method=m) for m in ("cash", "card", "debt")},
        "refunds_count": refunds.count(),
        "refunds_tiyin": {m: _sum(refunds, "total_tiyin", method=m) for m in ("cash", "debt")},
        "cash_in_tiyin": _sum(movements, type=CashMovementType.IN),
        "cash_out_tiyin": _sum(movements, type=CashMovementType.OUT),
        "debt_payments_tiyin": {m: -_sum(debt_paid, method=m) for m in ("cash", "card")},
        "expected_cash_tiyin": expected,
        "counted_cash_tiyin": counted,
        "difference_tiyin": None if counted is None else counted - expected,
    }
