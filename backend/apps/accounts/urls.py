"""
URL configuration untuk accounts app.
"""
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import AuthViewSet, KasirViewSet

router = DefaultRouter()
router.register(r'kasirs', KasirViewSet, basename='kasir')

urlpatterns = [
    path('', include(router.urls)),
    path('pin/', AuthViewSet.as_view({'post': 'pin_login'}), name='pin-login'),
    path('change-pin/', AuthViewSet.as_view({'post': 'change_pin'}), name='change-pin'),
    path('me/', AuthViewSet.as_view({'get': 'me'}), name='me'),
    path('login-users/', AuthViewSet.as_view({'get': 'login_users'}), name='login-users'),
]
