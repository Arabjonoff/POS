import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/data/customers/customer_directory.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/data/refunds/refund_calculator.dart';
import 'package:pos_app/data/refunds/refund_writer.dart';
import 'package:pos_app/data/refunds/sale_lookup.dart';
import 'package:pos_app/data/sales/sale_writer.dart';
import 'package:pos_app/features/pos/cart/cart.dart';
import 'package:pos_app/features/pos/payment/checkout.dart';
import 'package:pos_app/features/pos/payment/payment_draft.dart';

import '../helpers/catalog_seed.dart';
import '../helpers/sqlite.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = openTestDatabase();
    await seedCatalog(db);
    await db
        .into(db.customers)
        .insert(CustomersCompanion.insert(id: 'c1', fullName: 'Karimova'));
    await db
        .into(db.shifts)
        .insert(
          ShiftsCompanion.insert(
            id: 'shift-1',
            storeId: 'store-1',
            deviceId: 'device-1',
            openedBy: 'cashier-1',
            openedAt: DateTime.utc(2026, 10, 15, 8),
            openingCashTiyin: 0,
          ),
        );
  });
  tearDown(() => db.close());

  /// 2 × Non (4 000) + 1,250 kg Olma (15 000), chek chegirmasi 750.
  Future<String> sell({PayMode mode = PayMode.cash}) async {
    const cart = Cart(
      id: 'cart',
      slot: 0,
      discount: Discount.amount(75000),
      lines: [
        CartLine(
          id: 'l1',
          productId: 'p-non',
          name: 'Non issiq',
          unit: 'pcs',
          qtyMilli: 2000,
          priceTiyin: 400000,
          costTiyin: 300000,
        ),
        CartLine(
          id: 'l2',
          productId: 'p-olma',
          name: 'Olma qizil',
          unit: 'kg',
          weighted: true,
          qtyMilli: 1250,
          priceTiyin: 1500000,
          costTiyin: 1000000,
        ),
      ],
    );
    final done = await Checkout(SaleWriter(db, deviceNumber: 3)).complete(
      cart: cart,
      payment: PaymentDraft(
        totalTiyin: cart.totalTiyin,
        mode: mode,
        customerId: mode == PayMode.debt ? 'c1' : null,
      ),
      shiftId: 'shift-1',
      cashierId: 'cashier-1',
    );
    return done.sale.id;
  }

  Future<int> stock(String productId) async {
    final rows = await (db.select(
      db.stockMovements,
    )..where((m) => m.productId.equals(productId))).get();
    return rows.fold<int>(0, (s, m) => s + m.qtyMilli);
  }

  Future<RecordedRefund> refund(
    String saleId,
    Map<String, int> Function(RefundableSale) pick, {
    RefundMethod method = RefundMethod.cash,
  }) async {
    final sale = (await SaleLookup(db).refundable(saleId))!;
    return RefundWriter(db).record(
      sale: sale,
      quote: RefundQuote.of(sale, pick(sale)),
      method: method,
      shiftId: 'shift-1',
      cashierId: 'cashier-1',
      reason: 'Sifatsiz',
      approvedBy: 'manager-1',
    );
  }

  test('partial refund: rows, stock back, status, outbox payload', () async {
    final saleId = await sell();
    final sale = (await SaleLookup(db).refundable(saleId))!;
    expect(sale.totalTiyin, 2600000);
    expect(sale.items.map((i) => i.unit), ['pcs', 'kg']);

    final done = await refund(saleId, (s) => {s.items.first.saleItemId: 1000});
    // 4 000 − 750 × 4 000 / 26 750 = 4 000 − 112,15 → 3 887,85 (half-up).
    expect(done.totalTiyin, 400000 - 11215);
    expect(await stock('p-non'), -1000);

    final saleRow = await (db.select(
      db.sales,
    )..where((s) => s.id.equals(saleId))).getSingle();
    expect(saleRow.status, 'partially_refunded');

    final event = await (db.select(
      db.outboxEvents,
    )..where((e) => e.type.equals('refund.created'))).getSingle();
    final payload = jsonDecode(event.payload) as Map<String, Object?>;
    expect(payload['sale'], saleId);
    expect(payload['shift'], 'shift-1');
    expect(payload['approved_by'], 'manager-1');
    expect(payload['reason'], 'Sifatsiz');
    expect(payload['method'], 'cash');
    expect(payload['total_tiyin'], done.totalTiyin);
    expect(payload.containsKey('debt_entry_id'), isFalse);
    final items = (payload['items']! as List).cast<Map<String, Object?>>();
    expect(items.single['qty_milli'], 1000);
    expect(items.single['total_tiyin'], 400000);

    // Qolgani: endi hammasi → savdo to'liq yopiladi, summa qoldiq bilan.
    final again = (await SaleLookup(db).refundable(saleId))!;
    expect(again.items.first.remainingQtyMilli, 1000);
    expect(again.refundedTiyin, done.totalTiyin);
    final rest = await refund(
      saleId,
      (s) => {for (final i in s.items) i.saleItemId: i.remainingQtyMilli},
    );
    expect(done.totalTiyin + rest.totalTiyin, 2600000);
    expect(await stock('p-non'), 0);
    expect(await stock('p-olma'), 0);
    final closed = await (db.select(
      db.sales,
    )..where((s) => s.id.equals(saleId))).getSingle();
    expect(closed.status, 'refunded');
  });

  test('debt refund lowers the customer debt', () async {
    final saleId = await sell(mode: PayMode.debt);
    expect((await CustomerDirectory(db).byId('c1'))!.balanceTiyin, 2600000);
    final done = await refund(
      saleId,
      (s) => {s.items.last.saleItemId: 1250},
      method: RefundMethod.debt,
    );
    final balance = (await CustomerDirectory(db).byId('c1'))!.balanceTiyin;
    expect(balance, 2600000 - done.totalTiyin);
    final entry = await (db.select(
      db.debtEntries,
    )..where((d) => d.type.equals('refund'))).getSingle();
    expect(entry.amountTiyin, -done.totalTiyin);
    expect(entry.saleId, saleId);
    final payload =
        jsonDecode(
              (await (db.select(
                    db.outboxEvents,
                  )..where((e) => e.type.equals('refund.created'))).getSingle())
                  .payload,
            )
            as Map<String, Object?>;
    expect(payload['debt_entry_id'], entry.id);
  });

  test('cash sale cannot be refunded to debt', () async {
    final saleId = await sell();
    await expectLater(
      refund(
        saleId,
        (s) => {s.items.first.saleItemId: 1000},
        method: RefundMethod.debt,
      ),
      throwsA(isA<InvalidRefundException>()),
    );
    expect(await db.select(db.refunds).get(), isEmpty);
  });

  test('atomic: a failing step leaves nothing behind', () async {
    final saleId = await sell();
    final sale = (await SaleLookup(db).refundable(saleId))!;
    await expectLater(
      RefundWriter(db).record(
        sale: sale,
        quote: RefundQuote.of(sale, {sale.items.first.saleItemId: 1000}),
        method: RefundMethod.cash,
        shiftId: 'no-such-shift',
        cashierId: 'cashier-1',
      ),
      throwsA(anything),
    );
    expect(await db.select(db.refunds).get(), isEmpty);
    expect(await db.select(db.refundItems).get(), isEmpty);
    expect(await stock('p-non'), -2000);
    final events = await db.select(db.outboxEvents).get();
    expect(events.map((e) => e.type), ['sale.completed']);
  });

  test('lookup: by number (any case), recent first', () async {
    final first = await sell();
    final second = await sell();
    final lookup = SaleLookup(db);
    expect(await lookup.idByNumber(' d3-000001 '), first);
    expect(await lookup.idByNumber('D3-999999'), isNull);
    final recent = await lookup.recent();
    expect(recent.map((s) => s.id), [second, first]);
  });
}
