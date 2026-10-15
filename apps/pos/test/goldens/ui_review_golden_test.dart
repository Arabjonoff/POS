import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/app/locale.dart';
import 'package:pos_app/app/session/session.dart';
import 'package:pos_app/app/status/app_status.dart';
import 'package:pos_app/data/db/app_database.dart';

import '../helpers/catalog_seed.dart';
import '../helpers/keyboard.dart';
import '../helpers/pump_app.dart';
import '../helpers/report_vectors.dart';
import '../helpers/sqlite.dart';
import 'golden_helpers.dart';

/// UI tekshiruvi (T-091): eng uzun til — rus tilida asosiy ekranlar.
const StaffUser _owner = StaffUser(
  id: 'owner-1',
  fullName: 'Dilshod Rahimov',
  role: 'owner',
  isActive: true,
);

Future<void> _open(WidgetTester tester, Size size) async {
  final db = await seedReportVectors(openTestDatabase());
  addTearDown(db.close);
  await seedCatalog(db);
  await pumpPosApp(
    tester,
    size: size,
    db: db,
    session: const Session(
      stage: SessionStage.unlocked,
      device: testDevice,
      user: _owner,
    ),
    overrides: [
      initialLocaleProvider.overrideWithValue(AppLocales.ru),
      connectionStatusProvider.overrideWithValue(ConnectionStatus.online),
      printerStatusProvider.overrideWithValue(PrinterStatus.ready),
      pendingEventsProvider.overrideWith((ref) => Stream.value(0)),
      clockProvider.overrideWithValue(() => DateTime.utc(2026, 10, 15, 10)),
    ],
  );
  await scanCode(tester, '4780000000014');
}

void main() {
  goldenAcrossDevices('ui_review', 'ru_pos', _open);

  goldenAcrossDevices('ui_review', 'ru_payment', (tester, size) async {
    await _open(tester, size);
    await press(tester, LogicalKeyboardKey.f12);
  });

  goldenAcrossDevices('ui_review', 'ru_reports', (tester, size) async {
    await _open(tester, size);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit5);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
  });
}
