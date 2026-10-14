import pytest
from django.core.exceptions import ValidationError

from apps.core.phone import normalize_phone, validate_phone


@pytest.mark.parametrize(
    "raw",
    [
        "+998901234567",
        "998901234567",
        "901234567",
        "90 123 45 67",
        "+998 (90) 123-45-67",
        " +998 90 123 45 67 ",
    ],
)
def test_normalize_phone(raw):
    assert normalize_phone(raw) == "+998901234567"


@pytest.mark.parametrize(
    "raw",
    [
        "",
        "12345",
        "+7 901 234 56 78",
        "99890123456",
        "9989012345678",
        "90-abc-45-67",
        "++998901234567",
    ],
)
def test_normalize_phone_rejects_invalid(raw):
    with pytest.raises(ValueError, match="phone must"):
        normalize_phone(raw)


def test_validate_phone_accepts_normalized():
    validate_phone("+998901234567")


@pytest.mark.parametrize("value", ["998901234567", "+998 90 123 45 67", ""])
def test_validate_phone_rejects_non_normalized(value):
    with pytest.raises(ValidationError):
        validate_phone(value)
