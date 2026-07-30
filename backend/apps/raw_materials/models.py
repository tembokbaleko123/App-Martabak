from django.db import models
from django.conf import settings


class MaterialItem(models.Model):
    """
    Master list of material names (free text, user-defined).
    """
    name = models.CharField(
        max_length=100,
        help_text='Nama bahan baku (bebas)'
    )
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'material_items'
        verbose_name = 'Material Item'
        verbose_name_plural = 'Material Items'
        ordering = ['name']

    def __str__(self):
        return self.name


class MaterialCostEntry(models.Model):
    """
    Entry for manual cost calculation per date range.
    """
    date_from = models.DateField(
        help_text='Tanggal mulai periode'
    )
    date_to = models.DateField(
        help_text='Tanggal akhir periode'
    )
    total_cost = models.IntegerField(
        default=0,
        help_text='Total biaya bahan baku (calculated from items)'
    )
    total_revenue = models.IntegerField(
        default=0,
        help_text='Total pendapatan dari orders (calculated)'
    )
    profit = models.IntegerField(
        default=0,
        help_text='Laba = total_revenue - total_cost'
    )
    notes = models.TextField(
        blank=True,
        null=True,
        help_text='Catatan opsional'
    )
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        related_name='cost_entries'
    )
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'material_cost_entries'
        verbose_name = 'Material Cost Entry'
        verbose_name_plural = 'Material Cost Entries'
        ordering = ['-date_from']

    def __str__(self):
        return f'{self.date_from} - {self.date_to}'

    def save(self, *args, **kwargs):
        self.profit = self.total_revenue - self.total_cost
        super().save(*args, **kwargs)


class MaterialCostItem(models.Model):
    """
    Individual material cost item within a cost entry.
    """
    cost_entry = models.ForeignKey(
        MaterialCostEntry,
        on_delete=models.CASCADE,
        related_name='items'
    )
    material_name = models.CharField(
        max_length=100,
        help_text='Nama bahan (free text)'
    )
    quantity = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        help_text='Jumlah bahan'
    )
    price_per_unit = models.IntegerField(
        help_text='Harga per unit'
    )
    subtotal = models.IntegerField(
        default=0,
        help_text='quantity × price_per_unit'
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'material_cost_items'
        verbose_name = 'Material Cost Item'
        verbose_name_plural = 'Material Cost Items'

    def __str__(self):
        return f'{self.material_name} x {self.quantity}'

    def save(self, *args, **kwargs):
        self.subtotal = int(float(self.quantity) * self.price_per_unit)
        super().save(*args, **kwargs)
