from rest_framework import serializers


class TenantPKField(serializers.PrimaryKeyRelatedField):
    """Faqat joriy tenant obyektlari (yumshoq o'chirilganlar ham emas); boshqasi — "topilmadi"."""

    def get_queryset(self):
        tenant_id = self.context["request"].user.tenant_id
        queryset = super().get_queryset().filter(tenant_id=tenant_id)
        model_fields = {f.name for f in queryset.model._meta.get_fields()}
        if "deleted_at" in model_fields:
            queryset = queryset.filter(deleted_at__isnull=True)
        return queryset


class ClientIdMixin:
    """`id` klientda yaratilishi mumkin (UUIDv7); keyin o'zgarmaydi."""

    def validate_id(self, value):
        model = self.Meta.model
        if self.instance is not None and value != self.instance.pk:
            raise serializers.ValidationError("Id cannot be changed.")
        if self.instance is None and model.objects.filter(pk=value).exists():
            raise serializers.ValidationError("Object with this id already exists.", code="unique")
        return value
