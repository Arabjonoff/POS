import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/app/session/pin_gate.dart';
import 'package:pos_app/app/session/session.dart';
import 'package:pos_app/data/catalog/product_editor.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_ui/pos_ui.dart';

import '../helpers/catalog_seed.dart';
import '../helpers/keyboard.dart';
import '../helpers/pump_app.dart';
import '../helpers/sqlite.dart';

late AppDatabase _db;

const StaffUser manager = StaffUser(
  id: 'manager-1',
  fullName: 'Bobur',
  role: 'manager',
  isActive: true,
  pinHash: 'hash',
);

Future<void> open(WidgetTester tester, {bool asManager = false}) async {
  _db = openTestDatabase();
  addTearDown(_db.close);
  await seedCatalog(_db);
  await _db.into(_db.staffUsers).insert(manager);
  for (final (id, qty) in const [('p-sut', 5000), ('p-tuxum', 30000)]) {
    await _db
        .into(_db.productStock)
        .insert(
          ProductStockCompanion.insert(
            productId: id,
            storeId: 'store-1',
            qtyMilli: qty,
            updatedAt: DateTime.utc(2026, 10, 15),
          ),
        );
  }
  await pumpPosApp(
    tester,
    db: _db,
    session: asManager
        ? const Session(
            stage: SessionStage.unlocked,
            device: testDevice,
            user: manager,
          )
        : unlockedSession,
    overrides: <Override>[
      pinGateProvider.overrideWith(
        (ref) => PinGate(
          ref.watch(appDatabaseProvider),
          verify: (pin, _) async => pin == '1234',
        ),
      ),
    ],
  );
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pumpAndSettle();
  await tap(tester, find.byKey(const ValueKey('products-inventory')));
}

Future<void> tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> newCount(WidgetTester tester, String scopeKey) async {
  await tap(tester, find.byKey(const ValueKey('inventory-new')));
  await tap(tester, find.byKey(ValueKey(scopeKey)));
}

String qty(int milli) => PosFormat.qtyWithUnit(milli, unit: 'dona');

Future<Map<String, int>> stock() async =>
    Map.fromEntries(await stockQuery(_db).get());

void main() {
  testWidgets('scan to count, diff report, post → stock = counted', (
    tester,
  ) async {
    await open(tester, asManager: true);
    expect(find.text("Hali inventarizatsiya yo'q"), findsOneWidget);
    await newCount(tester, 'scope-c-milk');
    // Sut (tizimda 5) — 3 ta skan; tuxum — sanalmagan.
    for (var i = 0; i < 3; i++) {
      await scanCode(tester, '4600000000015');
    }
    expect(
      find.text('Sanalgan: 1 · Sanalmagan: 1 · Ortiqcha: 0 · Kam: 1'),
      findsOneWidget,
    );
    expect(find.text('Farq: ${qty(-2000)}'), findsOneWidget);

    // Sanalmaganlardan tuxumni qo'shib, 32 deb yozamiz.
    await tap(tester, find.byKey(const ValueKey('count-uncounted')));
    await tap(tester, find.byKey(const ValueKey('uncounted-p-tuxum')));
    await tester.enterText(
      find.byKey(const ValueKey('counted-p-tuxum')),
      '32',
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Sanalgan: 2 · Sanalmagan: 0 · Ortiqcha: 1 · Kam: 1'),
      findsOneWidget,
    );

    await tap(tester, find.byKey(const ValueKey('count-post')));
    expect(find.text('Tasdiqlash kerak'), findsNothing);
    expect(
      find.text(
        'Inventarizatsiya tasdiqlandi: qoldiq sanalgan songa tenglashdi',
      ),
      findsOneWidget,
    );
    final s = await stock();
    expect((s['p-sut'], s['p-tuxum']), (3000, 32000));
    // Sanalmagan (boshqa kategoriya) — o'zgarmagan.
    expect(s['p-non'], 0);
    // Tasdiqlangan — faqat o'qish, farq ko'rinadi.
    expect(find.byKey(const ValueKey('count-post')), findsNothing);
    expect(find.text('Farq: +${qty(2000)}'), findsOneWidget);
  });

  testWidgets('unknown code warns; cashier posts with a PIN', (tester) async {
    await open(tester);
    await newCount(tester, 'scope-all');
    await scanCode(tester, '4780000000038');
    expect(
      find.text("Bu kod bazada yo'q — avval tovar qo'shing"),
      findsOneWidget,
    );
    await scanCode(tester, '4780000000014');
    await tap(tester, find.byKey(const ValueKey('count-post')));
    expect(find.text('Tasdiqlash kerak'), findsOneWidget);
    await tester.tap(find.text('Bobur'));
    await tester.pumpAndSettle();
    await typeSlowly(tester, '1234');
    await press(tester, LogicalKeyboardKey.enter);
    expect((await stock())['p-non'], 1000);
    final count = (await _db.select(_db.inventoryCounts).get()).single;
    expect((count.status, count.postedBy), ('posted', 'manager-1'));
  });

  testWidgets('empty count is not posted; draft can be deleted', (
    tester,
  ) async {
    await open(tester, asManager: true);
    await newCount(tester, 'scope-all');
    await tap(tester, find.byKey(const ValueKey('count-post')));
    expect(find.text('Hech narsa sanalmagan'), findsOneWidget);
    await tap(tester, find.byKey(const ValueKey('count-delete')));
    // O'chirish tasdiq so'raydi (audit UI-P1-1).
    expect(find.text("Sanoqni o'chirasizmi?"), findsOneWidget);
    await tap(tester, find.byKey(const ValueKey('pos-confirm-ok')));
    expect(find.text("Hali inventarizatsiya yo'q"), findsOneWidget);
  });
}
