import uuid
from datetime import date, datetime, time, timedelta
from zoneinfo import ZoneInfo

from drf_spectacular.types import OpenApiTypes
from drf_spectacular.utils import OpenApiParameter, extend_schema, extend_schema_view
from rest_framework.decorators import action
from rest_framework.exceptions import ValidationError
from rest_framework.response import Response

from apps.accounts.models import Role
from apps.accounts.permissions import IsTenantMember
from apps.core.tenancy import TenantScopedReadOnlyViewSet
from apps.tenants.models import Tenant

from .models import CashMovement, Refund, Sale, Shift
from .serializers import (
    CashMovementSerializer,
    RefundSerializer,
    SaleSerializer,
    ShiftReportSerializer,
    ShiftSerializer,
)
from .services import shift_report


def _uuid_param(params, name):
    value = params.get(name)
    if not value:
        return None
    try:
        return uuid.UUID(value)
    except ValueError:
        raise ValidationError({name: "Must be a valid UUID."}) from None


def _date_param(params, name):
    value = params.get(name)
    if not value:
        return None
    try:
        return date.fromisoformat(value)
    except ValueError:
        raise ValidationError({name: "Must be a date (YYYY-MM-DD)."}) from None


def _bool_param(value):
    return {"true": True, "1": True, "false": False, "0": False}.get((value or "").lower())


class SalesReadViewSet(TenantScopedReadOnlyViewSet):
    """Faqat o'qish. Kassir faqat o'zinikini ko'radi (`own_field`)."""

    permission_classes = [IsTenantMember]
    own_field = "cashier"

    def get_queryset(self):
        queryset = super().get_queryset()
        user = self.request.user
        if user.role == Role.CASHIER:
            queryset = queryset.filter(**{self.own_field: user})
        return queryset

    def filter_uuid(self, queryset, *names):
        for name in names:
            if (value := _uuid_param(self.request.query_params, name)) is not None:
                queryset = queryset.filter(**{f"{name}_id": value})
        return queryset


@extend_schema_view(
    list=extend_schema(
        parameters=[
            OpenApiParameter("device", OpenApiTypes.UUID),
            OpenApiParameter("open", bool, description="Faqat ochiq smenalar"),
        ]
    )
)
@extend_schema(tags=["sales"])
class ShiftViewSet(SalesReadViewSet):
    queryset = Shift.objects.all()
    serializer_class = ShiftSerializer
    own_field = "opened_by"

    def get_queryset(self):
        queryset = super().get_queryset()
        if self.action != "list":
            return queryset
        queryset = self.filter_uuid(queryset, "device")
        if (is_open := _bool_param(self.request.query_params.get("open"))) is not None:
            queryset = queryset.filter(closed_at__isnull=is_open)
        return queryset

    @extend_schema(responses=ShiftReportSerializer)
    @action(detail=True, methods=["get"])
    def report(self, request, pk=None):
        return Response(ShiftReportSerializer(shift_report(self.get_object())).data)


@extend_schema_view(
    list=extend_schema(
        parameters=[
            OpenApiParameter("shift", OpenApiTypes.UUID),
            OpenApiParameter("customer", OpenApiTypes.UUID),
            OpenApiParameter("date_from", OpenApiTypes.DATE, description="Do'kon vaqt zonasida"),
            OpenApiParameter("date_to", OpenApiTypes.DATE, description="Shu kun ham kiradi"),
        ]
    )
)
@extend_schema(tags=["sales"])
class SaleViewSet(SalesReadViewSet):
    queryset = Sale.objects.prefetch_related("items", "payments")
    serializer_class = SaleSerializer

    def get_queryset(self):
        queryset = super().get_queryset()
        if self.action != "list":
            return queryset
        queryset = self.filter_uuid(queryset, "shift", "customer")
        params = self.request.query_params
        date_from, date_to = _date_param(params, "date_from"), _date_param(params, "date_to")
        if date_from or date_to:
            tz = ZoneInfo(Tenant.objects.get(pk=self.get_tenant_id()).timezone)
            if date_from:
                queryset = queryset.filter(sold_at__gte=datetime.combine(date_from, time.min, tz))
            if date_to:
                end = datetime.combine(date_to + timedelta(days=1), time.min, tz)
                queryset = queryset.filter(sold_at__lt=end)
        return queryset


@extend_schema_view(
    list=extend_schema(
        parameters=[
            OpenApiParameter("sale", OpenApiTypes.UUID),
            OpenApiParameter("shift", OpenApiTypes.UUID),
        ]
    )
)
@extend_schema(tags=["sales"])
class RefundViewSet(SalesReadViewSet):
    queryset = Refund.objects.prefetch_related("items")
    serializer_class = RefundSerializer

    def get_queryset(self):
        queryset = super().get_queryset()
        if self.action == "list":
            queryset = self.filter_uuid(queryset, "sale", "shift")
        return queryset


@extend_schema_view(list=extend_schema(parameters=[OpenApiParameter("shift", OpenApiTypes.UUID)]))
@extend_schema(tags=["sales"])
class CashMovementViewSet(SalesReadViewSet):
    queryset = CashMovement.objects.all()
    serializer_class = CashMovementSerializer
    own_field = "created_by"

    def get_queryset(self):
        queryset = super().get_queryset()
        if self.action == "list":
            queryset = self.filter_uuid(queryset, "shift")
        return queryset
