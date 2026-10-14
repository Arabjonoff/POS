import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/data/ids.dart';
import 'package:pos_app/data/refunds/refund_calculator.dart';
import 'package:pos_app/data/sync/outbox.dart';

/// Pul qanday qaytariladi: naqd yoki mijoz qarzidan ayiriladi.
enum RefundMethod { cash, debt }

class RecordedRefund {
  const RecordedRefund({required this.id, required this.totalTiyin});

  final String id;
  final int totalTiyin;
}

/// Qaytarishni yozadi — **bitta SQLite tranzaksiyasida**: Refund +
/// RefundItem + qoldiq harakati (+qty) + (nasiyadan bo'lsa) qarz yozuvi
/// (−summa) + `sales.status` + outbox `refund.created`
/// (`docs/specs/sales-api.md`). Savdo o'zgarmaydi — faqat teskari yozuv.
class RefundWriter {
  RefundWriter(this._db, {IdGenerator? newId, DateTime Function()? now})
    : _newId = newId ?? _defaultId,
      _now = now ?? _clockNow;

  static String _defaultId() => newId();
  static DateTime _clockNow() => clock.now();

  final AppDatabase _db;
  final IdGenerator _newId;
  final DateTime Function() _now;

  Future<RecordedRefund> record({
    required RefundableSale sale,
    required RefundQuote quote,
    required RefundMethod method,
    required String shiftId,
    required String cashierId,
    String reason = '',
    String? approvedBy,
  }) {
    if (method == RefundMethod.debt &&
        (!quote.debtAllowed(sale) || sale.customerId == null)) {
      throw const InvalidRefundException(RefundProblem.debtNotAllowed);
    }
    return _db.transaction(() async {
      final refundId = _newId();
      final eventId = _newId();
      final at = _now();
      final debtEntryId = method == RefundMethod.debt && quote.totalTiyin > 0
          ? _newId()
          : null;
      final shift = await (_db.select(
        _db.shifts,
      )..where((s) => s.id.equals(shiftId))).getSingle();
      final products = {for (final i in sale.items) i.saleItemId: i.productId};

      await _db
          .into(_db.refunds)
          .insert(
            RefundsCompanion.insert(
              id: refundId,
              saleId: sale.id,
              shiftId: shiftId,
              cashierId: cashierId,
              approvedBy: Value(approvedBy),
              reason: Value(reason.trim()),
              method: method.name,
              totalTiyin: quote.totalTiyin,
              debtEntryId: Value(debtEntryId),
              at: at,
            ),
          );

      final items = <Map<String, Object?>>[];
      for (final line in quote.lines) {
        final itemId = _newId();
        await _db
            .into(_db.refundItems)
            .insert(
              RefundItemsCompanion.insert(
                id: itemId,
                refundId: refundId,
                saleItemId: line.saleItemId,
                qtyMilli: line.qtyMilli,
                totalTiyin: line.totalTiyin,
              ),
            );
        await _db
            .into(_db.stockMovements)
            .insert(
              StockMovementsCompanion.insert(
                id: _newId(),
                productId: products[line.saleItemId]!,
                storeId: Value(shift.storeId),
                qtyMilli: line.qtyMilli,
                type: 'refund',
                refType: 'refund',
                refId: refundId,
                outboxEventId: Value(eventId),
                at: at,
              ),
            );
        items.add({
          'id': itemId,
          'sale_item': line.saleItemId,
          'qty_milli': line.qtyMilli,
          'total_tiyin': line.totalTiyin,
        });
      }

      if (debtEntryId != null) {
        await _db
            .into(_db.debtEntries)
            .insert(
              DebtEntriesCompanion.insert(
                id: debtEntryId,
                customerId: sale.customerId!,
                amountTiyin: -quote.totalTiyin,
                type: 'refund',
                saleId: Value(sale.id),
                refundId: Value(refundId),
                shiftId: Value(shiftId),
                byUserId: Value(cashierId),
                at: at,
              ),
            );
      }

      // Savdo holati — yagona o'zgaruvchan ustun (serverdagidek).
      await (_db.update(_db.sales)..where((s) => s.id.equals(sale.id))).write(
        SalesCompanion(
          status: Value(quote.closesSale ? 'refunded' : 'partially_refunded'),
        ),
      );

      await _db.enqueueEvent(
        id: eventId,
        type: OutboxEventType.refundCreated,
        createdAt: at,
        payload: {
          'id': refundId,
          'sale': sale.id,
          'shift': shiftId,
          'cashier': cashierId,
          'approved_by': ?approvedBy,
          'reason': reason.trim(),
          'method': method.name,
          'total_tiyin': quote.totalTiyin,
          'at': isoUtc(at),
          'debt_entry_id': ?debtEntryId,
          'items': items,
        },
      );
      return RecordedRefund(id: refundId, totalTiyin: quote.totalTiyin);
    });
  }
}

final refundWriterProvider = Provider<RefundWriter>(
  (ref) => RefundWriter(ref.watch(appDatabaseProvider)),
);
