import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/data/catalog/product_import.dart';
import 'package:pos_app/data/catalog/stock_history.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/data/remote/api.dart';
import 'package:pos_app/data/sync/outbox.dart';

import '../helpers/catalog_seed.dart';
import '../helpers/fake_import.dart';
import '../helpers/pump_app.dart';
import '../helpers/sqlite.dart';

late AppDatabase _db;

class SavingFiles extends FakeFiles {
  Uint8List? bytes;

  @override
  Future<bool> save(String name, Uint8List bytes) async {
    this.bytes = bytes;
    return super.save(name, bytes);
  }
}

Future<void> open(
  WidgetTester tester, {
  StockHistoryFetcher? history,
  ImportFiles? files,
}) async {
  _db = openTestDatabase();
  addTearDown(_db.close);
  await seedCatalog(_db);
  await pumpPosApp(
    tester,
    db: _db,
    overrides: <Override>[
      if (history != null)
        stockHistoryFetcherProvider.overrideWithValue(history),
      if (files != null) importFilesProvider.overrideWithValue(files),
    ],
  );
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pumpAndSettle();
}

Future<void> tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Shu kassada yuborilmagan savdo harakati (−2 dona).
Future<void> pendingSale() async {
  await _db.enqueueEvent(
    id: 'e-1',
    type: OutboxEventType.saleCompleted,
    createdAt: DateTime.utc(2026, 10, 15, 9),
    payload: const {},
  );
  await _db
      .into(_db.stockMovements)
      .insert(
        StockMovementsCompanion.insert(
          id: 'm-1',
          productId: 'p-non',
          qtyMilli: -2000,
          type: 'sale',
          refType: 'sale',
          refId: 's-1',
          outboxEventId: const Value('e-1'),
          at: DateTime.utc(2026, 10, 15, 9),
        ),
      );
}

void main() {
  testWidgets('history: unsent local moves on top of the server ones', (
    tester,
  ) async {
    await open(
      tester,
      history: (id) async => [
        StockMove(
          type: 'receipt',
          qtyMilli: 50000,
          at: DateTime.utc(2026, 10, 14, 6),
          byName: 'Bobur',
        ),
      ],
    );
    await pendingSale();
    await tap(tester, find.text('Non issiq'));
    await tap(tester, find.byKey(const ValueKey('product-stock-history')));
    expect(find.text('Yuborilmagan'), findsOneWidget);
    expect(find.textContaining('Savdo'), findsOneWidget);
    expect(find.textContaining('Kirim · Bobur'), findsOneWidget);
    expect(find.text("To'liq tarix uchun internet kerak"), findsNothing);
  });

  testWidgets('history offline: local only + a note', (tester) async {
    await open(
      tester,
      history: (id) async => throw const ApiFailure(ApiFailureKind.network),
    );
    await pendingSale();
    await tap(tester, find.text('Non issiq'));
    await tap(tester, find.byKey(const ValueKey('product-stock-history')));
    expect(find.text('Yuborilmagan'), findsOneWidget);
    expect(find.text("To'liq tarix uchun internet kerak"), findsOneWidget);
  });

  testWidgets('low stock → order list CSV is saved', (tester) async {
    final files = SavingFiles();
    await open(tester, files: files);
    await (_db.update(_db.products)..where((p) => p.id.equals('p-sut'))).write(
      const ProductsCompanion(
        minStockMilli: Value(5000),
        costPriceTiyin: Value(950000),
      ),
    );
    await _db
        .into(_db.productStock)
        .insert(
          ProductStockCompanion.insert(
            productId: 'p-sut',
            storeId: 'store-1',
            qtyMilli: 3000,
            updatedAt: DateTime.utc(2026, 10, 15),
          ),
        );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('products-order-list')), findsNothing);
    await tap(tester, find.byKey(const ValueKey('products-filter-low')));
    await tap(tester, find.byKey(const ValueKey('products-order-list')));

    expect(files.savedName, 'buyurtma.csv');
    final text = utf8.decode(files.bytes!.sublist(3));
    expect(text, contains('Sut 1 L;4600000000015;3;5;7;9500;66500'));
    expect(find.text("Buyurtma ro'yxati saqlandi"), findsOneWidget);
  });
}
