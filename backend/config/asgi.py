"""
ASGI config for App Martabak.
"""
import os
from django.core.asgi import get_asgi_application

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.prod')

application = get_asgi_application()
