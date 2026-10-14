import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/data/catalog/product_editor.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/data/inventory/count_store.dart';
import 'package:pos_app/data/sync/outbox.dart';

import '../helpers/catalog_seed.dart';
import '../helpers/sqlite.dart';

void main() {
  late AppDatabase db;
  late CountStore store;

  setUp(() async {
    db = openTestDatabase();
    await seedCatalog(db);
    for (final (id, qty) in const [
      ('p-non', 20000),
      ('p-sut', 8000),
      ('p-tuxum', 30000),
    ]) {
      await db
          .into(db.productStock)
          .insert(
            ProductStockCompanion.insert(
              productId: id,
              storeId: 'store-1',
              qtyMilli: qty,
              updatedAt: DateTime.utc(2026, 10, 15),
            ),
          );
    }
    store = CountStore(db, now: () => DateTime.utc(2026, 10, 15, 18));
  });
  tearDown(() => db.close());

  Future<Map<String, int>> stock() async =>
      Map.fromEntries(await stockQuery(db).get());

  test('scans add up; diff = counted − system; uncounted listed', () async {
    final id = await store.create(categoryId: 'c-milk');
    for (var i = 0; i < 7; i++) {
      await store.addCounted(id, 'p-sut');
    }
    await store.addCounted(id, 'p-tuxum');
    final doc = (await store.load(id))!;
    expect(doc.scope, 'category');
    expect(doc.categoryName, 'Sut');
    expect(
      [for (final l in doc.lines) (l.productId, l.countedMilli, l.diffMilli)],
      [
        ('p-sut', 7000, -1000),
        ('p-tuxum', 1000, -29000),
      ],
    );
    // Qamrov — faqat "Sut" kategoriyasi, sanalganlarsiz.
    expect(doc.uncounted, isEmpty);
    expect((doc.surplusCount, doc.shortageCount), (0, 2));

    final all = (await store.load(await store.create()))!;
    expect(all.scope, 'all');
    expect(all.uncounted.map((u) => u.productId), contains('p-non'));
    expect(all.uncounted.map((u) => u.productId), isNot(contains('p-old')));
  });

  test('post: stock = counted for counted items only; payload', () async {
    final id = await store.create();
    await store.addCounted(id, 'p-non', qtyMilli: 18000);
    await store.addCounted(id, 'p-sut', qtyMilli: 8000); // farqsiz
    await store.addCounted(id, 'p-cola', qtyMilli: 5000); // tizimda 0
    await store.post(id, by: 'manager-1', storeId: 'store-1');

    final s = await stock();
    expect((s['p-non'], s['p-sut'], s['p-cola']), (18000, 8000, 5000));
    // Sanalmagan tuxum o'zgarmadi.
    expect(s['p-tuxum'], 30000);

    final moves = await (db.select(
      db.stockMovements,
    )..where((m) => m.type.equals('inventory'))).get();
    expect(
      {for (final m in moves) m.productId: m.qtyMilli},
      {
        'p-non': -2000,
        'p-cola': 5000,
      },
    );

    final doc = (await store.load(id))!;
    expect(doc.status, 'posted');
    expect(
      [for (final l in doc.lines) (l.expectedMilli, l.diffMilli)],
      [
        (20000, -2000),
        (8000, 0),
        (0, 5000),
      ],
    );
    expect(doc.uncounted, isEmpty);

    final event =
        await (db.select(
              db.outboxEvents,
            )..where((e) => e.type.equals(OutboxEventType.inventoryPosted)))
            .getSingle();
    expect(jsonDecode(event.payload), {
      'id': id,
      'scope': 'all',
      'category': null,
      'note': '',
      'items': [
        {'product': 'p-non', 'counted_milli': 18000},
        {'product': 'p-sut', 'counted_milli': 8000},
        {'product': 'p-cola', 'counted_milli': 5000},
      ],
      'by': 'manager-1',
    });

    // Qayta tasdiqlash — hech narsa.
    await store.post(id, by: 'manager-1');
    expect((await stock())['p-non'], 18000);
  });

  test('set counted, remove line, empty count, delete draft', () async {
    final id = await store.create();
    await store.addCounted(id, 'p-non');
    var doc = (await store.load(id))!;
    await store.setCounted(doc.lines.single.id, 0);
    doc = (await store.load(id))!;
    expect(doc.lines.single.diffMilli, -20000);
    expect(
      () => store.setCounted(doc.lines.single.id, -1),
      throwsArgumentError,
    );
    await store.removeLine(doc.lines.single.id);
    await expectLater(
      store.post(id, by: 'm'),
      throwsA(isA<CountEmptyException>()),
    );
    await store.deleteDraft(id);
    expect(await store.load(id), isNull);
  });

  test('list: drafts first', () async {
    final a = await store.create();
    await store.addCounted(a, 'p-non', qtyMilli: 20000);
    await store.post(a, by: 'm');
    final b = await store.create(categoryId: 'c-veg');
    final list = await store.watchAll().first;
    expect(
      [for (final c in list) (c.id, c.status, c.categoryName)],
      [
        (b, 'draft', 'Sabzavot'),
        (a, 'posted', null),
      ],
    );
  });
}
