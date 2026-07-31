"""
Services untuk reports app.
"""
from datetime import date, datetime, timedelta
from django.db.models import Sum, Count, Avg
from django.db.models.functions import TruncDate
from django.utils import timezone
from apps.orders.models import Order, OrderItem


class ReportService:
    """
    Service untuk generate laporan.
    """

    @staticmethod
    def _get_date_range(target_date: date):
        """
        Convert date to datetime range in WITA timezone (UTC+8).

        Args:
            target_date: Date in WITA timezone

        Returns:
            Tuple of (start_datetime, end_datetime) in WITA timezone
        """
        from zoneinfo import ZoneInfo
        wita_tz = ZoneInfo('Asia/Makassar')
        start_dt = datetime.combine(target_date, datetime.min.time())
        start_dt = wita_tz.localize(start_dt)
        end_dt = start_dt + timedelta(days=1)
        return start_dt, end_dt

    @staticmethod
    def daily_report(target_date: date) -> dict:
        """
        Generate laporan harian.

        Args:
            target_date: Tanggal laporan

        Returns:
            Dict dengan summary, per_kasir, top_menus
        """
        start_dt, end_dt = ReportService._get_date_range(target_date)

        orders = Order.objects.filter(
            created_at__gte=start_dt,
            created_at__lt=end_dt,
            status__in=['paid', 'pending', 'expired']
        )

        paid_orders = orders.filter(status='paid')
        pending_orders = orders.filter(status='pending')
        expired_orders = orders.filter(status='expired')

        total_transaksi = paid_orders.count()
        total_pemasukan = paid_orders.aggregate(total=Sum('total_amount'))['total'] or 0
        rata_rata = total_pemasukan / total_transaksi if total_transaksi > 0 else 0

        per_kasir = orders.filter(status='paid').values(
            'kasir_id',
            'kasir__username'
        ).annotate(
            transaksi=Count('id'),
            total=Sum('total_amount')
        ).order_by('-total')

        per_kasir_list = [
            {
                'kasir_id': item['kasir_id'],
                'name': item['kasir__username'],
                'transaksi': item['transaksi'],
                'total': item['total'] or 0,
            }
            for item in per_kasir
        ]

        top_menus_data = OrderItem.objects.filter(
            order__in=paid_orders
        ).values(
            'menu_id',
            'menu__name',
            'menu__emoji'
        ).annotate(
            qty=Sum('qty'),
            total=Sum('subtotal')
        ).order_by('-total')[:5]

        top_menus_list = [
            {
                'menu_id': item['menu_id'],
                'name': item['menu__name'],
                'emoji': item['menu__emoji'] or '',
                'qty': item['qty'],
                'total': item['total'] or 0,
            }
            for item in top_menus_data
        ]

        return {
            'date': target_date.isoformat(),
            'summary': {
                'total_transaksi': total_transaksi,
                'total_pemasukan': total_pemasukan,
                'rata_rata': int(rata_rata),
                'lunas': total_transaksi,
                'pending': pending_orders.count(),
                'expired': expired_orders.count(),
            },
            'per_kasir': per_kasir_list,
            'top_menus': top_menus_list,
        }

    @staticmethod
    def top_menus(from_date: date, to_date: date, limit: int = 5) -> list:
        """
        Get top N menu dalam rentang waktu.

        Args:
            from_date: Tanggal mulai
            to_date: Tanggal akhir
            limit: Jumlah menu (default 5)

        Returns:
            List of top menus
        """
        start_dt, end_dt = ReportService._get_date_range(to_date)
        from_start, _ = ReportService._get_date_range(from_date)

        orders = Order.objects.filter(
            created_at__gte=from_start,
            created_at__lt=end_dt,
            status='paid'
        )

        top_menus_data = OrderItem.objects.filter(
            order__in=orders
        ).values(
            'menu_id',
            'menu__name',
            'menu__emoji'
        ).annotate(
            qty=Sum('qty'),
            total=Sum('subtotal')
        ).order_by('-total')[:limit]

        return [
            {
                'menu_id': item['menu_id'],
                'name': item['menu__name'],
                'emoji': item['menu__emoji'] or '',
                'qty': item['qty'],
                'total': item['total'] or 0,
            }
            for item in top_menus_data
        ]

    @staticmethod
    def kasir_performance(target_date: date) -> list:
        """
        Get performa kasir di tanggal tertentu.

        Args:
            target_date: Tanggal laporan

        Returns:
            List of kasir performance
        """
        start_dt, end_dt = ReportService._get_date_range(target_date)

        orders = Order.objects.filter(
            created_at__gte=start_dt,
            created_at__lt=end_dt,
            status__in=['paid', 'pending', 'expired']
        )

        kasir_data = orders.filter(status='paid').values(
            'kasir_id',
            'kasir__username'
        ).annotate(
            transaksi=Count('id'),
            total=Sum('total_amount'),
            rata_rata=Avg('total_amount')
        ).order_by('-total')

        return [
            {
                'kasir_id': item['kasir_id'],
                'name': item['kasir__username'],
                'transaksi': item['transaksi'],
                'total': item['total'] or 0,
                'rata_rata': int(item['rata_rata'] or 0),
            }
            for item in kasir_data
        ]

    @staticmethod
    def profit_report(from_date: date, to_date: date) -> dict:
        """
        Generate profit report per periode.

        Args:
            from_date: Tanggal mulai
            to_date: Tanggal akhir

        Returns:
            Dict dengan total_revenue, total_cost, profit, dan entries
        """
        from apps.raw_materials.models import MaterialCostEntry

        entries = MaterialCostEntry.objects.filter(
            date_from__gte=from_date,
            date_to__lte=to_date
        ).order_by('-date_from')

        entries_list = [
            {
                'id': entry.id,
                'date_from': entry.date_from.isoformat(),
                'date_to': entry.date_to.isoformat(),
                'total_cost': entry.total_cost,
                'total_revenue': entry.total_revenue,
                'profit': entry.profit,
            }
            for entry in entries
        ]

        total_cost = sum(e['total_cost'] for e in entries_list)
        total_revenue = sum(e['total_revenue'] for e in entries_list)
        total_profit = total_revenue - total_cost

        return {
            'date_from': from_date.isoformat(),
            'date_to': to_date.isoformat(),
            'total_cost': total_cost,
            'total_revenue': total_revenue,
            'total_profit': total_profit,
            'entries': entries_list,
        }
