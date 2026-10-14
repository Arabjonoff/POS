import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/app/locale.dart';
import 'package:pos_app/core/format/unit_code.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/data/shifts/shift_service.dart';
import 'package:pos_app/features/printing/receipt.dart';
import 'package:pos_app/l10n/gen/app_localizations.dart';

/// Snapshot: `test/printing/receipts/<name>.txt`. Yangilash:
/// `UPDATE_RECEIPTS=1 flutter test test/printing/receipt_test.dart`.
void expectSnapshot(String name, String actual) {
  final file = File('test/printing/receipts/$name.txt');
  final update = Platform.environment['UPDATE_RECEIPTS'] == '1';
  if (update || !file.existsSync()) {
    file.writeAsStringSync('$actual\n');
    if (!update) {
      fail(
        'Snapshot yaratildi: ${file.path} — tekshirib qayta ishga tushiring',
      );
    }
    return;
  }
  expect(actual, file.readAsStringSync().replaceAll('\r\n', '\n').trimRight());
}

final AppLocalizations uz = lookupAppLocalizations(AppLocales.uzLatn);

/// `printing.md` dagi namuna: naqd, qaytim, chek chegirmasi, vaznli tovar.
final ReceiptData cash = ReceiptData(
  storeName: 'Baraka market',
  storeAddress: 'Chilonzor 7, 12-uy',
  storePhone: '+998 71 200 00 00',
  number: 'D3-000123',
  soldAt: DateTime.utc(2026, 10, 13, 15, 15),
  cashierName: 'Aziza',
  lines: const [
    ReceiptLine(
      name: 'Non',
      qtyMilli: 1000,
      priceTiyin: 400000,
      totalTiyin: 400000,
    ),
    ReceiptLine(
      name: 'Sut 1L',
      qtyMilli: 2000,
      priceTiyin: 1250000,
      totalTiyin: 2500000,
    ),
    ReceiptLine(
      name: 'Kartoshka',
      qtyMilli: 1250,
      unit: UnitCode.kg,
      priceTiyin: 600000,
      totalTiyin: 750000,
    ),
  ],
  discountTiyin: 150000,
  totalTiyin: 3500000,
  payments: const [
    ReceiptPayment(
      method: 'cash',
      amountTiyin: 3500000,
      receivedTiyin: 5000000,
      changeTiyin: 1500000,
    ),
  ],
);

String render(
  ReceiptData data, {
  PaperWidth width = PaperWidth.mm58,
  AppLocalizations? l10n,
  bool copy = false,
}) => ReceiptBuilder.render(
  ReceiptBuilder(l10n ?? uz, width: width).build(data, copy: copy),
  width,
);

void main() {
  test('cash, 58 mm (spec sample)', () {
    expectSnapshot('cash_58', render(cash));
  });

  test('cash, 80 mm', () {
    expectSnapshot('cash_80', render(cash, width: PaperWidth.mm80));
  });

  test('debt: customer and their debt after the sale', () {
    final data = ReceiptData(
      storeName: 'Baraka market',
      footer: "Qarzni 10 kun ichida to'lang",
      number: 'D3-000124',
      soldAt: DateTime.utc(2026, 10, 13, 16, 2),
      cashierName: 'Aziza',
      lines: const [
        ReceiptLine(
          name: 'Choy Ahmad 100 g',
          qtyMilli: 1000,
          priceTiyin: 2300000,
          totalTiyin: 2300000,
        ),
      ],
      discountTiyin: 0,
      totalTiyin: 2300000,
      payments: const [ReceiptPayment(method: 'debt', amountTiyin: 2300000)],
      customerName: 'Karimova Dilnoza',
      customerDebtTiyin: 5800000,
    );
    expectSnapshot('debt_58', render(data));
  });

  test('mixed, long name wraps, line discount, reprint copy', () {
    final data = ReceiptData(
      storeName: "Do'kon",
      header: 'Ochiq: 07:00 - 23:00',
      number: 'D3-000125',
      soldAt: DateTime.utc(2026, 10, 13, 17, 30),
      cashierName: 'Aziza Karimova',
      lines: const [
        ReceiptLine(
          name: "Kungaboqar yog'i Oltin Saxovat 5 litr plastik idishda",
          qtyMilli: 1000,
          priceTiyin: 9800000,
          discountTiyin: 980000,
          totalTiyin: 8820000,
        ),
        ReceiptLine(
          name: 'Olma qizil',
          qtyMilli: 1250,
          unit: UnitCode.kg,
          priceTiyin: 1500000,
          totalTiyin: 1875000,
        ),
      ],
      discountTiyin: 0,
      totalTiyin: 10695000,
      payments: const [
        ReceiptPayment(
          method: 'cash',
          amountTiyin: 2695000,
          receivedTiyin: 3000000,
          changeTiyin: 305000,
        ),
        ReceiptPayment(method: 'card', amountTiyin: 5000000),
        ReceiptPayment(method: 'debt', amountTiyin: 3000000),
      ],
      customerName: 'Olim aka',
      customerDebtTiyin: 3000000,
    );
    expectSnapshot('mixed_58', render(data, copy: true));
  });

  test('russian', () {
    expectSnapshot(
      'cash_58_ru',
      render(cash, l10n: lookupAppLocalizations(AppLocales.ru)),
    );
  });

  test('every row fits the paper', () {
    for (final width in PaperWidth.values) {
      final rows = ReceiptBuilder(uz, width: width).build(cash);
      for (final row in rows) {
        expect(row.text.length, lessThanOrEqualTo(width.chars), reason: '$row');
      }
    }
  });

  test('plain() keeps receipts ASCII-friendly', () {
    expect(ReceiptBuilder.plain('1 250 so’m −1'), "1 250 so'm -1");
  });

  group('shift report', () {
    ShiftReport report({bool closed = false}) => ShiftReport(
      shift: Shift(
        id: 'shift-1',
        storeId: 'store-1',
        deviceId: 'device-1',
        openedBy: 'cashier-1',
        openedAt: DateTime.utc(2026, 10, 15, 3),
        openingCashTiyin: 10000000,
        closedBy: closed ? 'cashier-1' : null,
        closedAt: closed ? DateTime.utc(2026, 10, 15, 16) : null,
        countedCashTiyin: closed ? 25950000 : null,
        expectedCashTiyin: closed ? 26000000 : null,
      ),
      salesCount: 42,
      salesTotal: 31250000,
      paymentsCash: 20500000,
      paymentsCard: 8750000,
      paymentsDebt: 2000000,
      refundsCount: 1,
      refundsCash: 400000,
      refundsDebt: 0,
      cashIn: 2000000,
      cashOut: 6000000,
      debtPaymentsCash: 900000,
      debtPaymentsCard: 0,
      // 100 000 + 205 000 − 4 000 + 20 000 − 60 000 + 9 000.
      expectedCash: 26000000,
    );

    String renderShift(ShiftReport r) => ReceiptBuilder.render(
      ReceiptBuilder(uz).buildShift(
        r,
        storeName: 'Baraka market',
        cashierName: 'Aziza',
        printedAt: DateTime.utc(2026, 10, 15, 12, 30),
      ),
      PaperWidth.mm58,
    );

    test('X report, 58 mm', () {
      expectSnapshot('shift_x_58', renderShift(report()));
    });

    test('Z report with the shortage', () {
      expectSnapshot('shift_z_58', renderShift(report(closed: true)));
    });
  });
}
