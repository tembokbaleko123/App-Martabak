"""
Custom pagination untuk App Martabak.
"""
from rest_framework.pagination import PageNumberPagination
from rest_framework.response import Response


class StandardResultsSetPagination(PageNumberPagination):
    """
    Pagination standar dengan response format:
    {
        "status": true,
        "message": "...",
        "data": [...],
        "pagination": {
            "next": "...",
            "previous": "...",
            "count": 100,
            "num_pages": 10
        }
    }
    """

    page_size = 25
    page_size_query_param = 'page_size'
    max_page_size = 100

    def get_paginated_response(self, data):
        return Response({
            'status': True,
            'message': 'Berhasil mendapatkan data',
            'data': data,
            'pagination': {
                'next': self.get_next_link(),
                'previous': self.get_previous_link(),
                'count': self.page.paginator.count,
                'num_pages': self.page.paginator.num_pages,
            }
        })
