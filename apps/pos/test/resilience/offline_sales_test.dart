import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/data/catalog/product_editor.dart' show stockQuery;
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/data/remote/api.dart';
import 'package:pos_app/data/sales/sale_writer.dart';
import 'package:pos_app/data/sync/outbox.dart';
import 'package:pos_app/data/sync/sync_engine.dart';

import '../helpers/fake_sync_server.dart';
import '../helpers/sqlite.dart';

/// Kun bo'yi internet yo'q: 500 savdo, keyin sinxron va push o'rtasida
/// uzilish (T-090). Hammasi aniq bir marta serverga yetadi.
void main() {
  test(
    '500 offline sales, connection drops mid-push → exactly 500, once',
    () async {
      // Haqiqiy fayl (WAL, synchronous=FULL) — yozish vaqti real bo'lsin.
      setUpTestSqlite();
      final dir = await Directory.systemTemp.createTemp('pos_offline_');
      final db = AppDatabase(NativeDatabase(File('${dir.path}/pos.sqlite')));
      addTearDown(() async {
        await db.close();
        try {
          await dir.delete(recursive: true);
        } on FileSystemException {
          // Windows: fayl hali band bo'lishi mumkin — temp papka.
        }
      });
      final server = FakeSyncServer()..stock['bread'] = 1000000;
      var now = DateTime.utc(2026, 10, 15, 4);
      final engine = SyncEngine(
        db,
        () async => deviceApi(server.http.dio, 'tok'),
        now: () => now,
      );
      await db.batch((b) {
        b
          ..insert(
            db.shifts,
            ShiftsCompanion.insert(
              id: 'shift-1',
              storeId: 'store-1',
              deviceId: 'device-1',
              openedBy: 'u',
              openedAt: now,
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
      await engine.syncOnce(); // boshlang'ich qoldiq: 1000 dona

      server.offline = true;
      final writer = SaleWriter(db, deviceNumber: 1, now: () => now);
      final write = Stopwatch()..start();
      for (var i = 0; i < 500; i++) {
        now = now.add(const Duration(seconds: 30));
        await writer.complete(
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
            payments: [
              SalePaymentInput.cash(amountTiyin: 500000, receivedTiyin: 500000),
            ],
          ),
        );
      }
      write.stop();
      expect((await engine.syncOnce()).pushed, 0);
      expect(Map.fromEntries(await stockQuery(db).get())['bread'], 500000);

      // Internet qaytdi, lekin birinchi paket javobi yo'qoladi.
      server
        ..offline = false
        ..loseNextResponse = true;
      now = now.add(const Duration(minutes: 10));
      final sync = Stopwatch()..start();
      await engine.syncOnce();
      for (var i = 0; i < 5; i++) {
        now = now.add(const Duration(minutes: 10));
        await engine.syncOnce();
      }
      sync.stop();

      expect(server.applied.length, 500);
      expect(server.stock['bread'], 500000);
      final pending = await (db.select(
        db.outboxEvents,
      )..where((e) => e.status.isNotValue(OutboxStatus.sent))).get();
      expect(pending, isEmpty);
      expect(Map.fromEntries(await stockQuery(db).get())['bread'], 500000);

      // ignore: avoid_print — natija hujjatga yoziladi.
      print(
        'T-090 500 sales: write ${(write.elapsedMicroseconds / 500 / 1000).toStringAsFixed(2)} ms/sale, '
        'sync ${sync.elapsedMilliseconds} ms (batches ${server.batchSizes})',
      );
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
