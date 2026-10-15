import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/app/session/pin_gate.dart';
import 'package:pos_app/app/sync/sales_gate.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/features/pos/cart/cart.dart';
import 'package:pos_app/features/pos/cart/cart_controller.dart';
import 'package:pos_app/features/pos/payment/payment_dialog.dart';
import 'package:pos_ui/pos_ui.dart';

import '../helpers/catalog_seed.dart';
import '../helpers/keyboard.dart';
import '../helpers/pump_app.dart';
import '../helpers/sqlite.dart';

String som(int amount) => PosFormat.money(amount * 100, currency: "so'm");

late ProviderContainer _container;

CartState get cart => _container.read(cartControllerProvider).requireValue;

List<(String, int)> get lines => [
  for (final l in cart.cart.lines) (l.productId, l.qtyMilli),
];

Future<AppDatabase> open(
  WidgetTester tester, {
  AppDatabase? db,
  Size size = const Size(1440, 900),
  List<Override> overrides = const [],
}) async {
  final database = db ?? openTestDatabase();
  if (db == null) {
    addTearDown(database.close);
    await seedCatalog(database);
  }
  final (c, _) = await pumpPosApp(
    tester,
    db: database,
    size: size,
    overrides: overrides,
  );
  _container = c;
  return database;
}

void main() {
  group('scanner', () {
    testWidgets('known code goes to the cart; same code again → qty +1', (
      tester,
    ) async {
      await open(tester);
      expect(find.text('Tovarni skanerlang yoki qidiring'), findsOneWidget);

      await scanCode(tester, '4780000000014');
      expect(lines, [('p-non', 1000)]);
      expect(find.text('Non issiq'), findsWidgets);
      await scanCode(tester, '4780000000014');
      await scanCode(tester, '5449000000996');
      expect(lines, [('p-non', 2000), ('p-cola', 1000)]);
      // Jami: 2 × 4 000 + 14 000.
      expect(find.text(som(22000)), findsOneWidget);
      // Skaner belgilari qidiruvga tushmagan.
      expect(find.text('4780000000014'), findsNothing);
    });

    testWidgets('scale barcode → weighted line with the weight', (
      tester,
    ) async {
      await open(tester);
      await scanCode(tester, '2012345012509');
      expect(lines, [('p-olma', 1250)]);
      expect(
        find.text(PosFormat.qtyWithUnit(1250, unit: 'kg', weighted: true)),
        findsOneWidget,
      );
      expect(find.text(som(18750)), findsWidgets);
    });

    testWidgets('unknown, inactive and misread codes are not added', (
      tester,
    ) async {
      await open(tester);
      await scanCode(tester, '4780000000038');
      // Qizil xabar kod bilan va "Yangi tovar qo'shish".
      expect(find.text('Tovar topilmadi: 4780000000038'), findsOneWidget);
      expect(find.byKey(const ValueKey('pos-add-product')), findsOneWidget);
      await scanCode(tester, '4780000000021');
      // Yangi skan — eski xabar yo'qoladi.
      expect(find.byKey(const ValueKey('pos-not-found')), findsNothing);
      expect(
        find.text("Bu tovarni sotib bo'lmaydi: nofaol yoki narxi yo'q"),
        findsOneWidget,
      );
      await scanCode(tester, '4780000000015');
      expect(
        find.text("Kod noto'g'ri o'qildi, qayta skanerlang"),
        findsOneWidget,
      );
      expect(lines, isEmpty);
    });
  });

  group('search and quick buttons', () {
    testWidgets('typing searches (latin/cyrillic agnostic); Enter adds', (
      tester,
    ) async {
      await open(tester);
      await typeSlowly(tester, 'pat');
      expect(find.text('Patir non'), findsOneWidget);
      await press(tester, LogicalKeyboardKey.enter);
      expect(lines, [('p-patir', 1000)]);
      // Qidiruv tozalanadi — yana tez tugmalar.
      expect(find.text('Hammasi'), findsOneWidget);
    });

    testWidgets('↓ picks the next result; Esc clears the search', (
      tester,
    ) async {
      await open(tester);
      await typeSlowly(tester, 'non');
      expect(find.text('Nonvoy pechenyesi'), findsOneWidget);
      await press(tester, LogicalKeyboardKey.arrowDown);
      await press(tester, LogicalKeyboardKey.enter);
      expect(lines, [('p-nonvoy', 1000)]);

      await typeSlowly(tester, 'choy');
      expect(find.text('Choy Ahmad 100 g'), findsOneWidget);
      await press(tester, LogicalKeyboardKey.escape);
      expect(find.text('Choy Ahmad 100 g'), findsNothing);
      expect(lines, [('p-nonvoy', 1000)]);
    });

    testWidgets('quick tile: piece → +1, weighted → asks the weight', (
      tester,
    ) async {
      await open(tester);
      await tester.tap(find.text('Sabzavot'));
      await tester.pumpAndSettle();
      expect(find.text('Non issiq'), findsNothing);

      await tester.tap(find.text('Kartoshka'));
      await tester.pumpAndSettle();
      expect(find.text('Vazn, kg'), findsOneWidget);
      // Fizik klaviatura: 0,75 + Enter.
      await typeSlowly(tester, '0,75');
      await press(tester, LogicalKeyboardKey.enter);
      expect(lines, [('p-kartoshka', 750)]);

      await tester.tap(find.text('Hammasi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tuxum'));
      await tester.tap(find.text('Tuxum'));
      await tester.pumpAndSettle();
      expect(lines, [('p-kartoshka', 750), ('p-tuxum', 2000)]);
    });

    testWidgets('a tap adds without a flash; only a scan flashes the edge', (
      tester,
    ) async {
      await open(tester);
      await tester.tap(find.text('Tuxum'));
      await tester.pump();
      expect(lines, [('p-tuxum', 1000)]);
      // Oddiy bosish — chaqnash umuman yo'q (avval savat paneli yashil bo'lardi).
      expect(find.byType(PosScanFeedbackOverlay), findsNothing);
      await tester.pumpAndSettle();

      await scanCode(tester, '4780000000014');
      expect(find.byType(PosScanFeedbackOverlay), findsOneWidget);
    });
  });

  group('product grid', () {
    Future<void> setStock(AppDatabase db, Map<String, int> qty) async {
      for (final MapEntry(key: id, value: q) in qty.entries) {
        await db
            .into(db.productStock)
            .insert(
              ProductStockCompanion.insert(
                productId: id,
                storeId: testDevice.storeId,
                qtyMilli: q,
                updatedAt: DateTime.utc(2026, 10, 15),
              ),
            );
      }
    }

    testWidgets('favorites first; tabs filter; every card is ≥ 160 × 112', (
      tester,
    ) async {
      await open(tester);
      // Tez tugmali tovarlar bor — "Sevimlilar" birinchi va tanlangan.
      final favorites = find.byKey(const ValueKey('tab-favorites'));
      final all = find.byKey(const ValueKey('tab-all'));
      expect(favorites, findsOneWidget);
      expect(
        tester.getRect(favorites).left,
        lessThan(tester.getRect(all).left),
      );
      expect(find.text('Tuxum'), findsOneWidget);
      // Tez tugmasiz tovar faqat "Hammasi" da.
      expect(find.text('Choy Ahmad 100 g'), findsNothing);
      await tester.tap(all);
      await tester.pumpAndSettle();
      expect(find.text('Choy Ahmad 100 g'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('tab-c-veg')));
      await tester.pumpAndSettle();
      expect(find.text('Kartoshka'), findsOneWidget);
      expect(find.text('Tuxum'), findsNothing);

      for (final tile in tester.widgetList<PosProductTile>(
        find.byType(PosProductTile),
      )) {
        final size = tester.getSize(find.byWidget(tile));
        expect(size.width, greaterThanOrEqualTo(PosProductTile.minWidth));
        expect(size.height, PosProductTile.height);
      }
    });

    testWidgets('top sellers join favorites after a sale', (tester) async {
      await open(tester);
      expect(find.text('Choy Ahmad 100 g'), findsNothing);
      await typeSlowly(tester, 'choy');
      await press(tester, LogicalKeyboardKey.enter);
      await press(tester, LogicalKeyboardKey.f12);
      await press(tester, LogicalKeyboardKey.enter);
      expect(cart.cart.lines, isEmpty);
      // Endi "Sevimlilar" da (so'nggi 30 kunda sotilgan).
      expect(find.text('Choy Ahmad 100 g'), findsOneWidget);
    });

    testWidgets('search filters the grid; ↑/↓ highlights a card', (
      tester,
    ) async {
      await open(tester);
      await typeSlowly(tester, 'non');
      // Natija hamma tovardan (tez tugmasizlar ham), tab tanlanmagan.
      expect(find.text('Nonvoy pechenyesi'), findsOneWidget);
      expect(find.text('Tuxum'), findsNothing);
      bool selected(String name) => tester
          .widget<PosProductTile>(
            find.ancestor(
              of: find.text(name),
              matching: find.byType(PosProductTile),
            ),
          )
          .selected;
      expect(selected('Non issiq'), isTrue);
      await press(tester, LogicalKeyboardKey.arrowDown);
      expect(selected('Non issiq'), isFalse);
      // Tab bosilsa — qidiruv tozalanadi.
      await tester.tap(find.byKey(const ValueKey('tab-all')));
      await tester.pumpAndSettle();
      expect(find.text('Choy Ahmad 100 g'), findsOneWidget);
    });

    testWidgets('stock: low badge, out-of-stock card warns but adds', (
      tester,
    ) async {
      final db = openTestDatabase();
      addTearDown(db.close);
      await seedCatalog(db);
      await db
          .update(db.products)
          .replace(
            (await (db.select(
              db.products,
            )..where((p) => p.id.equals('p-sut'))).getSingle()).copyWith(
              minStockMilli: 5000,
            ),
          );
      await setStock(db, {'p-non': 24000, 'p-sut': 3000, 'p-tuxum': 0});
      await open(tester, db: db);

      expect(
        find.text(PosFormat.qtyWithUnit(24000, unit: 'dona', weighted: false)),
        findsOneWidget,
      );
      expect(find.text('Kam'), findsOneWidget);
      final out = tester.widget<PosProductTile>(
        find.ancestor(
          of: find.text('Tuxum'),
          matching: find.byType(PosProductTile),
        ),
      );
      expect(out.out, isTrue);
      expect(out.stock, "Qoldiq yo'q");

      await tester.tap(find.text('Tuxum'));
      await tester.pumpAndSettle();
      expect(lines, [('p-tuxum', 1000)]);
      expect(
        find.text(
          "«Tuxum» qoldiqda yo'q — chekka qo'shildi. Qoldiqni tekshiring",
        ),
        findsOneWidget,
      );
    });

    testWidgets('no stock kept at all → no stock lines, nothing grey', (
      tester,
    ) async {
      final db = openTestDatabase();
      addTearDown(db.close);
      await seedCatalog(db);
      await setStock(db, {'p-non': 0});
      await open(tester, db: db);
      expect(find.text("Qoldiq yo'q"), findsNothing);
      expect(
        tester
            .widgetList<PosProductTile>(find.byType(PosProductTile))
            .where((t) => t.out || t.stock != null),
        isEmpty,
      );
    });

    testWidgets('not found: "add product" opens the card with the code', (
      tester,
    ) async {
      await open(tester);
      await scanCode(tester, '4780000000038');
      await tester.tap(find.byKey(const ValueKey('pos-add-product')));
      await tester.pumpAndSettle();
      expect(find.text('4780000000038'), findsWidgets);
      await press(tester, LogicalKeyboardKey.escape);
      // Bekor qilindi — xabar ham yopiladi, savat bo'sh.
      expect(find.byKey(const ValueKey('pos-not-found')), findsNothing);
      expect(lines, isEmpty);
    });

    testWidgets('Esc closes the not-found message', (tester) async {
      await open(tester);
      await scanCode(tester, '4780000000038');
      await press(tester, LogicalKeyboardKey.escape);
      expect(find.byKey(const ValueKey('pos-not-found')), findsNothing);
    });
  });

  group('cart keys', () {
    testWidgets('F2 sets qty, Delete removes, undo brings it back', (
      tester,
    ) async {
      await open(tester);
      await scanCode(tester, '4780000000014');
      await scanCode(tester, '5449000000996');
      await press(tester, LogicalKeyboardKey.arrowUp);
      expect(cart.selectedLine!.productId, 'p-non');

      await press(tester, LogicalKeyboardKey.f2);
      expect(find.text('Miqdor'), findsOneWidget);
      await typeSlowly(tester, '3');
      await press(tester, LogicalKeyboardKey.enter);
      expect(lines, [('p-non', 3000), ('p-cola', 1000)]);

      await press(tester, LogicalKeyboardKey.delete);
      expect(lines, [('p-cola', 1000)]);
      expect(find.text("Non issiq o'chirildi"), findsOneWidget);
      await tester.tap(find.text('Bekor qilish'));
      await tester.pumpAndSettle();
      expect(lines, [('p-non', 3000), ('p-cola', 1000)]);
    });

    testWidgets('stepper changes qty', (tester) async {
      await open(tester);
      await scanCode(tester, '4780000000014');
      await tester.tap(find.byTooltip("Ko'paytirish"));
      await tester.pumpAndSettle();
      expect(lines, [('p-non', 2000)]);
      await tester.tap(find.byTooltip('Kamaytirish'));
      await tester.pumpAndSettle();
      expect(lines, [('p-non', 1000)]);
    });

    testWidgets('F6 defers the check; tabs switch between them', (
      tester,
    ) async {
      await open(tester);
      await scanCode(tester, '4780000000014');
      await press(tester, LogicalKeyboardKey.f6);
      expect(find.text('Chek 2'), findsOneWidget);
      expect(lines, isEmpty);
      await scanCode(tester, '5449000000996');

      await tester.tap(find.text('Chek 1'));
      await tester.pumpAndSettle();
      expect(lines, [('p-non', 1000)]);
      await tester.tap(find.text('Chek 2'));
      await tester.pumpAndSettle();
      expect(lines, [('p-cola', 1000)]);
    });

    testWidgets('F12: pay is off for an empty cart and when sales stop', (
      tester,
    ) async {
      await open(
        tester,
        overrides: [
          salesBlockProvider.overrideWithValue(SalesBlock.readonly),
        ],
      );
      await scanCode(tester, '4780000000014');
      expect(
        find.text("Obuna muddati tugagan — savdo to'xtatilgan"),
        findsWidgets,
      );
      await press(tester, LogicalKeyboardKey.f12);
      expect(find.byType(PaymentDialog), findsNothing);
    });
  });

  group('discount', () {
    Future<void> addManager(AppDatabase db) => db
        .into(db.staffUsers)
        .insert(
          StaffUsersCompanion.insert(
            id: 'manager-1',
            fullName: 'Bobur',
            role: 'manager',
            pinHash: const Value('hash'),
          ),
        );

    final fakePin = pinGateProvider.overrideWith(
      (ref) => PinGate(
        ref.watch(appDatabaseProvider),
        verify: (pin, _) async => pin == '1234',
      ),
    );

    Future<void> discountPercent(WidgetTester tester, String percent) async {
      await press(tester, LogicalKeyboardKey.f3);
      expect(find.text('Butun chekka'), findsOneWidget);
      await tester.tap(find.text('Butun chekka'));
      await tester.pumpAndSettle();
      await typeSlowly(tester, percent);
      await press(tester, LogicalKeyboardKey.enter);
    }

    testWidgets('cashier gives 5% alone', (tester) async {
      await open(tester, overrides: [fakePin]);
      await scanCode(tester, '5449000000996');
      await discountPercent(tester, '5');
      expect(cart.cart.discount, const Discount.percent(500));
      // 14 000 − 700.
      expect(find.text(som(13300)), findsOneWidget);
    });

    testWidgets('bigger discount needs a manager PIN; it is recorded', (
      tester,
    ) async {
      final db = openTestDatabase();
      addTearDown(db.close);
      await seedCatalog(db);
      await addManager(db);
      await open(tester, db: db, overrides: [fakePin]);
      await scanCode(tester, '5449000000996');
      await discountPercent(tester, '20');
      expect(find.text('Tasdiqlash kerak'), findsOneWidget);
      await tester.tap(find.text('Bobur'));
      await tester.pumpAndSettle();
      await typeSlowly(tester, '1234');
      await press(tester, LogicalKeyboardKey.enter);

      expect(find.text('Tasdiqlash kerak'), findsNothing);
      expect(
        cart.cart.discount,
        const Discount.percent(2000, approvedBy: 'manager-1'),
      );
      expect(cart.cart.approvedBy, 'manager-1');
    });

    testWidgets('approval cancelled → no discount', (tester) async {
      await open(tester, overrides: [fakePin]);
      await scanCode(tester, '5449000000996');
      await discountPercent(tester, '20');
      expect(find.text('Tasdiqlash kerak'), findsOneWidget);
      await press(tester, LogicalKeyboardKey.escape);
      expect(cart.cart.discount, isNull);
    });
  });

  testWidgets('the cart is back after the app is killed and reopened', (
    tester,
  ) async {
    final db = openTestDatabase();
    addTearDown(db.close);
    await seedCatalog(db);
    await open(tester, db: db);
    await scanCode(tester, '4780000000014');
    await scanCode(tester, '2012345012509');
    await press(tester, LogicalKeyboardKey.f6);
    await scanCode(tester, '5449000000996');
    await _container.read(cartControllerProvider.notifier).flush();

    // Ilova "o'ldirildi": yangi konteyner, o'sha baza.
    await tester.pumpWidget(const SizedBox());
    _container.dispose();
    await open(tester, db: db);
    expect(cart.carts, hasLength(2));
    expect(find.text('Chek 2'), findsOneWidget);
    await tester.tap(find.text('Chek 1'));
    await tester.pumpAndSettle();
    expect(lines, [('p-non', 1000), ('p-olma', 1250)]);
  });

  testWidgets('phone: swipe left removes a line', (tester) async {
    await open(tester, size: const Size(390, 844));
    await scanCode(tester, '4780000000014');
    expect(find.text('Non issiq'), findsOneWidget);
    await tester.drag(find.text('Non issiq'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(lines, isEmpty);
    expect(find.text("Non issiq o'chirildi"), findsOneWidget);
  });
}
