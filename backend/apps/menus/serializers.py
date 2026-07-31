"""
Serializers untuk menus app.
"""
from django.conf import settings
from django.db import IntegrityError
from django.db.models import Max
from rest_framework import serializers
from .models import Menu


class MenuSerializer(serializers.ModelSerializer):
    image_url = serializers.SerializerMethodField()
    default_image_url = serializers.SerializerMethodField()

    class Meta:
        model = Menu
        fields = ['id', 'name', 'price', 'category', 'emoji', 'image', 'image_url', 'default_image_url', 'is_active', 'sort_order']
        read_only_fields = ['id', 'image_url', 'default_image_url']

    def get_image_url(self, obj):
        if obj.image:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.image.url)
            return obj.image.url
        return None

    def get_default_image_url(self, obj):
        default_images = {
            'manis': 'defaults/martabak_manis.jpg',
            'telur': 'defaults/martabak_telur.jpg',
            'tipis': 'defaults/martabak_tipis.jpg',
        }
        default_path = default_images.get(obj.category, 'defaults/martabak_manis.jpg')
        if settings.DEBUG:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(f'/media/{default_path}')
            return f'/media/{default_path}'
        return f'{settings.MEDIA_URL}{default_path}'


class MenuCreateUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Menu
        fields = ['id', 'name', 'price', 'category', 'emoji', 'image', 'is_active', 'sort_order']
        read_only_fields = ['id']

    def validate_price(self, value):
        if value < 0:
            raise serializers.ValidationError('Harga tidak boleh negatif')
        if value > 100_000_000:
            raise serializers.ValidationError('Harga tidak boleh lebih dari Rp 100.000.000')
        return value

    def validate(self, attrs):
        category = attrs.get('category')
        sort_order = attrs.get('sort_order')

        if sort_order is None or sort_order == 0:
            return attrs

        if category is None:
            return attrs

        queryset = Menu.objects.filter(category=category, sort_order=sort_order)

        if self.instance:
            queryset = queryset.exclude(pk=self.instance.pk)

        if queryset.exists():
            raise serializers.ValidationError({
                'sort_order': f'sort_order {sort_order} sudah digunakan dalam category {category}. Gunakan angka lain.'
            })

        return attrs

    def create(self, validated_data):
        validated_data['is_active'] = True

        category = validated_data.get('category')
        sort_order = validated_data.get('sort_order')

        if sort_order is None or sort_order == 0:
            max_sort = Menu.objects.filter(category=category).aggregate(
                max_order=Max('sort_order')
            )['max_order']
            validated_data['sort_order'] = (max_sort or 0) + 1

        try:
            return super().create(validated_data)
        except IntegrityError:
            raise serializers.ValidationError({
                'sort_order': f'sort_order {validated_data["sort_order"]} sudah digunakan dalam category {category}. Gunakan angka lain.'
            })
