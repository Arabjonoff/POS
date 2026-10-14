from django.apps import AppConfig


class DevicesConfig(AppConfig):
    name = "apps.devices"
    label = "devices"
    verbose_name = "Devices"

    def ready(self):
        from . import authentication  # noqa: F401  (drf-spectacular extension ro'yxatga olinadi)
