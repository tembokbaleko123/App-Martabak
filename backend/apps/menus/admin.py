"""
Admin configuration untuk menus app.
"""
from django.contrib import admin
from .models import Menu


@admin.register(Menu)
class MenuAdmin(admin.ModelAdmin):
    list_display = ['name', 'price', 'category', 'emoji', 'is_active', 'sort_order']
    list_filter = ['category', 'is_active']
    search_fields = ['name']
    ordering = ['category', 'sort_order']
