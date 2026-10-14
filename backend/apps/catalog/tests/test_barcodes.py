import pytest

from apps.catalog.barcodes import BarcodeError, gtin_check_digit, normalize_barcode


@pytest.mark.parametrize(
    "code",
    [
        "4780000000014",  # EAN-13
        "4006381333931",  # EAN-13
        "2012345012509",  # tarozi kodi (barcode.md misoli)
        "96385074",  # EAN-8
        "036000291452",  # UPC-A
        "0012345678905",  # boshida nol
        "ABC-123",  # Code128/39
        "12345",  # ichki kod, nazoratsiz uzunlik
        "123456789",
    ],
)
def test_valid_barcodes(code):
    assert normalize_barcode(code) == code


def test_strips_whitespace_keeps_leading_zeros():
    assert normalize_barcode("  0012345678905\n") == "0012345678905"


@pytest.mark.parametrize("code", ["4780000000013", "2012345012503", "96385075", "036000291453"])
def test_wrong_check_digit(code):
    with pytest.raises(BarcodeError) as exc:
        normalize_barcode(code)
    assert exc.value.code == "invalid_check_digit"


@pytest.mark.parametrize("code", ["", "123", "12 34 56", "кириллица", "a" * 65, "abc\tdef"])
def test_invalid_format(code):
    with pytest.raises(BarcodeError) as exc:
        normalize_barcode(code)
    assert exc.value.code == "invalid_barcode"


@pytest.mark.parametrize(("body", "digit"), [("478000000001", 4), ("9638507", 4), ("03600029145", 2)])
def test_check_digit(body, digit):
    assert gtin_check_digit(body) == digit
