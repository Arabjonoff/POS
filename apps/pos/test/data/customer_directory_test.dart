import 'dart:convert';

import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/data/customers/customer_directory.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/data/sync/outbox.dart';

import '../helpers/sqlite.dart';

void main() {
  late AppDatabase db;
  late CustomerDirectory customers;

  setUp(() async {
    db = openTestDatabase();
    customers = CustomerDirectory(db);
    final at = DateTime.utc(2026, 10, 14);
    await db.batch((b) {
      b
        ..insertAll(db.customers, [
          CustomersCompanion.insert(
            id: 'c1',
            fullName: "Karimova O'g'iloy",
            phone: const Value('+998 90 123 45 67'),
            debtLimitTiyin: const Value(50000000),
            balanceTiyin: const Value(999),
          ),
          CustomersCompanion.insert(
            id: 'c2',
            fullName: 'Азиз Раҳимов',
            balanceTiyin: const Value(2000000),
          ),
          CustomersCompanion.insert(
            id: 'c3',
            fullName: "O'chirilgan",
            deletedAt: Value(at),
          ),
        ])
        ..insertAll(db.debtEntries, [
          DebtEntriesCompanion.insert(
            id: 'd1',
            customerId: 'c1',
            amountTiyin: 30000000,
            type: 'sale',
            at: at,
          ),
          DebtEntriesCompanion.insert(
            id: 'd2',
            customerId: 'c1',
            amountTiyin: -10000000,
            type: 'payment',
            at: at,
          ),
        ]);
    });
  });
  tearDown(() => db.close());

  test('balance is the ledger sum; no entries yet → server balance', () async {
    final all = await customers.all();
    expect(
      [for (final c in all) (c.id, c.balanceTiyin)],
      [
        ('c1', 20000000),
        ('c2', 2000000),
      ],
    );
  });

  test('debt limit: balance + amount ≤ limit; no limit → allowed', () async {
    final karimova = (await customers.byId('c1'))!;
    expect(karimova.availableTiyin, 30000000);
    expect(karimova.allowsDebt(30000000), isTrue);
    expect(karimova.allowsDebt(30000001), isFalse);
    expect((await customers.byId('c2'))!.allowsDebt(1 << 40), isTrue);
  });

  test('search by name in any script and by phone digits', () async {
    final all = await customers.all();
    List<String> ids(String q) => [
      for (final c in CustomerDirectory.filter(all, q)) c.id,
    ];
    expect(ids('ogiloy'), ['c1']);
    expect(ids('rahimov'), ['c2']);
    expect(ids('aziz'), ['c2']);
    expect(ids('123 45'), ['c1']);
    expect(ids(''), ['c1', 'c2']);
  });

  test('quick create writes the customer and customer.upserted', () async {
    final created = await customers.create(
      name: ' Dilnoza ',
      phone: '901112233',
      createdBy: 'cashier-1',
    );
    expect(created.name, 'Dilnoza');
    expect(created.limitTiyin, isNull);
    final row = await (db.select(
      db.customers,
    )..where((c) => c.id.equals(created.id))).getSingle();
    expect(row.phone, '+998901112233');
    final event = await db.select(db.outboxEvents).getSingle();
    expect(event.type, 'customer.upserted');
    expect(jsonDecode(event.payload), {
      'id': created.id,
      'full_name': 'Dilnoza',
      'phone': '+998901112233',
      'note': '',
      'by': 'cashier-1',
    });
  });

  group('opening balance (T-103)', () {
    Future<int> balanceOf(String id) async => (await customers.watchAll().first)
        .singleWhere((c) => c.id == id)
        .balanceTiyin;

    test(
      'debt: one opening entry + opening_balance in the same event',
      () async {
        final at = DateTime.utc(2026, 9, 1, 7);
        final created = await customers.create(
          name: 'Eski qarzdor',
          createdBy: 'cashier-1',
          opening: OpeningBalanceInput(amountTiyin: 15000000, at: at),
        );
        expect(created.balanceTiyin, 15000000);
        expect(await balanceOf(created.id), 15000000);
        final entry = await (db.select(
          db.debtEntries,
        )..where((e) => e.customerId.equals(created.id))).getSingle();
        expect(
          (entry.type, entry.amountTiyin, entry.at, entry.shiftId),
          ('opening', 15000000, at, null),
        );
        final event = await db.select(db.outboxEvents).getSingle();
        final payload = jsonDecode(event.payload) as Map<String, Object?>;
        expect(payload['by'], 'cashier-1');
        expect(payload['opening_balance'], {
          'id': entry.id,
          'direction': 'debt',
          'amount_tiyin': 15000000,
          'at': '2026-09-01T07:00:00.000Z',
        });
      },
    );

    test('credit: negative balance, approver is the author', () async {
      final created = await customers.create(
        name: 'Avansli',
        createdBy: 'cashier-1',
        opening: OpeningBalanceInput(
          amountTiyin: 5000000,
          at: DateTime.utc(2026, 10, 1),
          credit: true,
          approvedBy: 'manager-1',
        ),
      );
      expect(await balanceOf(created.id), -5000000);
      final payload =
          jsonDecode((await db.select(db.outboxEvents).getSingle()).payload)
              as Map<String, Object?>;
      expect(payload['by'], 'manager-1');
      expect((payload['opening_balance'] as Map)['direction'], 'credit');
    });

    test('editing never adds the opening balance again', () async {
      final created = await customers.create(
        name: 'Eski qarzdor',
        createdBy: 'cashier-1',
        opening: OpeningBalanceInput(
          amountTiyin: 100000,
          at: DateTime.utc(2026, 10, 1),
        ),
      );
      await customers.update(id: created.id, name: 'Yangi ism', by: 'm');
      expect(await balanceOf(created.id), 100000);
      final events = await db.select(db.outboxEvents).get();
      expect(
        jsonDecode(events.last.payload) as Map,
        isNot(contains('opening_balance')),
      );
    });

    test('zero or negative opening amount is refused', () async {
      expect(
        () => customers.create(
          name: 'X',
          createdBy: 'c',
          opening: OpeningBalanceInput(amountTiyin: 0, at: DateTime.utc(2026)),
        ),
        throwsArgumentError,
      );
      expect(await db.select(db.outboxEvents).get(), isEmpty);
    });
  });

  group('customer card (T-060)', () {
    test('pay debt: ledger entry, outbox, balance = sum of entries', () async {
      // c1: 300 000 − 100 000 = 200 000.
      await customers.payDebt(
        customerId: 'c1',
        amountTiyin: 5000000,
        method: 'cash',
        by: 'cashier-1',
        shiftId: 'shift-1',
      );
      final entries = await (db.select(
        db.debtEntries,
      )..where((d) => d.customerId.equals('c1'))).get();
      final sum = entries.fold<int>(0, (s, e) => s + e.amountTiyin);
      expect((await customers.byId('c1'))!.balanceTiyin, sum);
      expect(sum, 15000000);
      final payment = entries.firstWhere((e) => e.amountTiyin == -5000000);
      expect(
        (payment.type, payment.method, payment.shiftId),
        (
          'payment',
          'cash',
          'shift-1',
        ),
      );
      final event = await (db.select(
        db.outboxEvents,
      )..where((e) => e.type.equals(OutboxEventType.debtPaid))).getSingle();
      final payload = jsonDecode(event.payload) as Map<String, Object?>;
      expect(payload['id'], payment.id);
      expect(payload['customer'], 'c1');
      expect(payload['amount_tiyin'], 5000000);
      expect(payload['method'], 'cash');
      expect(payload['shift'], 'shift-1');
      expect(payload['by'], 'cashier-1');
    });

    test('paying more than the debt is refused; nothing written', () async {
      await expectLater(
        customers.payDebt(
          customerId: 'c1',
          amountTiyin: 20000001,
          method: 'card',
          by: 'c',
        ),
        throwsA(
          isA<PaymentExceedsDebtException>().having(
            (e) => e.balanceTiyin,
            'balance',
            20000000,
          ),
        ),
      );
      expect(await db.select(db.outboxEvents).get(), isEmpty);
      expect(
        () => customers.payDebt(
          customerId: 'c1',
          amountTiyin: 100,
          method: 'bonus',
          by: 'c',
        ),
        throwsArgumentError,
      );
    });

    test('history newest first; details', () async {
      await customers.payDebt(
        customerId: 'c1',
        amountTiyin: 100,
        method: 'card',
        by: 'c',
      );
      final history = await customers.watchHistory('c1').first;
      expect(history.first.type, 'payment');
      expect(history.first.method, 'card');
      expect(history.map((h) => h.id), containsAll(['d1', 'd2']));
      final d = (await customers.details('c1'))!;
      expect(
        (d.name, d.limitTiyin, d.balanceTiyin),
        (
          "Karimova O'g'iloy",
          50000000,
          19999900,
        ),
      );
      expect(await customers.details('c3'), isNull);
    });

    test('update: limit only in the payload when changed', () async {
      await customers.update(
        id: 'c2',
        name: 'Aziz',
        phone: '+998901112233',
        by: 'c',
      );
      await customers.update(
        id: 'c2',
        name: 'Aziz',
        by: 'manager-1',
        changeLimit: true,
        limitTiyin: 10000000,
      );
      final events = await (db.select(
        db.outboxEvents,
      )..where((e) => e.type.equals(OutboxEventType.customerUpserted))).get();
      final payloads = [
        for (final e in events) jsonDecode(e.payload) as Map<String, Object?>,
      ];
      expect(payloads.first.containsKey('debt_limit_tiyin'), isFalse);
      expect(payloads.first['phone'], '+998901112233');
      expect(payloads.last['debt_limit_tiyin'], 10000000);
      expect(payloads.last['by'], 'manager-1');
      final d = (await customers.details('c2'))!;
      expect((d.name, d.limitTiyin), ('Aziz', 10000000));
    });
  });
}
