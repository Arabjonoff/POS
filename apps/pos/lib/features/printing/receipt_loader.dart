import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/core/format/unit_code.dart';
import 'package:pos_app/data/customers/customer_directory.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/features/printing/receipt.dart';

/// Yozilgan savdodan chek ma'lumotini yig'adi (do'kon, kassir, qatorlar,
/// to'lovlar, nasiya mijozi va uning hozirgi qarzi).
class ReceiptLoader {
  const ReceiptLoader(this._db);

  final AppDatabase _db;

  Future<ReceiptData?> load(String saleId) async {
    final sale = await (_db.select(
      _db.sales,
    )..where((s) => s.id.equals(saleId))).getSingleOrNull();
    if (sale == null) return null;

    final items =
        await (_db.select(_db.saleItems)
              ..where((i) => i.saleId.equals(saleId))
              ..orderBy([(i) => OrderingTerm.asc(i.position)]))
            .get();
    final payments = await (_db.select(
      _db.salePayments,
    )..where((p) => p.saleId.equals(saleId))).get();
    final shift = await (_db.select(
      _db.shifts,
    )..where((s) => s.id.equals(sale.shiftId))).getSingleOrNull();
    final store = shift == null
        ? null
        : await (_db.select(
            _db.stores,
          )..where((s) => s.id.equals(shift.storeId))).getSingleOrNull();
    final cashier = await (_db.select(
      _db.staffUsers,
    )..where((u) => u.id.equals(sale.cashierId))).getSingleOrNull();

    final productIds = {for (final i in items) i.productId};
    final products = await (_db.select(
      _db.products,
    )..where((p) => p.id.isIn(productIds))).get();
    final unitCodes = {
      for (final u in await _db.select(_db.units).get()) u.id: u.code,
    };
    final units = {
      for (final p in products) p.id: UnitCode.fromCode(unitCodes[p.unitId]),
    };

    final hasDebt = payments.any((p) => p.method == 'debt');
    final customerId = sale.customerId;
    final customer = hasDebt && customerId != null
        ? await CustomerDirectory(_db).byId(customerId)
        : null;
    // Qarz — shu savdodan keyingi holat (qayta chop etilsa ham o'sha kundagi
    // raqam, keyingi to'lov/savdolar emas; audit PRN-B15).
    final debtAfter = customer == null
        ? null
        : (await _db
                  .customSelect(
                    'SELECT COALESCE(SUM(amount_tiyin), 0) AS s '
                    'FROM debt_entries WHERE customer_id = ? AND at <= ?',
                    variables: [
                      Variable.withString(customer.id),
                      Variable.withDateTime(sale.soldAt),
                    ],
                    readsFrom: {_db.debtEntries},
                  )
                  .getSingle())
              .read<int>('s');

    const order = {'cash': 0, 'card': 1, 'debt': 2};
    payments.sort(
      (a, b) => (order[a.method] ?? 3).compareTo(order[b.method] ?? 3),
    );

    return ReceiptData(
      storeName: store?.name ?? '',
      storeAddress: store?.address ?? '',
      storePhone: store?.phone ?? '',
      header: store?.receiptHeader ?? '',
      footer: store?.receiptFooter ?? '',
      number: sale.number,
      soldAt: sale.soldAt,
      cashierName: cashier?.fullName ?? '',
      lines: [
        for (final i in items)
          ReceiptLine(
            name: i.nameSnapshot,
            qtyMilli: i.qtyMilli,
            unit: units[i.productId] ?? UnitCode.pcs,
            priceTiyin: i.priceTiyin,
            discountTiyin: i.discountTiyin,
            totalTiyin: i.totalTiyin,
          ),
      ],
      discountTiyin: sale.discountTiyin,
      totalTiyin: sale.totalTiyin,
      payments: [
        for (final p in payments)
          ReceiptPayment(
            method: p.method,
            amountTiyin: p.amountTiyin,
            receivedTiyin: p.receivedTiyin,
            changeTiyin: p.changeTiyin,
          ),
      ],
      customerName: customer?.name,
      customerDebtTiyin: debtAfter,
    );
  }
}

final receiptLoaderProvider = Provider<ReceiptLoader>(
  (ref) => ReceiptLoader(ref.watch(appDatabaseProvider)),
);
