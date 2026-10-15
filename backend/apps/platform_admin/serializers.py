from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

from rest_framework import serializers

from apps.accounts.models import User
from apps.billing.models import PaymentMethod, Plan, Subscription, SubscriptionPayment
from apps.billing.services import tenant_today
from apps.billing.status import compute_status
from apps.core.fields import StrictIntegerField, money_field
from apps.core.phone import normalize_phone
from apps.devices.models import Device
from apps.sync.models import SyncEvent
from apps.tenants.models import Tenant

from .models import AdminAuditLog


def live_status(tenant) -> tuple[str, int | None]:
    """Obuna holati bugungi kun bo'yicha (kesh emas)."""
    sub = getattr(tenant, "subscription", None)
    info = compute_status(
        today=tenant_today(tenant),
        trial_ends_at=sub.trial_ends_at if sub else None,
        paid_until=sub.paid_until if sub else None,
        grace_days=sub.grace_days if sub else 0,
        is_blocked=tenant.is_blocked,
    )
    return info.status, info.days_left


class TenantListSerializer(serializers.ModelSerializer):
    owner_name = serializers.CharField(read_only=True, default="")
    plan = serializers.SerializerMethodField()
    status = serializers.SerializerMethodField()
    paid_until = serializers.SerializerMethodField()
    trial_ends_at = serializers.SerializerMethodField()
    devices_count = serializers.IntegerField(read_only=True)
    last_activity_at = serializers.DateTimeField(read_only=True, allow_null=True)

    class Meta:
        model = Tenant
        fields = [
            "id",
            "name",
            "owner_phone",
            "owner_name",
            "plan",
            "status",
            "paid_until",
            "trial_ends_at",
            "devices_count",
            "last_activity_at",
            "is_blocked",
            "created_at",
        ]

    def _sub(self, tenant):
        return getattr(tenant, "subscription", None)

    def get_plan(self, tenant) -> str | None:
        sub = self._sub(tenant)
        return str(sub.plan_id) if sub else None

    def get_status(self, tenant) -> str:
        return live_status(tenant)[0]

    def get_paid_until(self, tenant) -> str | None:
        sub = self._sub(tenant)
        return sub.paid_until.isoformat() if sub and sub.paid_until else None

    def get_trial_ends_at(self, tenant) -> str | None:
        sub = self._sub(tenant)
        return sub.trial_ends_at.isoformat() if sub and sub.trial_ends_at else None


class SubscriptionSerializer(serializers.ModelSerializer):
    plan = serializers.PrimaryKeyRelatedField(queryset=Plan.objects.all())
    status = serializers.SerializerMethodField()
    days_left = serializers.SerializerMethodField()

    class Meta:
        model = Subscription
        fields = [
            "plan",
            "trial_ends_at",
            "paid_until",
            "grace_days",
            "offline_days",
            "status",
            "days_left",
        ]
        read_only_fields = ["paid_until"]

    def get_status(self, sub) -> str:
        return live_status(sub.tenant)[0]

    def get_days_left(self, sub) -> int | None:
        return live_status(sub.tenant)[1]


class TenantDetailSerializer(TenantListSerializer):
    subscription = SubscriptionSerializer(read_only=True, allow_null=True)
    users_count = serializers.IntegerField(read_only=True)

    class Meta(TenantListSerializer.Meta):
        fields = [
            *TenantListSerializer.Meta.fields,
            "address",
            "timezone",
            "default_locale",
            "notes",
            "blocked_reason",
            "subscription",
            "users_count",
        ]


class TenantUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Tenant
        fields = ["name", "address", "timezone", "default_locale", "notes"]

    def validate_timezone(self, value):
        try:
            ZoneInfo(value)
        except (ZoneInfoNotFoundError, ValueError):
            raise serializers.ValidationError("Unknown time zone.") from None
        return value


class OwnerInputSerializer(serializers.Serializer):
    phone = serializers.CharField()
    full_name = serializers.CharField(max_length=200)
    password = serializers.CharField(
        required=False, allow_blank=True, min_length=8, write_only=True
    )

    def validate_phone(self, value):
        try:
            return normalize_phone(value)
        except ValueError as exc:
            raise serializers.ValidationError(str(exc)) from None


class OnboardSerializer(TenantUpdateSerializer):
    owner = OwnerInputSerializer()
    plan = serializers.PrimaryKeyRelatedField(queryset=Plan.objects.filter(is_active=True))
    trial_days = serializers.IntegerField(min_value=0, max_value=90, default=14)

    class Meta(TenantUpdateSerializer.Meta):
        fields = [*TenantUpdateSerializer.Meta.fields, "owner", "plan", "trial_days"]


class UserBriefSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ["id", "phone", "full_name", "role", "is_active", "last_login", "created_at"]


class OnboardResultSerializer(serializers.Serializer):
    tenant = TenantDetailSerializer()
    owner = UserBriefSerializer()
    temporary_password = serializers.CharField(allow_null=True)


class ReasonSerializer(serializers.Serializer):
    reason = serializers.CharField(max_length=300)


class OptionalReasonSerializer(serializers.Serializer):
    reason = serializers.CharField(max_length=300, required=False, allow_blank=True, default="")


class PasswordResultSerializer(serializers.Serializer):
    temporary_password = serializers.CharField()


class PlanSerializer(serializers.ModelSerializer):
    price_tiyin_per_month = money_field()
    subscribers_count = serializers.IntegerField(read_only=True, default=0)

    class Meta:
        model = Plan
        fields = [
            "id",
            "name",
            "price_tiyin_per_month",
            "max_devices",
            "max_users",
            "features",
            "is_active",
            "sort",
            "subscribers_count",
        ]


class PaymentInputSerializer(serializers.Serializer):
    amount_tiyin = money_field()
    months = StrictIntegerField(min_value=1, max_value=36)
    method = serializers.ChoiceField(choices=PaymentMethod.choices)
    note = serializers.CharField(max_length=300, required=False, allow_blank=True, default="")


class PaymentSerializer(serializers.ModelSerializer):
    tenant_name = serializers.CharField(source="tenant.name", read_only=True)

    class Meta:
        model = SubscriptionPayment
        fields = [
            "id",
            "tenant",
            "tenant_name",
            "amount_tiyin",
            "months",
            "paid_at",
            "period_from",
            "period_to",
            "method",
            "note",
            "recorded_by",
            "reverses",
        ]


class ReverseInputSerializer(serializers.Serializer):
    note = serializers.CharField(max_length=300)


class PlatformDeviceSerializer(serializers.ModelSerializer):
    tenant_name = serializers.CharField(source="tenant.name", read_only=True)
    code = serializers.CharField(read_only=True)

    class Meta:
        model = Device
        fields = [
            "id",
            "tenant",
            "tenant_name",
            "code",
            "name",
            "platform",
            "app_version",
            "last_sync_at",
            "last_seen_at",
            "is_blocked",
            "created_at",
        ]


class SyncEventSerializer(serializers.ModelSerializer):
    class Meta:
        model = SyncEvent
        fields = [
            "id",
            "device",
            "type",
            "status",
            "error",
            "attempts",
            "client_created_at",
            "received_at",
            "applied_at",
        ]


class AuditLogSerializer(serializers.ModelSerializer):
    actor_name = serializers.CharField(source="actor.full_name", read_only=True)

    class Meta:
        model = AdminAuditLog
        fields = [
            "id",
            "actor",
            "actor_name",
            "action",
            "target_type",
            "target_id",
            "tenant",
            "before",
            "after",
            "reason",
            "at",
        ]


class ExpiringSerializer(serializers.Serializer):
    tenant = serializers.UUIDField()
    name = serializers.CharField()
    paid_until = serializers.DateField()
    days_left = serializers.IntegerField()


class MonthRevenueSerializer(serializers.Serializer):
    month = serializers.CharField()
    revenue_tiyin = serializers.IntegerField()


class TenantCountsSerializer(serializers.Serializer):
    total = serializers.IntegerField()
    trial = serializers.IntegerField()
    active = serializers.IntegerField()
    grace = serializers.IntegerField()
    readonly = serializers.IntegerField()
    blocked = serializers.IntegerField()


class StatsSerializer(serializers.Serializer):
    tenants = TenantCountsSerializer()
    mrr_tiyin = serializers.IntegerField()
    revenue_this_month_tiyin = serializers.IntegerField()
    expiring_soon = ExpiringSerializer(many=True)
    stale_devices = serializers.IntegerField()
    monthly_revenue = MonthRevenueSerializer(many=True)
