from django.urls import path

from .imports import ImportApplyView, ImportCheckView, ImportTemplateView, ImportUploadView
from .views import SyncPriceHistoryView, SyncPullView, SyncPushView

urlpatterns = [
    path("sync/push/", SyncPushView.as_view(), name="sync-push"),
    path("sync/pull/", SyncPullView.as_view(), name="sync-pull"),
    path("sync/price-history/", SyncPriceHistoryView.as_view(), name="sync-price-history"),
    path(
        "sync/product-import/template/",
        ImportTemplateView.as_view(),
        name="sync-product-import-template",
    ),
    path("sync/product-imports/", ImportUploadView.as_view(), name="sync-product-imports"),
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
