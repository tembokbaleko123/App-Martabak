"""
Views untuk goqris app.
"""
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.conf import settings
from core.permissions import IsOwner
from .services import goqris_service


class GoQrisViewSet(viewsets.GenericViewSet):
    """
    ViewSet untuk GoQris integration.

    Endpoints:
    - GET /api/v1/goqris/profile/ - Cek status subscription GoQris (owner only)
    """
    permission_classes = [IsAuthenticated, IsOwner]

    @action(detail=False, methods=['get'], url_path='profile')
    def profile(self, request):
        """
        Get GoQris profile & subscription info.
        """
        api_key = settings.GOQRIS_API_KEY
        if not api_key or api_key == 'GO_xxxxxx':
            return Response({
                'status': 'not_configured',
                'message': 'GoQris API key belum diset di .env'
            }, status=status.HTTP_400_BAD_REQUEST)

        try:
            data = goqris_service.get_profile()
            return Response({
                'status': 'active',
                'data': data
            })
        except Exception as e:
            return Response({
                'status': 'error',
                'message': str(e)
            }, status=status.HTTP_502_BAD_GATEWAY)
