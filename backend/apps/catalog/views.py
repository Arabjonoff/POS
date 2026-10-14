from django.db.models import Prefetch, Q
from django.shortcuts import get_object_or_404
from django.utils import timezone
from drf_spectacular.types import OpenApiTypes
from drf_spectacular.utils import OpenApiParameter, extend_schema, extend_schema_view
from rest_framework import status
from rest_framework.decorators import action
from rest_framework.response import Response

from apps.accounts.permissions import IsManagerOrOwner, IsTenantMember
from apps.core.exceptions import DomainError
from apps.core.tenancy import TenantScopedViewSet

from .models import Category, Product, ProductBarcode, Unit
from .serializers import CategorySerializer, ProductSerializer, UnitSerializer
from .services import soft_delete_category

READ_ACTIONS = frozenset({"list", "retrieve", "by_barcode"})


class CatalogViewSet(TenantScopedViewSet):
    """O'qish — tenantning har bir xodimi; yozish — ega va menejer."""

    def get_permissions(self):
        if self.action in READ_ACTIONS:
            return [IsTenantMember()]
        return [IsManagerOrOwner()]

    def get_queryset(self):
        return super().get_queryset().filter(deleted_at__isnull=True)


@extend_schema(tags=["catalog"])
class UnitViewSet(CatalogViewSet):
    queryset = Unit.objects.all()
    serializer_class = UnitSerializer

    def perform_destroy(self, unit):
        if Product.objects.filter(unit=unit, deleted_at__isnull=True).exists():
            raise DomainError("unit_in_use", "Unit is used by products.", status_code=409)
        unit.deleted_at = timezone.now()
        unit.save(update_fields=["deleted_at", "updated_at"])


@extend_schema(tags=["catalog"])
class CategoryViewSet(CatalogViewSet):
    queryset = Category.objects.all()
    serializer_class = CategorySerializer

    def perform_destroy(self, category):
        soft_delete_category(category)


def _bool_param(value):
    return {"true": True, "1": True, "false": False, "0": False}.get((value or "").lower())


@extend_schema_view(
    list=extend_schema(
        parameters=[
            OpenApiParameter("search", str, description="Nom (qisman), shtrix-kod yoki PLU"),
            OpenApiParameter("category", OpenApiTypes.UUID),
            OpenApiParameter("is_active", bool),
            OpenApiParameter("quick_button", bool),
        ]
    ),
    destroy=extend_schema(description="Nofaol qilish (`is_active=false`); tarix saqlanadi."),
)
@extend_schema(tags=["catalog"])
class ProductViewSet(CatalogViewSet):
    queryset = Product.objects.select_related("unit", "category")
    serializer_class = ProductSerializer

    def get_queryset(self):
        queryset = (
            super()
            .get_queryset()
            .prefetch_related(
                Prefetch(
                    "barcodes", queryset=ProductBarcode.objects.filter(deleted_at__isnull=True)
                )
            )
        )
        if self.action != "list":
            return queryset
        params = self.request.query_params
        if search := params.get("search", "").strip():
            queryset = queryset.filter(
                Q(name__icontains=search)
                | Q(plu_code=search)
                | Q(barcodes__barcode=search, barcodes__deleted_at__isnull=True)
            ).distinct()
        if category := params.get("category"):
            queryset = queryset.filter(category_id=category)
        if (is_active := _bool_param(params.get("is_active"))) is not None:
            queryset = queryset.filter(is_active=is_active)
        if _bool_param(params.get("quick_button")):
            queryset = queryset.filter(quick_button=True)
        return queryset

    def perform_destroy(self, product):
        product.is_active = False
        product.save(update_fields=["is_active", "updated_at"])

    @extend_schema(
        parameters=[OpenApiParameter("code", str, OpenApiParameter.PATH)],
        responses=ProductSerializer,
    )
    @action(detail=False, methods=["get"], url_path=r"by-barcode/(?P<code>[^/]+)")
    def by_barcode(self, request, code=None):
        barcode = get_object_or_404(
            ProductBarcode.objects.filter(tenant_id=self.get_tenant_id(), deleted_at__isnull=True),
            barcode=(code or "").strip(),
        )
        product = get_object_or_404(self.get_queryset(), pk=barcode.product_id)
        return Response(self.get_serializer(product).data, status=status.HTTP_200_OK)
