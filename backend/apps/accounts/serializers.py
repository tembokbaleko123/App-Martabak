"""
Serializers untuk accounts app.
"""
import bcrypt
from rest_framework import serializers
from django.contrib.auth import authenticate
from rest_framework_simplejwt.tokens import RefreshToken
from .models import Kasir


class PinLoginSerializer(serializers.Serializer):
    username = serializers.CharField(max_length=100)
    pin = serializers.CharField(max_length=6, min_length=4, write_only=True)

    def validate(self, attrs):
        username = attrs.get('username')
        pin = attrs.get('pin')

        try:
            kasir = Kasir.objects.get(username=username, is_active=True)
        except Kasir.DoesNotExist:
            raise serializers.ValidationError({'error': 'Username atau PIN salah'})

        if not bcrypt.checkpw(pin.encode('utf-8'), kasir.pin_hash.encode('utf-8')):
            raise serializers.ValidationError({'error': 'Username atau PIN salah'})

        refresh = RefreshToken.for_user(kasir)

        attrs['kasir'] = kasir
        attrs['refresh'] = str(refresh)
        attrs['access'] = str(refresh.access_token)

        return attrs


class ChangePinSerializer(serializers.Serializer):
    old_pin = serializers.CharField(max_length=6, min_length=4, write_only=True)
    new_pin = serializers.CharField(max_length=6, min_length=4, write_only=True)

    def validate_old_pin(self, value):
        user = self.context['request'].user
        if not bcrypt.checkpw(value.encode('utf-8'), user.pin_hash.encode('utf-8')):
            raise serializers.ValidationError('PIN lama salah')
        return value

    def validate_new_pin(self, value):
        if len(value) < 4:
            raise serializers.ValidationError('PIN minimal 4 digit')
        return value

    def save(self):
        user = self.context['request'].user
        new_pin_hash = bcrypt.hashpw(
            self.validated_data['new_pin'].encode('utf-8'),
            bcrypt.gensalt()
        ).decode('utf-8')
        user.pin_hash = new_pin_hash
        user.save(update_fields=['pin_hash'])


class KasirSerializer(serializers.ModelSerializer):
    class Meta:
        model = Kasir
        fields = ['id', 'username', 'role', 'is_active']
        read_only_fields = ['id', 'role']


class KasirCreateSerializer(serializers.ModelSerializer):
    pin = serializers.CharField(max_length=6, min_length=4, write_only=True)

    class Meta:
        model = Kasir
        fields = ['id', 'username', 'pin', 'role', 'is_active']
        read_only_fields = ['id']

    def create(self, attrs):
        pin = attrs.pop('pin')
        pin_hash = bcrypt.hashpw(pin.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
        kasir = Kasir(**attrs, pin_hash=pin_hash)
        kasir.save()
        return kasir
