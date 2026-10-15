import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:pos_app/data/db/app_database.dart';

/// Outbox hodisa turlari (`docs/specs/sync-api.md`).
abstract final class OutboxEventType {
  static const String shiftOpened = 'shift.opened';
  static const String shiftClosed = 'shift.closed';
  static const String cashMoved = 'cash.moved';
  static const String saleCompleted = 'sale.completed';
  static const String refundCreated = 'refund.created';
  static const String debtPaid = 'debt.paid';
  static const String customerUpserted = 'customer.upserted';
  static const String supplierUpserted = 'supplier.upserted';
  static const String productUpserted = 'product.upserted';
  static const String receiptPosted = 'receipt.posted';
  static const String receiptCorrected = 'receipt.corrected';
  static const String receiptReversed = 'receipt.reversed';
  static const String storeUpserted = 'store.upserted';
  static const String inventoryPosted = 'inventory.posted';
}

/// Outbox holati.
abstract final class OutboxStatus {
  static const String pending = 'pending';
  static const String sent = 'sent';
  static const String rejected = 'rejected';
}

/// Vaqtni serverga ISO-8601 (UTC, vaqt zonasi bilan) ko'rinishida beradi.
String isoUtc(DateTime t) => t.toUtc().toIso8601String();

extension OutboxWriter on AppDatabase {
  /// Hodisani navbatga qo'yadi. Hujjat yozuvi bilan **bitta tranzaksiyada**
  /// chaqiriladi (`transaction(() async { ...; await enqueueEvent(...); })`).
  Future<void> enqueueEvent({
    required String id,
    required String type,
    required Map<String, Object?> payload,
    required DateTime createdAt,
  }) => into(outboxEvents).insert(
    OutboxEventsCompanion.insert(
      id: id,
      type: type,
      payload: jsonEncode(payload),
      createdAt: createdAt,
    ),
  );

  /// Serverga hali yuborilmagan hodisalar soni (holat qatori uchun).
  Stream<int> watchPendingEventCount() {
    final count = outboxEvents.id.count();
    return (selectOnly(outboxEvents)
          ..addColumns([count])
          ..where(outboxEvents.status.equals(OutboxStatus.pending)))
        .map((row) => row.read(count) ?? 0)
        .watchSingle();
  }
}
