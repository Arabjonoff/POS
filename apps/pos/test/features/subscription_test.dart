import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/app/status/app_status.dart';
import 'package:pos_app/app/sync/subscription_notice.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/features/pos/payment/payment_dialog.dart';
import 'package:pos_ui/pos_ui.dart';

import '../helpers/catalog_seed.dart';
import '../helpers/keyboard.dart';
import '../helpers/pump_app.dart';
import '../helpers/sqlite.dart';

// 15.10.2026 10:00 Toshkent.
final DateTime now = DateTime.utc(2026, 10, 15, 5);

Finder get banner => find.byKey(const ValueKey('subscription-banner'));
Finder get blockBanner => find.byKey(const ValueKey('sales-block-banner'));

/// Oxirgi pull'dagi obuna holati bilan ilovani ochadi.
Future<AppDatabase> open(
  WidgetTester tester, {
  required String status,
  int? daysLeft,
  DateTime? pulledAt,
  DateTime? offlineGraceUntil,
  String phone = '',
}) async {
  final db = openTestDatabase();
  addTearDown(db.close);
  await seedCatalog(db);
  await db
      .into(db.syncState)
      .insert(
        SyncStateCompanion.insert(
          subscriptionJson: Value(
            jsonEncode({
              'status': status,
              'paid_until': null,
              'days_left': daysLeft,
              'offline_days': 7,
            }),
          ),
          lastPullAt: Value(pulledAt ?? now),
          offlineGraceUntil: Value(
            offlineGraceUntil ?? now.add(const Duration(days: 7)),
          ),
        ),
      );
  await pumpPosApp(
    tester,
    db: db,
    overrides: <Override>[
      clockProvider.overrideWithValue(() => now),
      supportPhoneProvider.overrideWithValue(phone),
    ],
  );
  return db;
}

Future<void> expectPayWorks(WidgetTester tester, {required bool works}) async {
  await scanCode(tester, '4780000000014');
  await press(tester, LogicalKeyboardKey.f12);
  expect(find.byType(PaymentDialog), works ? findsOneWidget : findsNothing);
}

void main() {
  testWidgets('trial: blue banner with days left; selling works', (
    tester,
  ) async {
    await open(tester, status: 'trial', daysLeft: 12);
    expect(
      find.descendant(
        of: banner,
        matching: find.text('Sinov davri: yana 12 kun'),
      ),
      findsOneWidget,
    );
    expect(blockBanner, findsNothing);
    // Bir qator, 28 dp — kassa ekraniga joy qolsin.
    expect(tester.getSize(banner).height, PosSizes.noticeBarHeight);
    await expectPayWorks(tester, works: true);
  });

  testWidgets('trial banner can be closed; payment warnings cannot', (
    tester,
  ) async {
    await open(tester, status: 'trial', daysLeft: 12);
    final close = find.byKey(const ValueKey('notice-close'));
    expect(tester.getSize(close).width, PosSizes.touchMin);
    await tester.tap(close);
    await tester.pumpAndSettle();
    expect(banner, findsNothing);
  });

  testWidgets('expiring banner has no close button', (tester) async {
    await open(tester, status: 'active', daysLeft: 2);
    expect(banner, findsOneWidget);
    expect(find.byKey(const ValueKey('notice-close')), findsNothing);
  });

  testWidgets('active, 2 days left: yellow warning with the contact', (
    tester,
  ) async {
    await open(
      tester,
      status: 'active',
      daysLeft: 2,
      phone: '+998 71 200 00 00',
    );
    expect(
      find.text("Obunaga 2 kun qoldi — to'lovni unutmang"),
      findsOneWidget,
    );
    expect(find.text('Aloqa: +998 71 200 00 00'), findsOneWidget);
    await expectPayWorks(tester, works: true);
  });

  testWidgets('active with plenty of days: no banner', (tester) async {
    await open(tester, status: 'active', daysLeft: 20);
    expect(banner, findsNothing);
    expect(blockBanner, findsNothing);
  });

  testWidgets('offline days count down from the last pull', (tester) async {
    // Pull 4 kun oldin: 6 kun qolgan edi → endi 2.
    await open(
      tester,
      status: 'active',
      daysLeft: 6,
      pulledAt: now.subtract(const Duration(days: 4)),
    );
    expect(
      find.text("Obunaga 2 kun qoldi — to'lovni unutmang"),
      findsOneWidget,
    );
  });

  testWidgets('grace: red banner, still selling', (tester) async {
    await open(tester, status: 'grace', daysLeft: 2);
    expect(
      find.text(
        "To'lov muddati o'tdi — 2 kun ichida to'lang, aks holda savdo to'xtaydi",
      ),
      findsOneWidget,
    );
    expect(find.text("Administrator bilan bog'laning"), findsOneWidget);
    await expectPayWorks(tester, works: true);
  });

  testWidgets('readonly: pay off, clear reason, what still works, contact', (
    tester,
  ) async {
    await open(tester, status: 'readonly', phone: '+998 71 200 00 00');
    expect(banner, findsNothing);
    expect(
      find.descendant(
        of: blockBanner,
        matching: find.text("Obuna muddati tugagan — savdo to'xtatilgan"),
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        "Ko'rish, hisobotlar va sinxron ishlaydi. "
        "Savdoni tiklash uchun obunani to'lang.",
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: blockBanner,
        matching: find.text('Aloqa: +998 71 200 00 00'),
      ),
      findsOneWidget,
    );
    await expectPayWorks(tester, works: false);
  });

  testWidgets('blocked: reason and contact; pay off', (tester) async {
    await open(tester, status: 'blocked');
    expect(
      find.descendant(
        of: blockBanner,
        matching: find.text("Do'kon bloklangan — savdo to'xtatilgan"),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: blockBanner,
        matching: find.text("Administrator bilan bog'laning"),
      ),
      findsOneWidget,
    );
    await expectPayWorks(tester, works: false);
  });

  testWidgets('offline longer than offline_days: connect to sync, pay off', (
    tester,
  ) async {
    await open(
      tester,
      status: 'active',
      daysLeft: 20,
      offlineGraceUntil: now.subtract(const Duration(hours: 1)),
    );
    expect(
      find.descendant(
        of: blockBanner,
        matching: find.text(
          'Internetga ulaning — sinxrondan keyin savdo davom etadi. '
          "Hamma ma'lumot saqlangan.",
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: blockBanner,
        matching: find.text("Administrator bilan bog'laning"),
      ),
      findsNothing,
    );
    await expectPayWorks(tester, works: false);
  });

  testWidgets('readonly also stops posting a stock receipt', (tester) async {
    await open(tester, status: 'readonly');
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('receiving-new')));
    await tester.pumpAndSettle();
    expect(
      find.text(
        "Hozir tasdiqlab bo'lmaydi: "
        "Obuna muddati tugagan — savdo to'xtatilgan",
      ),
      findsOneWidget,
    );
    final post = tester.widget<PosButton>(
      find.byKey(const ValueKey('receipt-post')),
    );
    expect(post.onPressed, isNull);
  });
}
