from datetime import timedelta
from zoneinfo import ZoneInfo

import pytest
from django.utils import timezone

from apps.core.ids import new_id
from apps.sales.services import record_cash_movement, record_refund, record_sale

pytestmark = pytest.mark.django_db

SHIFTS = "/api/v1/shifts/"
SALES = "/api/v1/sales/"
REFUNDS = "/api/v1/refunds/"
CASH = "/api/v1/cash-movements/"


@pytest.fixture
def data(
    device,
    shift,
    cashier,
    product,
    customer,
    sale_payload,
    make_shift,
    make_device,
    make_user,
    tenant,
):
    """Ikki kassir: `cashier` (1-qurilma) va `other` (2-qurilma), har birida savdo."""
    sale = record_sale(
        device,
        sale_payload(shift, cashier, [(product, 2_000, 400_000)], customer=customer),
    )
    record_refund(
        device,
        {
            "id": str(new_id()),
            "sale": str(sale.id),
            "shift": str(shift.id),
            "cashier": str(cashier.id),
            "method": "cash",
            "total_tiyin": 400_000,
            "at": timezone.now().isoformat(),
            "items": [
                {
                    "id": str(new_id()),
                    "sale_item": str(sale.items.get().id),
                    "qty_milli": 1_000,
                    "total_tiyin": 400_000,
                }
            ],
        },
    )
    record_cash_movement(
        device,
        {
            "id": str(new_id()),
            "shift": str(shift.id),
            "type": "out",
            "amount_tiyin": 1_000,
            "reason": "xarajat",
            "by": str(cashier.id),
            "at": timezone.now().isoformat(),
        },
    )
    other = make_user(tenant, role="cashier")
    other_device = make_device(tenant, number=2)
    other_shift = make_shift(other_device, other)
    other_sale = record_sale(
        other_device, sale_payload(other_shift, other, [(product, 1_000, 400_000)])
    )
    return {"sale": sale, "shift": shift, "other_sale": other_sale, "other_shift": other_shift}


def _ids(response):
    assert response.status_code == 200, response.json()
    return {row["id"] for row in response.json()["results"]}


def test_manager_sees_everything(client_as, manager, data):
    client = client_as(manager)
    assert _ids(client.get(SALES)) == {str(data["sale"].id), str(data["other_sale"].id)}
    assert _ids(client.get(SHIFTS)) == {str(data["shift"].id), str(data["other_shift"].id)}
    assert len(_ids(client.get(REFUNDS))) == 1
    assert len(_ids(client.get(CASH))) == 1


def test_cashier_sees_only_own(client_as, cashier, data):
    client = client_as(cashier)
    assert _ids(client.get(SALES)) == {str(data["sale"].id)}
    assert _ids(client.get(SHIFTS)) == {str(data["shift"].id)}
    assert client.get(f"{SALES}{data['other_sale'].id}/").status_code == 404
    assert client.get(f"{SHIFTS}{data['other_shift'].id}/report/").status_code == 404
    assert len(_ids(client.get(REFUNDS))) == 1
    assert len(_ids(client.get(CASH))) == 1


def test_sale_detail_has_items_and_payments(client_as, manager, data):
    sale = client_as(manager).get(f"{SALES}{data['sale'].id}/").json()
    assert sale["status"] == "partially_refunded"
    assert sale["items"][0]["qty_milli"] == 2_000
    assert sale["payments"][0]["method"] == "cash"
    assert sale["total_tiyin"] == 800_000


def test_filters(client_as, manager, data, customer):
    client = client_as(manager)
    assert _ids(client.get(f"{SALES}?shift={data['shift'].id}")) == {str(data["sale"].id)}
    assert _ids(client.get(f"{SALES}?customer={customer.id}")) == {str(data["sale"].id)}
    assert _ids(client.get(f"{REFUNDS}?sale={data['other_sale'].id}")) == set()
    assert _ids(client.get(f"{CASH}?shift={data['other_shift'].id}")) == set()
    assert _ids(client.get(f"{SHIFTS}?open=true")) == {
        str(data["shift"].id),
        str(data["other_shift"].id),
    }
    assert _ids(client.get(f"{SHIFTS}?open=false")) == set()
    assert _ids(client.get(f"{SHIFTS}?device={data['shift'].device_id}")) == {str(data["shift"].id)}
    assert client.get(f"{SALES}?shift=abc").status_code == 400
    assert client.get(f"{SALES}?date_from=14.10.2026").status_code == 400


def test_date_filter_uses_store_timezone(client_as, manager, data, tenant):
    tz = ZoneInfo(tenant.timezone)
    today = timezone.now().astimezone(tz).date()
    client = client_as(manager)
    both = {str(data["sale"].id), str(data["other_sale"].id)}
    assert _ids(client.get(f"{SALES}?date_from={today}&date_to={today}")) == both
    tomorrow = today + timedelta(days=1)
    assert _ids(client.get(f"{SALES}?date_from={tomorrow}")) == set()
    yesterday = today - timedelta(days=1)
    assert _ids(client.get(f"{SALES}?date_to={yesterday}")) == set()


def test_shift_report_endpoint(client_as, cashier, data):
    report = client_as(cashier).get(f"{SHIFTS}{data['shift'].id}/report/").json()
    assert report["sales_count"] == 1
    assert report["payments_tiyin"]["cash"] == 800_000
    assert report["refunds_tiyin"]["cash"] == 400_000
    assert report["cash_out_tiyin"] == 1_000
    assert report["expected_cash_tiyin"] == 100_000_00 + 800_000 - 400_000 - 1_000


@pytest.mark.parametrize("url", [SHIFTS, SALES, REFUNDS, CASH])
def test_read_only(client_as, owner, url):
    assert client_as(owner).post(url, {}, format="json").status_code == 405


@pytest.mark.parametrize("url", [SHIFTS, SALES, REFUNDS, CASH])
def test_requires_auth(api_client, url):
    assert api_client.get(url).status_code == 401


def test_other_tenant_isolated(client_as, make_user, other_tenant, data):
    stranger = client_as(make_user(other_tenant, role="owner"))
    for url in (SHIFTS, SALES, REFUNDS, CASH):
        assert stranger.get(url).json()["count"] == 0
    assert stranger.get(f"{SALES}{data['sale'].id}/").status_code == 404
    assert stranger.get(f"{SHIFTS}{data['shift'].id}/").status_code == 404
    assert stranger.get(f"{SHIFTS}{data['shift'].id}/report/").status_code == 404
