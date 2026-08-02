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

        try:
            if not bcrypt.checkpw(pin.encode('utf-8'), kasir.pin_hash.encode('utf-8')):
                raise serializers.ValidationError({'error': 'Username atau PIN salah'})
        except (ValueError, TypeError):
            raise serializers.ValidationError({'error': 'Akun bermasalah. Hubungi owner.'})

        refresh = RefreshToken.for_user(kasir)

        attrs['kasir'] = kasir
        attrs['refresh'] = str(refresh)
        attrs['access'] = str(refresh.access_token)

        return attrs


class ChangePinSerializer(serializers.Serializer):
    old_pin = serializers.CharField(max_length=6, min_length=6, write_only=True)
    new_pin = serializers.CharField(max_length=6, min_length=6, write_only=True)

    def validate_old_pin(self, value):
        user = self.context['request'].user
        try:
            if not bcrypt.checkpw(value.encode('utf-8'), user.pin_hash.encode('utf-8')):
                raise serializers.ValidationError('PIN lama salah')
        except (ValueError, TypeError):
            raise serializers.ValidationError('Akun bermasalah. Hubungi owner.')
        return value

    def validate_new_pin(self, value):
        if len(value) < 6:
            raise serializers.ValidationError('PIN minimal 6 digit untuk keamanan.')

        if len(set(value)) == 1:
            raise serializers.ValidationError('PIN tidak boleh semua digit sama (e.g., 1111)')

        for i in range(len(value) - 3):
            chunk = value[i:i+4]
            if all(int(chunk[j+1]) - int(chunk[j]) == 1 for j in range(3)):
                raise serializers.ValidationError('PIN tidak boleh mengandung urutan berurutan (4 digit atau lebih).')

        for i in range(len(value) - 3):
            chunk = value[i:i+4]
            if all(int(chunk[j]) - int(chunk[j+1]) == 1 for j in range(3)):
                raise serializers.ValidationError('PIN tidak boleh mengandung urutan berurutan (4 digit atau lebih).')

        for i in range(len(value) - 3):
            if value[i] == value[i+1] == value[i+2]:
                chunk = value[i:i+3]
                if i + 3 < len(value) and value[i] != value[i+3]:
                    raise serializers.ValidationError('PIN tidak boleh mengandung digit berulang (3 kali atau lebih).')

        for i in range(len(value) - 3):
            forward_cyclic = all(
                (int(value[j+1]) - int(value[j])) % 10 == 1
                for j in range(i, i + 3)
            )
            if forward_cyclic:
                raise serializers.ValidationError('PIN tidak boleh berurutan (termasuk wrap-around).')

        for i in range(len(value) - 3):
            reverse_cyclic = all(
                (int(value[j]) - int(value[j+1])) % 10 == 1
                for j in range(i, i + 3)
            )
            if reverse_cyclic:
                raise serializers.ValidationError('PIN tidak boleh berurutan (termasuk wrap-around).')

        common_pins = {'0000', '1111', '1234', '4321', '9999', '2222', '3333', '4444', '5555', '6666', '7777', '8888', '000000', '111111', '123456', '654321'}
        if value in common_pins:
            raise serializers.ValidationError('PIN terlalu umum. Gunakan PIN lain.')

        return value

    def validate(self, attrs):
        old_pin = attrs.get('old_pin')
        new_pin = attrs.get('new_pin')
        if old_pin and new_pin and old_pin == new_pin:
            raise serializers.ValidationError({
                'new_pin': 'PIN baru tidak boleh sama dengan PIN lama.'
            })
        return attrs

    def save(self):
        user = self.context['request'].user
        if not user.is_authenticated:
            raise PermissionError('User must be authenticated')
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
    pin = serializers.CharField(max_length=6, min_length=6, write_only=True)

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
