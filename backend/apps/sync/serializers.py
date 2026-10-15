from rest_framework import serializers

from apps.devices.serializers import AppReleaseSerializer, SubscriptionSnapshotSerializer

MAX_EVENTS = 100


class EventSerializer(serializers.Serializer):
    id = serializers.UUIDField()
    type = serializers.CharField(max_length=32)
    payload = serializers.DictField()
    created_at = serializers.DateTimeField()


class PushRequestSerializer(serializers.Serializer):
    events = EventSerializer(many=True, min_length=1, max_length=MAX_EVENTS)


class EventErrorSerializer(serializers.Serializer):
    code = serializers.CharField()
    message = serializers.CharField()
    details = serializers.JSONField()


class EventResultSerializer(serializers.Serializer):
    id = serializers.UUIDField()
    status = serializers.ChoiceField(choices=["applied", "duplicate", "pending", "rejected"])
    error = EventErrorSerializer(required=False)


class PushResponseSerializer(serializers.Serializer):
    results = EventResultSerializer(many=True)
    server_time = serializers.DateTimeField()


class PullQuerySerializer(serializers.Serializer):
    cursor = serializers.CharField(default="0", max_length=64)
    limit = serializers.IntegerField(min_value=1, max_value=500, default=500)

    def validate_cursor(self, value):
        from .pull import parse_cursor

        try:
            parse_cursor(value)
        except ValueError as exc:
            raise serializers.ValidationError(str(exc)) from None
        return value


class ChangeSerializer(serializers.Serializer):
    entity = serializers.CharField()
    op = serializers.ChoiceField(choices=["upsert", "delete"])
    id = serializers.UUIDField()
    data = serializers.JSONField(allow_null=True)


class PullResponseSerializer(serializers.Serializer):
    changes = ChangeSerializer(many=True)
    next_cursor = serializers.CharField()
    has_more = serializers.BooleanField()
    subscription = SubscriptionSnapshotSerializer()
    # Eski kassa e'tibor bermaydi (CLAUDE.md, 10-qoida).
    app = AppReleaseSerializer(allow_null=True, required=False)
    # Server qo'llab-quvvatlaydigan qo'shimcha imkoniyatlar (masalan, `receipt_corrections`).
    features = serializers.ListField(child=serializers.CharField(), required=False)
    server_time = serializers.DateTimeField()
