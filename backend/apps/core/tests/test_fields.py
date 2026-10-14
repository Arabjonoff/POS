import pytest
from rest_framework import serializers

from apps.core.fields import money_field


class S(serializers.Serializer):
    price = money_field()


@pytest.mark.parametrize("value", [0, 1, 15_000_000, 9_000_000_000_000])
def test_accepts_integers(value):
    s = S(data={"price": value})
    assert s.is_valid(), s.errors
    assert s.validated_data["price"] == value


@pytest.mark.parametrize("value", [150.5, 150.0, "150", True, None, -1])
def test_rejects_non_integers_and_negative(value):
    assert not S(data={"price": value}).is_valid()
