import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/widgets.dart' show Size;
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/app/status/app_status.dart';
import 'package:pos_app/app/sync/subscription_notice.dart';
import 'package:pos_app/data/db/app_database.dart';

import '../helpers/catalog_seed.dart';
import '../helpers/keyboard.dart';
import '../helpers/pump_app.dart';
import '../helpers/sqlite.dart';
import 'golden_helpers.dart';

Future<void> _open(
  WidgetTester tester,
  Size size, {
  required String status,
  int? daysLeft,
}) async {
  final now = DateTime.utc(2026, 10, 15, 5);
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
          lastPullAt: Value(now),
          offlineGraceUntil: Value(now.add(const Duration(days: 7))),
        ),
      );
  await pumpPosApp(
    tester,
    size: size,
    db: db,
    overrides: [
      connectionStatusProvider.overrideWithValue(ConnectionStatus.online),
      printerStatusProvider.overrideWithValue(PrinterStatus.ready),
      pendingEventsProvider.overrideWith((ref) => Stream.value(0)),
      clockProvider.overrideWithValue(() => now),
      supportPhoneProvider.overrideWithValue('+998 71 200 00 00'),
    ],
  );
  await scanCode(tester, '4780000000014');
  await tester.pumpAndSettle();
}

void main() {
  goldenAcrossDevices(
    'subscription',
    'grace',
    (tester, size) => _open(tester, size, status: 'grace', daysLeft: 2),
  );
  goldenAcrossDevices(
    'subscription',
    'readonly',
    (tester, size) => _open(tester, size, status: 'readonly'),
  );
}
