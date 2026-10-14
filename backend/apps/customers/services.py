"""Nasiya amallari. Balans faqat DebtEntry orqali o'zgaradi; mijoz qatori qulflanadi."""

from django.db import transaction
from django.db.models import Q, Sum, Value
from django.db.models.functions import Coalesce
from django.utils import timezone

from apps.core.exceptions import DomainError

from .models import Customer, DebtEntry, DebtType


def customer_balance(customer) -> int:
    total = DebtEntry.objects.filter(customer=customer).aggregate(s=Sum("amount_tiyin"))["s"]
    return total or 0


def with_balance(queryset):
    """`balance_tiyin` annotatsiyasi (qarzi yo'q mijozda 0)."""
    return queryset.annotate(balance_tiyin=Coalesce(Sum("debt_entries__amount_tiyin"), Value(0)))


def check_debt_limit(customer, amount_tiyin: int) -> bool:
    """Qarzga `amount_tiyin` sotish limit ichidami (kassada oshsa — menejer ruxsati)."""
    if customer.debt_limit_tiyin is None:
        return True
    return customer_balance(customer) + amount_tiyin <= customer.debt_limit_tiyin


def _lock(customer) -> Customer:
    return Customer.objects.select_for_update().get(pk=customer.pk)


def _positive(amount_tiyin) -> None:
    if not isinstance(amount_tiyin, int) or isinstance(amount_tiyin, bool) or amount_tiyin <= 0:
        raise ValueError("amount_tiyin must be a positive int")


def _create(customer, **fields) -> DebtEntry:
    if fields.get("at") is None:
        fields["at"] = timezone.now()
    return DebtEntry.objects.create(tenant_id=customer.tenant_id, customer=customer, **fields)


@transaction.atomic
def record_sale_debt(customer, *, amount_tiyin: int, sale_id, user=None, at=None, id=None):
    """Qarzga savdo (T-017). Limit bu yerda tekshirilmaydi — savdo allaqachon bo'lgan."""
    _positive(amount_tiyin)
    customer = _lock(customer)
    return _create(
        customer,
        **({"id": id} if id else {}),
        amount_tiyin=amount_tiyin,
        type=DebtType.SALE,
        sale_id=sale_id,
        created_by=user,
        at=at,
    )


@transaction.atomic
def record_refund_debt(customer, *, amount_tiyin: int, sale_id, user=None, at=None, id=None):
    """Qarzga sotilgan savdo qaytarildi (T-017): qarz kamayadi."""
    _positive(amount_tiyin)
    customer = _lock(customer)
    return _create(
        customer,
        **({"id": id} if id else {}),
        amount_tiyin=-amount_tiyin,
        type=DebtType.REFUND,
        sale_id=sale_id,
        created_by=user,
        at=at,
    )


@transaction.atomic
def pay_debt(
    customer,
    *,
    amount_tiyin: int,
    method: str,
    user=None,
    note: str = "",
    at=None,
    id=None,
    enforce_balance: bool = True,
) -> DebtEntry:
    """To'lov. `enforce_balance=False` — oflayn kassadan kelgan to'lov (rad etilmaydi)."""
    _positive(amount_tiyin)
    customer = _lock(customer)
    if enforce_balance:
        balance = customer_balance(customer)
        # Q-003: avans yo'q — qarzdan ko'p to'lov qabul qilinmaydi.
        if amount_tiyin > balance:
            raise DomainError(
                "payment_exceeds_debt",
                "Payment is larger than the current debt.",
                status_code=409,
                details={"balance_tiyin": balance},
            )
    return _create(
        customer,
        **({"id": id} if id else {}),
        amount_tiyin=-amount_tiyin,
        type=DebtType.PAYMENT,
        method=method,
        note=note,
        created_by=user,
        at=at,
    )


@transaction.atomic
def adjust_debt(customer, *, amount_tiyin: int, note: str, user, id=None) -> DebtEntry:
    """Qo'lda tuzatish (faqat ega; huquq view'da). Sabab majburiy."""
    if not isinstance(amount_tiyin, int) or isinstance(amount_tiyin, bool) or amount_tiyin == 0:
        raise ValueError("amount_tiyin must be a non-zero int")
    if not note.strip():
        raise ValueError("note is required")
    customer = _lock(customer)
    return _create(
        customer,
        **({"id": id} if id else {}),
        amount_tiyin=amount_tiyin,
        type=DebtType.ADJUSTMENT,
        note=note,
        created_by=user,
    )


@transaction.atomic
def soft_delete_customer(customer) -> None:
    customer = _lock(customer)
    if customer_balance(customer) != 0:
        raise DomainError("customer_has_debt", "Customer has a non-zero balance.", 409)
    customer.deleted_at = timezone.now()
    customer.save(update_fields=["deleted_at", "updated_at"])


def debtors_first(queryset):
    """Qarzdorlar birinchi (qarz kamayib), keyin ism."""
    return with_balance(queryset).order_by("-balance_tiyin", "full_name", "id")


def search_customers(queryset, term: str):
    term = term.strip()
    if not term:
        return queryset
    return queryset.filter(Q(full_name__icontains=term) | Q(phone__icontains=term))
