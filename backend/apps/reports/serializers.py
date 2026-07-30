"""
Serializers untuk reports app.
"""
from rest_framework import serializers


class ReportSummarySerializer(serializers.Serializer):
    total_transaksi = serializers.IntegerField()
    total_pemasukan = serializers.IntegerField()
    rata_rata = serializers.IntegerField()
    lunas = serializers.IntegerField()
    pending = serializers.IntegerField()
    expired = serializers.IntegerField()


class PerKasirSerializer(serializers.Serializer):
    kasir_id = serializers.IntegerField()
    name = serializers.CharField()
    transaksi = serializers.IntegerField()
    total = serializers.IntegerField()


class TopMenuSerializer(serializers.Serializer):
    menu_id = serializers.IntegerField()
    name = serializers.CharField()
    emoji = serializers.CharField(required=False, allow_blank=True)
    qty = serializers.IntegerField()
    total = serializers.IntegerField()


class DailyReportSerializer(serializers.Serializer):
    date = serializers.DateField()
    summary = ReportSummarySerializer()
    per_kasir = PerKasirSerializer(many=True)
    top_menus = TopMenuSerializer(many=True)


class TopMenuListSerializer(serializers.Serializer):
    menu_id = serializers.IntegerField()
    name = serializers.CharField()
    emoji = serializers.CharField(required=False, allow_blank=True)
    qty = serializers.IntegerField()
    total = serializers.IntegerField()


class KasirPerformanceSerializer(serializers.Serializer):
    kasir_id = serializers.IntegerField()
    name = serializers.CharField()
    transaksi = serializers.IntegerField()
    total = serializers.IntegerField()
    rata_rata = serializers.IntegerField()


class ProfitEntrySerializer(serializers.Serializer):
    id = serializers.IntegerField()
    date_from = serializers.DateField()
    date_to = serializers.DateField()
    total_cost = serializers.IntegerField()
    total_revenue = serializers.IntegerField()
    profit = serializers.IntegerField()


class ProfitReportSerializer(serializers.Serializer):
    date_from = serializers.DateField()
    date_to = serializers.DateField()
    total_cost = serializers.IntegerField()
    total_revenue = serializers.IntegerField()
    total_profit = serializers.IntegerField()
    entries = ProfitEntrySerializer(many=True)
