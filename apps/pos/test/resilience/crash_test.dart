import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/data/catalog/product_editor.dart' show stockQuery;
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/data/sales/sale_writer.dart';

import '../helpers/sqlite.dart';

/// Elektr/jarayon o'limi: savdo tranzaksiyasi o'rtasida jarayon o'ladi.
/// SQLite (WAL, `synchronous=FULL`) — yo hammasi, yo hech narsa
/// (CLAUDE.md, 2-qoida; T-090).
void main() {
  late Directory dir;
  late String path;

  AppDatabase openFile() => AppDatabase(NativeDatabase(File(path)));

  Future<int> count(AppDatabase db, String table) async =>
      (await db.customSelect('SELECT COUNT(*) AS n FROM $table').getSingle())
          .read<int>('n');

  /// Bola jarayon: yozadi va `exit(3)` bilan o'ladi.
  Future<void> runChild(String mode, String saleId) async {
    final result = await Process.run(
      'dart',
      ['run', 'test/resilience/crash_child.dart', path, mode, saleId],
      runInShell: true,
    );
    expect(result.stdout, contains('written'), reason: '${result.stderr}');
    expect(result.exitCode, 3);
  }

  setUp(() async {
    setUpTestSqlite();
    dir = await Directory.systemTemp.createTemp('pos_crash_');
    path = '${dir.path}${Platform.pathSeparator}pos.sqlite';
    final db = openFile();
    await db.batch((b) {
      b
        ..insert(
          db.shifts,
          ShiftsCompanion.insert(
            id: 'shift-1',
            storeId: 'store-1',
            deviceId: 'device-1',
            openedBy: 'u',
            openedAt: DateTime.utc(2026, 10, 15, 4),
            openingCashTiyin: 0,
          ),
        )
        ..insert(
          db.products,
          ProductsCompanion.insert(
            id: 'bread',
            name: 'Non',
            unitId: 'pcs',
            sellPriceTiyin: 500000,
            costPriceTiyin: const Value(400000),
          ),
        );
    });
    await db.close();
  });

  tearDown(() async {
    try {
      await dir.delete(recursive: true);
    } on FileSystemException {
      // Windows: fayl hali band bo'lishi mumkin — temp papka.
    }
  });

  test(
    'process dies mid-transaction → no half sale, database intact',
    () async {
      await runChild('crash', 'sale-crash');

      final db = openFile();
      addTearDown(db.close);
      final check = await db.customSelect('PRAGMA integrity_check').getSingle();
      expect(check.data.values.single, 'ok');
      for (final table in [
        'sales',
        'sale_items',
        'stock_movements',
        'outbox_events',
      ]) {
        expect(await count(db, table), 0, reason: table);
      }

      // Ilova odatdagidek ishlashda davom etadi.
      final sale =
          await SaleWriter(
            db,
            deviceNumber: 1,
            now: () => DateTime.utc(2026, 10, 15, 6),
          ).complete(
            const CompletedSaleInput(
              shiftId: 'shift-1',
              cashierId: 'u',
              lines: [
                SaleLineInput(
                  productId: 'bread',
                  name: 'Non',
                  qtyMilli: 1000,
                  priceTiyin: 500000,
                  costTiyin: 400000,
                ),
              ],
              payments: [SalePaymentInput.card(amountTiyin: 500000)],
            ),
          );
      expect(sale.id, isNotEmpty);
      expect(await count(db, 'sales'), 1);
      expect(await count(db, 'outbox_events'), 1);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test(
    'process dies right after COMMIT → the sale survives (durability)',
    () async {
      await runChild('commit', 'sale-ok');

      final db = openFile();
      addTearDown(db.close);
      expect(await count(db, 'sales'), 1);
      expect(await count(db, 'sale_items'), 1);
      expect(await count(db, 'outbox_events'), 1);
      final stock = Map.fromEntries(await stockQuery(db).get());
      expect(stock['bread'], -1000);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
