"""
Views untuk menus app.
"""
from rest_framework import viewsets
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from .models import Menu
from .serializers import MenuSerializer, MenuCreateUpdateSerializer
from core.permissions import IsOwnerOrReadOnly


class MenuViewSet(viewsets.ModelViewSet):
    """
    ViewSet untuk CRUD menu (owner only untuk write).

    Endpoints:
    - GET /api/v1/menus/ - List menu aktif (semua user)
    - GET /api/v1/menus/all/ - List semua menu (owner only)
    - POST /api/v1/menus/ - Tambah menu (owner only)
    - PATCH /api/v1/menus/{id}/ - Edit menu (owner only)
    - DELETE /api/v1/menus/{id}/ - Soft delete menu (owner only)
    """
    permission_classes = [IsOwnerOrReadOnly]

    def get_queryset(self):
        user = self.request.user
        if user.is_authenticated and user.role == 'owner':
            return Menu.objects.all()
        return Menu.objects.filter(is_active=True)

    def get_serializer_class(self):
        if self.action in ['create', 'update', 'partial_update']:
            return MenuCreateUpdateSerializer
        return MenuSerializer

    @action(detail=False, methods=['get'], url_path='all')
    def list_all(self, request):
        """
        List semua menu (aktif dan nonaktif) - owner only.
        """
        if not request.user.is_authenticated or request.user.role != 'owner':
            return Response({'error': 'Unauthorized'}, status=403)
        menus = self.get_queryset().order_by('category', 'sort_order', 'name')
        serializer = MenuSerializer(menus, many=True)
        return Response(serializer.data)
