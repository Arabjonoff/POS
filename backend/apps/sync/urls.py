from django.urls import path

from .views import SyncPushView

urlpatterns = [
    path("sync/push/", SyncPushView.as_view(), name="sync-push"),
]
