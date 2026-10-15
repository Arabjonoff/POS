import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/core/format/unit_code.dart';
import 'package:pos_app/data/customers/customer_directory.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/features/printing/mono_bitmap.dart';
import 'package:pos_app/features/printing/receipt.dart';

/// Chek uchun savdo ma'lumoti — lokal bazadan yoki serverdan (boshqa kassa
/// cheki, T-110). Do'kon rekvizitlari, birliklar va qarz — lokal bazadan.
class ReceiptSource {
  const ReceiptSource({
    required this.storeId,
    required this.number,
    required this.soldAt,
    required this.cashierName,
    required this.discountTiyin,
    required this.totalTiyin,
    required this.items,
    required this.payments,
    this.customerId,
  });

  final String? storeId;
  final String number;
  final DateTime soldAt;
  final String cashierName;
  final String? customerId;
  final int discountTiyin;
  final int totalTiyin;
  final List<ReceiptSourceItem> items;
  final List<ReceiptPayment> payments;
}

class ReceiptSourceItem {
  const ReceiptSourceItem({
    required this.productId,
    required this.name,
    required this.qtyMilli,
    required this.priceTiyin,
    required this.discountTiyin,
    required this.totalTiyin,
  });

  final String productId;
  final String name;
  final int qtyMilli;
  final int priceTiyin;
  final int discountTiyin;
  final int totalTiyin;
}

/// Yozilgan savdodan chek ma'lumotini yig'adi (do'kon, kassir, qatorlar,
/// to'lovlar, nasiya mijozi va uning savdodan keyingi qarzi).
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
    final cashier = await (_db.select(
      _db.staffUsers,
    )..where((u) => u.id.equals(sale.cashierId))).getSingleOrNull();

    return fromSource(
      ReceiptSource(
        storeId: shift?.storeId,
        number: sale.number,
        soldAt: sale.soldAt,
        cashierName: cashier?.fullName ?? '',
        customerId: sale.customerId,
        discountTiyin: sale.discountTiyin,
        totalTiyin: sale.totalTiyin,
        items: [
          for (final i in items)
            ReceiptSourceItem(
              productId: i.productId,
              name: i.nameSnapshot,
              qtyMilli: i.qtyMilli,
              priceTiyin: i.priceTiyin,
              discountTiyin: i.discountTiyin,
              totalTiyin: i.totalTiyin,
            ),
        ],
        payments: [
          for (final p in payments)
            ReceiptPayment(
              method: p.method,
              amountTiyin: p.amountTiyin,
              receivedTiyin: p.receivedTiyin,
              changeTiyin: p.changeTiyin,
            ),
        ],
      ),
    );
  }

  Future<ReceiptData> fromSource(ReceiptSource sale) async {
    final storeId = sale.storeId;
    final store = storeId == null
        ? null
        : await (_db.select(
            _db.stores,
          )..where((s) => s.id.equals(storeId))).getSingleOrNull();

    final productIds = {for (final i in sale.items) i.productId};
    final products = await (_db.select(
      _db.products,
    )..where((p) => p.id.isIn(productIds))).get();
    final unitCodes = {
      for (final u in await _db.select(_db.units).get()) u.id: u.code,
    };
    final units = {
      for (final p in products) p.id: UnitCode.fromCode(unitCodes[p.unitId]),
    };

    final hasDebt = sale.payments.any((p) => p.method == 'debt');
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
    final payments = [...sale.payments]
      ..sort(
        (a, b) => (order[a.method] ?? 3).compareTo(order[b.method] ?? 3),
      );

    return ReceiptData(
      storeName: store?.name ?? '',
      storeAddress: store?.address ?? '',
      storePhone: store?.phone ?? '',
      header: store?.receiptHeader ?? '',
      footer: store?.receiptFooter ?? '',
      legalName: store?.legalName ?? '',
      tin: store?.tin ?? '',
      logo: decodeStoreLogo(store?.receiptLogo),
      options: decodeReceiptOptions(store?.receiptOptions),
      number: sale.number,
      soldAt: sale.soldAt,
      cashierName: sale.cashierName,
      lines: [
        for (final i in sale.items)
          ReceiptLine(
            name: i.name,
            qtyMilli: i.qtyMilli,
            unit: units[i.productId] ?? UnitCode.pcs,
            priceTiyin: i.priceTiyin,
            discountTiyin: i.discountTiyin,
            totalTiyin: i.totalTiyin,
          ),
      ],
      discountTiyin: sale.discountTiyin,
      totalTiyin: sale.totalTiyin,
      payments: payments,
      customerName: customer?.name,
      customerDebtTiyin: debtAfter,
    );
  }
}

final receiptLoaderProvider = Provider<ReceiptLoader>(
  (ref) => ReceiptLoader(ref.watch(appDatabaseProvider)),
);

/// `stores.receipt_logo` (base64 kulrang PNG) → rasm; buzuq — `null`.
GrayImage? decodeStoreLogo(String? base64Png) {
  if (base64Png == null || base64Png.isEmpty) return null;
  try {
    return GrayImage.fromPng(base64Decode(base64Png));
  } on FormatException {
    return null;
  }
}

/// `stores.receipt_options` (JSON) → ko'rsat/yashir; buzuq — standart.
ReceiptOptions decodeReceiptOptions(String? json) {
  if (json == null || json.isEmpty) return const ReceiptOptions();
  try {
    final value = jsonDecode(json);
    return value is Map<String, Object?>
        ? ReceiptOptions.fromJson(value)
        : const ReceiptOptions();
  } on FormatException {
    return const ReceiptOptions();
  }
}
