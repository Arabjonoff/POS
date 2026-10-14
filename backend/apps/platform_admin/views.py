import uuid
from datetime import date, datetime, time, timedelta
from zoneinfo import ZoneInfo

from django.db.models import Count, Max, OuterRef, Q, Subquery, Sum
from django.shortcuts import get_object_or_404
from drf_spectacular.types import OpenApiTypes
from drf_spectacular.utils import OpenApiParameter, extend_schema, extend_schema_view
from rest_framework import mixins, status, viewsets
from rest_framework.decorators import action
from rest_framework.exceptions import ValidationError
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.accounts.models import Role, User
from apps.accounts.permissions import IsPlatformAdmin
from apps.billing.models import Plan, SubscriptionPayment
from apps.devices.models import Device
from apps.sync.models import EventStatus, SyncEvent
from apps.tenants.models import DEFAULT_TIMEZONE, Tenant

from . import services, stats
from .models import AdminAuditLog
from .serializers import (
    AuditLogSerializer,
    OnboardResultSerializer,
    OnboardSerializer,
    OptionalReasonSerializer,
    PasswordResultSerializer,
    PaymentInputSerializer,
    PaymentSerializer,
    PaymentsListSerializer,
    PlanSerializer,
    PlatformDeviceSerializer,
    ReasonSerializer,
    ReverseInputSerializer,
    StatsSerializer,
    SubscriptionSerializer,
    SyncEventSerializer,
    TenantDetailSerializer,
    TenantListSerializer,
    TenantUpdateSerializer,
    UserBriefSerializer,
)

PLATFORM_TZ = ZoneInfo(DEFAULT_TIMEZONE)


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


def _body(serializer_class, data, **kwargs):
    serializer = serializer_class(data=data, **kwargs)
    serializer.is_valid(raise_exception=True)
    return serializer.validated_data


class PlatformMixin:
    permission_classes = [IsPlatformAdmin]


def _tenants():
    owners = User.objects.filter(tenant=OuterRef("pk"), role=Role.OWNER).order_by("created_at")
    return Tenant.objects.select_related("subscription__plan").annotate(
        owner_name=Subquery(owners.values("full_name")[:1]),
        devices_count=Count("devices", distinct=True),
        users_count=Count("users", distinct=True),
        last_activity_at=Max("devices__last_seen_at"),
    )


@extend_schema_view(
    list=extend_schema(
        parameters=[
            OpenApiParameter("search", str, description="Nom yoki ega telefoni"),
            OpenApiParameter(
                "status", str, enum=["trial", "active", "grace", "readonly", "blocked"]
            ),
        ]
    ),
    create=extend_schema(request=OnboardSerializer, responses={201: OnboardResultSerializer}),
    partial_update=extend_schema(request=TenantUpdateSerializer, responses=TenantDetailSerializer),
)
@extend_schema(tags=["platform"])
class TenantViewSet(
    PlatformMixin,
    mixins.ListModelMixin,
    mixins.RetrieveModelMixin,
    mixins.CreateModelMixin,
    mixins.UpdateModelMixin,
    viewsets.GenericViewSet,
):
    http_method_names = ["get", "post", "patch"]

    def get_queryset(self):
        queryset = _tenants().order_by("-created_at")
        if self.action != "list":
            return queryset
        params = self.request.query_params
        if search := params.get("search", "").strip():
            queryset = queryset.filter(Q(name__icontains=search) | Q(owner_phone__icontains=search))
        if wanted := params.get("status"):
            # Kesh (`Subscription.status`) — har o'zgarishda va kunlik yangilanadi.
            if wanted == "blocked":
                queryset = queryset.filter(is_blocked=True)
            else:
                queryset = queryset.filter(is_blocked=False, subscription__status=wanted)
        return queryset

    def get_serializer_class(self):
        return TenantListSerializer if self.action == "list" else TenantDetailSerializer

    def _detail(self, tenant, code=status.HTTP_200_OK):
        return Response(TenantDetailSerializer(_tenants().get(pk=tenant.pk)).data, status=code)

    def create(self, request):
        data = dict(_body(OnboardSerializer, request.data))
        tenant, owner, password = services.onboard_tenant(actor=request.user, data=data)
        result = {
            "tenant": _tenants().get(pk=tenant.pk),
            "owner": owner,
            "temporary_password": password,
        }
        return Response(OnboardResultSerializer(result).data, status=status.HTTP_201_CREATED)

    def partial_update(self, request, pk=None):
        tenant = self.get_object()
        data = _body(TenantUpdateSerializer, request.data, partial=True)
        return self._detail(services.update_tenant(tenant, actor=request.user, data=data))

    @extend_schema(request=ReasonSerializer, responses=TenantDetailSerializer)
    @action(detail=True, methods=["post"])
    def block(self, request, pk=None):
        reason = _body(ReasonSerializer, request.data)["reason"]
        tenant = services.set_tenant_blocked(
            self.get_object(), actor=request.user, blocked=True, reason=reason
        )
        return self._detail(tenant)

    @extend_schema(request=OptionalReasonSerializer, responses=TenantDetailSerializer)
    @action(detail=True, methods=["post"])
    def unblock(self, request, pk=None):
        reason = _body(OptionalReasonSerializer, request.data)["reason"]
        tenant = services.set_tenant_blocked(
            self.get_object(), actor=request.user, blocked=False, reason=reason
        )
        return self._detail(tenant)

    @extend_schema(request=SubscriptionSerializer, responses=TenantDetailSerializer)
    @action(detail=True, methods=["patch"])
    def subscription(self, request, pk=None):
        tenant = self.get_object()
        data = _body(SubscriptionSerializer, request.data, partial=True)
        services.update_subscription(tenant, actor=request.user, data=data)
        return self._detail(tenant)

    @extend_schema(responses=UserBriefSerializer(many=True))
    @action(detail=True, methods=["get"])
    def users(self, request, pk=None):
        users = self.get_object().users.order_by("created_at")
        return Response(UserBriefSerializer(users, many=True).data)

    @extend_schema(methods=["get"], request=None, responses=PaymentSerializer(many=True))
    @extend_schema(
        methods=["post"], request=PaymentInputSerializer, responses={201: PaymentSerializer}
    )
    @action(detail=True, methods=["get", "post"])
    def payments(self, request, pk=None):
        tenant = self.get_object()
        if request.method == "GET":
            payments = SubscriptionPayment.objects.filter(tenant=tenant).select_related("tenant")
            return Response(PaymentSerializer(payments.order_by("-paid_at"), many=True).data)
        data = _body(PaymentInputSerializer, request.data)
        payment = services.add_payment(tenant, actor=request.user, data=data)
        return Response(PaymentSerializer(payment).data, status=status.HTTP_201_CREATED)

    @extend_schema(
        parameters=[OpenApiParameter("status", str, enum=EventStatus.values)],
        responses=SyncEventSerializer(many=True),
    )
    @action(detail=True, methods=["get"], url_path="sync-events")
    def sync_events(self, request, pk=None):
        events = SyncEvent.objects.filter(tenant=self.get_object()).order_by("-received_at")
        if wanted := request.query_params.get("status"):
            events = events.filter(status=wanted)
        page = self.paginate_queryset(events)
        return self.get_paginated_response(SyncEventSerializer(page, many=True).data)


@extend_schema(tags=["platform"], request=None, responses=PasswordResultSerializer)
class UserResetPasswordView(PlatformMixin, APIView):
    def post(self, request, pk):
        user = get_object_or_404(User.objects.filter(tenant__isnull=False), pk=pk)
        password = services.reset_password(user, actor=request.user)
        return Response(PasswordResultSerializer({"temporary_password": password}).data)


@extend_schema_view(destroy=extend_schema(description="Nofaol qilish; obunalar saqlanadi."))
@extend_schema(tags=["platform"])
class PlanViewSet(PlatformMixin, viewsets.ModelViewSet):
    serializer_class = PlanSerializer
    http_method_names = ["get", "post", "patch", "delete"]

    def get_queryset(self):
        return Plan.objects.annotate(subscribers_count=Count("subscription")).order_by(
            "sort", "name"
        )

    def perform_create(self, serializer):
        serializer.instance = services.save_plan(
            None, actor=self.request.user, data=serializer.validated_data
        )

    def perform_update(self, serializer):
        serializer.instance = services.save_plan(
            serializer.instance, actor=self.request.user, data=serializer.validated_data
        )

    def perform_destroy(self, plan):
        services.save_plan(plan, actor=self.request.user, data={"is_active": False})


@extend_schema_view(
    list=extend_schema(
        parameters=[
            OpenApiParameter("tenant", OpenApiTypes.UUID),
            OpenApiParameter("date_from", OpenApiTypes.DATE),
            OpenApiParameter("date_to", OpenApiTypes.DATE),
        ],
        responses=PaymentsListSerializer,
    )
)
@extend_schema(tags=["platform"])
class PaymentViewSet(PlatformMixin, viewsets.ReadOnlyModelViewSet):
    serializer_class = PaymentSerializer

    def get_queryset(self):
        queryset = SubscriptionPayment.objects.select_related("tenant").order_by("-paid_at", "-id")
        if self.action != "list":
            return queryset
        params = self.request.query_params
        if tenant := _uuid_param(params, "tenant"):
            queryset = queryset.filter(tenant_id=tenant)
        if date_from := _date_param(params, "date_from"):
            queryset = queryset.filter(
                paid_at__gte=datetime.combine(date_from, time.min, PLATFORM_TZ)
            )
        if date_to := _date_param(params, "date_to"):
            end = datetime.combine(date_to + timedelta(days=1), time.min, PLATFORM_TZ)
            queryset = queryset.filter(paid_at__lt=end)
        return queryset

    def list(self, request, *args, **kwargs):
        queryset = self.get_queryset()
        total = queryset.aggregate(s=Sum("amount_tiyin"))["s"] or 0
        page = self.paginate_queryset(queryset)
        response = self.get_paginated_response(self.get_serializer(page, many=True).data)
        response.data["total_tiyin"] = total
        return response

    @extend_schema(request=ReverseInputSerializer, responses={201: PaymentSerializer})
    @action(detail=True, methods=["post"])
    def reverse(self, request, pk=None):
        note = _body(ReverseInputSerializer, request.data)["note"]
        reversal = services.cancel_payment(self.get_object(), actor=request.user, note=note)
        return Response(PaymentSerializer(reversal).data, status=status.HTTP_201_CREATED)


@extend_schema_view(
    list=extend_schema(
        parameters=[
            OpenApiParameter("tenant", OpenApiTypes.UUID),
            OpenApiParameter("blocked", bool),
            OpenApiParameter("stale_days", int, description="N kundan beri sinxronlanmagan"),
        ]
    )
)
@extend_schema(tags=["platform"])
class PlatformDeviceViewSet(PlatformMixin, viewsets.ReadOnlyModelViewSet):
    serializer_class = PlatformDeviceSerializer

    def get_queryset(self):
        queryset = Device.objects.select_related("tenant").order_by("tenant__name", "number")
        if self.action != "list":
            return queryset
        params = self.request.query_params
        if tenant := _uuid_param(params, "tenant"):
            queryset = queryset.filter(tenant_id=tenant)
        if params.get("blocked", "").lower() in ("true", "1"):
            queryset = queryset.filter(is_blocked=True)
        if (stale := params.get("stale_days")) is not None:
            if not stale.isdigit():
                raise ValidationError({"stale_days": "Must be a non-negative integer."})
            queryset = queryset.filter(stats.stale_q(int(stale)))
        return queryset

    @extend_schema(request=ReasonSerializer, responses=PlatformDeviceSerializer)
    @action(detail=True, methods=["post"])
    def block(self, request, pk=None):
        reason = _body(ReasonSerializer, request.data)["reason"]
        device = services.set_device_blocked(
            self.get_object(), actor=request.user, blocked=True, reason=reason
        )
        return Response(PlatformDeviceSerializer(device).data)

    @extend_schema(request=OptionalReasonSerializer, responses=PlatformDeviceSerializer)
    @action(detail=True, methods=["post"])
    def unblock(self, request, pk=None):
        reason = _body(OptionalReasonSerializer, request.data)["reason"]
        device = services.set_device_blocked(
            self.get_object(), actor=request.user, blocked=False, reason=reason
        )
        return Response(PlatformDeviceSerializer(device).data)


@extend_schema(tags=["platform"], responses=StatsSerializer)
class StatsView(PlatformMixin, APIView):
    def get(self, request):
        return Response(StatsSerializer(stats.platform_stats()).data)


@extend_schema_view(
    list=extend_schema(
        parameters=[
            OpenApiParameter("tenant", OpenApiTypes.UUID),
            OpenApiParameter("actor", OpenApiTypes.UUID),
            OpenApiParameter("target_type", str),
            OpenApiParameter("action", str),
        ]
    )
)
@extend_schema(tags=["platform"])
class AuditLogViewSet(PlatformMixin, viewsets.ReadOnlyModelViewSet):
    serializer_class = AuditLogSerializer

    def get_queryset(self):
        queryset = AdminAuditLog.objects.select_related("actor")
        params = self.request.query_params
        for name in ("tenant", "actor"):
            if (value := _uuid_param(params, name)) is not None:
                queryset = queryset.filter(**{f"{name}_id": value})
        for name in ("target_type", "action"):
            if value := params.get(name):
                queryset = queryset.filter(**{name: value})
        return queryset
