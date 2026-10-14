"""DRF maydonlari: pul va miqdor faqat butun son (qaror 0002)."""

from rest_framework import serializers


class StrictIntegerField(serializers.IntegerField):
    """Faqat JSON butun son: `150.0`, `"150"`, `true` rad etiladi (DRF IntegerField ularni oladi)."""

    default_error_messages = {"not_integer": "A whole number is required (no decimals, no strings)."}

    def to_internal_value(self, data):
        if isinstance(data, bool) or not isinstance(data, int):
            self.fail("not_integer")
        return super().to_internal_value(data)


def money_field(**kwargs) -> StrictIntegerField:
    """Tiyin: manfiy emas butun son."""
    kwargs.setdefault("min_value", 0)
    return StrictIntegerField(**kwargs)
