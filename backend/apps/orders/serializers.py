"""
Serializers untuk orders app.
"""
import logging
from rest_framework import serializers
from .models import Order, OrderItem
from apps.menus.serializers import MenuSerializer

logger = logging.getLogger(__name__)


class OrderItemSerializer(serializers.ModelSerializer):
    menu_name = serializers.CharField(source='menu.name', read_only=True)
    menu_emoji = serializers.CharField(source='menu.emoji', read_only=True)

    class Meta:
        model = OrderItem
        fields = ['id', 'menu', 'menu_name', 'menu_emoji', 'qty', 'price_at_order', 'subtotal']
        read_only_fields = ['id', 'price_at_order', 'subtotal']


class OrderItemCreateSerializer(serializers.Serializer):
    menu_id = serializers.IntegerField()
    qty = serializers.IntegerField(min_value=1)

    def validate(self, attrs):
        from apps.menus.models import Menu
        try:
            menu = Menu.objects.get(id=attrs['menu_id'], is_active=True)
        except Menu.DoesNotExist:
            raise serializers.ValidationError('Menu tidak ditemukan atau tidak aktif')
        return attrs


class OrderSerializer(serializers.ModelSerializer):
    items = OrderItemSerializer(many=True, read_only=True)
    kasir_name = serializers.CharField(source='kasir.username', read_only=True)

    class Meta:
        model = Order
        fields = [
            'id', 'ref_id', 'kasir', 'kasir_name', 'items',
            'total_amount', 'status', 'payment_method', 'payment_method_label',
            'note', 'qr_string', 'qr_image_url', 'expires_at', 'paid_at',
            'created_at', 'updated_at'
        ]
        read_only_fields = [
            'id', 'ref_id', 'kasir', 'total_amount', 'status',
            'payment_method', 'payment_method_label',
            'qr_string', 'qr_image_url', 'expires_at', 'paid_at',
            'created_at', 'updated_at'
        ]


class CreateOrderSerializer(serializers.Serializer):
    PAYMENT_METHOD_LABELS = {
        'goqris': 'GoQris QRIS',
        'cash': 'Tunai',
    }

    items = OrderItemCreateSerializer(many=True)
    note = serializers.CharField(required=False, allow_blank=True, default='')
    payment_method = serializers.ChoiceField(
        choices=['goqris', 'cash'],
        help_text='Metode pembayaran: goqris (QRIS) atau cash (Tunai) - WAJIB'
    )

    def validate_items(self, value):
        if not value:
            raise serializers.ValidationError('Minimal harus ada 1 item')
        return value

    def create(self, attrs):
        from datetime import date, timedelta
        from django.utils import timezone
        from apps.menus.models import Menu
        from apps.goqris.services import goqris_service
        from apps.settings_app.models import Settings

        kasir = self.context['request'].user
        payment_method = attrs.get('payment_method')
        payment_method_label = self.PAYMENT_METHOD_LABELS.get(payment_method, payment_method)

        today = date.today()
        prefix = f'INV-{today.strftime("%Y%m%d")}-'

        last_order = Order.objects.filter(
            ref_id__startswith=prefix
        ).order_by('-ref_id').first()

        if last_order:
            last_n = int(last_order.ref_id.split('-')[-1])
            new_n = last_n + 1
        else:
            new_n = 1

        ref_id = f'{prefix}{new_n:03d}'

        total_amount = 0
        order_items = []

        for item_data in attrs['items']:
            menu = Menu.objects.get(id=item_data['menu_id'])
            qty = item_data['qty']
            price = menu.price
            subtotal = qty * price
            total_amount += subtotal
            order_items.append({
                'menu': menu,
                'qty': qty,
                'price_at_order': price,
                'subtotal': subtotal,
            })

        order = Order.objects.create(
            ref_id=ref_id,
            kasir=kasir,
            total_amount=total_amount,
            note=attrs.get('note', ''),
            status='pending',
            payment_method=payment_method,
            payment_method_label=payment_method_label,
        )

        for item_data in order_items:
            OrderItem.objects.create(order=order, **item_data)

        if payment_method == 'cash':
            order.status = 'paid'
            order.paid_at = timezone.now()
            order.save(update_fields=['status', 'paid_at', 'updated_at'])
        else:
            settings = Settings.objects.first()
            if settings and settings.goqris_project_name:
                try:
                    goqris_response = goqris_service.create_order(
                        amount=total_amount,
                        ref_id=ref_id,
                        project_name=settings.goqris_project_name,
                    )
                    payment_detail = goqris_response.get('payment_detail', {})
                    order.qr_string = payment_detail.get('qr_string', '')
                    order.qr_image_url = payment_detail.get('qr_image', '')
                    order.expires_at = goqris_response.get('expires_at')
                    order.goqris_data = goqris_response
                    order.payment_method = 'goqris'
                    order.payment_method_label = 'GoQris QRIS'
                    order.save(update_fields=['qr_string', 'qr_image_url', 'expires_at', 'goqris_data', 'payment_method', 'payment_method_label', 'updated_at'])
                except Exception as e:
                    logger.error(f'[ORDER] GoQris failed: {str(e)}')
                    order.payment_method = 'goqris'
                    order.payment_method_label = 'GoQris QRIS'
                    order.save(update_fields=['payment_method', 'payment_method_label', 'updated_at'])
                    from core.exceptions import GoQrisException
                    raise GoQrisException(f'GoQris order creation failed: {str(e)}')
            else:
                order.status = 'paid'
                order.paid_at = timezone.now()
                order.payment_method = 'cash'
                order.payment_method_label = self.PAYMENT_METHOD_LABELS['cash']
                order.save(update_fields=['status', 'paid_at', 'payment_method', 'payment_method_label', 'updated_at'])

        return order


class OrderListSerializer(serializers.ModelSerializer):
    items_count = serializers.SerializerMethodField()
    kasir_name = serializers.CharField(source='kasir.username', read_only=True)

    class Meta:
        model = Order
        fields = [
            'id', 'ref_id', 'kasir_name', 'items_count',
            'total_amount', 'status', 'payment_method', 'payment_method_label',
            'note', 'created_at'
        ]

    def get_items_count(self, obj):
        return obj.items.count()
