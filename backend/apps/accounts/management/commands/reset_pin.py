"""
Management command untuk reset PIN kasir.
"""
from django.core.management.base import BaseCommand
import bcrypt
from apps.accounts.models import Kasir


class Command(BaseCommand):
    help = 'Reset PIN kasir. Default PIN setelah reset: 1234'

    def add_arguments(self, parser):
        parser.add_argument('username', type=str, help='Username kasir')
        parser.add_argument('--pin', type=str, default='1234', help='PIN baru (default: 1234)')

    def handle(self, *args, **options):
        username = options['username']
        new_pin = options['pin']

        try:
            kasir = Kasir.objects.get(username=username)
        except Kasir.DoesNotExist:
            self.stderr.write(self.style.ERROR(f'Kasir "{username}" tidak ditemukan'))
            return

        pin_hash = bcrypt.hashpw(new_pin.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
        kasir.pin_hash = pin_hash
        kasir.save()

        self.stdout.write(self.style.SUCCESS(f'PIN {username} direset ke: {new_pin}'))
