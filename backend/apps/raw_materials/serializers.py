from decimal import Decimal
from rest_framework import serializers
from django.db import transaction
from django.db.models import Sum

from apps.orders.models import Order
from .models import MaterialItem, MaterialCostEntry, MaterialCostItem


class MaterialItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = MaterialItem
        fields = ['id', 'name', 'is_active', 'created_at', 'updated_at']
        read_only_fields = ['id', 'created_at', 'updated_at']


class MaterialCostItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = MaterialCostItem
        fields = ['id', 'material_name', 'quantity', 'price_per_unit', 'subtotal', 'created_at']
        read_only_fields = ['id', 'subtotal', 'created_at']


class MaterialCostItemCreateSerializer(serializers.Serializer):
    material_name = serializers.CharField(max_length=100)
    quantity = serializers.DecimalField(max_digits=10, decimal_places=2, min_value=Decimal('0.01'))
    price_per_unit = serializers.IntegerField(min_value=1)

    def validate_quantity(self, value):
        if value <= 0:
            raise serializers.ValidationError('Quantity harus lebih dari 0')
        return value

    def validate_price_per_unit(self, value):
        if value <= 0:
            raise serializers.ValidationError('Harga per unit harus lebih dari 0')
        return value

    def create(self, attrs):
        item = MaterialCostItem(**attrs)
        item.save()
        return item


class MaterialCostEntrySerializer(serializers.ModelSerializer):
    items = MaterialCostItemSerializer(many=True, read_only=True)
    created_by_name = serializers.CharField(source='created_by.username', read_only=True)

    class Meta:
        model = MaterialCostEntry
        fields = [
            'id', 'date_from', 'date_to',
            'total_cost', 'total_revenue', 'profit',
            'notes', 'items', 'created_by_name',
            'created_at', 'updated_at'
        ]
        read_only_fields = [
            'id', 'total_cost', 'total_revenue', 'profit',
            'created_at', 'updated_at'
        ]


class MaterialCostEntryCreateSerializer(serializers.Serializer):
    date_from = serializers.DateField()
    date_to = serializers.DateField()
    items = MaterialCostItemCreateSerializer(many=True)
    notes = serializers.CharField(required=False, allow_blank=True, default='')

    def validate_items(self, value):
        if not value:
            raise serializers.ValidationError('Minimal harus ada 1 item bahan')
        return value

    def validate(self, attrs):
        date_from = attrs.get('date_from')
        date_to = attrs.get('date_to')
        if date_from and date_to and date_from > date_to:
            raise serializers.ValidationError({
                'date_to': 'date_to harus sama atau setelah date_from.'
            })
        return attrs

    @transaction.atomic
    def create(self, attrs):
        from apps.orders.models import Order

        items_data = attrs.pop('items')
        notes = attrs.pop('notes', '')
        kasir = self.context['request'].user

        cost_entry = MaterialCostEntry.objects.create(
            date_from=attrs['date_from'],
            date_to=attrs['date_to'],
            notes=notes,
            created_by=kasir,
        )

        total_cost = 0
        for item_data in items_data:
            item_data['cost_entry'] = cost_entry
            item = MaterialCostItem.objects.create(**item_data)
            total_cost += item.subtotal

        revenue_data = Order.objects.filter(
            created_at__date__gte=cost_entry.date_from,
            created_at__date__lte=cost_entry.date_to,
            status='paid'
        ).aggregate(total=Sum('total_amount'))

        total_revenue = revenue_data['total'] or 0

        cost_entry.total_cost = total_cost
        cost_entry.total_revenue = total_revenue
        cost_entry.save()

        return cost_entry


class MaterialCostEntryUpdateSerializer(serializers.Serializer):
    date_from = serializers.DateField(required=False)
    date_to = serializers.DateField(required=False)
    items = MaterialCostItemCreateSerializer(many=True, required=False)
    notes = serializers.CharField(required=False, allow_blank=True)

    def validate_items(self, value):
        if not value:
            raise serializers.ValidationError('Minimal harus ada 1 item bahan')
        return value

    def validate(self, attrs):
        date_from = attrs.get('date_from', getattr(self.instance, 'date_from', None))
        date_to = attrs.get('date_to', getattr(self.instance, 'date_to', None))
        if date_from and date_to and date_from > date_to:
            raise serializers.ValidationError({
                'date_to': 'date_to harus sama atau setelah date_from.'
            })
        return attrs

    @transaction.atomic
    def update(self, instance, validated_data):
        items_data = validated_data.get('items')
        notes = validated_data.get('notes')
        date_changed = False

        if 'date_from' in validated_data:
            instance.date_from = validated_data['date_from']
            date_changed = True
        if 'date_to' in validated_data:
            instance.date_to = validated_data['date_to']
            date_changed = True
        if notes is not None:
            instance.notes = notes

        instance.save()

        if items_data is not None:
            instance.items.all().delete()
            total_cost = 0
            for item_data in items_data:
                item_data['cost_entry'] = instance
                item = MaterialCostItem.objects.create(**item_data)
                total_cost += item.subtotal
            instance.total_cost = total_cost

            revenue_data = Order.objects.filter(
                created_at__date__gte=instance.date_from,
                created_at__date__lte=instance.date_to,
                status='paid'
            ).aggregate(total=Sum('total_amount'))
            instance.total_revenue = revenue_data['total'] or 0
            instance.save()
        elif date_changed:
            revenue_data = Order.objects.filter(
                created_at__date__gte=instance.date_from,
                created_at__date__lte=instance.date_to,
                status='paid'
            ).aggregate(total=Sum('total_amount'))
            instance.total_revenue = revenue_data['total'] or 0
            instance.save()

        return instance
