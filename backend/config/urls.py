from django.contrib import admin
from django.urls import include, path
from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView
from rest_framework.permissions import AllowAny

from apps.core.views import HealthView

api_v1 = [
    # Har bosqichda yangi ilovalar shu yerga qo'shiladi.
    path("", include("apps.accounts.urls")),
    path("", include("apps.devices.urls")),
    path("", include("apps.catalog.urls")),
    path("", include("apps.inventory.urls")),
    path("", include("apps.customers.urls")),
    path("", include("apps.sales.urls")),
    path("", include("apps.sync.urls")),
    path("", include("apps.reports.urls")),
    path("", include("apps.platform_admin.urls")),
]

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/health/", HealthView.as_view(), name="health"),
    path("api/schema/", SpectacularAPIView.as_view(permission_classes=[AllowAny]), name="schema"),
    path(
        "api/docs/",
        SpectacularSwaggerView.as_view(url_name="schema", permission_classes=[AllowAny]),
        name="docs",
    ),
    path("api/v1/", include((api_v1, "v1"))),
]
