import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/app/sync/subscription_notice.dart';

void main() {
  // 15.10.2026 10:00 Toshkent.
  final now = DateTime.utc(2026, 10, 15, 5);

  SubscriptionNotice? notice(
    String status,
    int? daysLeft, {
    DateTime? pulledAt,
  }) => subscriptionNotice(
    subscription: {'status': status, 'days_left': daysLeft},
    pulledAt: pulledAt ?? now,
    now: now,
  );

  test('trial always shows days left', () {
    expect(
      notice('trial', 12),
      const SubscriptionNotice(SubscriptionNoticeKind.trial, 12),
    );
  });

  test('active warns only within 3 days', () {
    expect(notice('active', 10), isNull);
    expect(notice('active', 4), isNull);
    expect(
      notice('active', 3),
      const SubscriptionNotice(SubscriptionNoticeKind.expiring, 3),
    );
    expect(
      notice('active', 1),
      const SubscriptionNotice(SubscriptionNoticeKind.expiring, 1),
    );
  });

  test('grace shows days to pay', () {
    expect(
      notice('grace', 2),
      const SubscriptionNotice(SubscriptionNoticeKind.grace, 2),
    );
  });

  test('offline days are subtracted by store date', () {
    // Pull 13.10 kechqurun (Toshkent 23:30) — 2 kun o'tdi.
    final pulled = DateTime.utc(2026, 10, 13, 18, 30);
    expect(
      notice('active', 5, pulledAt: pulled),
      const SubscriptionNotice(SubscriptionNoticeKind.expiring, 3),
    );
    expect(
      notice('trial', 3, pulledAt: pulled),
      const SubscriptionNotice(SubscriptionNoticeKind.trial, 1),
    );
    // Muddat oflaynda tugadi — aniq kunlar noma'lum.
    expect(
      notice('active', 2, pulledAt: pulled),
      const SubscriptionNotice(SubscriptionNoticeKind.grace, null),
    );
    expect(
      notice('grace', 1, pulledAt: pulled),
      const SubscriptionNotice(SubscriptionNoticeKind.grace, null),
    );
  });

  test('readonly, blocked, unknown or missing — no warning here', () {
    expect(notice('readonly', null), isNull);
    expect(notice('blocked', null), isNull);
    expect(notice('active', null), isNull);
    expect(
      subscriptionNotice(subscription: null, pulledAt: now, now: now),
      isNull,
    );
  });

  test('support phone defaults to the support line (Q-008)', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(supportPhoneProvider), '+998 91 498 01 68');
  });
}
