import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/app/session/pin_gate.dart';
import 'package:pos_app/data/customers/customer_directory.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/features/pos/cart/cart_controller.dart';
import 'package:pos_app/features/pos/payment/payment_dialog.dart';
import 'package:pos_ui/pos_ui.dart';

import '../helpers/catalog_seed.dart';
import '../helpers/keyboard.dart';
import '../helpers/pump_app.dart';
import '../helpers/sqlite.dart';

String som(int amount) => PosFormat.money(amount * 100, currency: "so'm");

late ProviderContainer _container;
late AppDatabase _db;

CartState get cart => _container.read(cartControllerProvider).requireValue;

/// Non issiq — 4 000, Coca-Cola — 14 000 (`catalog_seed.dart`).
const String non = '4780000000014';
const String cola = '5449000000996';

final Override fakePin = pinGateProvider.overrideWith(
  (ref) => PinGate(
    ref.watch(appDatabaseProvider),
    verify: (pin, _) async => pin == '1234',
  ),
);

Future<void> open(
  WidgetTester tester, {
  Size size = const Size(1440, 900),
}) async {
  _db = openTestDatabase();
  addTearDown(_db.close);
  await seedCatalog(_db);
  await _db
      .into(_db.customers)
      .insert(
        CustomersCompanion.insert(
          id: 'c1',
          fullName: 'Karimova Dilnoza',
          phone: const Value('+998901234567'),
          debtLimitTiyin: const Value(1000000),
        ),
      );
  await _db
      .into(_db.staffUsers)
      .insert(
        StaffUsersCompanion.insert(
          id: 'manager-1',
          fullName: 'Bobur',
          role: 'manager',
          pinHash: const Value('hash'),
        ),
      );
  final (c, _) = await pumpPosApp(
    tester,
    db: _db,
    size: size,
    overrides: [fakePin],
  );
  _container = c;
}

Future<List<Sale>> sales() => _db.select(_db.sales).get();

Future<Map<String, (int, int?, int)>> payments() async => {
  for (final p in await _db.select(_db.salePayments).get())
    p.method: (p.amountTiyin, p.receivedTiyin, p.changeTiyin),
};

Future<void> tapText(WidgetTester tester, String text) async {
  await tester.tap(find.text(text).last);
  await tester.pumpAndSettle();
}

Future<void> tapKey(WidgetTester tester, String key) async {
  await tester.tap(find.byKey(ValueKey(key)));
  await tester.pumpAndSettle();
}

Finder get dialog => find.byType(PaymentDialog);

Finder inDialog(String text) =>
    find.descendant(of: dialog, matching: find.text(text));

void main() {
  testWidgets('3 actions: scan → F12 → Enter records the sale', (
    tester,
  ) async {
    await open(tester);
    await scanCode(tester, non);
    await press(tester, LogicalKeyboardKey.f12);
    expect(dialog, findsOneWidget);
    await press(tester, LogicalKeyboardKey.enter);

    expect(dialog, findsNothing);
    final sale = (await sales()).single;
    expect(sale.totalTiyin, 400000);
    expect(sale.cashierId, 'cashier-1');
    expect(sale.shiftId, 'shift-test');
    expect(await payments(), {'cash': (400000, 400000, 0)});
    expect(cart.cart.isEmpty, isTrue);
    expect(find.text('Savdo yakunlandi'), findsOneWidget);
  });

  testWidgets('cash: quick 50 000 shows the change; message has it', (
    tester,
  ) async {
    await open(tester);
    await scanCode(tester, cola);
    await press(tester, LogicalKeyboardKey.f12);
    // Tez summalar: jamidan kichigi o'chiq yo'q (14 000 < 50 000).
    await tapText(tester, PosFormat.moneyAmount(5000000));
    expect(inDialog(som(36000)), findsOneWidget);
    await press(tester, LogicalKeyboardKey.enter);

    expect(await payments(), {'cash': (1400000, 5000000, 3600000)});
    expect(
      find.text('Savdo yakunlandi · Qaytim ${som(36000)}'),
      findsOneWidget,
    );
  });

  testWidgets('cash: typed amount; too little cannot be completed', (
    tester,
  ) async {
    await open(tester);
    await scanCode(tester, cola);
    await press(tester, LogicalKeyboardKey.f12);

    // "Aniq" ko'rsatilgan summa — birinchi raqam uni almashtiradi.
    await typeSlowly(tester, '10000');
    expect(inDialog('Yetmaydi'), findsOneWidget);
    expect(inDialog(som(4000)), findsOneWidget);
    await press(tester, LogicalKeyboardKey.enter);
    expect(await sales(), isEmpty);
    expect(dialog, findsOneWidget);

    // Backspace: 10 000 → 1 000 (yetmaydi 13 000).
    await press(tester, LogicalKeyboardKey.backspace);
    expect(inDialog(som(1000)), findsOneWidget);
    expect(inDialog(som(13000)), findsOneWidget);
    // "Aniq" → yana taklif; keyin 20 000 → qaytim 6 000.
    await tapText(tester, 'Aniq');
    await typeSlowly(tester, '20000');
    expect(inDialog(som(6000)), findsOneWidget);
    await press(tester, LogicalKeyboardKey.enter);
    expect(await payments(), {'cash': (1400000, 2000000, 600000)});
  });

  testWidgets('card: one tap', (tester) async {
    await open(tester);
    await scanCode(tester, non);
    await press(tester, LogicalKeyboardKey.f12);
    await tapKey(tester, 'pay-mode-card');
    expect(
      inDialog("Terminalda to'lovni o'tkazing, keyin tasdiqlang"),
      findsOneWidget,
    );
    await tapKey(tester, 'pay-complete');
    expect(await payments(), {'card': (400000, null, 0)});
    expect(cart.cart.isEmpty, isTrue);
  });

  testWidgets('debt within the limit: customer chosen, ledger entry', (
    tester,
  ) async {
    await open(tester);
    await scanCode(tester, non);
    await press(tester, LogicalKeyboardKey.f12);
    await tapKey(tester, 'pay-mode-debt');
    expect(inDialog('Mijozni tanlang'), findsOneWidget);
    expect(find.byKey(const ValueKey('pay-complete')), findsOneWidget);
    await tapText(tester, 'Karimova Dilnoza');
    expect(inDialog('Boshqa mijoz'), findsOneWidget);
    await press(tester, LogicalKeyboardKey.enter);

    final sale = (await sales()).single;
    expect(sale.customerId, 'c1');
    expect(sale.approvedBy, isNull);
    expect(await payments(), {'debt': (400000, null, 0)});
    final customer = await CustomerDirectory(_db).byId('c1');
    expect(customer!.balanceTiyin, 400000);
  });

  testWidgets('debt over the limit needs a manager PIN', (tester) async {
    await open(tester);
    // 14 000 > limit 10 000.
    await scanCode(tester, cola);
    await press(tester, LogicalKeyboardKey.f12);
    await tapKey(tester, 'pay-mode-debt');
    await tapText(tester, 'Karimova Dilnoza');
    expect(
      inDialog('Qarz limitdan oshadi — menejer yoki ega tasdiqlashi kerak'),
      findsOneWidget,
    );

    // Bekor qilinsa — savdo yo'q.
    await press(tester, LogicalKeyboardKey.enter);
    expect(find.text('Tasdiqlash kerak'), findsOneWidget);
    await press(tester, LogicalKeyboardKey.escape);
    expect(await sales(), isEmpty);
    expect(dialog, findsOneWidget);

    await press(tester, LogicalKeyboardKey.enter);
    await tapText(tester, 'Bobur');
    await typeSlowly(tester, '1234');
    await press(tester, LogicalKeyboardKey.enter);

    final sale = (await sales()).single;
    expect(sale.approvedBy, 'manager-1');
    expect(await payments(), {'debt': (1400000, null, 0)});
  });

  testWidgets('debt: a new customer is created on the spot', (tester) async {
    await open(tester);
    await scanCode(tester, non);
    await press(tester, LogicalKeyboardKey.f12);
    await tapKey(tester, 'pay-mode-debt');
    await tapText(tester, 'Yangi mijoz');
    await tester.enterText(
      find.descendant(of: dialog, matching: find.byType(TextField)).first,
      'Olim aka',
    );
    await tapText(tester, 'Saqlash');
    expect(inDialog('Olim aka'), findsOneWidget);
    await press(tester, LogicalKeyboardKey.enter);

    final sale = (await sales()).single;
    final created = (await CustomerDirectory(_db).all()).firstWhere(
      (c) => c.name == 'Olim aka',
    );
    expect(sale.customerId, created.id);
    expect(created.balanceTiyin, 400000);
  });

  testWidgets('mixed: card + debt, the rest in cash', (tester) async {
    await open(tester);
    await scanCode(tester, cola);
    await press(tester, LogicalKeyboardKey.f12);
    await tapKey(tester, 'pay-mode-mixed');
    await typeSlowly(tester, '4000');
    await tapKey(tester, 'pay-part-debt');
    await typeSlowly(tester, '5000');
    expect(inDialog('Naqd (qolgani)'), findsOneWidget);
    expect(inDialog(som(5000)), findsWidgets);
    // Nasiya qismi bor — mijoz kerak.
    await press(tester, LogicalKeyboardKey.enter);
    expect(inDialog('Mijozni tanlang'), findsWidgets);
    expect(await sales(), isEmpty);
    await tapText(tester, 'Karimova Dilnoza');
    await press(tester, LogicalKeyboardKey.enter);

    expect(await payments(), {
      'cash': (500000, 500000, 0),
      'card': (400000, null, 0),
      'debt': (500000, null, 0),
    });
  });

  testWidgets('mixed: parts above the total are rejected', (tester) async {
    await open(tester);
    await scanCode(tester, non);
    await press(tester, LogicalKeyboardKey.f12);
    await tapKey(tester, 'pay-mode-mixed');
    await typeSlowly(tester, '5000');
    await press(tester, LogicalKeyboardKey.enter);
    expect(inDialog('Karta va nasiya jamidan oshib ketdi'), findsOneWidget);
    expect(await sales(), isEmpty);
  });

  testWidgets('scanner is blocked while paying; Esc keeps the cart', (
    tester,
  ) async {
    await open(tester);
    await scanCode(tester, non);
    await press(tester, LogicalKeyboardKey.f12);
    await scanCode(tester, cola);

    expect(inDialog("Avval to'lovni yakunlang"), findsOneWidget);
    // Skaner Enter'i savdoni yakunlamagan, raqamlari summaga tushmagan.
    expect(dialog, findsOneWidget);
    expect(await sales(), isEmpty);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('pay-received')),
        matching: find.text(som(4000)),
      ),
      findsOneWidget,
    );
    expect(cart.cart.lines, hasLength(1));

    await press(tester, LogicalKeyboardKey.escape);
    expect(dialog, findsNothing);
    expect(cart.cart.lines, hasLength(1));
    // Fokus yana skanerda.
    await scanCode(tester, non);
    expect(cart.cart.lines.single.qtyMilli, 2000);
  });

  testWidgets('F4 puts a customer on the check; debt starts with them', (
    tester,
  ) async {
    await open(tester);
    await scanCode(tester, non);
    await press(tester, LogicalKeyboardKey.f4);
    expect(find.text('Chek mijozi'), findsOneWidget);
    await tapText(tester, 'Karimova Dilnoza');
    expect(cart.cart.customerId, 'c1');
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('cart-customer')),
        matching: find.text('Karimova Dilnoza'),
      ),
      findsOneWidget,
    );

    await press(tester, LogicalKeyboardKey.f12);
    await tapKey(tester, 'pay-mode-debt');
    expect(inDialog('Boshqa mijoz'), findsOneWidget);
    await press(tester, LogicalKeyboardKey.enter);
    expect((await sales()).single.customerId, 'c1');
  });

  testWidgets('phone: the dialog is a sheet and still completes', (
    tester,
  ) async {
    await open(tester, size: const Size(390, 844));
    await scanCode(tester, non);
    await tester.tap(find.text("To'lash"));
    await tester.pumpAndSettle();
    expect(dialog, findsOneWidget);
    await tapText(tester, PosFormat.moneyAmount(5000000));
    expect(inDialog(som(46000)), findsOneWidget);
    // Klaviatura yopiq — qaytim va "Yakunlash" aylantirmasdan ko'rinadi.
    expect(find.byType(PosNumericKeypad), findsNothing);
    final complete = find.byKey(const ValueKey('pay-complete'));
    expect(tester.getRect(complete).bottom, lessThan(844));

    // Summaga bosilsa — ekran klaviaturasi. 4 000 o'rniga 5 000 → qaytim 1 000.
    await tester.tap(find.byKey(const ValueKey('pay-received')));
    await tester.pumpAndSettle();
    expect(find.byType(PosNumericKeypad), findsOneWidget);
    // "Aniq" — taklif; birinchi raqam uni almashtiradi.
    await tapText(tester, 'Aniq');
    for (final key in ['5', '0', '0', '0']) {
      await tester.tap(
        find.descendant(
          of: find.byType(PosNumericKeypad),
          matching: find.text(key),
        ),
      );
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(inDialog(som(1000)), findsOneWidget);
    await tester.ensureVisible(complete);
    await tester.pumpAndSettle();
    await tester.tap(complete);
    await tester.pumpAndSettle();
    expect(await payments(), {'cash': (400000, 500000, 100000)});
  });
}
