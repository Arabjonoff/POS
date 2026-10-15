import 'dart:convert';

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/app/status/app_status.dart';
import 'package:pos_app/app/sync/sales_gate.dart';
import 'package:pos_app/core/time/store_time_zone.dart';

/// Obuna haqida ogohlantirish turi (`subscription-billing.md`, "Holatlar").
enum SubscriptionNoticeKind {
  /// Sinov davri — "Sinov: N kun qoldi".
  trial,

  /// To'langan muddat tugashiga ≤ 3 kun.
  expiring,

  /// Muddat o'tgan, imtiyozli kunlar — savdo hali ishlaydi.
  grace,
}

@immutable
class SubscriptionNotice {
  const SubscriptionNotice(this.kind, this.daysLeft);

  final SubscriptionNoticeKind kind;

  /// Joriy holat tugashiga qolgan kunlar (bugun ham kiradi); noma'lum —
  /// `null` (oflaynda muddat o'tib ketgan).
  final int? daysLeft;

  @override
  bool operator ==(Object other) =>
      other is SubscriptionNotice &&
      other.kind == kind &&
      other.daysLeft == daysLeft;

  @override
  int get hashCode => Object.hash(kind, daysLeft);

  @override
  String toString() => 'SubscriptionNotice($kind, $daysLeft)';
}

/// Shuncha kun qolganda faol obuna uchun ogohlantirish (serverdagi
/// `EXPIRY_WARNING_DAYS`).
const int expiryWarningDays = 3;

/// Oxirgi pull'dagi obuna holatidan hozirgi ogohlantirish.
///
/// `days_left` pull paytidagi qiymat; kassa oflayn tursa kunlar o'tadi —
/// do'kon sanasi (Toshkent) bo'yicha o'tgan kunlar ayiriladi. Sinov yoki
/// faol muddat oflaynda tugab qolsa — `grace` (kunlari noma'lum): aniq
/// holatni keyingi sinxron beradi.
SubscriptionNotice? subscriptionNotice({
  required Map<String, dynamic>? subscription,
  required DateTime? pulledAt,
  required DateTime now,
  StoreTimeZone zone = StoreTimeZone.tashkent,
}) {
  if (subscription == null) return null;
  final status = subscription['status'] as String?;
  final daysLeft = subscription['days_left'] as int?;
  if (daysLeft == null) return null;
  final elapsed = pulledAt == null
      ? 0
      : zone
            .today(now)
            .difference(zone.today(pulledAt))
            .inDays
            .clamp(0, 1 << 30);
  final left = daysLeft - elapsed;
  return switch (status) {
    'trial' when left > 0 => SubscriptionNotice(
      SubscriptionNoticeKind.trial,
      left,
    ),
    'active' when left > 0 && left <= expiryWarningDays => SubscriptionNotice(
      SubscriptionNoticeKind.expiring,
      left,
    ),
    'active' when left > expiryWarningDays => null,
    'grace' when left > 0 => SubscriptionNotice(
      SubscriptionNoticeKind.grace,
      left,
    ),
    'trial' || 'active' || 'grace' => const SubscriptionNotice(
      SubscriptionNoticeKind.grace,
      null,
    ),
    _ => null,
  };
}

final subscriptionNoticeProvider = Provider<SubscriptionNotice?>((ref) {
  // Savdo to'xtagan bo'lsa — o'sha sabab ko'rsatiladi, ogohlantirish emas.
  if (ref.watch(salesBlockProvider) != SalesBlock.none) return null;
  final state = ref.watch(syncStateProvider).value;
  final json = state?.subscriptionJson;
  if (state == null || json == null) return null;
  final now = ref
      .watch(clockProvider)()
      .add(Duration(milliseconds: state.serverTimeOffsetMs));
  return subscriptionNotice(
    subscription: jsonDecode(json) as Map<String, dynamic>,
    pulledAt: state.lastPullAt,
    now: now,
  );
});

/// To'lov va yordam uchun telefon (Q-008). Build paytida
/// `--dart-define=SUPPORT_PHONE=...` bilan almashtirish mumkin; bo'sh
/// berilsa ham standart raqam ishlatiladi.
const defaultSupportPhone = '+998 91 498 01 68';

final supportPhoneProvider = Provider<String>((ref) {
  const phone = String.fromEnvironment('SUPPORT_PHONE');
  return phone.isEmpty ? defaultSupportPhone : phone;
});
