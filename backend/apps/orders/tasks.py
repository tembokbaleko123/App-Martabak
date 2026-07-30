"""
Celery tasks untuk orders app.
"""
from celery import shared_task
from django.utils import timezone


@shared_task
def check_goqris_payment(order_id):
    """
    Task untuk cek status pembayaran GoQris.
    Dijadwalkan via Celery Beat.
    """
    from .models import Order
    from apps.goqris.services import goqris_service

    try:
        order = Order.objects.get(id=order_id)
    except Order.DoesNotExist:
        return

    if order.status != 'pending':
        return

    if order.expires_at and order.expires_at < timezone.now():
        order.status = 'expired'
        order.save(update_fields=['status', 'updated_at'])
        return

    try:
        status_data = goqris_service.check_status(order.ref_id)
        if status_data.get('paid'):
            order.status = 'paid'
            order.paid_at = timezone.now()
            order.save(update_fields=['status', 'paid_at', 'updated_at'])
    except Exception:
        pass


@shared_task
def check_expired_orders():
    """
    Task untuk expiredkan order yang sudah lewat waktu.
    Dijadwalkan tiap 1 menit via Celery Beat.
    """
    from .models import Order

    Order.objects.filter(
        status='pending',
        expires_at__lt=timezone.now()
    ).update(status='expired')
