import uuid

from django.db.models import F
from django.utils import timezone
from drf_spectacular.types import OpenApiTypes
from drf_spectacular.utils import OpenApiParameter, extend_schema, extend_schema_view
from rest_framework import mixins, status, viewsets
from rest_framework.decorators import action
from rest_framework.exceptions import ValidationError
from rest_framework.response import Response

from apps.accounts.permissions import IsManagerOrOwner, IsTenantMember
from apps.core.tenancy import TenantScopedMixin, TenantScopedViewSet

from . import services
from .models import (
    InventoryCount,
    MovementType,
    ProductStock,
    StockMovement,
    StockReceipt,
    Supplier,
)
from .serializers import (
    InventoryCountSerializer,
    ReverseReceiptSerializer,
    StockMovementSerializer,
    StockReceiptSerializer,
    StockSerializer,
    SupplierSerializer,
)

READ_ACTIONS = frozenset({"list", "retrieve"})
DOCUMENT_METHODS = ["get", "post", "patch", "delete"]


def _uuid_param(params, name):
    value = params.get(name)
    if not value:
        return None
    try:
        return uuid.UUID(value)
    except ValueError:
        raise ValidationError({name: "Must be a valid UUID."}) from None


def _bool_param(value):
    return {"true": True, "1": True, "false": False, "0": False}.get((value or "").lower())


@extend_schema(tags=["inventory"])
class SupplierViewSet(TenantScopedViewSet):
    """O'qish — tenantning har bir xodimi; yozish — ega va menejer. O'chirish — yumshoq."""

    queryset = Supplier.objects.all()
    serializer_class = SupplierSerializer

    def get_permissions(self):
        if self.action in READ_ACTIONS:
            return [IsTenantMember()]
        return [IsManagerOrOwner()]

    def get_queryset(self):
        return super().get_queryset().filter(deleted_at__isnull=True)

    def perform_destroy(self, supplier):
        supplier.deleted_at = timezone.now()
        supplier.save(update_fields=["deleted_at", "updated_at"])


class DocumentViewSet(TenantScopedViewSet):
    """Kirim va inventarizatsiya hujjatlari — faqat ega va menejer (tannarx ko'rinadi)."""

    permission_classes = [IsManagerOrOwner]
    http_method_names = DOCUMENT_METHODS

    def perform_create(self, serializer):
        # Tenant va do'kon servisda qo'yiladi.
        serializer.save()

    def get_queryset(self):
        queryset = super().get_queryset().prefetch_related("items")
        if self.action == "list" and (doc_status := self.request.query_params.get("status")):
            queryset = queryset.filter(status=doc_status)
        return queryset


@extend_schema_view(
    list=extend_schema(parameters=[OpenApiParameter("status", str, enum=["draft", "posted"])]),
    partial_update=extend_schema(description="Faqat qoralama; `items` yuborilsa — almashtiriladi."),
    destroy=extend_schema(description="Faqat qoralama; tasdiqlangani — `409 receipt_not_draft`."),
)
@extend_schema(tags=["inventory"])
class StockReceiptViewSet(DocumentViewSet):
    queryset = StockReceipt.objects.all()
    serializer_class = StockReceiptSerializer

    def perform_destroy(self, receipt):
        services.delete_receipt(receipt)

    @extend_schema(request=None, responses=StockReceiptSerializer)
    @action(detail=True, methods=["post"], url_path="post", url_name="post")
    def post_document(self, request, pk=None):
        receipt = services.post_receipt(self.get_object(), user=request.user)
        return Response(self.get_serializer(receipt).data)

    @extend_schema(request=ReverseReceiptSerializer, responses={201: StockReceiptSerializer})
    @action(detail=True, methods=["post"])
    def reverse(self, request, pk=None):
        body = ReverseReceiptSerializer(data=request.data)
        body.is_valid(raise_exception=True)
        reversal = services.reverse_receipt(
            self.get_object(), user=request.user, note=body.validated_data["note"]
        )
        return Response(self.get_serializer(reversal).data, status=status.HTTP_201_CREATED)


@extend_schema_view(
    list=extend_schema(parameters=[OpenApiParameter("status", str, enum=["draft", "posted"])]),
    partial_update=extend_schema(description="Faqat qoralama; `items` yuborilsa — almashtiriladi."),
    destroy=extend_schema(description="Faqat qoralama; tasdiqlangani — `409 count_not_draft`."),
)
@extend_schema(tags=["inventory"])
class InventoryCountViewSet(DocumentViewSet):
    queryset = InventoryCount.objects.all()
    serializer_class = InventoryCountSerializer

    def perform_destroy(self, count):
        services.delete_count(count)

    @extend_schema(request=None, responses=InventoryCountSerializer)
    @action(detail=True, methods=["post"], url_path="post", url_name="post")
    def post_document(self, request, pk=None):
        count = services.post_inventory(self.get_object(), user=request.user)
        return Response(self.get_serializer(count).data)


@extend_schema_view(
    list=extend_schema(
        parameters=[
            OpenApiParameter("product", OpenApiTypes.UUID),
            OpenApiParameter("store", OpenApiTypes.UUID),
            OpenApiParameter("low", bool, description="Qoldiq `min_stock_milli` dan kam"),
            OpenApiParameter("negative", bool, description="Manfiy qoldiq"),
        ]
    )
)
@extend_schema(tags=["inventory"])
class StockViewSet(TenantScopedMixin, mixins.ListModelMixin, viewsets.GenericViewSet):
    queryset = ProductStock.objects.order_by("product__name", "product_id")
    serializer_class = StockSerializer
    permission_classes = [IsTenantMember]

    def get_queryset(self):
        queryset = super().get_queryset()
        params = self.request.query_params
        if product := _uuid_param(params, "product"):
            queryset = queryset.filter(product_id=product)
        if store := _uuid_param(params, "store"):
            queryset = queryset.filter(store_id=store)
        if _bool_param(params.get("low")):
            queryset = queryset.filter(
                product__min_stock_milli__gt=0, qty_milli__lt=F("product__min_stock_milli")
            )
        if _bool_param(params.get("negative")):
            queryset = queryset.filter(qty_milli__lt=0)
        return queryset


@extend_schema_view(
    list=extend_schema(
        parameters=[
            OpenApiParameter("product", OpenApiTypes.UUID),
            OpenApiParameter("store", OpenApiTypes.UUID),
            OpenApiParameter("type", str, enum=MovementType.values),
        ]
    )
)
@extend_schema(tags=["inventory"])
class StockMovementViewSet(TenantScopedMixin, mixins.ListModelMixin, viewsets.GenericViewSet):
    """Harakatlar tarixi, yangisi birinchi."""

    queryset = StockMovement.objects.all()
    serializer_class = StockMovementSerializer
    permission_classes = [IsTenantMember]

    def get_queryset(self):
        queryset = super().get_queryset()
        params = self.request.query_params
        if product := _uuid_param(params, "product"):
            queryset = queryset.filter(product_id=product)
        if store := _uuid_param(params, "store"):
            queryset = queryset.filter(store_id=store)
        if movement_type := params.get("type"):
            queryset = queryset.filter(type=movement_type)
        return queryset
