"""
Core views untuk App Martabak.
"""
from django.http import JsonResponse
from django.views import View


class HealthCheckView(View):
    """
    Health check endpoint untuk monitoring.
    """

    def get(self, request):
        return JsonResponse({'status': 'ok'})
