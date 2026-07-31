"""
Views untuk orders app.
"""
import logging
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db import transaction
from django.utils import timezone
from dateutil.parser import parse as parse_datetime
from .models import Order, OrderItem
from .serializers import (
    OrderSerializer,
    OrderItemSerializer,
    CreateOrderSerializer,
    OrderListSerializer,
)
from apps.goqris.services import goqris_service
from core.permissions import IsOwnerOrKasir

logger = logging.getLogger(__name__)


class OrderViewSet(viewsets.GenericViewSet):
    """
    ViewSet untuk order management.

    Endpoints:
    - POST /api/v1/orders/ - Buat order baru
    - GET /api/v1/orders/ - List orders (owner: semua, kasir: miliknya)
    - GET /api/v1/orders/{id}/ - Detail order
    - GET /api/v1/orders/{id}/status/ - Cek status pembayaran
    - POST /api/v1/orders/{id}/cancel/ - Batalkan order (owner only)
    - GET /api/v1/orders/queue/ - Antrian shared (status pending/paid)
    - GET /api/v1/orders/me/ - Riwayat kasir yang login
    """
    permission_classes = [IsOwnerOrKasir]

    def get_queryset(self):
        user = self.request.user
        if user.role == 'owner':
            queryset = Order.objects.all()
        else:
            queryset = Order.objects.filter(kasir=user)

        if self.action == 'list':
            queryset = queryset.prefetch_related('items')
        return queryset

    def get_serializer_class(self):
        if self.action == 'create':
            return CreateOrderSerializer
        if self.action == 'list':
            return OrderListSerializer
        if self.action == 'retrieve':
            return OrderSerializer
        return OrderSerializer

    def create(self, request):
        """
        Buat order baru. Untuk Phase 4 langsung marked as paid.
        Phase 5 akan integrate dengan GoQris payment.
        """
        serializer = CreateOrderSerializer(data=request.data, context={'request': request})
        serializer.is_valid(raise_exception=True)
        order = serializer.save()
        return Response(OrderSerializer(order).data, status=status.HTTP_201_CREATED)

    def list(self, request):
        """
        List orders.
        Owner melihat semua, kasir hanya miliknya.
        """
        queryset = self.get_queryset().order_by('-created_at')
        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = OrderListSerializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        serializer = OrderListSerializer(queryset, many=True)
        return Response(serializer.data)

    def retrieve(self, request, pk=None):
        """
        Detail order.
        """
        try:
            order = self.get_queryset().get(pk=pk)
        except Order.DoesNotExist:
            return Response({'error': 'Order tidak ditemukan'}, status=404)
        serializer = OrderSerializer(order)
        return Response(serializer.data)

    @action(detail=True, methods=['get'], url_path='status')
    def order_status(self, request, pk=None):
        """
        Cek status pembayaran order.
        Jika order masih pending, akan cek ke GoQris API dan update status.
        """
        with transaction.atomic():
            try:
                order = Order.objects.select_for_update().get(pk=pk)
            except Order.DoesNotExist:
                return Response({'error': 'Order tidak ditemukan'}, status=404)

            is_expired = order.expires_at and order.expires_at < timezone.now()

            if order.status == 'pending' and not is_expired:
                try:
                    goqris_data = goqris_service.check_status(order.ref_id)

                    paid = goqris_data.get('paid', False)
                    payment_status = goqris_data.get('payment_status', '')

                    if paid or payment_status == 'paid':
                        order.status = 'paid'
                        paid_at = goqris_data.get('paid_at')
                        if paid_at:
                            order.paid_at = parse_datetime(paid_at)
                        order.save(update_fields=['status', 'paid_at', 'updated_at'])
                        logger.info(f'[ORDER] Payment confirmed via GoQris: ref_id={order.ref_id}')
                    elif payment_status == 'expired' or goqris_data.get('expired'):
                        order.status = 'expired'
                        order.save(update_fields=['status', 'updated_at'])
                        logger.info(f'[ORDER] Payment expired via GoQris: ref_id={order.ref_id}')

                except Exception as e:
                    logger.warning(f'[ORDER] GoQris check_status failed for {order.ref_id}: {str(e)}')

            elif is_expired and order.status == 'pending':
                order.status = 'expired'
                order.save(update_fields=['status', 'updated_at'])

        return Response({
            'ref_id': order.ref_id,
            'status': order.status,
            'payment_method': order.payment_method,
            'payment_method_label': order.payment_method_label,
            'total_amount': order.total_amount,
            'is_expired': order.status == 'expired' or (
                order.expires_at and order.expires_at < timezone.now()
            ),
            'paid_at': order.paid_at.isoformat() if order.paid_at else None,
        })

    @action(detail=True, methods=['post'], url_path='cancel')
    def cancel(self, request, pk=None):
        """
        Batalkan order (owner only).
        """
        if request.user.role != 'owner':
            return Response({'error': 'Hanya owner yang bisa membatalkan order'}, status=403)
        try:
            order = self.get_queryset().get(pk=pk)
        except Order.DoesNotExist:
            return Response({'error': 'Order tidak ditemukan'}, status=404)
        if order.status in ['paid', 'cancelled']:
            return Response({'error': 'Order tidak bisa dibatalkan'}, status=400)
        order.status = 'cancelled'
        order.save(update_fields=['status', 'updated_at'])
        return Response({'message': 'Order berhasil dibatalkan'})

    @action(detail=False, methods=['get'], url_path='queue')
    def queue(self, request):
        """
        Antrian shared - semua order pending dan paid (untuk display kasir).
        Hanya menampilkan order hari ini dan kemarin.
        """
        from datetime import date, timedelta
        today = date.today()
        queryset = Order.objects.filter(
            status__in=['pending', 'paid'],
            created_at__date__gte=today - timedelta(days=1)
        ).order_by('-created_at')[:50]
        serializer = OrderListSerializer(queryset, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'], url_path='me')
    def my_orders(self, request):
        """
        Riwayat order kasir yang login.
        """
        queryset = Order.objects.filter(
            kasir=request.user
        ).order_by('-created_at')
        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = OrderListSerializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        serializer = OrderListSerializer(queryset, many=True)
        return Response(serializer.data)
