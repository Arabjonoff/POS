from rest_framework import serializers

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
