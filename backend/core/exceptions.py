"""
Custom exceptions untuk App Martabak.
"""
from django.conf import settings
from rest_framework.views import exception_handler
from rest_framework.response import Response
from rest_framework import status


def custom_exception_handler(exc, context):
    """
    Custom exception handler dengan format response:
    {
        "status": false,
        "message": "Error message",
        "errors": {...}  # Only in DEBUG mode
    }
    """
    if isinstance(exc, GoQrisException):
        return Response(
            {
                'status': False,
                'message': exc.message,
                'errors': None,
            },
            status=exc.status_code
        )

    if isinstance(exc, PaymentException):
        return Response(
            {
                'status': False,
                'message': exc.message,
                'errors': None,
            },
            status=exc.status_code
        )

    response = exception_handler(exc, context)

    if response is not None:
        detail = exc.detail if hasattr(exc, 'detail') else str(exc)
        if isinstance(detail, dict):
            first_key = next(iter(detail), None)
            message = detail[first_key][0] if first_key and isinstance(detail[first_key], list) else str(detail)
        elif isinstance(detail, list):
            message = detail[0] if detail else str(exc)
        else:
            message = str(detail)

        custom_response_data = {
            'status': False,
            'message': message,
            'errors': response.data if settings.DEBUG else None,
        }
        response.data = custom_response_data

    return response


class GoQrisException(Exception):
    """
    Exception untuk error dari GoQris API.
    """

    def __init__(self, message, status_code=status.HTTP_502_BAD_GATEWAY):
        self.message = message
        self.status_code = status_code
        super().__init__(self.message)


class PaymentException(Exception):
    """
    Exception untuk error payment.
    """

    def __init__(self, message, status_code=status.HTTP_400_BAD_REQUEST):
        self.message = message
        self.status_code = status_code
        super().__init__(self.message)
