import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/app/session/pin_gate.dart';
import 'package:pos_app/data/customers/customer_directory.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_ui/pos_ui.dart';

import '../helpers/keyboard.dart';
import '../helpers/pump_app.dart';
import '../helpers/sqlite.dart';

String som(int amount) => PosFormat.money(amount * 100, currency: "so'm");

late AppDatabase _db;

Future<void> open(WidgetTester tester) async {
  _db = openTestDatabase();
  addTearDown(_db.close);
  final at = DateTime.utc(2026, 10, 14, 7);
  await _db.batch((b) {
    b
      ..insertAll(_db.customers, [
        CustomersCompanion.insert(
          id: 'c1',
          fullName: 'Karimova Dilnoza',
          phone: const Value('+998 90 123 45 67'),
          debtLimitTiyin: const Value(50000000),
        ),
        CustomersCompanion.insert(id: 'c2', fullName: 'Aziz aka'),
        CustomersCompanion.insert(id: 'c3', fullName: 'Olim'),
      ])
      ..insertAll(_db.debtEntries, [
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
          method: const Value('cash'),
          at: at.add(const Duration(hours: 1)),
        ),
        DebtEntriesCompanion.insert(
          id: 'd3',
          customerId: 'c3',
          amountTiyin: 5000000,
          type: 'sale',
          at: at,
        ),
      ])
      ..insert(
        _db.staffUsers,
        StaffUsersCompanion.insert(
          id: 'manager-1',
          fullName: 'Bobur',
          role: 'manager',
          pinHash: const Value('hash'),
        ),
      );
  });
  await pumpPosApp(
    tester,
    db: _db,
    overrides: <Override>[
      pinGateProvider.overrideWith(
        (ref) => PinGate(
          ref.watch(appDatabaseProvider),
          verify: (pin, _) async => pin == '1234',
        ),
      ),
    ],
  );
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(LogicalKeyboardKey.digit4);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pumpAndSettle();
}

Future<void> tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<int> balance(String id) async =>
    (await CustomerDirectory(_db).byId(id))!.balanceTiyin;

Future<int> ledger(String id) async {
  final rows = await (_db.select(
    _db.debtEntries,
  )..where((d) => d.customerId.equals(id))).get();
  return rows.fold<int>(0, (s, e) => s + e.amountTiyin);
}

void main() {
  testWidgets('debtors first; search; debtors filter; total debt', (
    tester,
  ) async {
    await open(tester);
    final names = [
      for (final w in tester.widgetList<Text>(
        find.descendant(
          of: find.byType(PosCard),
          matching: find.byType(Text),
        ),
      ))
        w.data,
    ];
    expect(
      names.where((n) => ['Karimova Dilnoza', 'Olim', 'Aziz aka'].contains(n)),
      ['Karimova Dilnoza', 'Olim', 'Aziz aka'],
    );
    expect(find.text('Jami qarz: ${som(250000)}'), findsOneWidget);

    await tap(tester, find.byKey(const ValueKey('customers-debtors')));
    expect(find.text('Aziz aka'), findsNothing);
    await tester.enterText(
      find.byKey(const ValueKey('customers-search')),
      'karim',
    );
    await tester.pumpAndSettle();
    expect(find.text('Karimova Dilnoza'), findsOneWidget);
    expect(find.text('Olim'), findsNothing);
  });

  testWidgets('card: pay part, then full; balance = ledger sum', (
    tester,
  ) async {
    await open(tester);
    await tap(tester, find.byKey(const ValueKey('customer-c1')));
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('customer-balance')),
        matching: find.text(som(200000)),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Nasiyaga savdo'), findsOneWidget);

    await tap(tester, find.byKey(const ValueKey('customer-pay')));
    await typeSlowly(tester, '300000');
    await tap(tester, find.byKey(const ValueKey('debt-confirm')));
    expect(find.text("Qarzdan ko'p bo'lmasin: ${som(200000)}"), findsOneWidget);
    await tap(tester, find.byKey(const ValueKey('debt-full')));
    await tap(tester, find.byKey(const ValueKey('debt-method-card')));
    await tester.tap(find.text('3'));
    await tester.pumpAndSettle();
    // "To'liq" dan keyin klaviatura — 200 000 ga 3 qo'shilmasin: qaytadan.
    await tap(tester, find.byKey(const ValueKey('debt-full')));
    await tap(tester, find.byKey(const ValueKey('debt-confirm')));
    expect(
      find.text('${som(200000)} qabul qilindi · Qolgan qarz: ${som(0)}'),
      findsOneWidget,
    );
    expect(await balance('c1'), 0);
    expect(await ledger('c1'), 0);
    expect(find.byKey(const ValueKey('customer-pay')), findsNothing);
    final payment = await (_db.select(
      _db.debtEntries,
    )..where((d) => d.amountTiyin.equals(-20000000))).getSingle();
    expect(payment.method, 'card');
  });

  testWidgets('partial payment by keypad', (tester) async {
    await open(tester);
    await tap(tester, find.byKey(const ValueKey('customer-c3')));
    await tap(tester, find.byKey(const ValueKey('customer-pay')));
    await typeSlowly(tester, '20000');
    await press(tester, LogicalKeyboardKey.enter);
    expect(await balance('c3'), 3000000);
    expect(await ledger('c3'), 3000000);
  });

  testWidgets('edit: name freely; limit needs a manager PIN', (tester) async {
    await open(tester);
    await tap(tester, find.byKey(const ValueKey('customer-c2')));
    await tap(tester, find.byKey(const ValueKey('customer-edit')));
    await tester.enterText(
      find.byKey(const ValueKey('customer-name')),
      'Aziz Rahimov',
    );
    await tap(tester, find.byKey(const ValueKey('customer-save')));
    expect(find.text('Tasdiqlash kerak'), findsNothing);
    expect(find.text('Aziz Rahimov'), findsOneWidget);

    await tap(tester, find.byKey(const ValueKey('customer-edit')));
    await tester.enterText(
      find.byKey(const ValueKey('customer-limit')),
      '100000',
    );
    await tap(tester, find.byKey(const ValueKey('customer-save')));
    expect(find.text('Tasdiqlash kerak'), findsOneWidget);
    await tester.tap(find.text('Bobur'));
    await tester.pumpAndSettle();
    await typeSlowly(tester, '1234');
    await press(tester, LogicalKeyboardKey.enter);
    final c2 = await (_db.select(
      _db.customers,
    )..where((c) => c.id.equals('c2'))).getSingle();
    expect((c2.fullName, c2.debtLimitTiyin), ('Aziz Rahimov', 10000000));
    expect(find.text('Limit: ${som(100000)}'), findsOneWidget);
  });

  testWidgets('new customer opens its card', (tester) async {
    await open(tester);
    await tap(tester, find.byKey(const ValueKey('customers-add')));
    await tester.enterText(
      find.byKey(const ValueKey('new-customer-name')),
      'Yangi Xaridor',
    );
    await tap(tester, find.byKey(const ValueKey('new-customer-save')));
    expect(find.text('Yangi Xaridor'), findsOneWidget);
    expect(find.byKey(const ValueKey('customer-balance')), findsOneWidget);
  });

  testWidgets('new customer: phone is checked and saved as +998…', (
    tester,
  ) async {
    await open(tester);
    await tap(tester, find.byKey(const ValueKey('customers-add')));
    await tester.enterText(
      find.byKey(const ValueKey('new-customer-name')),
      'Telefonli',
    );
    final phone = find.descendant(
      of: find.byType(PosDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(phone.at(1), '12345');
    await tap(tester, find.byKey(const ValueKey('new-customer-save')));
    expect(find.text("Raqam noto'g'ri. Masalan: 90 123 45 67"), findsOneWidget);

    await tester.enterText(phone.at(1), '90 123 45 67');
    await tap(tester, find.byKey(const ValueKey('new-customer-save')));
    final saved = await (_db.select(
      _db.customers,
    )..where((c) => c.fullName.equals('Telefonli'))).getSingle();
    expect(saved.phone, '+998901234567');
  });

  group('opening balance (T-103)', openingTests);
}

void openingTests() {
  Future<void> fillNew(WidgetTester tester, String name) async {
    await tap(tester, find.byKey(const ValueKey('customers-add')));
    await tester.enterText(
      find.byKey(const ValueKey('new-customer-name')),
      name,
    );
  }

  testWidgets('debt opening: amount required, card shows debt and history', (
    tester,
  ) async {
    await open(tester);
    await fillNew(tester, 'Eski qarzdor');
    await tap(tester, find.byKey(const ValueKey('opening-debt')));
    expect(
      find.text(
        "Mijoz do'konga shu summani qarzdor (masalan, eski daftardan).",
      ),
      findsOneWidget,
    );
    // Summasiz saqlab bo'lmaydi.
    await tap(tester, find.byKey(const ValueKey('new-customer-save')));
    expect(find.text('Summani kiriting (0 dan katta)'), findsOneWidget);

    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('new-customer-opening-amount')),
        matching: find.byType(TextField),
      ),
      '1500000',
    );
    await tester.pumpAndSettle();
    // Mingliklar ajratiladi — katta summani tekshirish oson.
    expect(find.text('1 500 000'), findsOneWidget);
    await tap(tester, find.byKey(const ValueKey('new-customer-save')));

    expect(find.text('Eski qarzdor'), findsWidgets);
    expect(find.textContaining("Boshlang'ich qarz"), findsOneWidget);
    final created = await (_db.select(
      _db.customers,
    )..where((c) => c.fullName.equals('Eski qarzdor'))).getSingle();
    expect(await ledger(created.id), 150000000);
  });

  testWidgets('credit opening by a cashier needs a manager PIN', (
    tester,
  ) async {
    await open(tester);
    await fillNew(tester, 'Avansli');
    await tap(tester, find.byKey(const ValueKey('opening-credit')));
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('new-customer-opening-amount')),
        matching: find.byType(TextField),
      ),
      '50000',
    );
    await tap(tester, find.byKey(const ValueKey('new-customer-save')));
    expect(find.text('Tasdiqlash kerak'), findsOneWidget);
    await tester.tap(find.text('Bobur'));
    await tester.pumpAndSettle();
    await typeSlowly(tester, '1234');
    await press(tester, LogicalKeyboardKey.enter);

    // Kartada: "Mijoz haqi (avans)" va musbat summa; to'lov tugmasi yo'q.
    expect(find.text('Mijoz haqi (avans)'), findsOneWidget);
    expect(find.text(som(50000)), findsWidgets);
    expect(find.byKey(const ValueKey('customer-pay')), findsNothing);
    final created = await (_db.select(
      _db.customers,
    )..where((c) => c.fullName.equals('Avansli'))).getSingle();
    expect(await ledger(created.id), -5000000);
  });

  testWidgets('no opening: works exactly as before', (tester) async {
    await open(tester);
    await fillNew(tester, 'Oddiy');
    await tap(tester, find.byKey(const ValueKey('new-customer-save')));
    final created = await (_db.select(
      _db.customers,
    )..where((c) => c.fullName.equals('Oddiy'))).getSingle();
    expect(await ledger(created.id), 0);
    expect(find.text('Tasdiqlash kerak'), findsNothing);
  });
}
