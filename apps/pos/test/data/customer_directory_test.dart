import 'dart:convert';

import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/data/customers/customer_directory.dart';
import 'package:pos_app/data/db/app_database.dart';

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
    expect(row.phone, '901112233');
    final event = await db.select(db.outboxEvents).getSingle();
    expect(event.type, 'customer.upserted');
    expect(jsonDecode(event.payload), {
      'id': created.id,
      'full_name': 'Dilnoza',
      'phone': '901112233',
      'note': '',
      'by': 'cashier-1',
    });
  });
}
