import json
from pathlib import Path

import pytest

from apps.core.money import line_total, mul_div_half_up, percent_of

VECTORS = Path(__file__).resolve().parents[4] / "testdata" / "money_rounding.json"


def _cases():
    return json.loads(VECTORS.read_text(encoding="utf-8"))["cases"]


@pytest.mark.parametrize(("value", "num", "den", "expected"), _cases())
def test_shared_rounding_vectors(value, num, den, expected):
    assert mul_div_half_up(value, num, den) == expected


def test_rejects_float_and_bool():
    with pytest.raises(TypeError):
        mul_div_half_up(1.5, 1, 2)  # type: ignore[arg-type]
    with pytest.raises(TypeError):
        mul_div_half_up(True, 1, 2)


def test_zero_denominator():
    with pytest.raises(ZeroDivisionError):
        mul_div_half_up(1, 1, 0)


def test_line_total_weighted_item():
    # 1,250 kg × 6 000 so'm = 7 500 so'm (tiyinda)
    assert line_total(600_000, 1_250) == 750_000


def test_line_total_pieces():
    assert line_total(1_250_000, 2_000) == 2_500_000


def test_percent_of_basis_points():
    assert percent_of(3_500_000, 1_000) == 350_000  # 10%
    assert percent_of(1_005, 5_000) == 503  # 502.5 -> 503
