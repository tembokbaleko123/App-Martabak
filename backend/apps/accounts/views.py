"""
Views untuk accounts app.
"""
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAuthenticated
from .models import Kasir
from .serializers import (
    PinLoginSerializer,
    ChangePinSerializer,
    KasirSerializer,
    KasirCreateSerializer,
)


class AuthViewSet(viewsets.GenericViewSet):
    """
    ViewSet untuk autentikasi.

    Endpoints:
    - POST /api/v1/accounts/pin/ - Login dengan PIN
    - POST /api/v1/accounts/change-pin/ - Ganti PIN sendiri
    - GET /api/v1/accounts/me/ - Info user yang login
    """
    permission_classes = [AllowAny]

    @action(detail=False, methods=['post'], url_path='pin')
    def pin_login(self, request):
        """
        Login dengan username + PIN.
        Returns JWT token.
        """
        serializer = PinLoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        kasir = serializer.validated_data['kasir']
        return Response({
            'refresh': serializer.validated_data['refresh'],
            'access': serializer.validated_data['access'],
            'user': KasirSerializer(kasir).data,
        })

    @action(detail=False, methods=['post'], url_path='change-pin')
    def change_pin(self, request):
        """
        Ganti PIN sendiri (owner only).
        """
        if not request.user.is_authenticated or request.user.role != 'owner':
            return Response({'error': 'Hanya owner yang bisa mengganti PIN'}, status=403)
        serializer = ChangePinSerializer(data=request.data, context={'request': request})
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response({'message': 'PIN berhasil diubah'})

    @action(detail=False, methods=['get'], url_path='me')
    def me(self, request):
        """
        Get info user yang sedang login.
        """
        if not request.user.is_authenticated:
            return Response({'error': 'Not authenticated'}, status=status.HTTP_401_UNAUTHORIZED)
        return Response(KasirSerializer(request.user).data)


class KasirViewSet(viewsets.ModelViewSet):
    """
    ViewSet untuk CRUD kasir (owner only).

    Endpoints:
    - GET /api/v1/accounts/kasirs/ - List semua kasir
    - POST /api/v1/accounts/kasirs/ - Tambah kasir baru
    - GET /api/v1/accounts/kasirs/{id}/ - Detail kasir
    - PATCH /api/v1/accounts/kasirs/{id}/ - Edit kasir
    - DELETE /api/v1/accounts/kasirs/{id}/ - Soft delete kasir
    - POST /api/v1/accounts/kasirs/{id}/reset-pin/ - Reset PIN kasir (owner only)
    """
    queryset = Kasir.objects.filter(is_active=True)
    permission_classes = [IsAuthenticated]

    def get_serializer_class(self):
        if self.action == 'create':
            return KasirCreateSerializer
        return KasirSerializer

    def perform_destroy(self, instance):
        instance.is_active = False
        instance.save(update_fields=['is_active'])

    @action(detail=True, methods=['post'], url_path='reset-pin')
    def reset_pin(self, request, pk=None):
        """
        Reset PIN kasir ke default (owner only).
        """
        if request.user.role != 'owner':
            return Response({'error': 'Hanya owner yang bisa reset PIN'}, status=403)
        try:
            kasir = self.get_queryset().get(pk=pk)
        except Kasir.DoesNotExist:
            return Response({'error': 'Kasir tidak ditemukan'}, status=404)
        import bcrypt
        kasir.pin_hash = bcrypt.hashpw('1234'.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
        kasir.save(update_fields=['pin_hash'])
        return Response({'message': f'PIN {kasir.username} direset ke 1234'})
