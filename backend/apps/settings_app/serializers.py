"""
Serializers untuk settings_app.
"""
from rest_framework import serializers
from .models import Settings


class SettingsSerializer(serializers.ModelSerializer):
    class Meta:
        model = Settings
        fields = ['id', 'goqris_project_name']
        read_only_fields = ['id']
