import 'dart:convert';

import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/data/sales/sale_writer.dart';
import 'package:pos_app/data/shifts/shift_service.dart';
import 'package:pos_app/data/sync/outbox.dart';

import '../helpers/sqlite.dart';

void main() {
  late AppDatabase db;
  late ShiftService shifts;
  var now = DateTime.utc(2026, 10, 14, 8);

  setUp(() {
    db = openTestDatabase();
    now = DateTime.utc(2026, 10, 14, 8);
    shifts = ShiftService(db, now: () => now);
  });
  tearDown(() => db.close());

  Future<Shift> openShift({int cash = 10000000}) => shifts.open(
    deviceId: 'device-1',
    storeId: 'store-1',
    cashierId: 'cashier-1',
    openingCashTiyin: cash,
  );

  SaleLineInput line(int price) => SaleLineInput(
    productId: 'p',
    name: 'Tovar',
    qtyMilli: 1000,
    priceTiyin: price,
    costTiyin: 0,
  );

  Future<void> sell(
    String shiftId,
    List<SalePaymentInput> payments, {
    int price = 0,
    String? customer,
  }) async {
    final total = payments.fold(0, (s, p) => s + p.amountTiyin);
    await SaleWriter(db, deviceNumber: 1, now: () => now).complete(
      CompletedSaleInput(
        shiftId: shiftId,
        cashierId: 'cashier-1',
        customerId: customer,
        lines: [line(price == 0 ? total : price)],
        payments: payments,
      ),
    );
  }

  test('open writes the shift and shift.opened to the outbox', () async {
    final shift = await openShift();
    expect(shift.openedBy, 'cashier-1');
    expect(shift.closedAt, isNull);
    expect((await shifts.currentShift('device-1'))!.id, shift.id);

    final event = await db.select(db.outboxEvents).getSingle();
    expect(event.type, OutboxEventType.shiftOpened);
    expect(jsonDecode(event.payload), {
      'id': shift.id,
      'cashier': 'cashier-1',
      'opening_cash_tiyin': 10000000,
      'opened_at': '2026-10-14T08:00:00.000Z',
    });
  });

  test('only one open shift per device', () async {
    await openShift();
    await expectLater(openShift(), throwsA(isA<ShiftAlreadyOpenException>()));
    // Boshqa qurilmada — mumkin.
    await shifts.open(
      deviceId: 'device-2',
      storeId: 'store-1',
      cashierId: 'c',
      openingCashTiyin: 0,
    );
  });

  test('X report numbers match the sales, refunds and cash movements', () async {
    final shift = await openShift(); // 100 000 so'm
    // Naqd 50 000 (olingan 60 000), karta 30 000, aralash: naqd 5 000 + nasiya 15 000.
    await sell(shift.id, [
      const SalePaymentInput.cash(amountTiyin: 5000000, receivedTiyin: 6000000),
    ]);
    await sell(shift.id, [const SalePaymentInput.card(amountTiyin: 3000000)]);
    await sell(shift.id, [
      const SalePaymentInput.cash(amountTiyin: 500000, receivedTiyin: 500000),
      const SalePaymentInput.debt(amountTiyin: 1500000),
    ], customer: 'k1');

    final saleId = (await db.select(db.sales).get()).first.id;
    await db
        .into(db.refunds)
        .insert(
          RefundsCompanion.insert(
            id: 'r1',
            saleId: saleId,
            shiftId: shift.id,
            cashierId: 'cashier-1',
            method: 'cash',
            totalTiyin: 1000000,
            at: now,
          ),
        );
    await db
        .into(db.refunds)
        .insert(
          RefundsCompanion.insert(
            id: 'r2',
            saleId: saleId,
            shiftId: shift.id,
            cashierId: 'cashier-1',
            method: 'debt',
            totalTiyin: 200000,
            at: now,
          ),
        );
    for (final (id, type, amount) in [
      ('m1', 'in', 2000000),
      ('m2', 'out', 7000000),
    ]) {
      await db
          .into(db.cashMovements)
          .insert(
            CashMovementsCompanion.insert(
              id: id,
              shiftId: shift.id,
              type: type,
              amountTiyin: amount,
              byUserId: 'cashier-1',
              at: now,
            ),
          );
    }
    for (final (id, method, amount) in [
      ('d1', 'cash', -800000),
      ('d2', 'card', -300000),
    ]) {
      await db
          .into(db.debtEntries)
          .insert(
            DebtEntriesCompanion.insert(
              id: id,
              customerId: 'k1',
              amountTiyin: amount,
              type: 'payment',
              method: Value(method),
              shiftId: Value(shift.id),
              at: now,
            ),
          );
    }
    // Boshqa qurilma smenasi hisobga kirmaydi.
    final other = await shifts.open(
      deviceId: 'device-2',
      storeId: 'store-1',
      cashierId: 'c2',
      openingCashTiyin: 0,
    );
    await db
        .into(db.cashMovements)
        .insert(
          CashMovementsCompanion.insert(
            id: 'other',
            shiftId: other.id,
            type: 'in',
            amountTiyin: 999,
            byUserId: 'c2',
            at: now,
          ),
        );
    await sell(other.id, [const SalePaymentInput.card(amountTiyin: 777)]);

    final r = await shifts.report(shift.id);
    expect(r.isOpen, isTrue);
    expect(r.salesCount, 3);
    expect(r.salesTotal, 5000000 + 3000000 + 2000000);
    expect(r.paymentsCash, 5500000);
    expect(r.paymentsCard, 3000000);
    expect(r.paymentsDebt, 1500000);
    expect(r.refundsCount, 2);
    expect(r.refundsCash, 1000000);
    expect(r.refundsDebt, 200000);
    expect(r.cashIn, 2000000);
    expect(r.cashOut, 7000000);
    expect(r.debtPaymentsCash, 800000);
    expect(r.debtPaymentsCard, 300000);
    // 100 000 + 55 000 − 10 000 + 20 000 − 70 000 + 8 000 = 103 000 so'm
    expect(r.expectedCash, 10300000);
    expect(r.difference, isNull);
  });

  test(
    'close: counted vs expected, Z report frozen, shift.closed sent',
    () async {
      final shift = await openShift(cash: 1000000);
      await sell(shift.id, [
        const SalePaymentInput.cash(
          amountTiyin: 2500000,
          receivedTiyin: 3000000,
        ),
      ]);
      now = now.add(const Duration(hours: 9));

      final z = await shifts.close(
        shiftId: shift.id,
        closedBy: 'manager-1',
        countedCashTiyin: 3400000,
      );
      expect(z.isOpen, isFalse);
      expect(z.expectedCash, 3500000);
      expect(z.countedCash, 3400000);
      expect(z.difference, -100000); // 1 000 so'm kam
      expect(await shifts.currentShift('device-1'), isNull);

      final closed = await db.select(db.shifts).getSingle();
      expect(closed.closedBy, 'manager-1');
      expect(closed.expectedCashTiyin, 3500000);

      final events = await (db.select(
        db.outboxEvents,
      )..orderBy([(e) => OrderingTerm(expression: e.createdAt)])).get();
      expect(events.map((e) => e.type), [
        OutboxEventType.shiftOpened,
        OutboxEventType.saleCompleted,
        OutboxEventType.shiftClosed,
      ]);
      expect(jsonDecode(events.last.payload), {
        'id': shift.id,
        'closed_by': 'manager-1',
        'counted_cash_tiyin': 3400000,
        'closed_at': '2026-10-14T17:00:00.000Z',
      });

      // Yopilgandan keyin qo'shilgan narsa Z hisobotni o'zgartirmaydi.
      expect((await shifts.report(shift.id)).expectedCash, 3500000);
      await expectLater(
        shifts.close(shiftId: shift.id, closedBy: 'x', countedCashTiyin: 0),
        throwsA(isA<ShiftNotOpenException>()),
      );
    },
  );

  test('suggested opening cash = last counted cash', () async {
    expect(await shifts.suggestedOpeningCash('device-1'), 0);
    final first = await openShift(cash: 0);
    await shifts.close(
      shiftId: first.id,
      closedBy: 'c',
      countedCashTiyin: 4200000,
    );
    expect(await shifts.suggestedOpeningCash('device-1'), 4200000);
    expect(await shifts.suggestedOpeningCash('device-2'), 0);
  });

  test('negative amounts are rejected', () {
    expect(() => openShift(cash: -1), throwsArgumentError);
  });
}
