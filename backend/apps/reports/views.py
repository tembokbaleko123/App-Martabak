"""
Views untuk reports app.
"""
from datetime import datetime, date
from rest_framework import viewsets
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from core.permissions import IsOwner
from .services import ReportService
from .serializers import (
    DailyReportSerializer,
    TopMenuListSerializer,
    KasirPerformanceSerializer,
    ProfitReportSerializer,
)


class ReportViewSet(viewsets.GenericViewSet):
    """
    ViewSet untuk laporan.

    Endpoints:
    - GET /api/v1/reports/daily/ - Laporan harian (owner only)
    - GET /api/v1/reports/top-menus/ - Top N menu (owner only)
    - GET /api/v1/reports/kasir-performance/ - Performa kasir (owner only)
    """
    permission_classes = [IsAuthenticated, IsOwner]

    def _parse_date(self, date_str):
        """Parse date string to date object."""
        if not date_str:
            return date.today()
        try:
            return datetime.strptime(date_str, '%Y-%m-%d').date()
        except ValueError:
            return date.today()

    @action(detail=False, methods=['get'], url_path='daily')
    def daily(self, request):
        """
        Laporan harian.

        Query params:
        - date: YYYY-MM-DD (default: today)
        """
        date_str = request.query_params.get('date')
        target_date = self._parse_date(date_str)

        data = ReportService.daily_report(target_date)
        serializer = DailyReportSerializer(data)
        return Response({
            'status': True,
            'message': 'Berhasil mendapatkan laporan harian',
            'data': serializer.data,
        })

    @action(detail=False, methods=['get'], url_path='top-menus')
    def top_menus(self, request):
        """
        Top N menu dalam rentang waktu.

        Query params:
        - from: YYYY-MM-DD (required)
        - to: YYYY-MM-DD (required)
        - limit: int (default 5)
        """
        from_date_str = request.query_params.get('from')
        to_date_str = request.query_params.get('to')
        limit_str = request.query_params.get('limit', '5')

        if not from_date_str or not to_date_str:
            return Response({
                'status': False,
                'message': 'Parameter from dan to wajib diisi',
            }, status=400)

        try:
            from_date = datetime.strptime(from_date_str, '%Y-%m-%d').date()
            to_date = datetime.strptime(to_date_str, '%Y-%m-%d').date()
        except ValueError:
            return Response({
                'status': False,
                'message': 'Format date harus YYYY-MM-DD',
            }, status=400)

        try:
            limit = int(limit_str)
            if limit < 1:
                limit = 5
        except ValueError:
            limit = 5

        data = ReportService.top_menus(from_date, to_date, limit)
        serializer = TopMenuListSerializer(data, many=True)
        return Response({
            'status': True,
            'message': 'Berhasil mendapatkan top menu',
            'data': serializer.data,
        })

    @action(detail=False, methods=['get'], url_path='kasir-performance')
    def kasir_performance(self, request):
        """
        Performa kasir di tanggal tertentu.

        Query params:
        - date: YYYY-MM-DD (default: today)
        """
        date_str = request.query_params.get('date')
        target_date = self._parse_date(date_str)

        data = ReportService.kasir_performance(target_date)
        serializer = KasirPerformanceSerializer(data, many=True)
        return Response({
            'status': True,
            'message': 'Berhasil mendapatkan performa kasir',
            'data': serializer.data,
        })

    @action(detail=False, methods=['get'], url_path='profit')
    def profit(self, request):
        """
        Laporan profit per periode.

        Query params:
        - from: YYYY-MM-DD (required)
        - to: YYYY-MM-DD (required)
        """
        from_date_str = request.query_params.get('from')
        to_date_str = request.query_params.get('to')

        if not from_date_str or not to_date_str:
            return Response({
                'status': False,
                'message': 'Parameter from dan to wajib diisi',
            }, status=400)

        try:
            from_date = datetime.strptime(from_date_str, '%Y-%m-%d').date()
            to_date = datetime.strptime(to_date_str, '%Y-%m-%d').date()
        except ValueError:
            return Response({
                'status': False,
                'message': 'Format date harus YYYY-MM-DD',
            }, status=400)

        data = ReportService.profit_report(from_date, to_date)
        serializer = ProfitReportSerializer(data)
        return Response({
            'status': True,
            'message': 'Berhasil mendapatkan laporan profit',
            'data': serializer.data,
        })
