"""
Models untuk categories app.
"""
from django.db import models, transaction


class CategoryManager(models.Manager):
    def active(self):
        return self.filter(is_active=True)


class Category(models.Model):
    """
    Model Category untuk mengelompokkan menu.

    Field:
    - name: Nama category (unique, stored lowercase)
    - sort_order: Urutan tampil (unique globally)
    - is_active: Untuk soft delete
    """
    name = models.CharField(max_length=50, unique=True)
    sort_order = models.IntegerField(default=0, unique=True)
    is_active = models.BooleanField(default=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    objects = CategoryManager()

    class Meta:
        db_table = 'categories'
        verbose_name = 'Category'
        verbose_name_plural = 'Categories'
        ordering = ['sort_order', 'name']

    def __str__(self):
        return self.name

    def delete(self, *args, **kwargs):
        with transaction.atomic():
            self.is_active = False
            self.save(update_fields=['is_active'])
            self.menus.all().update(is_active=False)
