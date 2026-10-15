from django.db.models import OuterRef, Prefetch, Subquery, Sum
from django.db.models.functions import Coalesce
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
from apps.devices.releases import app_release
from apps.inventory.models import StockMovement
from apps.sales.models import Refund, RefundItem, Sale, SaleItem, SalePayment

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


SERVER_FEATURES = ["receipt_corrections", "store_settings"]


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
        data |= {
            "subscription": subscription_snapshot(device.tenant),
            "app": app_release(device.platform),
            # Kassa yangi hodisani faqat server uni bilsa yuboradi (eski server
            # `unknown_event` bilan rad etib, kassa qoldig'i farq qilib qolmasin).
            "features": SERVER_FEATURES,
            "server_time": now,
        }
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


class StockMovementEntrySerializer(serializers.ModelSerializer):
    created_by_name = serializers.CharField(
        source="created_by.full_name", default=None, read_only=True, allow_null=True
    )

    class Meta:
        model = StockMovement
        fields = ["id", "type", "qty_milli", "ref_type", "at", "created_by_name"]
        read_only_fields = fields


class SyncStockMovementsView(APIView):
    """Kassa uchun tovar qoldiq harakatlari (onlayn, T-054): barcha kassalar,
    oxirgi 100 ta, faqat o'z tenanti."""

    authentication_classes = [DeviceTokenAuthentication]
    permission_classes = [IsDevice]
    LIMIT = 100

    @extend_schema(
        parameters=[OpenApiParameter("product", OpenApiTypes.UUID, required=True)],
        responses=StockMovementEntrySerializer(many=True),
        tags=["sync"],
    )
    def get(self, request):
        product_id = serializers.UUIDField().run_validation(request.query_params.get("product"))
        product = get_object_or_404(
            Product.objects.filter(tenant_id=request.auth.tenant_id, deleted_at__isnull=True),
            pk=product_id,
        )
        movements = (
            StockMovement.objects.filter(tenant_id=request.auth.tenant_id, product=product)
            .select_related("created_by")
            .order_by("-at", "-id")[: self.LIMIT]
        )
        return Response(StockMovementEntrySerializer(movements, many=True).data)


class DeviceSaleItemSerializer(serializers.ModelSerializer):
    refunded_qty_milli = serializers.IntegerField(read_only=True)
    refunded_tiyin = serializers.IntegerField(read_only=True)

    class Meta:
        model = SaleItem
        fields = [
            "id",
            "product",
            "name_snapshot",
            "barcode_snapshot",
            "qty_milli",
            "price_tiyin",
            "discount_tiyin",
            "total_tiyin",
            "refunded_qty_milli",
            "refunded_tiyin",
        ]
        read_only_fields = fields


class DeviceSalePaymentSerializer(serializers.ModelSerializer):
    class Meta:
        model = SalePayment
        fields = ["method", "amount_tiyin", "received_tiyin", "change_tiyin"]
        read_only_fields = fields


class DeviceSaleRefundSerializer(serializers.ModelSerializer):
    class Meta:
        model = Refund
        fields = ["id", "at", "method", "total_tiyin", "reason"]
        read_only_fields = fields


class DeviceSaleSerializer(serializers.ModelSerializer):
    device_number = serializers.IntegerField(source="device.number", read_only=True)
    cashier_name = serializers.CharField(source="cashier.full_name", read_only=True)
    customer_name = serializers.CharField(
        source="customer.full_name", default=None, read_only=True, allow_null=True
    )
    items = DeviceSaleItemSerializer(many=True, read_only=True)
    payments = DeviceSalePaymentSerializer(many=True, read_only=True)
    refunds = DeviceSaleRefundSerializer(many=True, read_only=True)

    class Meta:
        model = Sale
        fields = [
            "id",
            "number",
            "store",
            "device_number",
            "cashier",
            "cashier_name",
            "customer",
            "customer_name",
            "subtotal_tiyin",
            "discount_tiyin",
            "total_tiyin",
            "status",
            "sold_at",
            "items",
            "payments",
            "refunds",
        ]
        read_only_fields = fields


class SyncSaleView(APIView):
    """Boshqa kassa cheki chek raqami bo'yicha (onlayn, T-110, Q-006 → A):
    ko'rish, qayta chop etish, qaytarish uchun. Qurilma tokeni, faqat o'z
    tenanti; qatorlarda — oldin qaytarilgan miqdor va summa."""

    authentication_classes = [DeviceTokenAuthentication]
    permission_classes = [IsDevice]

    @extend_schema(
        operation_id="sync_sale_by_number",
        parameters=[OpenApiParameter("number", OpenApiTypes.STR, required=True)],
        responses=DeviceSaleSerializer,
        tags=["sync"],
    )
    def get(self, request):
        number = (request.query_params.get("number") or "").strip().upper()
        if not number:
            raise serializers.ValidationError({"number": "Required."})
        refunded = RefundItem.objects.filter(sale_item=OuterRef("pk")).values("sale_item")
        items = SaleItem.objects.annotate(
            refunded_qty_milli=Coalesce(
                Subquery(refunded.annotate(s=Sum("qty_milli")).values("s")), 0
            ),
            refunded_tiyin=Coalesce(
                Subquery(refunded.annotate(s=Sum("total_tiyin")).values("s")), 0
            ),
        )
        sale = get_object_or_404(
            Sale.objects.filter(tenant_id=request.auth.tenant_id)
            .select_related("device", "cashier", "customer")
            .prefetch_related(
                Prefetch("items", queryset=items),
                "payments",
                Prefetch("refunds", queryset=Refund.objects.order_by("at", "id")),
            ),
            number=number,
        )
        return Response(DeviceSaleSerializer(sale).data)
