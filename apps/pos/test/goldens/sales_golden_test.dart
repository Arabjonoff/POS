import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/app/status/app_status.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/features/printing/printer_service.dart';
import 'package:pos_app/features/printing/printer_settings.dart';
import 'package:pos_app/features/printing/receipt.dart';

import '../helpers/catalog_seed.dart';
import '../helpers/fake_printer.dart';
import '../helpers/pump_app.dart';
import '../helpers/sale_history_seed.dart';
import '../helpers/sqlite.dart';
import 'golden_helpers.dart';

Future<void> _open(WidgetTester tester, Size size) async {
  final db = openTestDatabase();
  addTearDown(db.close);
  await seedCatalog(db);
  await seedSaleHistory(db);
  await db
      .into(db.stores)
      .insert(StoresCompanion.insert(id: 'store-1', name: 'Baraka market'));
  await db.writeSetting(
    PrinterSettings.settingKey,
    jsonEncode(
      const PrinterSettings(
        connection: PrinterConnection.network,
        address: '192.168.1.50',
        width: PaperWidth.mm80,
      ).toJson(),
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
      clockProvider.overrideWithValue(() => historyNow),
      printerTransportFactoryProvider.overrideWithValue(
        (_) => FakeTransport(),
      ),
    ],
  );
  await tapNav(tester, 'Cheklar');
}

/// Cheklar tarixi (T-109): bugungi ro'yxat va tanlangan chek (qisman
/// qaytarilgan, karta + nasiya).
void main() {
  goldenAcrossDevices('sales', 'list', (tester, size) async {
    await _open(tester, size);
  });

  goldenAcrossDevices('sales', 'detail', (tester, size) async {
    await _open(tester, size);
    await tester.tap(find.byKey(const ValueKey('sale-D3-000002')));
    await tester.pumpAndSettle();
  });
}
