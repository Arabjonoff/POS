"""Holat o'tishlari sanalar bo'yicha (subscription-billing.md, "Testlar" va "Sanalar")."""

from datetime import date

import pytest

from apps.billing.status import Status, add_months, compute_status

# Sinov 1-oktabrda boshlangan, 14 kun: birinchi to'lanmagan kun — 15-oktabr.
TRIAL_ENDS = date(2026, 10, 15)
PAID_UNTIL = date(2026, 11, 30)


@pytest.mark.parametrize(
    ("case", "today", "paid_until", "blocked", "expected", "days_left"),
    [
        ("sinov ichida", date(2026, 10, 10), None, False, Status.TRIAL, 5),
        ("sinov oxirgi kuni", date(2026, 10, 14), None, False, Status.TRIAL, 1),
        ("sinov tugagan, grace 1-kun", date(2026, 10, 15), None, False, Status.GRACE, 3),
        ("sinov tugagan, grace oxirgi kun", date(2026, 10, 17), None, False, Status.GRACE, 1),
        ("sinov tugagan, readonly", date(2026, 10, 18), None, False, Status.READONLY, None),
        ("to'langan", date(2026, 11, 10), PAID_UNTIL, False, Status.ACTIVE, 21),
        ("3 kun qolgan", date(2026, 11, 28), PAID_UNTIL, False, Status.ACTIVE, 3),
        ("to'langan oxirgi kun", date(2026, 11, 30), PAID_UNTIL, False, Status.ACTIVE, 1),
        ("grace 1-kun", date(2026, 12, 1), PAID_UNTIL, False, Status.GRACE, 3),
        ("grace oxirgi kun", date(2026, 12, 3), PAID_UNTIL, False, Status.GRACE, 1),
        ("readonly", date(2026, 12, 4), PAID_UNTIL, False, Status.READONLY, None),
        (
            "bloklangan (to'langan bo'lsa ham)",
            date(2026, 11, 10),
            PAID_UNTIL,
            True,
            Status.BLOCKED,
            None,
        ),
        ("bloklangan sinovda", date(2026, 10, 10), None, True, Status.BLOCKED, None),
        (
            "sinov ichida oldindan to'langan",
            date(2026, 10, 10),
            PAID_UNTIL,
            False,
            Status.ACTIVE,
            52,
        ),
    ],
    ids=lambda v: v if isinstance(v, str) else None,
)
def test_status_by_date(case, today, paid_until, blocked, expected, days_left):
    info = compute_status(
        today=today,
        trial_ends_at=TRIAL_ENDS,
        paid_until=paid_until,
        grace_days=3,
        is_blocked=blocked,
    )
    assert info.status == expected, case
    assert info.days_left == days_left, case


def test_no_trial_no_payment_is_readonly():
    info = compute_status(
        today=date(2026, 10, 1), trial_ends_at=None, paid_until=None, grace_days=3
    )
    assert info.status == Status.READONLY


def test_zero_grace_goes_readonly_next_day():
    info = compute_status(
        today=date(2026, 12, 1), trial_ends_at=None, paid_until=PAID_UNTIL, grace_days=0
    )
    assert info.status == Status.READONLY


@pytest.mark.parametrize(
    ("status", "can_write"),
    [
        (Status.TRIAL, True),
        (Status.ACTIVE, True),
        (Status.GRACE, True),
        (Status.READONLY, False),
        (Status.BLOCKED, False),
    ],
)
def test_can_write(status, can_write):
    today = {
        Status.TRIAL: date(2026, 10, 10),
        Status.ACTIVE: date(2026, 11, 10),
        Status.GRACE: date(2026, 12, 1),
        Status.READONLY: date(2026, 12, 10),
        Status.BLOCKED: date(2026, 11, 10),
    }[status]
    info = compute_status(
        today=today,
        trial_ends_at=TRIAL_ENDS,
        paid_until=None if status == Status.TRIAL else PAID_UNTIL,
        grace_days=3,
        is_blocked=status == Status.BLOCKED,
    )
    assert info.status == status
    assert info.can_write is can_write


@pytest.mark.parametrize(
    ("today", "warning"),
    [(date(2026, 11, 27), False), (date(2026, 11, 28), True), (date(2026, 11, 30), True)],
)
def test_expiry_warning(today, warning):
    info = compute_status(today=today, trial_ends_at=None, paid_until=PAID_UNTIL, grace_days=3)
    assert info.expiry_warning is warning


@pytest.mark.parametrize(
    ("start", "months", "expected"),
    [
        (date(2026, 10, 14), 1, date(2026, 11, 14)),
        (date(2026, 10, 14), 12, date(2027, 10, 14)),
        (date(2026, 12, 15), 1, date(2027, 1, 15)),
        (date(2027, 1, 31), 1, date(2027, 2, 28)),
        (date(2028, 1, 31), 1, date(2028, 2, 29)),
        (date(2026, 8, 31), 1, date(2026, 9, 30)),
        (date(2027, 3, 31), -1, date(2027, 2, 28)),
        (date(2026, 1, 15), -1, date(2025, 12, 15)),
        (date(2026, 10, 14), 0, date(2026, 10, 14)),
    ],
)
def test_add_months(start, months, expected):
    assert add_months(start, months) == expected
