"""
Management command untuk seed data awal.
"""
import bcrypt
from django.core.management.base import BaseCommand
from apps.accounts.models import Kasir
from apps.menus.models import Menu
from apps.settings_app.models import Settings


class Command(BaseCommand):
    help = 'Seed data awal: owner, kasir, dan menu'

    def handle(self, *args, **options):
        self.stdout.write('Memulai seed data...')

        # Seed Owner
        owner, created = Kasir.objects.get_or_create(
            username='owner',
            defaults={
                'pin_hash': bcrypt.hashpw('000000'.encode('utf-8'), bcrypt.gensalt()).decode('utf-8'),
                'role': 'owner',
                'is_active': True,
                'email': 'owner@martabak.local',
                'first_name': 'Pak',
                'last_name': 'Hartono',
            }
        )
        if created:
            self.stdout.write(self.style.SUCCESS(f'Owner created: {owner.username}'))
        else:
            self.stdout.write(f'Owner already exists: {owner.username}')

        # Seed Kasir
        kasir_data = [
            {'username': 'Budi', 'pin': '1234'},
            {'username': 'Andi', 'pin': '1234'},
        ]

        for data in kasir_data:
            kasir, created = Kasir.objects.get_or_create(
                username=data['username'],
                defaults={
                    'pin_hash': bcrypt.hashpw(data['pin'].encode('utf-8'), bcrypt.gensalt()).decode('utf-8'),
                    'role': 'kasir',
                    'is_active': True,
                }
            )
            if created:
                self.stdout.write(self.style.SUCCESS(f'Kasir created: {kasir.username}'))
            else:
                self.stdout.write(f'Kasir already exists: {kasir.username}')

        # Seed Menu
        menu_data = [
            # Manis (5)
            {'name': 'Martabak Manis Coklat', 'price': 25000, 'category': 'manis', 'emoji': '🥞', 'sort_order': 1},
            {'name': 'Martabak Manis Coklat Keju', 'price': 30000, 'category': 'manis', 'emoji': '🥞', 'sort_order': 2},
            {'name': 'Martabak Manis Keju', 'price': 28000, 'category': 'manis', 'emoji': '🥞', 'sort_order': 3},
            {'name': 'Martabak Manis Susu', 'price': 22000, 'category': 'manis', 'emoji': '🥞', 'sort_order': 4},
            {'name': 'Martabak Manis Kacang', 'price': 20000, 'category': 'manis', 'emoji': '🥞', 'sort_order': 5},
            # Telur (3)
            {'name': 'Martabak Telur Biasa', 'price': 20000, 'category': 'telur', 'emoji': '🥚', 'sort_order': 6},
            {'name': 'Martabak Telur Spesial', 'price': 25000, 'category': 'telur', 'emoji': '🥚', 'sort_order': 7},
            {'name': 'Martabak Telur Keju', 'price': 30000, 'category': 'telur', 'emoji': '🥚', 'sort_order': 8},
            # Tipis (2)
            {'name': 'Martabak Tipis Biasa', 'price': 15000, 'category': 'tipis', 'emoji': '🥙', 'sort_order': 9},
            {'name': 'Martabak Tipis Spesial', 'price': 20000, 'category': 'tipis', 'emoji': '🥙', 'sort_order': 10},
        ]

        for data in menu_data:
            menu, created = Menu.objects.get_or_create(
                name=data['name'],
                defaults={
                    'price': data['price'],
                    'category': data['category'],
                    'emoji': data['emoji'],
                    'sort_order': data['sort_order'],
                    'is_active': True,
                }
            )
            if created:
                self.stdout.write(self.style.SUCCESS(f'Menu created: {menu.name}'))
            else:
                self.stdout.write(f'Menu already exists: {menu.name}')

        # Seed Settings
        settings, created = Settings.objects.get_or_create(
            id=1,
            defaults={
                'goqris_project_name': 'Martabak Pak Joko',
            }
        )
        if created:
            self.stdout.write(self.style.SUCCESS('Settings created'))
        else:
            self.stdout.write('Settings already exists')

        self.stdout.write(self.style.SUCCESS('Seed data selesai!'))
