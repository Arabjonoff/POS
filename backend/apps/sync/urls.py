from django.urls import path

from .views import SyncPriceHistoryView, SyncPullView, SyncPushView

urlpatterns = [
    path("sync/push/", SyncPushView.as_view(), name="sync-push"),
    path("sync/pull/", SyncPullView.as_view(), name="sync-pull"),
    path("sync/price-history/", SyncPriceHistoryView.as_view(), name="sync-price-history"),
]
