"""
Views untuk accounts app.
"""
import secrets
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAuthenticated
from core.throttles import LoginRateThrottle
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
    throttle_classes = [LoginRateThrottle]

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

    @action(detail=False, methods=['get'], url_path='login-users')
    def login_users(self, request):
        """
        List kasir aktif untuk login screen (public - tanpa auth).
        Hanya mengembalikan username dan role.
        """
        kasirs = Kasir.objects.filter(is_active=True).values('id', 'username', 'role')
        return Response({'data': list(kasirs)})

    @action(detail=False, methods=['post'], url_path='change-pin')
    def change_pin(self, request):
        """
        Ganti PIN sendiri (semua user).
        """
        if not request.user.is_authenticated:
            return Response({'error': 'Not authenticated'}, status=401)
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
    - GET /api/v1/accounts/kasirs/ - List semua kasir (owner: semua, others: aktif saja)
    - POST /api/v1/accounts/kasirs/ - Tambah kasir baru
    - GET /api/v1/accounts/kasirs/{id}/ - Detail kasir
    - PATCH /api/v1/accounts/kasirs/{id}/ - Edit kasir
    - DELETE /api/v1/accounts/kasirs/{id}/ - Soft delete kasir
    - POST /api/v1/accounts/kasirs/{id}/reset-pin/ - Reset PIN kasir (owner only)
    """
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        if self.request.user.role == 'owner':
            return Kasir.objects.all()
        return Kasir.objects.filter(is_active=True)

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
        Reset PIN kasir (owner only).
        Jika body ada 'new_pin' pakai itu (min 6 digit), kalau tidak generate random.
        """
        if request.user.role != 'owner':
            return Response({'error': 'Hanya owner yang bisa reset PIN'}, status=403)
        try:
            kasir = self.get_queryset().get(pk=pk)
        except Kasir.DoesNotExist:
            return Response({'error': 'Kasir tidak ditemukan'}, status=404)

        import bcrypt
        import re
        custom_pin = request.data.get('new_pin')

        if custom_pin:
            pin_str = str(custom_pin)
            if len(pin_str) < 6 or not re.match(r'^\d+$', pin_str):
                return Response({
                    'error': 'PIN harus minimal 6 digit angka'
                }, status=400)
            new_pin = pin_str
        else:
            new_pin = ''.join(secrets.choice('0123456789') for _ in range(6))

        kasir.pin_hash = bcrypt.hashpw(new_pin.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
        kasir.save(update_fields=['pin_hash'])
        return Response({
            'message': f'PIN {kasir.username} berhasil direset. PIN baru hanya ditampilkan SEKALI.',
            'new_pin': new_pin,
        })
