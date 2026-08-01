"""
Views untuk categories app.
"""
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from core.permissions import IsOwnerOrReadOnly
from .models import Category
from .serializers import CategorySerializer, CategoryCreateUpdateSerializer


class CategoryViewSet(viewsets.ModelViewSet):
    """
    ViewSet untuk CRUD category (owner only untuk write).

    Endpoints:
    - GET /api/v1/categories/ - List category aktif (semua user)
    - GET /api/v1/categories/all/ - List semua category (owner only)
    - POST /api/v1/categories/ - Tambah category (owner only)
    - PATCH /api/v1/categories/{id}/ - Edit category (owner only)
    - DELETE /api/v1/categories/{id}/ - Soft delete + deactivate menus (owner only)
    """
    permission_classes = [IsOwnerOrReadOnly]

    def get_queryset(self):
        user = self.request.user
        if user.is_authenticated and user.role == 'owner':
            return Category.objects.all()
        return Category.objects.active()

    def get_serializer_class(self):
        if self.action in ['create', 'update', 'partial_update']:
            return CategoryCreateUpdateSerializer
        return CategorySerializer

    def list(self, request):
        queryset = self.get_queryset().order_by('sort_order', 'name')
        serializer = CategorySerializer(queryset, many=True)
        return Response({
            'status': True,
            'data': serializer.data
        })

    def retrieve(self, request, pk=None):
        try:
            category = self.get_queryset().get(pk=pk)
        except Category.DoesNotExist:
            return Response({
                'status': False,
                'error': 'Category tidak ditemukan'
            }, status=404)
        serializer = CategorySerializer(category)
        return Response({
            'status': True,
            'data': serializer.data
        })

    def create(self, request):
        serializer = CategoryCreateUpdateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        category = serializer.save()
        return Response({
            'status': True,
            'message': 'Category berhasil dibuat',
            'data': CategorySerializer(category).data
        }, status=201)

    def update(self, request, pk=None):
        try:
            category = self.get_queryset().get(pk=pk)
        except Category.DoesNotExist:
            return Response({
                'status': False,
                'error': 'Category tidak ditemukan'
            }, status=404)
        serializer = CategoryCreateUpdateSerializer(category, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        category = serializer.save()
        return Response({
            'status': True,
            'message': 'Category berhasil diupdate',
            'data': CategorySerializer(category).data
        })

    def partial_update(self, request, pk=None):
        return self.update(request, pk)

    def destroy(self, request, pk=None):
        try:
            category = self.get_queryset().get(pk=pk)
        except Category.DoesNotExist:
            return Response({
                'status': False,
                'error': 'Category tidak ditemukan'
            }, status=404)

        category.delete()
        return Response({
            'status': True,
            'message': 'Category berhasil dihapus. Semua menu dalam category ini juga di-nonaktifkan.'
        })

    @action(detail=False, methods=['get'], url_path='all')
    def list_all(self, request):
        if not request.user.is_authenticated or request.user.role != 'owner':
            return Response({'error': 'Unauthorized'}, status=403)
        categories = Category.objects.all().order_by('sort_order', 'name')
        serializer = CategorySerializer(categories, many=True)
        return Response(serializer.data)
