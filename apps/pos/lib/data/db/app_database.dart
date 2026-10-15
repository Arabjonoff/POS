import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/data/db/app_database.steps.dart';
import 'package:pos_app/data/db/tables/document_tables.dart';
import 'package:pos_app/data/db/tables/reference_tables.dart';
import 'package:pos_app/data/db/tables/sync_tables.dart';

export 'package:pos_app/data/db/tables/document_tables.dart';
export 'package:pos_app/data/db/tables/reference_tables.dart';
export 'package:pos_app/data/db/tables/sync_tables.dart';

part 'app_database.g.dart';

/// Kassaning lokal bazasi (`docs/specs/data-model.md`, `sync.md`).
/// Savdo, kirim, qarz — avval shu yerda (bitta tranzaksiya + outbox),
/// keyin server.
@DriftDatabase(
  tables: [
    LocalSettings,
    // Ma'lumotnomalar (pull)
    Stores,
    StaffUsers,
    Units,
    Categories,
    Products,
    ProductBarcodes,
    Customers,
    Suppliers,
    ProductStock,
    DebtEntries,
    // Hujjatlar
    Shifts,
    Sales,
    SaleItems,
    SalePayments,
    Refunds,
    RefundItems,
    CashMovements,
    StockReceipts,
    StockReceiptItems,
    InventoryCounts,
    InventoryCountItems,
    StockMovements,
    // Sinxron
    OutboxEvents,
    SyncState,
    CartDrafts,
    DocCounters,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// Qurilmadagi doimiy baza fayli (`pos.sqlite`).
  factory AppDatabase.open() => AppDatabase(driftDatabase(name: 'pos'));

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: _upgrade,
    beforeOpen: (details) async {
      // Elektr o'chsa ham commit qilingan savdo yo'qolmasin: WAL + FULL.
      await customStatement('PRAGMA journal_mode = WAL');
      await customStatement('PRAGMA synchronous = FULL');
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  Future<String?> readSetting(String key) async {
    final row = await (select(
      localSettings,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> writeSetting(String key, String value) {
    return into(
      localSettings,
    ).insertOnConflictUpdate(LocalSetting(key: key, value: value));
  }
}

/// Sxema migratsiyalari. Har versiya — `drift_schemas/` dagi suratga
/// nisbatan (`dart run drift_dev make-migrations`), joriy jadval sinflariga
/// emas. Testlar: `test/drift/app_database/`.
extension _Migrations on GeneratedDatabase {
  OnUpgrade get _upgrade => stepByStep(
    // v2: do'kon qatlami, hujjatlar va sinxron jadvallari (T-032).
    from1To2: (m, schema) async {
      for (final entity in schema.entities) {
        if (entity == schema.localSettings) continue;
        await m.create(entity);
      }
    },
    // v3: ochiq savatda chek chegirmasi (T-042).
    from2To3: (m, schema) async {
      await m.addColumn(schema.cartDrafts, schema.cartDrafts.discountJson);
    },
    // v4: kirimni tuzatish va bekor qilish (T-102).
    from3To4: (m, schema) async {
      await m.addColumn(schema.stockReceipts, schema.stockReceipts.correctsId);
      await m.addColumn(schema.stockReceipts, schema.stockReceipts.reversesId);
    },
    // v5: chek rekvizitlari (T-104b).
    from4To5: (m, schema) async {
      await m.addColumn(schema.stores, schema.stores.legalName);
      await m.addColumn(schema.stores, schema.stores.tin);
      await m.addColumn(schema.stores, schema.stores.receiptLogo);
      await m.addColumn(schema.stores, schema.stores.receiptOptions);
    },
  );
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.open();
  ref.onDispose(db.close);
  return db;
});
