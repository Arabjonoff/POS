from rest_framework import serializers

from apps.tenants.models import Store

from .models import Device, Platform


class DeviceSerializer(serializers.ModelSerializer):
    code = serializers.CharField(read_only=True)

    class Meta:
        model = Device
        fields = [
            "id",
            "number",
            "code",
            "name",
            "platform",
            "app_version",
            "store",
            "is_blocked",
            "last_sync_at",
            "last_seen_at",
            "created_at",
        ]
        read_only_fields = fields


class DeviceRegisterSerializer(serializers.Serializer):
    id = serializers.UUIDField(required=False)
    name = serializers.CharField(max_length=100)
    platform = serializers.ChoiceField(choices=Platform.choices)
    app_version = serializers.CharField(max_length=32, required=False, allow_blank=True, default="")
    store = serializers.PrimaryKeyRelatedField(queryset=Store.objects.all(), required=False)

    def validate_store(self, store):
        if store.tenant_id != self.context["request"].user.tenant_id:
            raise serializers.ValidationError("Store not found.", code="does_not_exist")
        return store


class DeviceRegisterResponseSerializer(serializers.Serializer):
    device = DeviceSerializer()
    token = serializers.CharField()


class SubscriptionSnapshotSerializer(serializers.Serializer):
    status = serializers.CharField()
    paid_until = serializers.DateField(allow_null=True)
    days_left = serializers.IntegerField(allow_null=True)
    offline_days = serializers.IntegerField()


class AppReleaseSerializer(serializers.Serializer):
    """Kassa ilovasining oxirgi versiyasi (T-093)."""

    latest_version = serializers.CharField()
    download_url = serializers.CharField(allow_blank=True)


class DeviceMeSerializer(serializers.Serializer):
    device = DeviceSerializer()
    subscription = SubscriptionSnapshotSerializer()
    server_time = serializers.DateTimeField()
