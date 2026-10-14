from rest_framework.routers import SimpleRouter

from .views import (
    InventoryCountViewSet,
    StockMovementViewSet,
    StockReceiptViewSet,
    StockViewSet,
    SupplierViewSet,
)

router = SimpleRouter()
router.register("suppliers", SupplierViewSet, basename="supplier")
router.register("stock-receipts", StockReceiptViewSet, basename="stock-receipt")
router.register("inventory-counts", InventoryCountViewSet, basename="inventory-count")
router.register("stock", StockViewSet, basename="stock")
router.register("stock-movements", StockMovementViewSet, basename="stock-movement")

urlpatterns = router.urls
