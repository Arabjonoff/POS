from django.shortcuts import get_object_or_404
from django.utils import timezone
from drf_spectacular.types import OpenApiTypes
from drf_spectacular.utils import OpenApiParameter, extend_schema
from rest_framework import serializers
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.billing.services import subscription_snapshot
from apps.catalog.models import Product
from apps.catalog.serializers import PriceHistorySerializer
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


class SyncPriceHistoryView(APIView):
    """Kassa uchun tovar narx tarixi (onlayn): qurilma tokeni bilan, faqat
    o'z tenanti. Kim ko'rishi (menejer/ega) — kassada lokal PIN bilan."""

    authentication_classes = [DeviceTokenAuthentication]
    permission_classes = [IsDevice]
    LIMIT = 50

    @extend_schema(
        parameters=[OpenApiParameter("product", OpenApiTypes.UUID, required=True)],
        responses=PriceHistorySerializer(many=True),
        tags=["sync"],
    )
    def get(self, request):
        product_id = serializers.UUIDField().run_validation(request.query_params.get("product"))
        product = get_object_or_404(
            Product.objects.filter(tenant_id=request.auth.tenant_id, deleted_at__isnull=True),
            pk=product_id,
        )
        entries = product.price_history.select_related("changed_by").order_by("-at", "-id")
        return Response(PriceHistorySerializer(entries[: self.LIMIT], many=True).data)
