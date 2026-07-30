"""
Middleware untuk App Martabak.
"""
import time
import logging

logger = logging.getLogger('request_logger')


class RequestLoggingMiddleware:
    """
    Middleware untuk logging request API.
    Log format: METHOD PATH | User: username | Status: 200 | Time: 0.05s
    """

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        start_time = time.time()

        response = self.get_response(request)

        duration = time.time() - start_time

        user = getattr(request, 'user', None)
        if user and user.is_authenticated:
            username = getattr(user, 'username', 'Unknown')
        else:
            username = 'Anonymous'

        logger.info(
            f'{request.method} {request.path} | '
            f'User: {username} | '
            f'Status: {response.status_code} | '
            f'Time: {duration:.2f}s'
        )

        return response
