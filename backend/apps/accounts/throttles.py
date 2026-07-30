"""
Throttles untuk accounts app.
"""
from core.throttles import LoginRateThrottle


class LoginThrottle(LoginRateThrottle):
    """
    Throttle untuk login endpoint.
    """
    pass
