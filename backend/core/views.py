"""
Core views untuk App Martabak.
"""
from django.http import JsonResponse
from django.views import View
from django.db import connection


class HealthCheckView(View):
    """
    Health check endpoint untuk monitoring.
    """

    def get(self, request):
        try:
            with connection.cursor() as cursor:
                cursor.execute("SELECT 1")
            return JsonResponse({'status': 'ok', 'database': 'ok'})
        except Exception as e:
            return JsonResponse(
                {'status': 'error', 'database': 'down', 'error': str(e)},
                status=503
            )
