import 'dart:convert';

import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/data/sales/sale_writer.dart';
import 'package:pos_app/data/sync/outbox.dart';

import '../helpers/sqlite.dart';

const String shiftId = 'shift-1';
const String cashier = 'cashier-1';

/// Bashorat qilinadigan ID'lar: `id-1`, `id-2`, ...
class _Ids {
  int _n = 0;

  /// N-chi chaqiruvda shu ID qaytadi (to'qnashuvni sun'iy yaratish uchun).
  final Map<int, String> overrides = {};

  String call() {
    _n++;
    return overrides[_n] ?? 'id-$_n';
  }
}

void main() {
  late AppDatabase db;
  late _Ids ids;
  late SaleWriter writer;
  final soldAt = DateTime.utc(2026, 10, 14, 9, 30);

  setUp(() async {
    db = openTestDatabase();
    ids = _Ids();
    writer = SaleWriter(
      db,
      deviceNumber: 3,
      newId: ids.call,
      now: () => soldAt,
    );
    await db
        .into(db.shifts)
        .insert(
          ShiftsCompanion.insert(
            id: shiftId,
            storeId: 'store-1',
            deviceId: 'device-3',
            openedBy: cashier,
            openedAt: soldAt,
            openingCashTiyin: 0,
          ),
        );
  });
  tearDown(() => db.close());

  const bread = SaleLineInput(
    productId: 'bread',
    name: 'Non',
    barcode: '4780001000012',
    qtyMilli: 2000,
    priceTiyin: 500000,
    costTiyin: 400000,
  );
  const sugar = SaleLineInput(
    productId: 'sugar',
    name: 'Shakar',
    qtyMilli: 1250,
    priceTiyin: 1450000,
    costTiyin: 1200000,
    discountTiyin: 2500,
  );

  Future<Map<String, int>> counts() async => {
    for (final table in <TableInfo<Table, Object?>>[
      db.sales,
      db.saleItems,
      db.salePayments,
      db.stockMovements,
      db.debtEntries,
      db.outboxEvents,
      db.docCounters,
    ])
      table.actualTableName: (await db.select(table).get()).length,
  };

  test('cash sale writes everything in one go', () async {
    // 2 × 5 000 = 10 000; 1,250 × 14 500 = 18 125 − 25 = 18 100 so'm.
    const input = CompletedSaleInput(
      shiftId: shiftId,
      cashierId: cashier,
      storeId: 'store-1',
      lines: [bread, sugar],
      discountTiyin: 10000,
      payments: [
        SalePaymentInput.cash(amountTiyin: 2800000, receivedTiyin: 3000000),
      ],
    );
    expect(input.subtotalTiyin, 2810000);
    expect(input.totalTiyin, 2800000);

    final sale = await writer.complete(input);
    expect(sale.number, 'D3-000001');

    final row = await db.select(db.sales).getSingle();
    expect(row.id, sale.id);
    expect(row.totalTiyin, 2800000);
    expect(row.status, 'completed');
    expect(row.soldAt.isAtSameMomentAs(soldAt), isTrue);

    final items = await (db.select(
      db.saleItems,
    )..orderBy([(t) => OrderingTerm(expression: t.position)])).get();
    expect(items.map((i) => i.totalTiyin), [1000000, 1810000]);

    final payment = await db.select(db.salePayments).getSingle();
    expect(payment.changeTiyin, 200000);

    final moves = await db.select(db.stockMovements).get();
    expect(moves.map((m) => m.qtyMilli), unorderedEquals([-2000, -1250]));
    expect(moves.every((m) => m.refId == sale.id), isTrue);

    final event = await db.select(db.outboxEvents).getSingle();
    expect(event.type, OutboxEventType.saleCompleted);
    expect(event.status, OutboxStatus.pending);
    expect(moves.every((m) => m.outboxEventId == event.id), isTrue);
    final payload = jsonDecode(event.payload) as Map<String, dynamic>;
    expect(payload['id'], sale.id);
    expect(payload['number'], 'D3-000001');
    expect(payload['shift'], shiftId);
    expect(payload['sold_at'], '2026-10-14T09:30:00.000Z');
    expect(payload['subtotal_tiyin'], 2810000);
    expect(payload['total_tiyin'], 2800000);
    expect(payload.containsKey('customer'), isFalse);
    expect((payload['items'] as List).length, 2);
    expect((payload['payments'] as List).single, {
      'id': payment.id,
      'method': 'cash',
      'amount_tiyin': 2800000,
      'received_tiyin': 3000000,
      'change_tiyin': 200000,
    });

    expect(await db.select(db.debtEntries).get(), isEmpty);
  });

  test('receipt numbers are sequential per device', () async {
    const input = CompletedSaleInput(
      shiftId: shiftId,
      cashierId: cashier,
      lines: [bread],
      payments: [SalePaymentInput.card(amountTiyin: 1000000)],
    );
    expect((await writer.complete(input)).number, 'D3-000001');
    expect((await writer.complete(input)).number, 'D3-000002');
    expect((await writer.complete(input)).number, 'D3-000003');
  });

  test('debt sale adds a debt entry linked to the sale', () async {
    final sale = await writer.complete(
      const CompletedSaleInput(
        shiftId: shiftId,
        cashierId: cashier,
        customerId: 'customer-1',
        lines: [bread],
        payments: [
          SalePaymentInput.cash(amountTiyin: 400000, receivedTiyin: 400000),
          SalePaymentInput.debt(amountTiyin: 600000),
        ],
      ),
    );
    final debt = await db.select(db.debtEntries).getSingle();
    expect(debt.amountTiyin, 600000);
    expect(debt.customerId, 'customer-1');
    expect(debt.saleId, sale.id);
    expect(debt.type, 'sale');

    final row = await db.select(db.sales).getSingle();
    expect(row.debtEntryId, debt.id);
    final payload =
        jsonDecode((await db.select(db.outboxEvents).getSingle()).payload)
            as Map<String, dynamic>;
    expect(payload['debt_entry_id'], debt.id);
    expect(payload['customer'], 'customer-1');
  });

  group('validation (same rules as the server)', () {
    Future<void> expectInvalid(CompletedSaleInput input, String reason) async {
      await expectLater(
        writer.complete(input),
        throwsA(
          isA<InvalidSaleException>().having((e) => e.reason, 'reason', reason),
        ),
      );
      expect((await counts()).values.every((n) => n == 0), isTrue);
    }

    test('rejects bad input without writing anything', () async {
      await expectInvalid(
        const CompletedSaleInput(
          shiftId: shiftId,
          cashierId: cashier,
          lines: [],
          payments: [SalePaymentInput.card(amountTiyin: 1)],
        ),
        'no_items',
      );
      await expectInvalid(
        const CompletedSaleInput(
          shiftId: shiftId,
          cashierId: cashier,
          lines: [bread],
          payments: [SalePaymentInput.card(amountTiyin: 999999)],
        ),
        'payments_do_not_match_total',
      );
      await expectInvalid(
        const CompletedSaleInput(
          shiftId: shiftId,
          cashierId: cashier,
          lines: [bread],
          payments: [
            SalePaymentInput.cash(amountTiyin: 1000000, receivedTiyin: 500000),
          ],
        ),
        'received_less_than_amount',
      );
      await expectInvalid(
        const CompletedSaleInput(
          shiftId: shiftId,
          cashierId: cashier,
          lines: [bread],
          payments: [SalePaymentInput.debt(amountTiyin: 1000000)],
        ),
        'debt_requires_customer',
      );
      await expectInvalid(
        const CompletedSaleInput(
          shiftId: shiftId,
          cashierId: cashier,
          lines: [bread],
          discountTiyin: 2000000,
          payments: [SalePaymentInput.card(amountTiyin: 1)],
        ),
        'discount_out_of_range',
      );
    });
  });

  group('atomicity', () {
    test('failure in the middle rolls back the whole sale', () async {
      // 1: sale, 2: event, 3: item#1, 4: movement#1, 5: item#2 = item#1 ID
      // → PRIMARY KEY buziladi, sale va item#1 allaqachon yozilgan paytda.
      ids.overrides[5] = 'id-3';
      await expectLater(
        writer.complete(
          const CompletedSaleInput(
            shiftId: shiftId,
            cashierId: cashier,
            lines: [bread, bread],
            payments: [SalePaymentInput.card(amountTiyin: 2000000)],
          ),
        ),
        throwsA(isA<Exception>()),
      );
      expect(
        (await counts()).values.every((n) => n == 0),
        isTrue,
        reason: 'sale, items, movements, outbox and counter must be empty',
      );

      // Keyingi savdo raqami "yeyilmagan".
      ids.overrides.clear();
      final next = await writer.complete(
        const CompletedSaleInput(
          shiftId: shiftId,
          cashierId: cashier,
          lines: [bread],
          payments: [SalePaymentInput.card(amountTiyin: 1000000)],
        ),
      );
      expect(next.number, 'D3-000001');
    });

    test('foreign keys are enforced (unknown shift → nothing saved)', () async {
      await expectLater(
        writer.complete(
          const CompletedSaleInput(
            shiftId: 'missing-shift',
            cashierId: cashier,
            lines: [bread],
            payments: [SalePaymentInput.card(amountTiyin: 1000000)],
          ),
        ),
        throwsA(isA<Exception>()),
      );
      expect((await counts()).values.every((n) => n == 0), isTrue);
    });
  });

  test('pending event count stream follows the outbox', () async {
    final counts = <int>[];
    final sub = db.watchPendingEventCount().listen(counts.add);
    addTearDown(sub.cancel);
    await pumpEventQueue();
    await writer.complete(
      const CompletedSaleInput(
        shiftId: shiftId,
        cashierId: cashier,
        lines: [bread],
        payments: [SalePaymentInput.card(amountTiyin: 1000000)],
      ),
    );
    await pumpEventQueue();
    await db
        .update(db.outboxEvents)
        .write(
          const OutboxEventsCompanion(status: Value(OutboxStatus.sent)),
        );
    await pumpEventQueue();
    expect(counts, [0, 1, 0]);
  });
}
