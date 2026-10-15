import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:pos_app/app/session/pin_gate.dart';
import 'package:pos_app/app/session/session.dart';
import 'package:pos_app/data/catalog/price_history.dart';
import 'package:pos_app/data/catalog/product_images.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/data/remote/api.dart';
import 'package:pos_app/data/sync/outbox.dart';
import 'package:pos_app/features/products/product_card.dart';
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

final Override fakePin = pinGateProvider.overrideWith(
  (ref) => PinGate(
    ref.watch(appDatabaseProvider),
    verify: (pin, _) async => pin == '1234',
  ),
);

Future<void> open(
  WidgetTester tester, {
  bool asManager = false,
  PriceHistoryFetcher? history,
  Size size = const Size(1440, 900),
  List<Override> extra = const [],
}) async {
  _db = openTestDatabase();
  addTearDown(_db.close);
  await seedCatalog(_db);
  await _db.into(_db.staffUsers).insert(manager);
  await pumpPosApp(
    tester,
    db: _db,
    size: size,
    session: asManager
        ? const Session(
            stage: SessionStage.unlocked,
            device: testDevice,
            user: manager,
          )
        : unlockedSession,
    overrides: [
      fakePin,
      if (history != null)
        priceHistoryFetcherProvider.overrideWithValue(history),
      ...extra,
    ],
  );
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pumpAndSettle();
}

Finder get card => find.byType(ProductCard);

Finder inCard(String text) =>
    find.descendant(of: card, matching: find.text(text));

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

Future<Product> product(String id) =>
    (_db.select(_db.products)..where((p) => p.id.equals(id))).getSingle();

/// Rasm tanlash va tayyorlash (testda: tayyor kichik JPEG).
final List<Override> fakeImages = [
  imageSourcePickerProvider.overrideWithValue(
    () async => Uint8List.fromList([1, 2, 3]),
  ),
  imagePreparerProvider.overrideWithValue(
    (_) async =>
        Uint8List.fromList(img.encodeJpg(img.Image(width: 8, height: 8))),
  ),
];

void main() {
  group('image (T-105)', () {
    bool hasImage(Widget w) => w is PosThumbnail && w.image != null;

    testWidgets('add an image: shown at once, saved with the product', (
      tester,
    ) async {
      await open(tester, asManager: true, extra: fakeImages);
      await tap(tester, find.text('Non issiq'));
      expect(find.byWidgetPredicate(hasImage), findsNothing);
      await tap(tester, find.byKey(const ValueKey('product-image-pick')));
      expect(
        find.descendant(of: card, matching: find.byWidgetPredicate(hasImage)),
        findsOneWidget,
      );
      expect(inCard('Internetga hali yuklanmagan'), findsOneWidget);

      await tap(tester, find.byKey(const ValueKey('product-save')));
      final saved = (await product('p-non')).imageId;
      expect(saved, isNotNull);
      // Ro'yxatda kichik rasm.
      await tester.pumpAndSettle();
      expect(find.byWidgetPredicate(hasImage), findsWidgets);

      // Olib tashlash.
      await tap(tester, find.text('Non issiq'));
      await tap(tester, find.byKey(const ValueKey('product-image-remove')));
      await tap(tester, find.byKey(const ValueKey('product-save')));
      expect((await product('p-non')).imageId, isNull);
    });

    testWidgets('cancel keeps the old image', (tester) async {
      await open(tester, asManager: true, extra: fakeImages);
      await tap(tester, find.text('Non issiq'));
      await tap(tester, find.byKey(const ValueKey('product-image-pick')));
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect((await product('p-non')).imageId, isNull);
    });

    testWidgets('double tap on save creates one product (UI-P1-2)', (
      tester,
    ) async {
      await open(tester, asManager: true);
      await tap(tester, find.byKey(const ValueKey('products-add')));
      await tester.enterText(
        find.byKey(const ValueKey('product-name')),
        'Ikki marta',
      );
      await tester.enterText(
        find.byKey(const ValueKey('product-sell')),
        '1000',
      );
      await tester.pumpAndSettle();
      final save = find.byKey(const ValueKey('product-save'));
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.tap(save, warnIfMissed: false);
      await tester.pumpAndSettle();
      final rows = await (_db.select(
        _db.products,
      )..where((p) => p.name.equals('Ikki marta'))).get();
      expect(rows, hasLength(1));
    });
  });

  group('list', () {
    testWidgets('active products; search; category; inactive filter', (
      tester,
    ) async {
      await open(tester);
      expect(find.text('Non issiq'), findsOneWidget);
      expect(find.text('Eski tovar'), findsNothing);

      await tester.enterText(
        find.byKey(const ValueKey('products-search')),
        'pat',
      );
      await tester.pumpAndSettle();
      expect(find.text('Patir non'), findsOneWidget);
      expect(find.text('Non issiq'), findsNothing);
      await tester.enterText(
        find.byKey(const ValueKey('products-search')),
        '',
      );
      await tester.pumpAndSettle();

      await tap(tester, find.byKey(const ValueKey('products-category-c-milk')));
      expect(find.text('Tuxum'), findsOneWidget);
      expect(find.text('Non issiq'), findsNothing);
      await tap(tester, find.text('Hammasi').last);

      await tap(
        tester,
        find.byKey(const ValueKey('products-filter-inactive')),
      );
      expect(find.text('Eski tovar'), findsOneWidget);
      expect(find.text('Non issiq'), findsNothing);
    });

    testWidgets('stock: low and negative badges and filters', (tester) async {
      await open(tester);
      await (_db.update(_db.products)..where((p) => p.id.equals('p-sut')))
          .write(const ProductsCompanion(minStockMilli: Value(5000)));
      await _db
          .into(_db.productStock)
          .insert(
            ProductStockCompanion.insert(
              productId: 'p-cola',
              storeId: 'store-1',
              qtyMilli: -2000,
              updatedAt: DateTime.utc(2026, 10, 15),
            ),
          );
      await tester.pumpAndSettle();
      expect(find.text('Manfiy'), findsOneWidget);
      expect(find.text('Kam'), findsOneWidget);

      await tap(tester, find.byKey(const ValueKey('products-filter-negative')));
      expect(find.text('Coca-Cola 1,5 L'), findsOneWidget);
      expect(find.text('Sut 1 L'), findsNothing);
      await tap(tester, find.byKey(const ValueKey('products-filter-low')));
      expect(find.text('Sut 1 L'), findsOneWidget);
      expect(find.text('Coca-Cola 1,5 L'), findsNothing);
    });
  });

  group('scanner', () {
    testWidgets('known code opens its card', (tester) async {
      await open(tester);
      await scanCode(tester, '4780000000014');
      expect(card, findsOneWidget);
      expect(inCard('Non issiq'), findsWidgets);
    });

    testWidgets('unknown code → new card with the code; save with PIN', (
      tester,
    ) async {
      await open(tester);
      await scanCode(tester, '4780000000045');
      expect(inCard('Yangi tovar'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('product-barcode-4780000000045')),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const ValueKey('product-name')),
        'Qatiq 0,5 L',
      );
      await tester.enterText(
        find.byKey(const ValueKey('product-sell')),
        '9000',
      );
      await tester.enterText(
        find.byKey(const ValueKey('product-cost')),
        '7000',
      );
      await tester.pumpAndSettle();
      expect(inCard('Ustama: 28,6%'), findsOneWidget);
      await tap(tester, find.byKey(const ValueKey('product-save')));
      await approve(tester);

      expect(card, findsNothing);
      expect(find.text('Saqlandi'), findsOneWidget);
      expect(find.text('Qatiq 0,5 L'), findsOneWidget);
      final row = await (_db.select(
        _db.products,
      )..where((p) => p.name.equals('Qatiq 0,5 L'))).getSingle();
      expect((row.sellPriceTiyin, row.costPriceTiyin), (900000, 700000));
      final barcode = await (_db.select(
        _db.productBarcodes,
      )..where((b) => b.productId.equals(row.id))).getSingle();
      expect(barcode.barcode, '4780000000045');
      final event =
          await (_db.select(
                _db.outboxEvents,
              )..where((e) => e.type.equals(OutboxEventType.productUpserted)))
              .getSingle();
      expect((jsonDecode(event.payload) as Map)['by'], 'manager-1');
    });

    testWidgets('scanning a taken code inside the card warns', (tester) async {
      await open(tester);
      await tap(tester, find.byKey(const ValueKey('products-add')));
      await scanCode(tester, '5449000000996');
      expect(
        inCard('«5449000000996» — «Coca-Cola 1,5 L» tovarida bor'),
        findsOneWidget,
      );
      await tester.enterText(find.byKey(const ValueKey('product-name')), 'X');
      await tester.enterText(
        find.byKey(const ValueKey('product-sell')),
        '1000',
      );
      await tap(tester, find.byKey(const ValueKey('product-save')));
      // Saqlanmaydi, PIN ham so'ralmaydi.
      expect(find.text('Tasdiqlash kerak'), findsNothing);
      expect(card, findsOneWidget);
    });
  });

  group('edit', () {
    testWidgets('manager edits the price without a PIN', (tester) async {
      await open(tester, asManager: true);
      await tap(tester, find.text('Non issiq'));
      expect(find.byKey(const ValueKey('product-sell')), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('product-sell')),
        '4500',
      );
      await tap(tester, find.byKey(const ValueKey('product-save')));
      expect(find.text('Tasdiqlash kerak'), findsNothing);
      expect((await product('p-non')).sellPriceTiyin, 450000);
    });

    testWidgets('validation messages stay in the card', (tester) async {
      await open(tester, asManager: true);
      await tap(tester, find.byKey(const ValueKey('products-add')));
      await tester.enterText(find.byKey(const ValueKey('product-sell')), '0');
      await tap(tester, find.byKey(const ValueKey('product-save')));
      expect(inCard("Narx 0 dan katta bo'lishi kerak"), findsOneWidget);
      expect(card, findsOneWidget);
    });

    testWidgets('same name: a hint, saving is not blocked (audit P2-14)', (
      tester,
    ) async {
      await open(tester, asManager: true);
      await tap(tester, find.byKey(const ValueKey('products-add')));
      const hint = '«Non issiq» nomli tovar allaqachon bor. Shu tovarmi?';
      await tester.enterText(
        find.byKey(const ValueKey('product-name')),
        'NON  issiq',
      );
      await tester.pumpAndSettle();
      expect(inCard(hint), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('product-name')),
        'Non qora',
      );
      await tester.pumpAndSettle();
      expect(inCard(hint), findsNothing);
    });

    testWidgets('own name is not a duplicate', (tester) async {
      await open(tester, asManager: true);
      await tap(tester, find.text('Non issiq'));
      await tester.enterText(
        find.byKey(const ValueKey('product-name')),
        'Non issiq ',
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('allaqachon bor'), findsNothing);
    });

    testWidgets('card of a deleted product closes (audit P2-16)', (
      tester,
    ) async {
      await open(tester, asManager: true);
      await (_db.update(_db.products)..where((p) => p.id.equals('p-non')))
          .write(ProductsCompanion(deletedAt: Value(DateTime.utc(2026))));
      final context = tester.element(find.byType(Scaffold).first);
      unawaited(showProductCard(context, productId: 'p-non'));
      await tester.pumpAndSettle();
      expect(card, findsNothing);
      expect(
        find.text("Tovar topilmadi — u o'chirilgan bo'lishi mumkin"),
        findsOneWidget,
      );
    });

    testWidgets('deactivate hides it from the list', (tester) async {
      await open(tester, asManager: true);
      await tap(tester, find.text('Tuxum'));
      await tap(tester, find.byKey(const ValueKey('product-toggle-active')));
      expect((await product('p-tuxum')).isActive, isFalse);
      expect(find.text('Tuxum'), findsNothing);
    });

    testWidgets('price history (online) for a manager', (tester) async {
      await open(
        tester,
        asManager: true,
        history: (id) async => [
          PriceChange(
            sellPriceTiyin: 400000,
            costPriceTiyin: 300000,
            at: DateTime.utc(2026, 10, 1, 7),
            byName: 'Aziz',
          ),
        ],
      );
      await tap(tester, find.text('Non issiq'));
      await tap(tester, find.byKey(const ValueKey('product-history')));
      expect(
        find.textContaining(
          'Narx ${PosFormat.money(400000, currency: "so\x27m")} · '
          'Tannarx ${PosFormat.money(300000, currency: "so\x27m")}',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Aziz'), findsOneWidget);
    });

    testWidgets('price history offline; cashier does not see it', (
      tester,
    ) async {
      await open(
        tester,
        asManager: true,
        history: (id) async => throw const ApiFailure(ApiFailureKind.network),
      );
      await tap(tester, find.text('Non issiq'));
      await tap(tester, find.byKey(const ValueKey('product-history')));
      expect(
        find.text("Narx tarixini ko'rish uchun internet kerak"),
        findsOneWidget,
      );
    });
  });

  testWidgets('cashier: no price history section', (tester) async {
    await open(tester);
    await tap(tester, find.text('Non issiq'));
    expect(find.byKey(const ValueKey('product-history')), findsNothing);
  });

  group('input parsing', () {
    test('money', () {
      expect(parseMoneyTiyin('12 500'), 1250000);
      expect(parseMoneyTiyin('12500,5'), 1250050);
      expect(parseMoneyTiyin(''), 0);
      expect(parseMoneyTiyin('12,345'), isNull);
      expect(formatMoneyInput(1250050), '12 500,50');
      expect(formatMoneyInput(1250000), '12 500');
    });

    test('qty', () {
      expect(parseQtyMilli('5', fractional: false), 5000);
      expect(parseQtyMilli('0,5', fractional: false), isNull);
      expect(parseQtyMilli('0,25', fractional: true), 250);
      expect(formatQtyInput(1250, fractional: true), '1,25');
      expect(formatQtyInput(3000, fractional: false), '3');
    });
  });
}
