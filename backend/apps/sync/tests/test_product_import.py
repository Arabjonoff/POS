# Rus tilidagi CSV namunasi ataylab (kirill harflar).
# ruff: noqa: RUF001
import io
import time
from datetime import timedelta

import pytest
from django.core.files.uploadedfile import SimpleUploadedFile
from django.utils import timezone
from openpyxl import Workbook, load_workbook

from apps.catalog.importing import BadNumber, parse_money, parse_qty, suggest_mapping
from apps.catalog.models import Category, PriceHistory, Product, ProductBarcode, ProductImport
from apps.inventory.models import ProductStock, StockReceipt
from apps.sync.models import ChangeLog

pytestmark = pytest.mark.django_db

BASE = "/api/v1/sync/product-imports/"
HEADER = ["Nomi", "Shtrix-kod", "Kategoriya", "Birlik", "Narx", "Tannarx", "Qoldiq"]


def xlsx(rows, header=HEADER):
    workbook = Workbook()
    sheet = workbook.active
    sheet.append(header)
    for row in rows:
        sheet.append(row)
    buffer = io.BytesIO()
    workbook.save(buffer)
    return SimpleUploadedFile("tovarlar.xlsx", buffer.getvalue())


def upload(client, file):
    response = client.post(BASE, {"file": file}, format="multipart")
    assert response.status_code == 201, response.json()
    return response.json()


def mapping(data):
    return data["mapping"]


def test_template_has_the_columns(kassa):
    _, client = kassa
    response = client.get("/api/v1/sync/product-import/template/")
    assert response.status_code == 200
    sheet = load_workbook(io.BytesIO(response.content)).active
    assert [c.value for c in sheet[1]] == HEADER


def test_upload_suggests_mapping_and_sample(kassa):
    _, client = kassa
    data = upload(client, xlsx([["Non", 4780000000014, "Non", "dona", 4000, 3000, 20]]))
    assert data["columns"] == HEADER
    assert data["total_rows"] == 1
    # Excel soni — kasrsiz matn (shtrix-kod buzilmaydi).
    assert data["sample"][0][1] == "4780000000014"
    assert data["mapping"] == {
        "name": 0,
        "barcode": 1,
        "category": 2,
        "unit": 3,
        "sell_price": 4,
        "cost_price": 5,
        "stock": 6,
    }


def test_check_then_apply_creates_updates_and_stock(kassa, product, manager, tenant):
    _, client = kassa
    ProductBarcode.objects.create(tenant=tenant, product=product, barcode="4780000000014")
    data = upload(
        client,
        xlsx(
            [
                # Mavjud (shtrix-kod bo'yicha) — narx yangilanadi, qoldiq tegilmaydi.
                ["Non issiq", "4780000000014", "Non", "dona", "4 500", "3200", "99"],
                ["Olma qizil", "", "Sabzavot", "kg", "15000", "11000", "12,5"],
                ["Sut 1 L", "4600000000015", "sut", "шт", "12000,50", "", "10"],
                ["", "", "", "", "1000", "", ""],  # nom yo'q
                ["Cola", "4780000000015", "", "", "9000", "", ""],  # nazorat raqami xato
                ["Choy", "4600000000015", "", "", "9000", "", ""],  # faylda takror
                ["Shakar", "", "", "litrcha", "9000", "", ""],  # noma'lum birlik
                ["Guruch", "", "", "", "abc", "", ""],  # son emas
            ]
        ),
    )
    check = client.post(f"{BASE}{data['id']}/check/", {"mapping": mapping(data)}, format="json")
    assert check.status_code == 200, check.json()
    assert check.json()["creates"] == 2
    assert check.json()["updates"] == 1
    assert {(e["row"], e["field"], e["code"]) for e in check.json()["errors"]} == {
        (5, "name", "required"),
        (6, "barcode", "invalid_check_digit"),
        (7, "barcode", "duplicate_in_file"),
        (8, "unit", "unknown_unit"),
        (9, "sell_price", "invalid_number"),
    }
    # Tekshiruv bazaga yozmaydi.
    assert Product.objects.filter(tenant=tenant).count() == 1

    applied = client.post(
        f"{BASE}{data['id']}/apply/",
        {"mapping": mapping(data), "by": str(manager.id)},
        format="json",
    )
    assert applied.status_code == 200, applied.json()
    body = applied.json()
    assert (body["created"], body["updated"], body["skipped"]) == (2, 1, 5)

    product.refresh_from_db()
    assert (product.name, product.sell_price_tiyin, product.cost_price_tiyin) == (
        "Non issiq",
        450_000,
        320_000,
    )
    assert product.category.name == "Non"
    olma = Product.objects.get(tenant=tenant, name="Olma qizil")
    assert (olma.unit.code, olma.sell_price_tiyin) == ("kg", 1_500_000)
    sut = Product.objects.get(tenant=tenant, name="Sut 1 L")
    assert sut.sell_price_tiyin == 1_200_050
    assert sut.barcodes.get().barcode == "4600000000015"
    # Kategoriya katta-kichik harf farqsiz: "sut" yangi yaratilgan bitta.
    assert set(Category.objects.filter(tenant=tenant).values_list("name", flat=True)) == {
        "Non",
        "Sabzavot",
        "sut",
    }
    # Qoldiq — faqat yangilar: bitta kirim.
    stock = {s.product_id: s.qty_milli for s in ProductStock.objects.filter(tenant=tenant)}
    assert stock == {olma.pk: 12_500, sut.pk: 10_000}
    receipt = StockReceipt.objects.get(tenant=tenant)
    assert (receipt.status, receipt.number, receipt.note) == ("posted", body["receipt"], "Import")
    assert receipt.posted_by == manager
    # Narx tarixi: 2 yangi + 1 o'zgargan.
    assert PriceHistory.objects.filter(tenant=tenant, changed_by=manager).count() == 3
    # Pull: tovarlar, kategoriyalar, qoldiq.
    logged = set(ChangeLog.objects.filter(tenant=tenant).values_list("entity", "entity_id"))
    assert {("product", product.pk), ("product", olma.pk), ("stock", sut.pk)} <= logged
    assert ("category", sut.category_id) in logged

    again = client.post(
        f"{BASE}{data['id']}/apply/",
        {"mapping": mapping(data), "by": str(manager.id)},
        format="json",
    )
    assert again.status_code == 409


def test_cashier_cannot_apply(kassa, cashier):
    _, client = kassa
    data = upload(client, xlsx([["Non", "", "", "", "4000", "", ""]]))
    response = client.post(
        f"{BASE}{data['id']}/apply/",
        {"mapping": mapping(data), "by": str(cashier.id)},
        format="json",
    )
    assert response.status_code == 400


def test_mapping_requires_name_and_price(kassa):
    _, client = kassa
    data = upload(client, xlsx([["Non", "", "", "", "4000", "", ""]]))
    bad = mapping(data) | {"sell_price": None}
    response = client.post(f"{BASE}{data['id']}/check/", {"mapping": bad}, format="json")
    assert response.status_code == 400
    out_of_range = mapping(data) | {"name": 42}
    response = client.post(f"{BASE}{data['id']}/check/", {"mapping": out_of_range}, format="json")
    assert response.status_code == 400


def test_csv_semicolon_cp1251(kassa, manager, tenant):
    _, client = kassa
    text = "Название;Цена;Ед\nХлеб;4000;шт\nМука;9500,5;кг\n"
    file = SimpleUploadedFile("tovar.csv", text.encode("cp1251"))
    data = upload(client, file)
    assert data["mapping"]["name"] == 0
    assert data["mapping"]["sell_price"] == 1
    assert data["mapping"]["unit"] == 2
    response = client.post(
        f"{BASE}{data['id']}/apply/",
        {"mapping": mapping(data), "by": str(manager.id)},
        format="json",
    )
    assert response.json()["created"] == 2
    muka = Product.objects.get(tenant=tenant, name="Мука")
    assert (muka.unit.code, muka.sell_price_tiyin) == ("kg", 950_050)


def test_bad_files(kassa):
    _, client = kassa
    for file in [
        SimpleUploadedFile("x.txt", b"hello"),
        SimpleUploadedFile("x.xlsx", b"PK not really"),
        SimpleUploadedFile("x.csv", b"Nomi;Narx\n"),
    ]:
        response = client.post(BASE, {"file": file}, format="multipart")
        assert response.status_code == 400, file.name
        assert response.json()["error"]["code"] == "invalid_file"


def test_other_device_or_tenant_cannot_use_the_import(kassa, make_device, tenant, other_tenant):
    _, client = kassa
    data = upload(client, xlsx([["Non", "", "", "", "4000", "", ""]]))
    _, other_kassa = make_device(tenant, number=2)
    _, foreign = make_device(other_tenant)
    for c in (other_kassa, foreign):
        response = c.post(f"{BASE}{data['id']}/check/", {"mapping": mapping(data)}, format="json")
        assert response.status_code == 404


def test_old_import_expires(kassa):
    _, client = kassa
    data = upload(client, xlsx([["Non", "", "", "", "4000", "", ""]]))
    ProductImport.objects.filter(pk=data["id"]).update(
        created_at=timezone.now() - timedelta(hours=25)
    )
    response = client.post(f"{BASE}{data['id']}/check/", {"mapping": mapping(data)}, format="json")
    assert response.status_code == 404


def test_user_jwt_is_not_enough(client_as, manager):
    response = client_as(manager).post(BASE, {}, format="multipart")
    assert response.status_code in (401, 403)


def test_5000_rows(kassa, manager, tenant):
    _, client = kassa
    rows = [[f"Tovar {i}", "", f"Guruh {i % 20}", "dona", 1000 + i, 500, 3] for i in range(5000)]
    data = upload(client, xlsx(rows))
    assert data["total_rows"] == 5000
    started = time.monotonic()
    response = client.post(
        f"{BASE}{data['id']}/apply/",
        {"mapping": mapping(data), "by": str(manager.id)},
        format="json",
    )
    elapsed = time.monotonic() - started
    assert response.status_code == 200
    assert response.json()["created"] == 5000
    assert Product.objects.filter(tenant=tenant).count() == 5000
    assert ProductStock.objects.filter(tenant=tenant).count() == 5000
    assert elapsed < 30, elapsed


def test_parsers_and_header_aliases():
    assert parse_money("12 500") == 1_250_000
    assert parse_money("12500,5") == 1_250_050
    assert parse_money("0,005") == 1  # half-up
    with pytest.raises(BadNumber):
        parse_money("12,5,0")
    assert parse_qty("1,25", fractional=True) == 1250
    with pytest.raises(BadNumber):
        parse_qty("1,5", fractional=False)
    assert suggest_mapping(["  NOMI ", "Narx", "Штрих-код", "x"]) == {
        "name": 0,
        "barcode": 2,
        "category": None,
        "unit": None,
        "sell_price": 1,
        "cost_price": None,
        "stock": None,
    }
