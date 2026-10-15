import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:pos_api_client/pos_api_client.dart';
import 'package:pos_app/app/update/app_update.dart';
import 'package:pos_app/core/text/search_key.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/data/sync/server_features.dart';

/// Pull sahifasini lokal bazaga qo'llaydi (`docs/specs/sync.md`, `sync-api.md`).
/// Bitta sahifa — bitta tranzaksiya: o'zgarishlar + kursor + obuna holati
/// birga yoziladi (yarim qo'llangan sahifa bo'lmaydi). Konflikt: server g'olib.
class PullApplier {
  PullApplier(this._db, {DateTime Function()? now}) : _now = now ?? _clockNow;

  final AppDatabase _db;
  final DateTime Function() _now;

  Future<void> apply(PullResponse page) => _db.transaction(() async {
    for (final change in page.changes) {
      final data = change.data;
      if (change.op == OpEnum.upsert && data is Map<String, dynamic>) {
        await _upsert(change.entity, data);
      } else if (change.op == OpEnum.delete) {
        await _delete(change.entity, change.id);
      }
      // Noma'lum entity yoki op — eski kassa yangi serverda ham ishlasin.
    }
    await _saveState(page);
  });

  Future<void> _upsert(String entity, Map<String, dynamic> d) async {
    switch (entity) {
      case 'unit':
        await _db
            .into(_db.units)
            .insertOnConflictUpdate(
              UnitsCompanion.insert(
                id: _s(d['id']),
                code: _s(d['code']),
                name: Value(_s(d['name'])),
                isFractional: Value(d['is_fractional'] == true),
                deletedAt: const Value(null),
              ),
            );
      case 'category':
        await _db
            .into(_db.categories)
            .insertOnConflictUpdate(
              CategoriesCompanion.insert(
                id: _s(d['id']),
                name: _s(d['name']),
                parentId: Value(d['parent'] as String?),
                sort: Value(_i(d['sort'])),
                color: Value(_nullIfEmpty(d['color'])),
                deletedAt: const Value(null),
              ),
            );
      case 'product':
        await _upsertProduct(d);
      case 'supplier':
        await _db
            .into(_db.suppliers)
            .insertOnConflictUpdate(
              SuppliersCompanion.insert(
                id: _s(d['id']),
                name: _s(d['name']),
                phone: Value(_s(d['phone'])),
                note: Value(_s(d['note'])),
                deletedAt: const Value(null),
              ),
            );
      case 'customer':
        await _db
            .into(_db.customers)
            .insertOnConflictUpdate(
              CustomersCompanion.insert(
                id: _s(d['id']),
                fullName: _s(d['full_name']),
                phone: Value(_s(d['phone'])),
                note: Value(_s(d['note'])),
                debtLimitTiyin: Value(d['debt_limit_tiyin'] as int?),
                balanceTiyin: Value(_i(d['balance_tiyin'])),
                updatedAt: Value(_dt(d['updated_at'])),
                deletedAt: const Value(null),
              ),
            );
      case 'user':
        await _db
            .into(_db.staffUsers)
            .insertOnConflictUpdate(
              StaffUsersCompanion.insert(
                id: _s(d['id']),
                phone: Value(_nullIfEmpty(d['phone'])),
                fullName: _s(d['full_name']),
                role: _s(d['role']),
                isActive: Value(d['is_active'] != false),
                pinHash: Value(_nullIfEmpty(d['pin_hash'])),
              ),
            );
      case 'store':
        await _db
            .into(_db.stores)
            .insertOnConflictUpdate(
              StoresCompanion.insert(
                id: _s(d['id']),
                name: _s(d['name']),
                address: Value(_s(d['address'])),
                phone: Value(_s(d['phone'])),
                receiptHeader: Value(_s(d['receipt_header'])),
                receiptFooter: Value(_s(d['receipt_footer'])),
                // T-104b; eski server yubormaydi — standart qiymatlar.
                legalName: Value(_s(d['legal_name'])),
                tin: Value(_s(d['tin'])),
                receiptLogo: Value(_s(d['receipt_logo'])),
                receiptOptions: Value(
                  d['receipt_options'] is Map
                      ? jsonEncode(d['receipt_options'])
                      : '{}',
                ),
              ),
            );
      case 'debt_entry':
        await _db
            .into(_db.debtEntries)
            .insertOnConflictUpdate(
              DebtEntriesCompanion.insert(
                id: _s(d['id']),
                customerId: _s(d['customer']),
                amountTiyin: _i(d['amount_tiyin']),
                type: _s(d['type']),
                saleId: Value(d['sale_id'] as String?),
                method: Value(_nullIfEmpty(d['method'])),
                note: Value(_s(d['note'])),
                byUserId: Value(d['created_by'] as String?),
                at: _dt(d['at']) ?? _now(),
              ),
            );
      case 'stock':
        await _db
            .into(_db.productStock)
            .insertOnConflictUpdate(
              ProductStockCompanion.insert(
                productId: _s(d['product']),
                storeId: _s(d['store']),
                qtyMilli: _i(d['qty_milli']),
                updatedAt: _dt(d['updated_at']) ?? _now(),
              ),
            );
    }
  }

  Future<void> _upsertProduct(Map<String, dynamic> d) async {
    final id = _s(d['id']);
    final name = _s(d['name']);
    await _db
        .into(_db.products)
        .insertOnConflictUpdate(
          ProductsCompanion.insert(
            id: id,
            name: name,
            searchKey: Value(SearchKey.of(name)),
            categoryId: Value(d['category'] as String?),
            unitId: _s(d['unit']),
            sellPriceTiyin: _i(d['sell_price_tiyin']),
            costPriceTiyin: Value(_i(d['cost_price_tiyin'])),
            isWeighted: Value(d['is_weighted'] == true),
            pluCode: Value(_nullIfEmpty(d['plu_code'])),
            minStockMilli: Value(_i(d['min_stock_milli'])),
            ikpuCode: Value(_nullIfEmpty(d['ikpu_code'])),
            quickButton: Value(d['quick_button'] == true),
            isActive: Value(d['is_active'] != false),
            updatedAt: Value(_dt(d['updated_at'])),
            deletedAt: const Value(null),
          ),
        );
    // Shtrix-kodlar ro'yxati to'liq almashtiriladi (birinchisi — asosiy).
    await (_db.delete(
      _db.productBarcodes,
    )..where((t) => t.productId.equals(id))).go();
    final barcodes = (d['barcodes'] as List?)?.cast<String>() ?? const [];
    for (final (i, barcode) in barcodes.indexed) {
      await _db
          .into(_db.productBarcodes)
          .insertOnConflictUpdate(
            ProductBarcodesCompanion.insert(
              barcode: barcode,
              productId: id,
              isPrimary: Value(i == 0),
            ),
          );
    }
  }

  Future<void> _delete(String entity, String id) async {
    final now = Value(_now());
    switch (entity) {
      case 'unit':
        await (_db.update(_db.units)..where((t) => t.id.equals(id))).write(
          UnitsCompanion(deletedAt: now),
        );
      case 'category':
        await (_db.update(_db.categories)..where((t) => t.id.equals(id))).write(
          CategoriesCompanion(deletedAt: now),
        );
      case 'product':
        await (_db.update(_db.products)..where((t) => t.id.equals(id))).write(
          ProductsCompanion(deletedAt: now, isActive: const Value(false)),
        );
        await (_db.delete(
          _db.productBarcodes,
        )..where((t) => t.productId.equals(id))).go();
      case 'supplier':
        await (_db.update(_db.suppliers)..where((t) => t.id.equals(id))).write(
          SuppliersCompanion(deletedAt: now),
        );
      case 'customer':
        await (_db.update(_db.customers)..where((t) => t.id.equals(id))).write(
          CustomersCompanion(deletedAt: now),
        );
      case 'user':
        await (_db.delete(_db.staffUsers)..where((t) => t.id.equals(id))).go();
      case 'store':
        await (_db.delete(_db.stores)..where((t) => t.id.equals(id))).go();
      case 'debt_entry':
        await (_db.delete(_db.debtEntries)..where((t) => t.id.equals(id))).go();
      case 'stock':
        await (_db.delete(
          _db.productStock,
        )..where((t) => t.productId.equals(id))).go();
    }
  }

  Future<void> _saveState(PullResponse page) async {
    final now = _now();
    final serverTime = page.serverTime;
    await _db
        .into(_db.syncState)
        .insertOnConflictUpdate(
          SyncStateCompanion.insert(
            id: const Value(1),
            pullCursor: Value(page.nextCursor),
            lastPullAt: Value(now),
            subscriptionJson: Value(jsonEncode(page.subscription.toJson())),
            offlineGraceUntil: Value(
              serverTime.add(Duration(days: page.subscription.offlineDays)),
            ),
            serverTimeOffsetMs: Value(
              serverTime.difference(now).inMilliseconds,
            ),
          ),
        );
    // Yangi versiya e'loni (T-093); eski server — maydon yo'q (null).
    await _db.writeSetting(
      appReleaseSettingKey,
      encodeRelease(page.app?.latestVersion, page.app?.downloadUrl),
    );
    // Server imkoniyatlari (T-102); eski server — maydon yo'q (bo'sh ro'yxat).
    await _db.writeSetting(
      serverFeaturesSettingKey,
      encodeFeatures(page.features),
    );
  }

  static String _s(Object? v) => v is String ? v : (v?.toString() ?? '');

  static String? _nullIfEmpty(Object? v) =>
      v is String && v.isNotEmpty ? v : null;

  static int _i(Object? v) => v is int ? v : 0;

  static DateTime? _dt(Object? v) => v is String ? DateTime.tryParse(v) : null;
}

/// Serverdan barcha o'zgarishlarni oladi (sahifalab), har sahifadan keyin
/// `onProgress` — jami qo'llangan o'zgarishlar soni.
class SyncPuller {
  SyncPuller(this._db, this._api, {PullApplier? applier, this.pageSize = 500})
    : _applier = applier ?? PullApplier(_db);

  final AppDatabase _db;
  final PosApi _api;
  final PullApplier _applier;
  final int pageSize;

  Future<int> pullAll({void Function(int applied)? onProgress}) async {
    var applied = 0;
    while (true) {
      final state = await _db.select(_db.syncState).getSingleOrNull();
      final page = await _api.sync.syncPullRetrieve(
        cursor: state?.pullCursor ?? '0',
        limit: pageSize,
      );
      await _applier.apply(page);
      applied += page.changes.length;
      onProgress?.call(applied);
      if (!page.hasMore) return applied;
    }
  }
}

/// Joriy vaqt (testlarda flutter_test soxta vaqti).
DateTime _clockNow() => clock.now();
