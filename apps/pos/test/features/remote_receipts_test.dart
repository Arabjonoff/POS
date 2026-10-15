import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/app/session/session.dart';
import 'package:pos_app/app/status/app_status.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/data/remote/api.dart';
import 'package:pos_app/data/sync/outbox.dart';
import 'package:pos_app/features/printing/escpos.dart';
import 'package:pos_app/features/printing/printer_service.dart';
import 'package:pos_app/features/printing/printer_settings.dart';
import 'package:pos_app/features/refunds/refund_dialog.dart';
import 'package:pos_ui/pos_ui.dart';

import '../helpers/catalog_seed.dart';
import '../helpers/fake_printer.dart';
import '../helpers/fake_server.dart';
import '../helpers/keyboard.dart';
import '../helpers/pump_app.dart';
import '../helpers/remote_sale_fixture.dart';
import '../helpers/sale_history_seed.dart';
import '../helpers/sqlite.dart';

late AppDatabase _db;
late FakeTransport printer;
late FakeServer server;

/// Server javobi: `null` — internet yo'q.
(int, Object?)? Function() reply = () => (200, remoteSaleJson());

const StaffUser manager = StaffUser(
  id: 'manager-1',
  fullName: 'Bobur',
  role: 'manager',
  isActive: true,
  pinHash: 'hash',
);

Finder get dialog => find.byType(RefundDialog);

Future<void> open(WidgetTester tester, {bool sales = true}) async {
  reply = () => (200, remoteSaleJson());
  _db = openTestDatabase();
  addTearDown(_db.close);
  await seedCatalog(_db);
  await _db.into(_db.staffUsers).insert(manager);
  await _db
      .into(_db.stores)
      .insert(StoresCompanion.insert(id: 'store-1', name: 'Baraka market'));
  await _db.writeSetting(
    PrinterSettings.settingKey,
    jsonEncode(
      const PrinterSettings(
        connection: PrinterConnection.network,
        address: '192.168.1.50',
      ).toJson(),
    ),
  );
  printer = FakeTransport();
  server = FakeServer()..on('GET /api/v1/sync/sales/', (_) => reply());
  await pumpPosApp(
    tester,
    db: _db,
    session: const Session(
      stage: SessionStage.unlocked,
      device: testDevice,
      user: manager,
    ),
    tokens: MemoryDeviceTokenStore('dev_token'),
    overrides: [
      clockProvider.overrideWithValue(() => historyNow),
      dioFactoryProvider.overrideWithValue(server.dio),
      printerTransportFactoryProvider.overrideWithValue(
        (s) => s.configured ? printer : null,
      ),
    ],
  );
  if (sales) await tapNav(tester, 'Cheklar');
}

Future<void> tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('scanning another kassa receipt opens it from the server', (
    tester,
  ) async {
    await open(tester);
    await scanCode(tester, 'd2-000007');
    expect(find.text('2-kassa cheki'), findsOneWidget);
    expect(find.text('Qisman qaytarilgan'), findsOneWidget);
    expect(find.textContaining('Yaroqsiz'), findsOneWidget);
    expect(find.byKey(const ValueKey('sale-receipt-preview')), findsOneWidget);

    await tap(tester, find.byKey(const ValueKey('sale-reprint')));
    final job = printer.jobs.single;
    for (final text in ['D2-000007', 'NUSXA', 'Dilshod']) {
      expect(
        containsBytes(job, EscPos.encode(text, PrinterEncoding.cp866)),
        isTrue,
        reason: text,
      );
    }
  });

  testWidgets('refunding the rest writes a local refund for the server sale', (
    tester,
  ) async {
    await open(tester);
    await scanCode(tester, 'd2-000007');
    await tap(tester, find.byKey(const ValueKey('sale-refund')));
    expect(
      find.descendant(of: dialog, matching: find.text('Qaytarish · D2-000007')),
      findsOneWidget,
    );
    await tap(tester, find.byKey(const ValueKey('refund-all')));
    await tap(tester, find.byKey(const ValueKey('refund-reason-defective')));
    await tap(tester, find.byKey(const ValueKey('refund-confirm')));
    expect(dialog, findsNothing);

    final refund = (await _db.select(_db.refunds).get()).single;
    expect(refund.saleId, remoteSaleId);
    expect(refund.totalTiyin, 800000);
    final item = (await _db.select(_db.refundItems).get()).single;
    expect((item.saleItemId, item.qtyMilli), (remoteItemId, 2000));
    final event = (await _db.select(_db.outboxEvents).get()).single;
    expect(event.type, OutboxEventType.refundCreated);
    expect((jsonDecode(event.payload) as Map)['sale'], remoteSaleId);
    // Server hali eski holatni beradi, lokal qaytarish qo'shiladi.
    expect(find.text('Qaytarilgan'), findsOneWidget);
    final again = tester.widget<PosButton>(
      find.byKey(const ValueKey('sale-refund')),
    );
    expect(again.onPressed, isNull);
  });

  testWidgets('typed number: "search other kassas" button', (tester) async {
    await open(tester);
    await tester.enterText(
      find.byKey(const ValueKey('sales-search')),
      'D2-000007',
    );
    await tester.pumpAndSettle();
    await tap(tester, find.byKey(const ValueKey('sales-search-server')));
    expect(find.text('2-kassa cheki'), findsOneWidget);
  });

  testWidgets('offline or unknown: clear messages', (tester) async {
    await open(tester);
    reply = () => null;
    await scanCode(tester, 'd2-000007');
    expect(
      find.text(
        "Bu chek shu kassada yo'q. Boshqa kassa chekini ko'rish uchun "
        'internet kerak',
      ),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    reply = () => (404, {'detail': 'Not found.'});
    await scanCode(tester, 'd2-000099');
    expect(find.text('Chek topilmadi: D2-000099'), findsOneWidget);
    expect(find.text('2-kassa cheki'), findsNothing);
  });

  testWidgets('F8 refund dialog finds another kassa receipt', (tester) async {
    await open(tester, sales: false);
    await press(tester, LogicalKeyboardKey.f8);
    await tester.enterText(
      find.byKey(const ValueKey('refund-number')),
      'd2-000007',
    );
    await tap(
      tester,
      find.descendant(of: dialog, matching: find.text('Topish')),
    );
    expect(
      find.descendant(of: dialog, matching: find.text('Non issiq')),
      findsOneWidget,
    );

    reply = () => null;
    await tap(
      tester,
      find.descendant(of: dialog, matching: find.text('Boshqa chek')),
    );
    await tester.enterText(
      find.byKey(const ValueKey('refund-number')),
      'd2-000007',
    );
    await tap(
      tester,
      find.descendant(of: dialog, matching: find.text('Topish')),
    );
    expect(
      find.descendant(
        of: dialog,
        matching: find.textContaining('internet kerak'),
      ),
      findsOneWidget,
    );
  });
}
