"""Do'kon sozlamalari (chek rekvizitlari) — kassadan `store.upserted` (T-104b)."""

import base64
import binascii

from rest_framework import serializers

from apps.core.phone import normalize_phone
from apps.core.text import clean_line

from .models import Store

# Kassa logotipni kichraytirib yuboradi (≤ 576×240, kulrang PNG) — bu chegara
# zaxira bilan; katta rasm sinxron va chop etishni sekinlashtiradi.
MAX_LOGO_BYTES = 96 * 1024
_PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"

# Chekda ko'rsat/yashir kalitlari (qolganlari e'tiborsiz qoldiriladi).
RECEIPT_OPTION_KEYS = {
    "show_logo",
    "show_legal_name",
    "show_address",
    "show_phone",
    "show_tin",
    "show_cashier",
    "show_barcode",
    "show_header",
    "show_footer",
}


class StoreSettingsSerializer(serializers.ModelSerializer):
    phone = serializers.CharField(required=False, allow_blank=True, max_length=32)

    class Meta:
        model = Store
        fields = [
            "name",
            "address",
            "phone",
            "receipt_header",
            "receipt_footer",
            "legal_name",
            "tin",
            "receipt_logo",
            "receipt_options",
        ]

    def validate_name(self, value):
        value = clean_line(value)
        if not value:
            raise serializers.ValidationError("This field may not be blank.", code="blank")
        return value

    def validate_legal_name(self, value):
        return clean_line(value)

    def validate_address(self, value):
        return clean_line(value)

    def validate_phone(self, value):
        if not value or not value.strip():
            return ""
        try:
            return normalize_phone(value)
        except ValueError as exc:
            raise serializers.ValidationError(str(exc)) from None

    def validate_receipt_logo(self, value):
        if not value:
            return ""
        try:
            data = base64.b64decode(value, validate=True)
        except (binascii.Error, ValueError):
            raise serializers.ValidationError("Logo must be base64.") from None
        if not data.startswith(_PNG_SIGNATURE):
            raise serializers.ValidationError("Logo must be a PNG image.")
        if len(data) > MAX_LOGO_BYTES:
            raise serializers.ValidationError("Logo is too large.", code="too_large")
        return value

    def validate_receipt_options(self, value):
        if not isinstance(value, dict):
            raise serializers.ValidationError("Must be an object.")
        return {
            key: bool(flag)
            for key, flag in value.items()
            if key in RECEIPT_OPTION_KEYS and isinstance(flag, bool)
        }
