"""
Custom throttles untuk App Martabak.
"""
from rest_framework.throttling import SimpleRateThrottle


class LoginRateThrottle(SimpleRateThrottle):
    """
    Throttle untuk login endpoint.
    Rate: 20 per menit per IP.
    """
    scope = 'login'

    def get_cache_key(self, request, view):
        return self.get_ident(request)


class GoQrisRateThrottle(SimpleRateThrottle):
    """
    Throttle untuk GoQris API calls.
    Rate: 30 per menit per IP.
    """
    scope = 'goqris'

    def get_cache_key(self, request, view):
        return self.get_ident(request)


class QueueRateThrottle(SimpleRateThrottle):
    """
    Throttle untuk queue endpoint.
    Rate: 6 per menit per user (1 request setiap 10 detik).
    """
    scope = 'queue'

    def get_cache_key(self, request, view):
        if request.user and request.user.is_authenticated:
            return f'queue_{request.user.id}'
        return self.get_ident(request)
