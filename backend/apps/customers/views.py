from drf_spectacular.utils import OpenApiParameter, extend_schema, extend_schema_view
from rest_framework import status
from rest_framework.decorators import action
from rest_framework.response import Response

from apps.accounts.permissions import IsManagerOrOwner, IsOwner, IsTenantMember
from apps.core.tenancy import TenantScopedViewSet

from . import services
from .models import Customer
from .serializers import (
    AdjustmentSerializer,
    CustomerSerializer,
    DebtEntryResultSerializer,
    DebtEntrySerializer,
    PaymentSerializer,
)

MEMBER_ACTIONS = frozenset(
    {"list", "retrieve", "create", "update", "partial_update", "debt_entries", "payments"}
)


def _bool_param(value):
    return {"true": True, "1": True, "false": False, "0": False}.get((value or "").lower())


@extend_schema_view(
    list=extend_schema(
        parameters=[
            OpenApiParameter("search", str, description="Ism yoki telefon (qisman)"),
            OpenApiParameter("has_debt", bool, description="Faqat qarzdorlar (balans > 0)"),
        ],
        description="Qarzdorlar birinchi (qarz kamayib), keyin ism.",
    ),
    destroy=extend_schema(description="Yumshoq o'chirish; qarzi bor — `409 customer_has_debt`."),
)
@extend_schema(tags=["customers"])
class CustomerViewSet(TenantScopedViewSet):
    queryset = Customer.objects.all()
    serializer_class = CustomerSerializer

    def get_permissions(self):
        if self.action in MEMBER_ACTIONS:
            return [IsTenantMember()]
        if self.action == "adjustments":
            return [IsOwner()]
        return [IsManagerOrOwner()]

    def get_queryset(self):
        queryset = super().get_queryset().filter(deleted_at__isnull=True)
        if self.action != "list":
            return services.with_balance(queryset)
        params = self.request.query_params
        queryset = services.search_customers(queryset, params.get("search", ""))
        queryset = services.debtors_first(queryset)
        if _bool_param(params.get("has_debt")):
            queryset = queryset.filter(balance_tiyin__gt=0)
        return queryset

    def perform_destroy(self, customer):
        services.soft_delete_customer(customer)

    def _entry_response(self, entry, customer):
        data = {"entry": entry, "balance_tiyin": services.customer_balance(customer)}
        return Response(DebtEntryResultSerializer(data).data, status=status.HTTP_201_CREATED)

    @extend_schema(responses=DebtEntrySerializer(many=True))
    @action(detail=True, methods=["get"], url_path="debt-entries")
    def debt_entries(self, request, pk=None):
        customer = self.get_object()
        page = self.paginate_queryset(customer.debt_entries.all())
        return self.get_paginated_response(DebtEntrySerializer(page, many=True).data)

    @extend_schema(request=PaymentSerializer, responses={201: DebtEntryResultSerializer})
    @action(detail=True, methods=["post"])
    def payments(self, request, pk=None):
        customer = self.get_object()
        body = PaymentSerializer(data=request.data)
        body.is_valid(raise_exception=True)
        entry = services.pay_debt(customer, user=request.user, **body.validated_data)
        return self._entry_response(entry, customer)

    @extend_schema(request=AdjustmentSerializer, responses={201: DebtEntryResultSerializer})
    @action(detail=True, methods=["post"])
    def adjustments(self, request, pk=None):
        customer = self.get_object()
        body = AdjustmentSerializer(data=request.data)
        body.is_valid(raise_exception=True)
        entry = services.adjust_debt(customer, user=request.user, **body.validated_data)
        return self._entry_response(entry, customer)
