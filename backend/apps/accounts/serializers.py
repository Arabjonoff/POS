from django.contrib.auth import authenticate
from rest_framework import serializers
from rest_framework.exceptions import AuthenticationFailed

from apps.core.phone import normalize_phone

from .models import User


class TenantBriefSerializer(serializers.Serializer):
    id = serializers.UUIDField()
    name = serializers.CharField()


class MeSerializer(serializers.ModelSerializer):
    tenant = TenantBriefSerializer(allow_null=True)

    class Meta:
        model = User
        fields = ["id", "phone", "full_name", "role", "tenant"]
        read_only_fields = fields


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ["id", "phone", "full_name", "role", "is_active", "created_at"]
        read_only_fields = fields


def _invalid_credentials():
    return AuthenticationFailed("Invalid phone or password.", code="invalid_credentials")


class LoginSerializer(serializers.Serializer):
    phone = serializers.CharField(write_only=True)
    password = serializers.CharField(write_only=True, trim_whitespace=False)

    def validate(self, attrs):
        try:
            phone = normalize_phone(attrs["phone"])
        except ValueError:
            raise _invalid_credentials() from None
        user = authenticate(self.context.get("request"), phone=phone, password=attrs["password"])
        # Kassir parol bilan kirmaydi (faqat PIN), hatto parol qo'yilgan bo'lsa ham.
        if user is None or not user.can_use_password:
            raise _invalid_credentials()
        attrs["user"] = user
        return attrs


class LoginResponseSerializer(serializers.Serializer):
    access = serializers.CharField()
    refresh = serializers.CharField()
    user = MeSerializer()
