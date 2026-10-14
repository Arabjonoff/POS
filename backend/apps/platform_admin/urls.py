from django.urls import path
from rest_framework.routers import SimpleRouter

from . import views

router = SimpleRouter()
router.register("platform/tenants", views.TenantViewSet, basename="platform-tenant")
router.register("platform/plans", views.PlanViewSet, basename="platform-plan")
router.register("platform/payments", views.PaymentViewSet, basename="platform-payment")
router.register("platform/devices", views.PlatformDeviceViewSet, basename="platform-device")
router.register("platform/audit-log", views.AuditLogViewSet, basename="platform-audit")

urlpatterns = [
    path("platform/stats/", views.StatsView.as_view(), name="platform-stats"),
    path(
        "platform/users/<uuid:pk>/reset-password/",
        views.UserResetPasswordView.as_view(),
        name="platform-user-reset-password",
    ),
    *router.urls,
]
