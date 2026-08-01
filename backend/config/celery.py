"""
Konfigurasi Celery untuk App Martabak.
"""
import os
from celery import Celery

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.dev')

app = Celery('martabak')
app.config_from_object('django.conf:settings', namespace='CELERY')
app.autodiscover_tasks()

# Beat schedule untuk task periodic
# check_goqris_payment dihapus dari schedule karena butuh order_id
# (seharusnya dipanggil saat order dibuat via apply_async)
app.conf.beat_schedule = {
    'cek-order-expired-setiap-menit': {
        'task': 'apps.orders.tasks.check_expired_orders',
        'schedule': 60.0,
    },
}


@app.task(bind=True, ignore_result=True)
def debug_task(self):
    print(f'Request: {self.request!r}')
