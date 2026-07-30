"""
Custom throttles untuk App Martabak.
"""
from rest_framework.throttling import SimpleRateThrottle


class LoginRateThrottle(SimpleRateThrottle):
    """
    Throttle untuk login endpoint.
    Rate: 5 per menit per IP.
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
