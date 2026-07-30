from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import MaterialItemViewSet, MaterialCostEntryViewSet

router = DefaultRouter()
router.register(r'items', MaterialItemViewSet, basename='material-item')
router.register(r'cost-entries', MaterialCostEntryViewSet, basename='material-cost-entry')

urlpatterns = [
    path('', include(router.urls)),
]
