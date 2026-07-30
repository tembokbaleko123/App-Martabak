"""
Models untuk orders app.
"""
from django.db import models
from django.conf import settings


class Order(models.Model):
    """
    Model Order untuk transaksi martabak.

    Field:
    - ref_id: Reference ID unik (format: INV-YYYYMMDD-NNN)
    - kasir: FK ke Kasir yang membuat order
    - total_amount: Total harga
    - status: 'pending', 'paid', 'expired', 'cancelled'
    - payment_method: 'goqris' | 'cash'
    - payment_method_label: Label untuk display (e.g. "GoQris QRIS", "Tunai")
    - qr_string: String QRIS dari GoQris (hanya untuk goqris)
    - qr_image_url: URL gambar QR (opsional)
    - expires_at: Waktu kedaluwarsa QR
    - paid_at: Waktu pembayaran
    - note: Catatan bebas
    - goqris_data: Raw response GoQris (JSON)
    """
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('paid', 'Paid'),
        ('expired', 'Expired'),
        ('cancelled', 'Cancelled'),
    ]

    PAYMENT_METHOD_CHOICES = [
        ('goqris', 'GoQris QRIS'),
        ('cash', 'Tunai'),
    ]

    ref_id = models.CharField(max_length=50, unique=True)
    kasir = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.PROTECT,
        related_name='orders'
    )
    total_amount = models.BigIntegerField()
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    payment_method = models.CharField(
        max_length=20,
        choices=PAYMENT_METHOD_CHOICES,
        default='goqris',
        help_text='Metode pembayaran: goqris (QRIS) atau cash (Tunai)'
    )
    payment_method_label = models.CharField(
        max_length=50,
        blank=True,
        default='',
        help_text='Label metode pembayaran untuk display (e.g. "GoQris QRIS", "Tunai")'
    )
    qr_string = models.TextField(null=True, blank=True)
    qr_image_url = models.TextField(null=True, blank=True)
    expires_at = models.DateTimeField(null=True, blank=True)
    paid_at = models.DateTimeField(null=True, blank=True)
    note = models.TextField(null=True, blank=True)
    goqris_data = models.JSONField(null=True, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'orders'
        verbose_name = 'Order'
        verbose_name_plural = 'Orders'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['status', 'created_at']),
            models.Index(fields=['kasir', 'created_at']),
            models.Index(fields=['created_at']),
        ]

    def __str__(self):
        return f'{self.ref_id} - {self.status}'


class OrderItem(models.Model):
    """
    Model OrderItem untuk item dalam order.
    
    Field:
    - order: FK ke Order
    - menu: FK ke Menu
    - qty: Jumlah
    - price_at_order: Snapshot harga saat order dibuat
    - subtotal: qty * price_at_order
    """
    order = models.ForeignKey(
        Order,
        on_delete=models.CASCADE,
        related_name='items'
    )
    menu = models.ForeignKey(
        'menus.Menu',
        on_delete=models.PROTECT,
        related_name='order_items'
    )
    qty = models.IntegerField()
    price_at_order = models.BigIntegerField()
    subtotal = models.BigIntegerField()

    class Meta:
        db_table = 'order_items'
        verbose_name = 'Order Item'
        verbose_name_plural = 'Order Items'

    def __str__(self):
        return f'{self.menu.name} x {self.qty}'

    def save(self, *args, **kwargs):
        self.subtotal = self.qty * self.price_at_order
        super().save(*args, **kwargs)
