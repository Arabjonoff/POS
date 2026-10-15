import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/app/session/pin_gate.dart';
import 'package:pos_app/app/session/session.dart';
import 'package:pos_app/data/catalog/product_editor.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/data/sync/server_features.dart';
import 'package:pos_app/features/products/product_card.dart';

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
  await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pumpAndSettle();
}

Future<void> tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> newReceipt(WidgetTester tester) =>
    tap(tester, find.byKey(const ValueKey('receiving-new')));

Future<List<(String, int)>> lines() async => [
  for (final i in await (_db.select(
    _db.stockReceiptItems,
  )..orderBy([(i) => OrderingTerm.asc(i.position)])).get())
    (i.productId, i.qtyMilli),
];

Future<Map<String, int>> stock() async =>
    Map.fromEntries(await stockQuery(_db).get());

void main() {
  testWidgets('100 scans in a row land in the right lines', (tester) async {
    await open(tester);
    expect(find.text("Hali kirim yo'q"), findsOneWidget);
    await newReceipt(tester);
    for (var i = 0; i < 100; i++) {
      await scanCode(tester, i.isEven ? '4780000000014' : '5449000000996');
    }
    expect(await lines(), [('p-non', 50000), ('p-cola', 50000)]);
    expect(find.text('Non issiq'), findsOneWidget);
  });

  testWidgets('unknown code → new product card → added to the receipt', (
    tester,
  ) async {
    await open(tester, asManager: true);
    await newReceipt(tester);
    await scanCode(tester, '4780000000045');
    expect(find.byType(ProductCard), findsOneWidget);
    expect(
      find.byKey(const ValueKey('product-barcode-4780000000045')),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const ValueKey('product-name')),
      'Qatiq 0,5 L',
    );
    await tester.enterText(find.byKey(const ValueKey('product-sell')), '9000');
    await tester.enterText(find.byKey(const ValueKey('product-cost')), '7000');
    await tap(tester, find.byKey(const ValueKey('product-save')));

    expect(find.byType(ProductCard), findsNothing);
    expect(find.text('Qatiq 0,5 L'), findsOneWidget);
    final added = await lines();
    expect(added.single.$2, 1000);
    // Keyingi skan — shu qatorga +1.
    await scanCode(tester, '4780000000045');
    expect((await lines()).single.$2, 2000);
  });

  testWidgets('edit qty and price; post with a PIN → stock grows', (
    tester,
  ) async {
    await open(tester);
    await newReceipt(tester);
    await scanCode(tester, '4780000000014');
    final line = (await _db.select(_db.stockReceiptItems).get()).single;
    await tester.enterText(find.byKey(ValueKey('qty-${line.id}')), '24');
    await tester.enterText(find.byKey(ValueKey('cost-${line.id}')), '3500');
    await tester.enterText(find.byKey(ValueKey('sell-${line.id}')), '3000');
    await tester.pumpAndSettle();
    expect(find.text('Narx tannarxdan past'), findsOneWidget);

    await tap(tester, find.byKey(const ValueKey('receipt-post')));
    expect(find.text('Tasdiqlash kerak'), findsOneWidget);
    await tester.tap(find.text('Bobur'));
    await tester.pumpAndSettle();
    await typeSlowly(tester, '1234');
    await press(tester, LogicalKeyboardKey.enter);

    expect(find.text('Kirim tasdiqlandi: qoldiq oshdi'), findsOneWidget);
    expect((await stock())['p-non'], 24000);
    final non = await (_db.select(
      _db.products,
    )..where((p) => p.id.equals('p-non'))).getSingle();
    expect((non.costPriceTiyin, non.sellPriceTiyin), (350000, 300000));
    // Ro'yxatda — tasdiqlangan.
    expect(find.text('Tasdiqlangan'), findsOneWidget);
  });

  testWidgets('draft survives leaving the editor; can be deleted', (
    tester,
  ) async {
    await open(tester);
    await newReceipt(tester);
    await scanCode(tester, '5449000000996');
    await tap(tester, find.byKey(const ValueKey('receipt-back')));
    expect(find.text('Qoralama'), findsOneWidget);
    expect(find.textContaining('1 ta qator'), findsOneWidget);

    final receipt = (await _db.select(_db.stockReceipts).get()).single;
    await tap(tester, find.byKey(ValueKey('receipt-${receipt.id}')));
    expect(find.text('Coca-Cola 1,5 L'), findsOneWidget);
    // O'chirish tasdiq so'raydi (audit UI-P1-1): "Qaytish" — hech narsa o'chmaydi.
    await tap(tester, find.byKey(const ValueKey('receipt-delete')));
    expect(find.text("Qoralamani o'chirasizmi?"), findsOneWidget);
    await tap(tester, find.byKey(const ValueKey('pos-confirm-cancel')));
    expect(await _db.select(_db.stockReceipts).get(), hasLength(1));

    await tap(tester, find.byKey(const ValueKey('receipt-delete')));
    await tap(tester, find.byKey(const ValueKey('pos-confirm-ok')));
    expect(find.text("Hali kirim yo'q"), findsOneWidget);
    expect(await _db.select(_db.stockReceipts).get(), isEmpty);
  });

  testWidgets('supplier: quick create and pick (manager)', (tester) async {
    await open(tester, asManager: true);
    await newReceipt(tester);
    await tap(tester, find.byKey(const ValueKey('receipt-supplier')));
    await tap(tester, find.byKey(const ValueKey('supplier-new')));
    await tester.enterText(
      find.byKey(const ValueKey('supplier-name')),
      'Ulgurji Non',
    );
    await tap(tester, find.byKey(const ValueKey('supplier-save')));
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('receipt-supplier')),
        matching: find.text('Ulgurji Non'),
      ),
      findsOneWidget,
    );
    final receipt = (await _db.select(_db.stockReceipts).get()).single;
    expect(receipt.supplierId, isNotNull);
  });

  testWidgets('empty receipt is not posted', (tester) async {
    await open(tester, asManager: true);
    await newReceipt(tester);
    await tap(tester, find.byKey(const ValueKey('receipt-post')));
    expect(find.text("Bo'sh kirimni tasdiqlab bo'lmaydi"), findsOneWidget);
    expect(
      (await _db.select(_db.stockReceipts).get()).single.status,
      'draft',
    );
  });

  group('correction and cancel (T-102)', correctionTests);
}

Future<String> postedAsManager(WidgetTester tester, {int qty = 10}) async {
  await _db.writeSetting(
    serverFeaturesSettingKey,
    encodeFeatures([ServerFeature.receiptCorrections]),
  );
  await newReceipt(tester);
  await scanCode(tester, '4780000000014');
  final line = (await _db.select(_db.stockReceiptItems).get()).single;
  await tester.enterText(find.byKey(ValueKey('qty-${line.id}')), '$qty');
  await tester.pumpAndSettle();
  await tap(tester, find.byKey(const ValueKey('receipt-post')));
  return line.receiptId;
}

void correctionTests() {
  testWidgets('edit a posted receipt: 10 → 7, stock −3, history kept', (
    tester,
  ) async {
    await open(tester, asManager: true);
    final original = await postedAsManager(tester);
    expect((await stock())['p-non'], 10000);

    await tap(tester, find.byKey(ValueKey('receipt-$original')));
    await tap(tester, find.byKey(const ValueKey('receipt-edit')));
    // Tuzatish qoralamasi ochildi: banner, asl qatorlar nusxasi.
    expect(
      find.byKey(const ValueKey('receipt-correction-banner')),
      findsOneWidget,
    );
    final draft = await (_db.select(
      _db.stockReceipts,
    )..where((r) => r.correctsId.equals(original))).getSingle();
    final line = await (_db.select(
      _db.stockReceiptItems,
    )..where((i) => i.receiptId.equals(draft.id))).getSingle();
    await tester.enterText(find.byKey(ValueKey('qty-${line.id}')), '7');
    await tester.pumpAndSettle();
    // Qoralama qoldiqqa ta'sir qilmaydi.
    expect((await stock())['p-non'], 10000);

    await tap(tester, find.byKey(const ValueKey('receipt-post')));
    // Tasdiqlash oynasi: eski → yangi.
    expect(find.byKey(const ValueKey('correction-table')), findsOneWidget);
    expect(find.textContaining('10 → 7'), findsOneWidget);
    // Qoldiq 10 → 7 bo'ladi, manfiy emas (provider yuklanmagan paytda −3 ko'rsatardi).
    expect(find.textContaining('Qoldiq manfiy'), findsNothing);
    await tap(tester, find.byKey(const ValueKey('pos-confirm-ok')));

    expect(find.text('Kirim tuzatildi'), findsOneWidget);
    expect((await stock())['p-non'], 7000);
    // Ro'yxatda: asl — "Tuzatilgan", yangi — "Tuzatish · Tasdiqlangan".
    expect(find.text('Tuzatilgan'), findsOneWidget);
    expect(find.text('Tuzatish'), findsOneWidget);
    expect(find.text('Tasdiqlangan'), findsOneWidget);

    // Asl kirimni ochsak — yangi versiyaga havola, tahrirlash yo'q.
    await tap(tester, find.byKey(ValueKey('receipt-$original')));
    expect(find.byKey(const ValueKey('receipt-edit')), findsNothing);
    await tap(tester, find.byKey(const ValueKey('receipt-open-new-version')));
    expect(find.byKey(const ValueKey('receipt-edit')), findsOneWidget);
  });

  testWidgets('cancel a posted receipt: confirm, stock back to 0', (
    tester,
  ) async {
    await open(tester, asManager: true);
    final original = await postedAsManager(tester, qty: 5);
    expect((await stock())['p-non'], 5000);

    await tap(tester, find.byKey(ValueKey('receipt-$original')));
    await tap(tester, find.byKey(const ValueKey('receipt-cancel')));
    expect(find.text('Kirimni bekor qilasizmi?'), findsOneWidget);
    await tap(tester, find.byKey(const ValueKey('pos-confirm-cancel')));
    expect((await stock())['p-non'], 5000);

    await tap(tester, find.byKey(const ValueKey('receipt-cancel')));
    await tap(tester, find.byKey(const ValueKey('pos-confirm-ok')));
    expect(find.text('Kirim bekor qilindi'), findsOneWidget);
    expect((await stock())['p-non'], 0);
    expect(
      find.byKey(const ValueKey('receipt-cancelled-banner')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('receipt-cancel')), findsNothing);
  });

  testWidgets('old server: no edit buttons, a hint instead', (tester) async {
    await open(tester, asManager: true);
    final original = await postedAsManager(tester);
    await _db.writeSetting(serverFeaturesSettingKey, encodeFeatures([]));
    await tap(tester, find.byKey(ValueKey('receipt-$original')));
    expect(find.byKey(const ValueKey('receipt-edit')), findsNothing);
    expect(
      find.text(
        "Kirimni o'zgartirish server yangilangach ishlaydi "
        '(internetga ulaning).',
      ),
      findsOneWidget,
    );
  });
}
