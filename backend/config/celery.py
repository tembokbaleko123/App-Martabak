"""
Celery configuration untuk App Martabak.
"""
import os
from celery import Celery

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.dev')

app = Celery('martabak')
app.config_from_object('django.conf:settings', namespace='CELERY')
app.autodiscover_tasks()

app.conf.beat_schedule = {
    'check-goqris-payment-every-minute': {
        'task': 'apps.orders.tasks.check_goqris_payment',
        'schedule': 60.0,
    },
    'check-expired-orders-every-minute': {
        'task': 'apps.orders.tasks.check_expired_orders',
        'schedule': 60.0,
    },
}


@app.task(bind=True, ignore_result=True)
def debug_task(self):
    print(f'Request: {self.request!r}')
