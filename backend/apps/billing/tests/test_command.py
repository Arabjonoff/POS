from datetime import UTC, date, datetime
from io import StringIO

import pytest
import time_machine
from django.core.management import call_command

from apps.billing.models import Subscription
from apps.billing.services import record_payment, start_subscription
from apps.billing.status import Status

pytestmark = pytest.mark.django_db


def _run():
    out = StringIO()
    call_command("update_subscriptions", stdout=out)
    return out.getvalue()


def test_update_subscriptions_moves_statuses(make_tenant, plan):
    trial = make_tenant()
    paid = make_tenant()
    blocked = make_tenant()
    for tenant in (trial, paid, blocked):
        start_subscription(tenant, plan, trial_days=14, today=date(2026, 10, 1))
    record_payment(paid, amount_tiyin=1, months=1, method="cash", today=date(2026, 10, 5))
    blocked.is_blocked = True
    blocked.save()

    # 16-oktabr (Toshkent): sinov tugagan → grace; to'langan → active; bloklangan.
    with time_machine.travel(datetime(2026, 10, 16, 7, 0, tzinfo=UTC), tick=False):
        output = _run()
        assert "subscriptions: 3, changed: 2" in output
        statuses = {s.tenant_id: s.status for s in Subscription.objects.all()}
        assert statuses == {
            trial.id: Status.GRACE,
            paid.id: Status.ACTIVE,
            blocked.id: Status.BLOCKED,
        }
        assert "no changes" in _run()

    with time_machine.travel(datetime(2026, 10, 20, 7, 0, tzinfo=UTC), tick=False):
        _run()
        assert Subscription.objects.get(tenant=trial).status == Status.READONLY
