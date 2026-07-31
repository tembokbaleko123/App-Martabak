"""
Models untuk menus app.
"""
from django.db import models


class Menu(models.Model):
    """
    Model Menu untuk daftar menu martabak.
    
    Field:
    - name: Nama menu
    - price: Harga dalam rupiah
    - category: 'manis', 'telur', atau 'tipis'
    - emoji: Emoji untuk display di app
    - is_active: Untuk soft delete / toggle aktif
    - sort_order: Urutan tampil
    """
    CATEGORY_CHOICES = [
        ('manis', 'Manis'),
        ('telur', 'Telur'),
        ('tipis', 'Tipis'),
    ]

    name = models.CharField(max_length=100)
    price = models.BigIntegerField(help_text='Harga dalam rupiah')
    category = models.CharField(max_length=50, choices=CATEGORY_CHOICES)
    emoji = models.CharField(max_length=10, default='🥞')
    image = models.ImageField(
        upload_to='menus/',
        null=True,
        blank=True,
        help_text='Gambar menu (optional)'
    )
    is_active = models.BooleanField(default=True)
    sort_order = models.IntegerField(default=0)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'menus'
        verbose_name = 'Menu'
        verbose_name_plural = 'Menu'
        ordering = ['category', 'sort_order', 'name']
        constraints = [
            models.UniqueConstraint(
                fields=['category', 'sort_order'],
                name='unique_sort_order_per_category'
            )
        ]

    def __str__(self):
        return f'{self.emoji} {self.name} - Rp {self.price:,}'
