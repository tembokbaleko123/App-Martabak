"""
Models untuk accounts app.
"""
from django.contrib.auth.models import AbstractUser
from django.db import models


class Kasir(AbstractUser):
    """
    Model Kasir untuk autentikasi dan manajemen user.
    
    Field:
    - pin_hash: Hash PIN 4-6 digit
    - role: 'owner' atau 'kasir'
    - is_active: Untuk soft delete
    """
    ROLE_CHOICES = [
        ('owner', 'Owner'),
        ('kasir', 'Kasir'),
    ]

    pin_hash = models.CharField(max_length=255)
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='kasir')
    is_active = models.BooleanField(default=True)

    class Meta:
        db_table = 'kasirs'
        verbose_name = 'Kasir'
        verbose_name_plural = 'Kasir'

    def __str__(self):
        return f'{self.name} ({self.role})'

    @property
    def name(self):
        return self.username
