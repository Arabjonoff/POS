import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_api_client/pos_api_client.dart' as api;
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/data/refunds/refund_calculator.dart';
import 'package:pos_app/data/remote/api.dart';

/// Chek raqami ko'rinishi: `D3-000123` (kassa raqami + tartib raqami).
final RegExp receiptNumberPattern = RegExp(
  r'^[A-Z]\d+-\d+$',
  caseSensitive: false,
);

bool looksLikeReceiptNumber(String text) =>
    receiptNumberPattern.hasMatch(text.trim());

/// Server: `GET /api/v1/sync/sales/?number=` (qurilma tokeni). Topilmasa —
/// `null`; tarmoq/server xatosi — [ApiFailure].
typedef RemoteSaleFetcher = Future<api.DeviceSale?> Function(String number);

final remoteSaleFetcherProvider = Provider<RemoteSaleFetcher>((ref) {
  final tokens = ref.watch(deviceTokenStoreProvider);
  final dio = ref.watch(dioFactoryProvider);
  return (number) async {
    final token = await tokens.read();
    if (token == null) throw const ApiFailure(ApiFailureKind.unauthorized);
    try {
      return await deviceApi(
        dio,
        token,
      ).sync.syncSaleByNumber(number: number.trim().toUpperCase());
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw ApiFailure.from(e);
    } on Object catch (e) {
      throw ApiFailure.from(e);
    }
  };
});

/// Qaytarish (serverdagi yoki shu kassada hali yuborilmagan).
@immutable
class RemoteRefund {
  const RemoteRefund({
    required this.id,
    required this.at,
    required this.method,
    required this.totalTiyin,
    required this.reason,
  });

  final String id;
  final DateTime at;

  /// `cash` / `debt`.
  final String method;
  final int totalTiyin;
  final String reason;
}

/// Boshqa kassa cheki (T-110, Q-006 → A): serverdagi holat + shu kassada
/// qilingan, hali serverga yetmagan qaytarishlar (ikki marta qaytarilmasin).
@immutable
class RemoteSale {
  const RemoteSale({
    required this.sale,
    required this.refundable,
    required this.refunds,
  });

  final api.DeviceSale sale;
  final RefundableSale refundable;

  /// Hammasi (server + lokal), eskisi birinchi.
  final List<RemoteRefund> refunds;

  String get status {
    if (refunds.isEmpty) return 'completed';
    return refundable.fullyRefunded ? 'refunded' : 'partially_refunded';
  }
}

/// Natija: topildi / yo'q / internet yo'q / boshqa xato.
sealed class RemoteSaleResult {
  const RemoteSaleResult();
}

final class RemoteSaleFound extends RemoteSaleResult {
  const RemoteSaleFound(this.sale);

  final RemoteSale sale;
}

final class RemoteSaleNotFound extends RemoteSaleResult {
  const RemoteSaleNotFound();
}

final class RemoteSaleOffline extends RemoteSaleResult {
  const RemoteSaleOffline();
}

final class RemoteSaleFailed extends RemoteSaleResult {
  const RemoteSaleFailed();
}

/// Boshqa kassa chekini serverdan topadi va lokal qaytarishlar bilan
/// birlashtiradi (`receipt-history.md`, T-110).
class RemoteSales {
  const RemoteSales(this._db, this._fetch);

  final AppDatabase _db;
  final RemoteSaleFetcher _fetch;

  Future<RemoteSaleResult> find(String number) async {
    final api.DeviceSale? sale;
    try {
      sale = await _fetch(number);
    } on ApiFailure catch (e) {
      return e.kind == ApiFailureKind.network
          ? const RemoteSaleOffline()
          : const RemoteSaleFailed();
    }
    if (sale == null) return const RemoteSaleNotFound();
    return RemoteSaleFound(await _merge(sale));
  }

  Future<RemoteSale> _merge(api.DeviceSale sale) async {
    final serverRefundIds = {for (final r in sale.refunds) r.id};
    final local = [
      for (final r in await (_db.select(
        _db.refunds,
      )..where((r) => r.saleId.equals(sale.id))).get())
        if (!serverRefundIds.contains(r.id)) r,
    ];
    final localItems = local.isEmpty
        ? const <RefundItem>[]
        : await (_db.select(
                _db.refundItems,
              )..where((i) => i.refundId.isIn([for (final r in local) r.id])))
              .get();
    final pendingQty = <String, int>{};
    final pendingTotal = <String, int>{};
    for (final i in localItems) {
      pendingQty.update(
        i.saleItemId,
        (v) => v + i.qtyMilli,
        ifAbsent: () => i.qtyMilli,
      );
      pendingTotal.update(
        i.saleItemId,
        (v) => v + i.totalTiyin,
        ifAbsent: () => i.totalTiyin,
      );
    }

    final productIds = {for (final i in sale.items) i.product};
    final products = await (_db.select(
      _db.products,
    )..where((p) => p.id.isIn(productIds))).get();
    final unitCodes = {
      for (final u in await _db.select(_db.units).get()) u.id: u.code,
    };
    final units = {for (final p in products) p.id: unitCodes[p.unitId]};

    final refunds = [
      for (final r in sale.refunds)
        RemoteRefund(
          id: r.id,
          at: r.at,
          method: r.method.json ?? 'cash',
          totalTiyin: r.totalTiyin,
          reason: r.reason,
        ),
      for (final r in local)
        RemoteRefund(
          id: r.id,
          at: r.at,
          method: r.method,
          totalTiyin: r.totalTiyin,
          reason: r.reason,
        ),
    ]..sort((a, b) => a.at.compareTo(b.at));

    int paid(String method) => sale.payments
        .where((p) => p.method.json == method)
        .fold(0, (s, p) => s + p.amountTiyin);
    int refundedBy(String method) => refunds
        .where((r) => r.method == method)
        .fold(0, (s, r) => s + r.totalTiyin);

    return RemoteSale(
      sale: sale,
      refunds: refunds,
      refundable: RefundableSale(
        id: sale.id,
        number: sale.number,
        soldAt: sale.soldAt,
        customerId: sale.customer,
        subtotalTiyin: sale.subtotalTiyin,
        discountTiyin: sale.discountTiyin,
        totalTiyin: sale.totalTiyin,
        items: [
          for (final i in sale.items)
            RefundableItem(
              saleItemId: i.id,
              productId: i.product,
              name: i.nameSnapshot,
              unit: units[i.product] ?? 'pcs',
              qtyMilli: i.qtyMilli,
              priceTiyin: i.priceTiyin,
              totalTiyin: i.totalTiyin,
              refundedQtyMilli: i.refundedQtyMilli + (pendingQty[i.id] ?? 0),
              refundedTiyin: i.refundedTiyin + (pendingTotal[i.id] ?? 0),
            ),
        ],
        refundedTiyin: refunds.fold(0, (s, r) => s + r.totalTiyin),
        debtPaidTiyin: paid('debt'),
        debtRefundedTiyin: refundedBy('debt'),
      ),
    );
  }
}

final remoteSalesProvider = Provider<RemoteSales>(
  (ref) => RemoteSales(
    ref.watch(appDatabaseProvider),
    ref.watch(remoteSaleFetcherProvider),
  ),
);
