import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/app/session/pin_gate.dart';
import 'package:pos_app/app/session/session.dart';
import 'package:pos_app/data/customers/customer_directory.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/features/refunds/refund_dialog.dart';
import 'package:pos_ui/pos_ui.dart';

import '../helpers/catalog_seed.dart';
import '../helpers/keyboard.dart';
import '../helpers/pump_app.dart';
import '../helpers/sqlite.dart';

String som(int amount) => PosFormat.money(amount * 100, currency: "so'm");

late AppDatabase _db;

final Override fakePin = pinGateProvider.overrideWith(
  (ref) => PinGate(
    ref.watch(appDatabaseProvider),
    verify: (pin, _) async => pin == '1234',
  ),
);

const StaffUser manager = StaffUser(
  id: 'manager-1',
  fullName: 'Bobur',
  role: 'manager',
  isActive: true,
  pinHash: 'hash',
);

Future<void> open(WidgetTester tester, {Session? session}) async {
  _db = openTestDatabase();
  addTearDown(_db.close);
  await seedCatalog(_db);
  await _db.into(_db.staffUsers).insert(manager);
  await _db
      .into(_db.customers)
      .insert(CustomersCompanion.insert(id: 'c1', fullName: 'Karimova'));
  await pumpPosApp(
    tester,
    db: _db,
    overrides: [fakePin],
    session: session ?? unlockedSession,
  );
}

Finder get dialog => find.byType(RefundDialog);

Finder inDialog(String text) =>
    find.descendant(of: dialog, matching: find.text(text));

/// 2 × Non issiq (4 000) — naqd.
Future<void> sellTwoBreads(WidgetTester tester) async {
  await scanCode(tester, '4780000000014');
  await scanCode(tester, '4780000000014');
  await press(tester, LogicalKeyboardKey.f12);
  await press(tester, LogicalKeyboardKey.enter);
}

Future<void> tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> approve(WidgetTester tester) async {
  expect(find.text('Tasdiqlash kerak'), findsOneWidget);
  await tester.tap(find.text('Bobur'));
  await tester.pumpAndSettle();
  await typeSlowly(tester, '1234');
  await press(tester, LogicalKeyboardKey.enter);
}

Future<int> stock(String productId) async {
  final rows = await (_db.select(
    _db.stockMovements,
  )..where((m) => m.productId.equals(productId))).get();
  return rows.fold<int>(0, (s, m) => s + m.qtyMilli);
}

void main() {
  testWidgets('partial refund from the recent list, manager PIN', (
    tester,
  ) async {
    await open(tester);
    await sellTwoBreads(tester);
    await press(tester, LogicalKeyboardKey.f8);
    expect(dialog, findsOneWidget);
    await tap(tester, inDialog('D3-000001'));
    expect(inDialog('Non issiq'), findsOneWidget);

    await tap(
      tester,
      find.descendant(of: dialog, matching: find.byTooltip("Ko'paytirish")),
    );
    expect(inDialog(som(4000)), findsOneWidget);
    await tap(tester, find.byKey(const ValueKey('refund-reason-defective')));
    await press(tester, LogicalKeyboardKey.enter);
    await approve(tester);

    expect(dialog, findsNothing);
    expect(
      find.text('Qaytarildi · Mijozga ${som(4000)} bering'),
      findsOneWidget,
    );
    final refund = (await _db.select(_db.refunds).get()).single;
    expect(refund.totalTiyin, 400000);
    expect(refund.method, 'cash');
    expect(refund.reason, 'Sifatsiz');
    expect(refund.approvedBy, 'manager-1');
    expect(await stock('p-non'), -1000);
    final sale = (await _db.select(_db.sales).get()).single;
    expect(sale.status, 'partially_refunded');
  });

  testWidgets('find by typed number; whole check; other reason', (
    tester,
  ) async {
    await open(tester);
    await sellTwoBreads(tester);
    await press(tester, LogicalKeyboardKey.f8);
    await tester.enterText(
      find.byKey(const ValueKey('refund-number')),
      'd3-000001',
    );
    await tap(tester, inDialog('Topish'));
    await tap(tester, find.byKey(const ValueKey('refund-all')));
    expect(inDialog(som(8000)), findsOneWidget);
    await tester.enterText(
      find.descendant(of: dialog, matching: find.byType(TextField)),
      'Eskirgan',
    );
    await tap(tester, find.byKey(const ValueKey('refund-confirm')));
    await approve(tester);

    final refund = (await _db.select(_db.refunds).get()).single;
    expect(refund.totalTiyin, 800000);
    expect(refund.reason, 'Eskirgan');
    expect((await _db.select(_db.sales).get()).single.status, 'refunded');
    expect(await stock('p-non'), 0);

    // Qayta ochilsa — to'liq qaytarilgan.
    await press(tester, LogicalKeyboardKey.f8);
    expect(
      find.descendant(
        of: dialog,
        matching: find.textContaining('· Qaytarilgan'),
      ),
      findsOneWidget,
    );
    await tap(tester, inDialog('D3-000001'));
    expect(inDialog("Bu chek to'liq qaytarilgan"), findsOneWidget);
    expect(find.byKey(const ValueKey('refund-confirm')), findsNothing);
  });

  testWidgets('scanning the receipt barcode opens the sale', (tester) async {
    await open(tester);
    await sellTwoBreads(tester);
    await press(tester, LogicalKeyboardKey.f8);
    await scanCode(tester, 'd3-000001');
    expect(find.text('Qaytarish · D3-000001'), findsOneWidget);
    // Skaner Enter'i qaytarishni boshlamagan.
    expect(find.text('Tasdiqlash kerak'), findsNothing);
    expect(inDialog('Qaytariladigan tovarni tanlang'), findsNothing);

    await scanCode(tester, 'd3-000099');
    expect(inDialog('Bunday chek topilmadi'), findsOneWidget);
  });

  testWidgets('nothing chosen / no reason → refund is not saved', (
    tester,
  ) async {
    await open(tester);
    await sellTwoBreads(tester);
    await press(tester, LogicalKeyboardKey.f8);
    await tap(tester, inDialog('D3-000001'));
    await press(tester, LogicalKeyboardKey.enter);
    expect(inDialog('Qaytariladigan tovarni tanlang'), findsOneWidget);
    await tap(tester, find.byKey(const ValueKey('refund-all')));
    await press(tester, LogicalKeyboardKey.enter);
    expect(inDialog('Sababni tanlang'), findsOneWidget);
    expect(find.text('Tasdiqlash kerak'), findsNothing);
    expect(await _db.select(_db.refunds).get(), isEmpty);
  });

  testWidgets('debt sale: refund lowers the debt', (tester) async {
    await open(tester);
    await scanCode(tester, '4780000000014');
    await press(tester, LogicalKeyboardKey.f12);
    await tester.tap(find.byKey(const ValueKey('pay-mode-debt')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Karimova').last);
    await tester.pumpAndSettle();
    await press(tester, LogicalKeyboardKey.enter);
    expect((await CustomerDirectory(_db).byId('c1'))!.balanceTiyin, 400000);

    await press(tester, LogicalKeyboardKey.f8);
    await tap(tester, inDialog('D3-000001'));
    await tap(tester, find.byKey(const ValueKey('refund-all')));
    await tap(tester, find.byKey(const ValueKey('refund-method-debt')));
    await tap(tester, find.byKey(const ValueKey('refund-reason-mistake')));
    await tap(tester, find.byKey(const ValueKey('refund-confirm')));
    await approve(tester);

    expect(
      find.text('Qaytarildi · Qarzdan ${som(4000)} ayirildi'),
      findsOneWidget,
    );
    expect((await CustomerDirectory(_db).byId('c1'))!.balanceTiyin, 0);
    expect((await _db.select(_db.refunds).get()).single.method, 'debt');
  });

  testWidgets('a manager refunds without a second PIN', (tester) async {
    await open(
      tester,
      session: const Session(
        stage: SessionStage.unlocked,
        device: testDevice,
        user: manager,
      ),
    );
    await sellTwoBreads(tester);
    await press(tester, LogicalKeyboardKey.f8);
    await tap(tester, inDialog('D3-000001'));
    await tap(tester, find.byKey(const ValueKey('refund-all')));
    await tap(tester, find.byKey(const ValueKey('refund-reason-expired')));
    await press(tester, LogicalKeyboardKey.enter);
    expect(find.text('Tasdiqlash kerak'), findsNothing);
    final refund = (await _db.select(_db.refunds).get()).single;
    expect(refund.approvedBy, 'manager-1');
    expect(refund.cashierId, 'manager-1');
  });

  testWidgets('phone: refund button opens the dialog', (tester) async {
    _db = openTestDatabase();
    addTearDown(_db.close);
    await seedCatalog(_db);
    await pumpPosApp(tester, db: _db, size: const Size(390, 844));
    await tester.tap(find.byKey(const ValueKey('pos-refund')));
    await tester.pumpAndSettle();
    expect(dialog, findsOneWidget);
    expect(inDialog("Hali savdo yo'q"), findsOneWidget);
  });
}
