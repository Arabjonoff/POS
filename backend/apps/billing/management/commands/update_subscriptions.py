"""Kunlik: obuna holati keshini yangilash (cron: har kuni 00:05 Asia/Tashkent)."""

from collections import Counter

from django.core.management.base import BaseCommand

from apps.billing.models import Subscription
from apps.billing.services import refresh_status


class Command(BaseCommand):
    help = "Recompute cached subscription statuses (trial/active/grace/readonly/blocked)."

    def handle(self, *args, **options):
        changed = Counter()
        total = 0
        for sub in Subscription.objects.select_related("tenant").iterator(chunk_size=500):
            total += 1
            before = sub.status
            if refresh_status(sub):
                changed[f"{before}->{sub.status}"] += 1
        summary = ", ".join(f"{k}: {v}" for k, v in sorted(changed.items())) or "no changes"
        self.stdout.write(f"subscriptions: {total}, changed: {sum(changed.values())} ({summary})")
