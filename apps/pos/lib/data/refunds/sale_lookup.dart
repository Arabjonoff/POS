import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/data/refunds/refund_calculator.dart';

/// Ro'yxat uchun qisqa savdo.
class SaleSummary {
  const SaleSummary({
    required this.id,
    required this.number,
    required this.soldAt,
    required this.totalTiyin,
    required this.status,
  });

  final String id;
  final String number;
  final DateTime soldAt;
  final int totalTiyin;

  /// `completed` / `partially_refunded` / `refunded`.
  final String status;
}

/// Qaytarish uchun savdoni topish (shu kassaning lokal bazasidan).
class SaleLookup {
  const SaleLookup(this._db);

  final AppDatabase _db;

  /// Chek raqami (`D3-000123`, katta-kichik harf farqsiz) yoki chekdagi
  /// shtrix-koddan.
  Future<String?> idByNumber(String number) async {
    final value = number.trim().toUpperCase();
    if (value.isEmpty) return null;
    final row = await (_db.select(
      _db.sales,
    )..where((s) => s.number.equals(value))).getSingleOrNull();
    return row?.id;
  }

  /// Oxirgi savdolar (yangisi birinchi).
  Future<List<SaleSummary>> recent({int limit = 20}) async {
    final rows =
        await (_db.select(_db.sales)
              ..orderBy([(s) => OrderingTerm.desc(s.soldAt)])
              ..limit(limit))
            .get();
    return [
      for (final s in rows)
        SaleSummary(
          id: s.id,
          number: s.number,
          soldAt: s.soldAt,
          totalTiyin: s.totalTiyin,
          status: s.status,
        ),
    ];
  }

  /// Savdo qatorlari, oldin qaytarilganlari va nasiya qismi bilan.
  Future<RefundableSale?> refundable(String saleId) async {
    final sale = await (_db.select(
      _db.sales,
    )..where((s) => s.id.equals(saleId))).getSingleOrNull();
    if (sale == null) return null;
    final items =
        await (_db.select(_db.saleItems)
              ..where((i) => i.saleId.equals(saleId))
              ..orderBy([(i) => OrderingTerm.asc(i.position)]))
            .get();

    final refunded = <String, (int, int)>{};
    final rows = await _db
        .customSelect(
          'SELECT ri.sale_item_id AS item, SUM(ri.qty_milli) AS qty, '
          'SUM(ri.total_tiyin) AS total FROM refund_items ri '
          'JOIN refunds r ON r.id = ri.refund_id WHERE r.sale_id = ? '
          'GROUP BY ri.sale_item_id',
          variables: [Variable.withString(saleId)],
          readsFrom: {_db.refundItems, _db.refunds},
        )
        .get();
    for (final r in rows) {
      refunded[r.read<String>('item')] = (
        r.read<int>('qty'),
        r.read<int>('total'),
      );
    }

    Future<int> sum(String sql) async {
      final row = await _db
          .customSelect(
            sql,
            variables: [Variable.withString(saleId)],
            readsFrom: {_db.refunds, _db.salePayments},
          )
          .getSingle();
      return row.read<int>('v');
    }

    final productIds = {for (final i in items) i.productId};
    final products = await (_db.select(
      _db.products,
    )..where((p) => p.id.isIn(productIds))).get();
    final unitCodes = {
      for (final u in await _db.select(_db.units).get()) u.id: u.code,
    };
    final units = {for (final p in products) p.id: unitCodes[p.unitId]};

    return RefundableSale(
      id: sale.id,
      number: sale.number,
      soldAt: sale.soldAt,
      customerId: sale.customerId,
      subtotalTiyin: sale.subtotalTiyin,
      discountTiyin: sale.discountTiyin,
      totalTiyin: sale.totalTiyin,
      items: [
        for (final i in items)
          RefundableItem(
            saleItemId: i.id,
            productId: i.productId,
            name: i.nameSnapshot,
            unit: units[i.productId] ?? 'pcs',
            qtyMilli: i.qtyMilli,
            priceTiyin: i.priceTiyin,
            totalTiyin: i.totalTiyin,
            refundedQtyMilli: refunded[i.id]?.$1 ?? 0,
            refundedTiyin: refunded[i.id]?.$2 ?? 0,
          ),
      ],
      refundedTiyin: await sum(
        'SELECT COALESCE(SUM(total_tiyin), 0) AS v FROM refunds '
        'WHERE sale_id = ?',
      ),
      debtPaidTiyin: await sum(
        'SELECT COALESCE(SUM(amount_tiyin), 0) AS v FROM sale_payments '
        "WHERE sale_id = ? AND method = 'debt'",
      ),
      debtRefundedTiyin: await sum(
        'SELECT COALESCE(SUM(total_tiyin), 0) AS v FROM refunds '
        "WHERE sale_id = ? AND method = 'debt'",
      ),
    );
  }
}

final saleLookupProvider = Provider<SaleLookup>(
  (ref) => SaleLookup(ref.watch(appDatabaseProvider)),
);
