"""
Serializers untuk categories app.
"""
from django.db import IntegrityError, transaction
from django.db.models import Max
from rest_framework import serializers
from .models import Category


class CategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = ['id', 'name', 'sort_order', 'is_active', 'created_at', 'updated_at']
        read_only_fields = ['id', 'created_at', 'updated_at']


class CategoryCreateUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = ['id', 'name', 'sort_order', 'is_active']
        read_only_fields = ['id']

    def validate_name(self, value):
        if not value.strip():
            raise serializers.ValidationError("Nama category tidak boleh kosong")
        return value.strip().lower()

    def validate_sort_order(self, value):
        if value < 0:
            raise serializers.ValidationError("Sort order tidak boleh negatif")
        return value

    def validate(self, attrs):
        sort_order = attrs.get('sort_order')
        if sort_order is None:
            return attrs

        queryset = Category.objects.filter(sort_order=sort_order)
        if self.instance:
            queryset = queryset.exclude(pk=self.instance.pk)

        if queryset.exists():
            raise serializers.ValidationError({
                'sort_order': f'Sort order {sort_order} sudah digunakan. Gunakan angka lain.'
            })

        return attrs

    def create(self, validated_data):
        sort_order = validated_data.get('sort_order')
        if sort_order is None:
            with transaction.atomic():
                max_sort = Category.objects.select_for_update().aggregate(
                    max_order=Max('sort_order')
                )['max_order']
                validated_data['sort_order'] = (max_sort or 0) + 1

        try:
            return super().create(validated_data)
        except IntegrityError:
            raise serializers.ValidationError({
                'sort_order': f'Sort order {validated_data["sort_order"]} sudah digunakan.'
            })
