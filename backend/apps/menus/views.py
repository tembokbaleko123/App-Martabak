"""
Views untuk menus app.
"""
from django.db import transaction
from rest_framework import viewsets
from rest_framework.decorators import action
from rest_framework.response import Response
from .models import Menu
from .serializers import MenuSerializer, MenuCreateUpdateSerializer, MenuBulkUpdateSerializer
from core.permissions import IsOwnerOrReadOnly


class MenuViewSet(viewsets.ModelViewSet):
    """
    ViewSet untuk CRUD menu (owner only untuk write).

    Endpoints:
    - GET /api/v1/menus/ - List menu aktif dengan search (semua user)
    - GET /api/v1/menus/all/ - List semua menu (owner only)
    - POST /api/v1/menus/ - Tambah menu (owner only)
    - PATCH /api/v1/menus/{id}/ - Edit menu (owner only)
    - DELETE /api/v1/menus/{id}/ - Soft delete menu (owner only)
    - PATCH /api/v1/menus/bulk/ - Bulk update menus (owner only)
    """
    permission_classes = [IsOwnerOrReadOnly]

    def get_queryset(self):
        user = self.request.user

        if user.is_authenticated and user.role == 'owner':
            queryset = Menu.objects.all()
        else:
            queryset = Menu.objects.filter(
                is_active=True,
                category__is_active=True,
                category__isnull=False
            )

        search = self.request.query_params.get('search', None)
        if search and search.strip():
            queryset = queryset.filter(name__icontains=search.strip())

        return queryset.order_by('category', 'sort_order', 'name')

    def get_serializer_class(self):
        if self.action in ['create', 'update', 'partial_update']:
            return MenuCreateUpdateSerializer
        return MenuSerializer

    def list(self, request):
        queryset = self.get_queryset()
        serializer = MenuSerializer(queryset, many=True, context={'request': request})
        return Response({
            'status': True,
            'message': 'Berhasil mendapatkan data',
            'data': serializer.data
        })

    def retrieve(self, request, pk=None):
        try:
            menu = self.get_queryset().get(pk=pk)
        except Menu.DoesNotExist:
            return Response({
                'status': False,
                'error': 'Menu tidak ditemukan'
            }, status=404)
        serializer = MenuSerializer(menu, context={'request': request})
        return Response({
            'status': True,
            'data': serializer.data
        })

    def create(self, request):
        serializer = MenuCreateUpdateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        menu = serializer.save()
        return Response({
            'status': True,
            'message': 'Menu berhasil dibuat',
            'data': MenuSerializer(menu, context={'request': request}).data
        }, status=201)

    def update(self, request, pk=None):
        menu = self.get_object()
        serializer = MenuCreateUpdateSerializer(menu, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        menu = serializer.save()
        return Response({
            'status': True,
            'message': 'Menu berhasil diupdate',
            'data': MenuSerializer(menu, context={'request': request}).data
        })

    def partial_update(self, request, pk=None):
        return self.update(request, pk)

    def destroy(self, request, pk=None):
        menu = self.get_object()
        menu.is_active = False
        menu.save(update_fields=['is_active'])
        return Response({
            'status': True,
            'message': 'Menu berhasil dihapus'
        })

    @action(detail=False, methods=['get'], url_path='all')
    def list_all(self, request):
        if not request.user.is_authenticated or request.user.role != 'owner':
            return Response({'error': 'Unauthorized'}, status=403)
        queryset = self.get_queryset().order_by('category', 'sort_order', 'name')
        serializer = MenuSerializer(queryset, many=True, context={'request': request})
        return Response(serializer.data)

    @action(detail=False, methods=['patch'], url_path='bulk')
    def bulk_update(self, request):
        """
        Bulk update menus (owner only).
        bisa reassign ke category lain dan/atau aktivasi/deaktivasi.
        """
        if not request.user.is_authenticated or request.user.role != 'owner':
            return Response({'error': 'Unauthorized'}, status=403)

        serializer = MenuBulkUpdateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        menu_ids = serializer.validated_data['menu_ids']
        category_id = serializer.validated_data.get('category_id')
        is_active = serializer.validated_data.get('is_active')

        existing_ids = set(Menu.objects.filter(id__in=menu_ids).values_list('id', flat=True))
        requested_ids = set(menu_ids)
        missing_ids = requested_ids - existing_ids

        if missing_ids:
            return Response({
                'status': False,
                'error': f'Menu IDs tidak ditemukan: {sorted(missing_ids)}'
            }, status=400)

        menus = Menu.objects.filter(id__in=menu_ids).select_related('category')
        updated_menus = []

        with transaction.atomic():
            for menu in menus:
                if category_id is not None:
                    menu.category = category_id
                if is_active is not None:
                    menu.is_active = is_active
                menu.save(update_fields=['category', 'is_active'])
                updated_menus.append(menu)

        message_parts = []
        if category_id:
            message_parts.append(f'dipindahkan ke category {category_id.name}')
        if is_active is not None:
            message_parts.append(f'di{"aktivasi" if is_active else "nonaktifkan"}')

        message = f'{len(updated_menus)} menu berhasil diupdate'
        if message_parts:
            message += ' (' + ', '.join(message_parts) + ')'

        return Response({
            'status': True,
            'message': message,
            'updated_count': len(updated_menus),
            'updated_menus': [
                {
                    'id': m.id,
                    'name': m.name,
                    'category_id': m.category.id if m.category else None,
                    'category_name': m.category.name if m.category else None,
                    'is_active': m.is_active
                }
                for m in updated_menus
            ]
        })
