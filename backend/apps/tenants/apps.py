from django.apps import AppConfig


class TenantsConfig(AppConfig):
    name = "apps.tenants"
    label = "tenants"
    verbose_name = "Tenants"

    def ready(self):
        from . import signals  # noqa: F401
