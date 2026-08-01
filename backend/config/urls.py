"""
URL Configuration untuk App Martabak.
"""
from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static

from core.views import HealthCheckView

urlpatterns = [
    path('admin/', admin.site.urls),
    # API v1
    path('api/v1/accounts/', include('apps.accounts.urls')),
    path('api/v1/categories/', include('apps.categories.urls')),
    path('api/v1/menus/', include('apps.menus.urls')),
    path('api/v1/orders/', include('apps.orders.urls')),
    path('api/v1/goqris/', include('apps.goqris.urls')),
    path('api/v1/reports/', include('apps.reports.urls')),
    path('api/v1/raw-materials/', include('apps.raw_materials.urls')),
    path('api/v1/settings/', include('apps.settings_app.urls')),
    # Health check (public)
    path('api/v1/health/', HealthCheckView.as_view(), name='health-check'),
]

# Serve media files during development
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
