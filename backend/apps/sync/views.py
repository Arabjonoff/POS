from django.utils import timezone
from drf_spectacular.utils import extend_schema
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.billing.services import subscription_snapshot
from apps.devices.authentication import DeviceTokenAuthentication
from apps.devices.permissions import IsDevice

from . import services
from .pull import pull
from .serializers import (
    PullQuerySerializer,
    PullResponseSerializer,
    PushRequestSerializer,
    PushResponseSerializer,
)


class SyncPushView(APIView):
    """Kassa hodisalarini qabul qiladi (idempotent, paketli)."""

    authentication_classes = [DeviceTokenAuthentication]
    permission_classes = [IsDevice]

    @extend_schema(request=PushRequestSerializer, responses=PushResponseSerializer, tags=["sync"])
    def post(self, request):
        body = PushRequestSerializer(data=request.data)
        body.is_valid(raise_exception=True)
        results = services.push(request.auth, body.validated_data["events"])
        data = {"results": results, "server_time": timezone.now()}
        return Response(PushResponseSerializer(data).data)


class SyncPullView(APIView):
    """Server o'zgarishlari (ChangeLog) kursor bo'yicha + obuna holati."""

    authentication_classes = [DeviceTokenAuthentication]
    permission_classes = [IsDevice]

    @extend_schema(
        parameters=[PullQuerySerializer], responses=PullResponseSerializer, tags=["sync"]
    )
    def get(self, request):
        query = PullQuerySerializer(data=request.query_params)
        query.is_valid(raise_exception=True)
        device = request.auth
        data = pull(device, query.validated_data["cursor"], query.validated_data["limit"])
        now = timezone.now()
        device.last_sync_at = now
        device.last_seen_at = now
        device.save(update_fields=["last_sync_at", "last_seen_at"])
        data |= {"subscription": subscription_snapshot(device.tenant), "server_time": now}
        return Response(PullResponseSerializer(data).data)
