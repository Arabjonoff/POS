import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/app/locale.dart';
import 'package:pos_app/app/status/app_status.dart';
import 'package:pos_app/core/format/unit_code.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/features/printing/printer_service.dart';
import 'package:pos_app/features/printing/receipt.dart';
import 'package:pos_app/features/printing/receipt_loader.dart';
import 'package:pos_app/l10n/gen/app_localizations.dart';

/// Namuna chek (hali savdo bo'lmasa — chek ko'rinishi va test cheki uchun):
/// uzun o'zbekcha nom (qo'shtirnoq bilan), vaznli tovar, qator chegirmasi,
/// aralash to'lov va qaytim — chekning hamma qismi ko'rinsin.
ReceiptData sampleReceipt(
  AppLocalizations l10n, {
  String storeName = '',
  String storeAddress = '',
  String storePhone = '',
  String header = '',
  String footer = '',
  DateTime? at,
}) => ReceiptData(
  storeName: storeName.trim().isEmpty ? l10n.receiptSampleStore : storeName,
  storeAddress: storeAddress,
  storePhone: storePhone,
  header: header,
  footer: footer,
  number: 'D1-000123',
  soldAt: at ?? clock.now(),
  cashierName: l10n.roleCashier,
  lines: [
    ReceiptLine(
      name: l10n.receiptSampleItem1,
      qtyMilli: 1000,
      priceTiyin: 9800000,
      discountTiyin: 980000,
      totalTiyin: 8820000,
    ),
    ReceiptLine(
      name: l10n.receiptSampleItem2,
      qtyMilli: 1250,
      unit: UnitCode.kg,
      priceTiyin: 1500000,
      totalTiyin: 1875000,
    ),
    ReceiptLine(
      name: l10n.receiptSampleItem3,
      qtyMilli: 2000,
      priceTiyin: 400000,
      totalTiyin: 800000,
    ),
  ],
  discountTiyin: 0,
  totalTiyin: 11495000,
  payments: const [
    ReceiptPayment(
      method: 'cash',
      amountTiyin: 6495000,
      receivedTiyin: 7000000,
      changeTiyin: 505000,
    ),
    ReceiptPayment(method: 'card', amountTiyin: 5000000),
  ],
);

/// Chek ko'rinishi uchun ma'lumot: oxirgi savdo (do'kon sozlamalari bilan),
/// bo'lmasa — namuna. `isSample` — belgi uchun.
final FutureProvider<({ReceiptData data, bool isSample})>
receiptPreviewDataProvider =
    FutureProvider.autoDispose<({ReceiptData data, bool isSample})>((
      ref,
    ) async {
      final l10n = lookupAppLocalizations(ref.watch(localeProvider));
      final db = ref.watch(appDatabaseProvider);
      final service = ref.watch(printerServiceProvider);
      final lastId = await service.lastSaleId();
      if (lastId != null) {
        final data = await ref.watch(receiptLoaderProvider).load(lastId);
        if (data != null) return (data: data, isSample: false);
      }
      final store = await db.select(db.stores).getSingleOrNull();
      return (
        data: sampleReceipt(
          l10n,
          storeName: store?.name ?? '',
          storeAddress: store?.address ?? '',
          storePhone: store?.phone ?? '',
          header: store?.receiptHeader ?? '',
          footer: store?.receiptFooter ?? '',
          at: ref.watch(clockProvider)(),
        ),
        isSample: true,
      );
    });
