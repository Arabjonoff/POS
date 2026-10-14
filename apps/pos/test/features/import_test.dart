import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/app/session/pin_gate.dart';
import 'package:pos_app/app/session/session.dart';
import 'package:pos_app/data/catalog/product_import.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/features/products/import_dialog.dart';

import '../helpers/catalog_seed.dart';
import '../helpers/fake_import.dart';
import '../helpers/keyboard.dart';
import '../helpers/pump_app.dart';
import '../helpers/sqlite.dart';

const StaffUser manager = StaffUser(
  id: 'manager-1',
  fullName: 'Bobur',
  role: 'manager',
  isActive: true,
  pinHash: 'hash',
);

late FakeImportApi api;
late FakeFiles files;
int refreshed = 0;

Future<void> open(WidgetTester tester, {bool asManager = false}) async {
  final db = openTestDatabase();
  addTearDown(db.close);
  await seedCatalog(db);
  await db.into(db.staffUsers).insert(manager);
  api = FakeImportApi();
  files = FakeFiles();
  refreshed = 0;
  await pumpPosApp(
    tester,
    db: db,
    session: asManager
        ? const Session(
            stage: SessionStage.unlocked,
            device: testDevice,
            user: manager,
          )
        : unlockedSession,
    overrides: <Override>[
      productImportApiProvider.overrideWithValue(api),
      importFilesProvider.overrideWithValue(files),
      refreshCatalogProvider.overrideWithValue(() async => refreshed++),
      pinGateProvider.overrideWith(
        (ref) => PinGate(
          ref.watch(appDatabaseProvider),
          verify: (pin, _) async => pin == '1234',
        ),
      ),
    ],
  );
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('products-import')));
  await tester.pumpAndSettle();
}

Finder get dialog => find.byType(ImportDialog);

Future<void> tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('pick → map (change a column) → check → apply (manager)', (
    tester,
  ) async {
    await open(tester, asManager: true);
    expect(dialog, findsOneWidget);
    await tap(tester, find.byKey(const ValueKey('import-pick')));
    expect(find.text('Ustunlarni moslang'), findsOneWidget);
    expect(find.text('tovarlar.xlsx · 120 ta qator'), findsOneWidget);

    // Shtrix-kod ustuni — "Kod".
    await tap(tester, find.byKey(const ValueKey('import-field-barcode')));
    await tap(tester, find.byKey(const ValueKey('import-column-1')));
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('import-field-barcode')),
        matching: find.text('Kod'),
      ),
      findsOneWidget,
    );

    await tap(tester, find.byKey(const ValueKey('import-check')));
    expect(api.checked![ImportField.barcode], 1);
    expect(
      find.text('Yangi: 100 · Yangilanadi: 18 · Xato: 2'),
      findsOneWidget,
    );
    expect(find.text('5-qator · Narx: son emas'), findsOneWidget);
    expect(
      find.text('9-qator · Shtrix-kod: shtrix-kod nazorat raqami xato'),
      findsOneWidget,
    );

    await tap(tester, find.byKey(const ValueKey('import-apply')));
    expect(find.text('Tasdiqlash kerak'), findsNothing);
    expect(api.appliedBy, 'manager-1');
    expect(refreshed, 1);
    expect(
      find.text("Qo'shildi: 100 · Yangilandi: 18 · O'tkazib yuborildi: 2"),
      findsOneWidget,
    );
    await tap(tester, find.byKey(const ValueKey('import-close')));
    expect(dialog, findsNothing);
    // Toast ham natijani aytadi.
    expect(
      find.text("Qo'shildi: 100 · Yangilandi: 18 · O'tkazib yuborildi: 2"),
      findsOneWidget,
    );
  });

  testWidgets('name and price columns are required', (tester) async {
    await open(tester, asManager: true);
    await tap(tester, find.byKey(const ValueKey('import-pick')));
    await tap(tester, find.byKey(const ValueKey('import-field-sell_price')));
    await tap(tester, find.byKey(const ValueKey('import-column-none')));
    await tap(tester, find.byKey(const ValueKey('import-check')));
    expect(find.text('Nom va narx ustunlarini tanlang'), findsOneWidget);
    expect(api.checked, isNull);
  });

  testWidgets('cashier: apply needs a manager PIN', (tester) async {
    await open(tester);
    await tap(tester, find.byKey(const ValueKey('import-pick')));
    await tap(tester, find.byKey(const ValueKey('import-check')));
    await tap(tester, find.byKey(const ValueKey('import-apply')));
    expect(find.text('Tasdiqlash kerak'), findsOneWidget);
    await tester.tap(find.text('Bobur'));
    await tester.pumpAndSettle();
    await typeSlowly(tester, '1234');
    await press(tester, LogicalKeyboardKey.enter);
    expect(api.appliedBy, 'manager-1');
  });

  testWidgets('offline: clear message, nothing uploaded', (tester) async {
    await open(tester);
    api.offline = true;
    await tap(tester, find.byKey(const ValueKey('import-pick')));
    expect(find.text('Import uchun internet kerak'), findsOneWidget);
    expect(find.text('Ustunlarni moslang'), findsNothing);
  });

  testWidgets('template is saved', (tester) async {
    await open(tester);
    await tap(tester, find.byKey(const ValueKey('import-template')));
    expect(files.savedName, 'tovarlar-shablon.xlsx');
    expect(find.text('Shablon saqlandi'), findsOneWidget);
  });
}
