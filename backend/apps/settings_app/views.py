"""
Views untuk settings_app.
"""
from rest_framework import viewsets, status
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from .models import Settings
from .serializers import SettingsSerializer
from core.permissions import IsOwner


class SettingsViewSet(viewsets.GenericViewSet):
    """
    ViewSet untuk singleton settings.

    Endpoints:
    - GET /api/v1/settings/ - Lihat settings (owner only)
    - PATCH /api/v1/settings/ - Update settings (owner only)
    """
    permission_classes = [IsAuthenticated, IsOwner]
    serializer_class = SettingsSerializer

    def get_object(self):
        obj, _ = Settings.objects.get_or_create(id=1)
        return obj

    def list(self, request):
        obj = self.get_object()
        serializer = SettingsSerializer(obj)
        return Response(serializer.data)

    def partial_update(self, request, pk=None):
        obj = self.get_object()
        serializer = SettingsSerializer(obj, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data)
