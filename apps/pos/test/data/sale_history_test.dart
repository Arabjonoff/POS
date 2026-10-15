import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/data/sales/sale_history.dart';

import '../helpers/sale_history_seed.dart';
import '../helpers/sqlite.dart';

void main() {
  late AppDatabase db;
  late SaleHistory history;
  final today = DateTime.utc(2026, 10, 15);
  final yesterday = DateTime.utc(2026, 10, 14);

  setUp(() async {
    db = openTestDatabase();
    await seedSaleHistory(db);
    history = SaleHistory(db);
  });
  tearDown(() => db.close());

  Future<List<String>> numbers(SaleHistoryFilter filter) async => [
    for (final e in (await history.load(filter)).entries) e.number,
  ];

  test('one store day (Tashkent), newest first', () async {
    expect(await numbers(SaleHistoryFilter(day: today)), [
      'D3-000002',
      'D3-000001',
    ]);
    expect(await numbers(SaleHistoryFilter(day: yesterday)), ['D3-000003']);
    expect(
      await numbers(SaleHistoryFilter(day: DateTime.utc(2026, 10, 13))),
      isEmpty,
    );
  });

  test('entry: cashier, customer, positions, methods, refunds', () async {
    final page = await history.load(SaleHistoryFilter(day: today));
    final mixed = page.entries.first;
    expect(mixed.cashierName, 'Aziza');
    expect(mixed.customerName, 'Karimova Dilnoza');
    expect(mixed.itemCount, 1);
    expect(mixed.methods, ['card', 'debt']);
    expect(mixed.partiallyRefunded, isTrue);
    expect(mixed.refundedTiyin, 500000);
    final cash = page.entries.last;
    expect(cash.itemCount, 2);
    expect(cash.customerName, isNull);
    expect(cash.methods, ['cash']);
    expect(page.totalTiyin, 2500000 + 4800000);
    expect(page.refundedTiyin, 500000);
  });

  test('search ignores the date: number part, product, customer', () async {
    SaleHistoryFilter search(String q) =>
        SaleHistoryFilter(day: DateTime.utc(2026, 1, 1), query: q);
    expect(await numbers(search('000003')), ['D3-000003']);
    expect(await numbers(search('d3-000001')), ['D3-000001']);
    expect(await numbers(search('olma')), ['D3-000003']);
    expect(await numbers(search('karimova')), ['D3-000002']);
    expect(await numbers(search('100%')), isEmpty);
  });

  test('payment filter: a mixed sale shows under each method', () async {
    Future<List<String>> by(SalePaymentFilter p) =>
        numbers(SaleHistoryFilter(day: today, payment: p));
    expect(await by(SalePaymentFilter.cash), ['D3-000001']);
    expect(await by(SalePaymentFilter.card), ['D3-000002']);
    expect(await by(SalePaymentFilter.debt), ['D3-000002']);
  });

  test('scanned receipt barcode finds the sale', () async {
    expect(await history.idByNumber('d3-000002'), 's2');
    expect(await history.idByNumber('4780000000014'), isNull);
    expect((await history.refunds('s2')).single.totalTiyin, 500000);
  });

  test('live: a new refund updates the list', () async {
    final pages = <SaleHistoryPage>[];
    final sub = history.watch(SaleHistoryFilter(day: today)).listen(pages.add);
    Future<void> until(bool Function() done) async {
      for (var i = 0; i < 100 && !done(); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    }

    await until(() => pages.isNotEmpty);
    expect(pages.last.refundedTiyin, 500000);
    await db
        .into(db.refunds)
        .insert(
          RefundsCompanion.insert(
            id: 'r3',
            saleId: 's1',
            shiftId: 'shift-test',
            cashierId: 'cashier-1',
            method: 'cash',
            totalTiyin: 800000,
            at: DateTime.utc(2026, 10, 15, 8),
          ),
        );
    await until(() => pages.last.refundedTiyin != 500000);
    expect(pages.last.refundedTiyin, 1300000);
    await sub.cancel();
  });
}
