from rest_framework.routers import SimpleRouter

from .views import CategoryViewSet, ProductViewSet, UnitViewSet

router = SimpleRouter()
router.register("units", UnitViewSet, basename="unit")
router.register("categories", CategoryViewSet, basename="category")
router.register("products", ProductViewSet, basename="product")

urlpatterns = router.urls
