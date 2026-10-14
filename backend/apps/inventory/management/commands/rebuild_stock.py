"""Qoldiq keshini (ProductStock) harakatlardan qayta hisoblash."""

from django.core.management.base import BaseCommand

from apps.inventory.services import rebuild_stock


class Command(BaseCommand):
    help = "Recompute ProductStock cache from StockMovement (source of truth)."

    def add_arguments(self, parser):
        parser.add_argument("--tenant", help="Only this tenant id")

    def handle(self, *args, tenant=None, **options):
        fixed = rebuild_stock(tenant)
        self.stdout.write(f"stock rows fixed: {fixed}")
