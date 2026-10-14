from django.utils import timezone
from drf_spectacular.utils import extend_schema
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.devices.authentication import DeviceTokenAuthentication
from apps.devices.permissions import IsDevice

from . import services
from .serializers import PushRequestSerializer, PushResponseSerializer


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
