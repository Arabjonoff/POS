from rest_framework.routers import SimpleRouter

from .views import CashMovementViewSet, RefundViewSet, SaleViewSet, ShiftViewSet

router = SimpleRouter()
router.register("shifts", ShiftViewSet, basename="shift")
router.register("sales", SaleViewSet, basename="sale")
router.register("refunds", RefundViewSet, basename="refund")
router.register("cash-movements", CashMovementViewSet, basename="cash-movement")

urlpatterns = router.urls
