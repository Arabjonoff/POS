from django.urls import path

from apps.reports.views import DeviceReportView

from .images import ProductImageView
from .imports import ImportApplyView, ImportCheckView, ImportTemplateView, ImportUploadView
from .views import SyncPriceHistoryView, SyncPullView, SyncPushView, SyncStockMovementsView

urlpatterns = [
    path("sync/push/", SyncPushView.as_view(), name="sync-push"),
    path("sync/pull/", SyncPullView.as_view(), name="sync-pull"),
    path("sync/reports/", DeviceReportView.as_view(), name="sync-reports"),
    path("sync/price-history/", SyncPriceHistoryView.as_view(), name="sync-price-history"),
    path("sync/stock-movements/", SyncStockMovementsView.as_view(), name="sync-stock-movements"),
    path(
        "sync/product-import/template/",
        ImportTemplateView.as_view(),
        name="sync-product-import-template",
    ),
    path("sync/product-imports/", ImportUploadView.as_view(), name="sync-product-imports"),
    path(
        "sync/product-images/<uuid:pk>/",
        ProductImageView.as_view(),
        name="sync-product-image",
    ),
    path(
        "sync/product-imports/<uuid:pk>/check/",
        ImportCheckView.as_view(),
        name="sync-product-import-check",
    ),
    path(
        "sync/product-imports/<uuid:pk>/apply/",
        ImportApplyView.as_view(),
        name="sync-product-import-apply",
    ),
]
