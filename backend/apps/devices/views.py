from django.utils import timezone
from drf_spectacular.utils import OpenApiResponse, extend_schema
from rest_framework import status
from rest_framework.response import Response
from rest_framework.throttling import ScopedRateThrottle
from rest_framework.views import APIView

from apps.accounts.permissions import IsManagerOrOwner, IsOwner
from apps.billing.services import subscription_snapshot
from apps.core.tenancy import TenantScopedReadOnlyViewSet

from .authentication import DeviceTokenAuthentication
from .models import Device
from .permissions import IsDevice
from .serializers import (
    DeviceMeSerializer,
    DeviceRegisterResponseSerializer,
    DeviceRegisterSerializer,
    DeviceSerializer,
)
from .services import register_device


class DeviceRegisterView(APIView):
    """Ega kassa qurilmasini ulaydi; javobda qurilma tokeni (faqat bir marta)."""

    permission_classes = [IsOwner]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "auth"

    @extend_schema(
        request=DeviceRegisterSerializer,
        responses={
            201: DeviceRegisterResponseSerializer,
            200: OpenApiResponse(DeviceRegisterResponseSerializer, "Qayta ro'yxatdan o'tish"),
        },
        tags=["devices"],
    )
    def post(self, request):
        serializer = DeviceRegisterSerializer(data=request.data, context={"request": request})
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data
        device, token, created = register_device(
            user=request.user,
            name=data["name"],
            platform=data["platform"],
            app_version=data.get("app_version", ""),
            store=data.get("store"),
            device_id=data.get("id"),
        )
        return Response(
            {"device": DeviceSerializer(device).data, "token": token},
            status=status.HTTP_201_CREATED if created else status.HTTP_200_OK,
        )


class DeviceMeView(APIView):
    """Qurilma o'zi haqida va obuna holati (kassa ulanganda tekshiradi)."""

    authentication_classes = [DeviceTokenAuthentication]
    permission_classes = [IsDevice]

    @extend_schema(responses=DeviceMeSerializer, tags=["devices"])
    def get(self, request):
        device = request.auth
        device.last_seen_at = timezone.now()
        device.last_ip = request.META.get("REMOTE_ADDR") or None
        device.save(update_fields=["last_seen_at", "last_ip"])
        return Response(
            {
                "device": DeviceSerializer(device).data,
                "subscription": subscription_snapshot(device.tenant),
                "server_time": device.last_seen_at,
            }
        )


@extend_schema(tags=["devices"])
class DeviceViewSet(TenantScopedReadOnlyViewSet):
    """O'z tenanti qurilmalari (ega va menejer)."""

    queryset = Device.objects.all()
    serializer_class = DeviceSerializer
    permission_classes = [IsManagerOrOwner]
