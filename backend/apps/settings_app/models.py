"""
Models untuk settings_app app.
"""
from django.db import models


class Settings(models.Model):
    """
    Model Settings singleton untuk konfigurasi aplikasi.

    Field:
    - goqris_project_name: Nama project/toko di GoQris (akan terlihat saat scan QRIS)
      API Key diambil dari .env (GOQRIS_API_KEY)
    """
    id = models.IntegerField(default=1, primary_key=True)
    goqris_project_name = models.CharField(max_length=100, blank=True, default='')

    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'settings'
        verbose_name = 'Settings'
        verbose_name_plural = 'Settings'

    def __str__(self):
        return f'Settings ({self.goqris_project_name or "Martabak"})'

    def save(self, *args, **kwargs):
        self.id = 1
        super().save(*args, **kwargs)

    @classmethod
    def get_instance(cls):
        obj, _ = cls.objects.get_or_create(id=1)
        return obj
