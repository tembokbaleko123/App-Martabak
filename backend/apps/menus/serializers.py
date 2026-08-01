"""
Serializers untuk menus app.
"""
from django.conf import settings
from django.db import IntegrityError, transaction
from django.db.models import Max
from rest_framework import serializers
from apps.categories.models import Category
from .models import Menu


class MenuSerializer(serializers.ModelSerializer):
    category = serializers.SerializerMethodField()
    image_url = serializers.SerializerMethodField()
    default_image_url = serializers.SerializerMethodField()

    class Meta:
        model = Menu
        fields = ['id', 'name', 'price', 'category', 'emoji', 'image', 'image_url', 'default_image_url', 'is_active', 'sort_order']
        read_only_fields = ['id', 'image_url', 'default_image_url']

    def get_category(self, obj):
        if obj.category:
            return {
                'id': obj.category.id,
                'name': obj.category.name
            }
        return None

    def get_image_url(self, obj):
        if obj.image:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.image.url)
            return obj.image.url
        return None

    def get_default_image_url(self, obj):
        default_path = 'defaults/martabak.jpg'
        if settings.DEBUG:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(f'/media/{default_path}')
            return f'/media/{default_path}'
        return f'{settings.MEDIA_URL}{default_path}'


class MenuCreateUpdateSerializer(serializers.ModelSerializer):
    category_id = serializers.PrimaryKeyRelatedField(
        queryset=Category.objects.all(),
        source='category',
        write_only=True,
        required=False,
        allow_null=True
    )

    class Meta:
        model = Menu
        fields = ['id', 'name', 'price', 'category_id', 'emoji', 'image', 'is_active', 'sort_order']
        read_only_fields = ['id']

    def validate_name(self, value):
        if not value or not value.strip():
            raise serializers.ValidationError("Nama menu tidak boleh kosong")
        return value.strip()

    def validate_price(self, value):
        if value <= 0:
            raise serializers.ValidationError('Harga tidak boleh 0 atau negatif')
        if value > 100_000_000:
            raise serializers.ValidationError('Harga tidak boleh lebih dari Rp 100.000.000')
        return value

    def validate(self, attrs):
        category = attrs.get('category')
        sort_order = attrs.get('sort_order')

        if sort_order is None:
            return attrs

        if category is None:
            queryset = Menu.objects.filter(category__isnull=True, sort_order=sort_order)
        else:
            queryset = Menu.objects.filter(category=category, sort_order=sort_order)

        if self.instance:
            queryset = queryset.exclude(pk=self.instance.pk)

        if queryset.exists():
            if category is None:
                raise serializers.ValidationError({
                    'sort_order': f'sort_order {sort_order} sudah digunakan untuk menu tanpa category. Gunakan angka lain.'
                })
            raise serializers.ValidationError({
                'sort_order': f'sort_order {sort_order} sudah digunakan dalam category ini. Gunakan angka lain.'
            })

        return attrs

    def create(self, validated_data):
        validated_data['is_active'] = True

        category = validated_data.get('category')
        sort_order = validated_data.get('sort_order')

        if sort_order is None:
            with transaction.atomic():
                max_sort = Menu.objects.filter(category=category).select_for_update().aggregate(
                    max_order=Max('sort_order')
                )['max_order']
                validated_data['sort_order'] = (max_sort or 0) + 1

        try:
            return super().create(validated_data)
        except IntegrityError:
            raise serializers.ValidationError({
                'sort_order': f'sort_order {validated_data["sort_order"]} sudah digunakan dalam category ini.'
            })


class MenuBulkUpdateSerializer(serializers.Serializer):
    menu_ids = serializers.ListField(
        child=serializers.IntegerField(min_value=1),
        min_length=1,
        help_text='List of menu IDs to update'
    )
    category_id = serializers.PrimaryKeyRelatedField(
        queryset=Category.objects.all(),
        required=False,
        allow_null=True,
        help_text='New category ID (optional)'
    )
    is_active = serializers.BooleanField(
        required=False,
        help_text='Set menu active status (optional)'
    )

    def validate(self, attrs):
        if not attrs.get('menu_ids'):
            raise serializers.ValidationError({'menu_ids': 'Minimal 1 menu ID harus diberikan.'})
        return attrs

    def validate_category_id(self, value):
        if value and not value.is_active:
            raise serializers.ValidationError('Category tidak aktif. Pilih category yang aktif.')
        return value
