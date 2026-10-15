import 'package:flutter/material.dart' show ValueKey;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/app/status/app_status.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/data/receipts/receipt_store.dart';
import 'package:pos_app/data/sync/server_features.dart';

import '../helpers/catalog_seed.dart';
import '../helpers/pump_app.dart';
import '../helpers/sqlite.dart';
import 'golden_helpers.dart';

/// Tasdiqlangan kirim va qoralama (narx tannarxdan past qatori bilan).
/// [correction] — tasdiqlangan kirimning tuzatish qoralamasi ham (T-102).
Future<(AppDatabase, String, String)> _seed({bool correction = false}) async {
  final db = openTestDatabase();
  await seedCatalog(db);
  var minute = 0;
  final store = ReceiptStore(
    db,
    now: () => DateTime.utc(2026, 10, 15, 4, minute += 10),
  );
  final supplier = await store.createSupplier(name: 'Ulgurji Non', by: 'm');
  final posted = await store.create();
  await store.setSupplier(posted, supplier);
  await store.addProduct(posted, 'p-non', qtyMilli: 40000);
  await store.addProduct(posted, 'p-patir', qtyMilli: 20000);
  await store.post(posted, by: 'm');

  final draft = await store.create();
  await store.setSupplier(draft, supplier);
  await store.addProduct(draft, 'p-cola', qtyMilli: 12000);
  await store.addProduct(draft, 'p-olma', qtyMilli: 25500);
  await store.addProduct(draft, 'p-choy', qtyMilli: 6000);
  final doc = (await store.load(draft))!;
  await store.setCost(doc.lines[0].id, 1100000);
  await store.setCost(doc.lines[1].id, 1100000);
  await store.setCost(doc.lines[2].id, 2400000); // narxdan qimmat
  await db.writeSetting(
    serverFeaturesSettingKey,
    encodeFeatures([ServerFeature.receiptCorrections]),
  );
  var open = draft;
  if (correction) {
    open = await store.startCorrection(posted);
    final fix = (await store.load(open))!;
    await store.setQty(fix.lines.first.id, 36000);
  }
  return (db, open, posted);
}

Future<(String, String)> _open(
  WidgetTester tester,
  Size size, {
  bool correction = false,
}) async {
  final (db, draft, posted) = await _seed(correction: correction);
  addTearDown(db.close);
  await pumpPosApp(
    tester,
    size: size,
    db: db,
    overrides: [
      connectionStatusProvider.overrideWithValue(ConnectionStatus.online),
      printerStatusProvider.overrideWithValue(PrinterStatus.ready),
      pendingEventsProvider.overrideWith((ref) => Stream.value(0)),
      clockProvider.overrideWithValue(() => DateTime.utc(2026, 10, 15, 10)),
    ],
  );
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pumpAndSettle();
  final nav = find.text('Kirim');
  if (size.width < 600 && nav.evaluate().isNotEmpty) {
    await tester.tap(nav.last);
    await tester.pumpAndSettle();
  }
  return (draft, posted);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  goldenAcrossDevices('receiving', 'list', (tester, size) async {
    await _open(tester, size);
  });

  goldenAcrossDevices('receiving', 'editor', (tester, size) async {
    final (draft, _) = await _open(tester, size);
    await tester.tap(find.byKey(ValueKey('receipt-$draft')));
    await tester.pumpAndSettle();
  });

  // T-102: tasdiqlangan kirim — "Tahrirlash" va "Bekor qilish".
  goldenAcrossDevices('receiving', 'posted', (tester, size) async {
    final (_, posted) = await _open(tester, size);
    await _tap(tester, find.byKey(ValueKey('receipt-$posted')));
  });

  // T-102: tuzatish qoralamasi (banner) va saqlash oldidan tasdiqlash oynasi.
  goldenAcrossDevices('receiving', 'correction', (tester, size) async {
    final (draft, _) = await _open(tester, size, correction: true);
    await _tap(tester, find.byKey(ValueKey('receipt-$draft')));
  });

  goldenAcrossDevices('receiving', 'correction_confirm', (tester, size) async {
    final (draft, _) = await _open(tester, size, correction: true);
    await _tap(tester, find.byKey(ValueKey('receipt-$draft')));
    await _tap(tester, find.byKey(const ValueKey('receipt-post')));
  });
}
