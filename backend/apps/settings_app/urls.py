"""
URL configuration untuk settings_app.
"""
from django.urls import path
from .views import SettingsViewSet

urlpatterns = [
    path('', SettingsViewSet.as_view({
        'get': 'list',
        'patch': 'partial_update',
    }), name='settings'),
]
