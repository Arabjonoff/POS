import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/data/catalog/product_catalog.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_ui/pos_ui.dart';

import '../helpers/keyboard.dart';
import '../helpers/pump_app.dart';
import '../helpers/sqlite.dart';

/// 10 000 tovarli do'kon (T-090): katalog yuklash, qidiruv va kassa
/// ekranining ochilishi. Chegaralar CI uchun zaxira bilan; haqiqiy
/// natijalar `docs/resilience.md` da.
const int productCount = 10000;

const List<String> _words = [
  'Non',
  'Sut',
  'Choy',
  'Shakar',
  'Guruch',
  'Yog',
  'Olma',
  'Pishloq',
  'Makaron',
  'Tuxum',
];

/// To'g'ri EAN-13 (`478` + 9 xona + nazorat raqami).
String ean13(int i) {
  final base = '478${i.toString().padLeft(9, '0')}';
  var sum = 0;
  for (var k = 0; k < 12; k++) {
    sum += int.parse(base[k]) * (k.isEven ? 1 : 3);
  }
  return '$base${(10 - sum % 10) % 10}';
}

Future<void> seed(AppDatabase db) => db.batch((b) {
  b
    ..insert(db.units, UnitsCompanion.insert(id: 'pcs', code: 'pcs'))
    ..insert(
      db.categories,
      CategoriesCompanion.insert(id: 'c1', name: 'Oziq-ovqat'),
    )
    ..insertAll(db.products, [
      for (var i = 0; i < productCount; i++)
        ProductsCompanion.insert(
          id: 'p$i',
          name:
              '${_words[i % _words.length]} ${_words[(i ~/ 10) % _words.length]} $i',
          unitId: 'pcs',
          sellPriceTiyin: 100000 + i,
          categoryId: const Value('c1'),
          quickButton: Value(i < 24),
        ),
    ])
    ..insertAll(db.productBarcodes, [
      for (var i = 0; i < productCount; i++)
        ProductBarcodesCompanion.insert(
          barcode: ean13(i),
          productId: 'p$i',
          isPrimary: const Value(true),
        ),
    ]);
});

void main() {
  test('catalog of 10 000 products loads fast; search stays < 50 ms', () async {
    final db = openTestDatabase();
    addTearDown(db.close);
    await seed(db);

    await ProductCatalog.load(db); // isitish
    final load = Stopwatch()..start();
    final catalog = await ProductCatalog.load(db);
    load.stop();
    expect(catalog.search('9999').single.name, contains('9999'));

    final search = Stopwatch()..start();
    ['s', 'sh', 'sha', 'shak', 'shakar', 'shakar m'].forEach(catalog.search);
    search.stop();
    final perKeystroke = search.elapsedMicroseconds / 6 / 1000;

    // ignore: avoid_print — natija hujjatga yoziladi.
    print(
      'T-090 catalog: load ${load.elapsedMilliseconds} ms, '
      'search ${perKeystroke.toStringAsFixed(2)} ms/keystroke',
    );
    expect(load.elapsedMilliseconds, lessThan(2000));
    expect(perKeystroke, lessThan(50));
  });

  testWidgets('kassa opens with 10 000 products; scan finds the last one', (
    tester,
  ) async {
    final db = openTestDatabase();
    addTearDown(db.close);
    await tester.runAsync(() => seed(db));

    final open = Stopwatch()..start();
    await pumpPosApp(tester, db: db);
    open.stop();
    // ignore: avoid_print — natija hujjatga yoziladi.
    print('T-090 kassa open: ${open.elapsedMilliseconds} ms');
    expect(find.byType(PosSearchField), findsWidgets);
    expect(open.elapsedMilliseconds, lessThan(10000));

    await scanCode(tester, ean13(productCount - 1));
    expect(find.text('Tuxum Tuxum 9999'), findsWidgets);
  });
}
