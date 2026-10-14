from django.urls import path
from rest_framework.routers import SimpleRouter

from .views import DeviceMeView, DeviceRegisterView, DeviceViewSet

router = SimpleRouter()
router.register("devices", DeviceViewSet, basename="device")

urlpatterns = [
    path("devices/register/", DeviceRegisterView.as_view(), name="device-register"),
    path("devices/me/", DeviceMeView.as_view(), name="device-me"),
    *router.urls,
]
