"""
Serializers untuk menus app.
"""
from rest_framework import serializers
from .models import Menu


class MenuSerializer(serializers.ModelSerializer):
    class Meta:
        model = Menu
        fields = ['id', 'name', 'price', 'category', 'emoji', 'is_active', 'sort_order']
        read_only_fields = ['id']


class MenuCreateUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Menu
        fields = ['id', 'name', 'price', 'category', 'emoji', 'is_active', 'sort_order']
        read_only_fields = ['id']

    def validate_price(self, value):
        if value < 0:
            raise serializers.ValidationError('Harga tidak boleh negatif')
        if value > 100_000_000:
            raise serializers.ValidationError('Harga tidak boleh lebih dari Rp 100.000.000')
        return value
