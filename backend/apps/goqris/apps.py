"""
Apps configuration untuk goqris.
"""
from django.apps import AppConfig


class GoqrisConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'apps.goqris'
    verbose_name = 'GoQris Payment'
