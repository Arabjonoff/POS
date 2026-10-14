import 'package:flutter/foundation.dart';
import 'package:pos_app/core/format/app_format.dart';
import 'package:pos_app/core/format/unit_code.dart';
import 'package:pos_app/l10n/gen/app_localizations.dart';

/// Chek qatori (savdo qatorining surati).
class ReceiptLine {
  const ReceiptLine({
    required this.name,
    required this.qtyMilli,
    required this.priceTiyin,
    required this.totalTiyin,
    this.unit = UnitCode.pcs,
    this.discountTiyin = 0,
  });

  final String name;
  final int qtyMilli;
  final UnitCode unit;
  final int priceTiyin;
  final int discountTiyin;
  final int totalTiyin;
}

/// To'lov: `cash` / `card` / `debt` (`sale_payments.method`).
class ReceiptPayment {
  const ReceiptPayment({
    required this.method,
    required this.amountTiyin,
    this.receivedTiyin,
    this.changeTiyin = 0,
  });

  final String method;
  final int amountTiyin;

  /// Naqd: mijoz bergan pul.
  final int? receivedTiyin;
  final int changeTiyin;
}

/// Chek uchun hamma ma'lumot — bazadan yig'iladi (`ReceiptLoader`).
class ReceiptData {
  const ReceiptData({
    required this.storeName,
    required this.number,
    required this.soldAt,
    required this.cashierName,
    required this.lines,
    required this.discountTiyin,
    required this.totalTiyin,
    required this.payments,
    this.storeAddress = '',
    this.storePhone = '',
    this.header = '',
    this.footer = '',
    this.customerName,
    this.customerDebtTiyin,
  });

  final String storeName;
  final String storeAddress;
  final String storePhone;

  /// Do'kon sozlamasidagi qo'shimcha sarlavha va pastki matn.
  final String header;
  final String footer;

  final String number;
  final DateTime soldAt;
  final String cashierName;
  final List<ReceiptLine> lines;

  /// Butun chekka chegirma (qator chegirmalari qatorlarda).
  final int discountTiyin;
  final int totalTiyin;
  final List<ReceiptPayment> payments;

  /// Nasiya bo'lsa: mijoz va uning savdodan keyingi qarzi.
  final String? customerName;
  final int? customerDebtTiyin;

  int get changeTiyin => payments.fold(0, (sum, p) => sum + p.changeTiyin);
}

/// Chek kengligi: 58 mm — 32 belgi, 80 mm — 48 belgi (`printing.md`).
enum PaperWidth {
  mm58(32),
  mm80(48)
  ;

  const PaperWidth(this.chars);

  final int chars;
}

/// Chek qatori va uning ko'rinishi (ESC/POS kodlovchi uchun).
@immutable
class ReceiptRow {
  const ReceiptRow(
    this.text, {
    this.bold = false,
    this.center = false,
    this.barcode = false,
  });

  /// Chek raqami shtrix-kodi (CODE128): qaytarishda skanerlanadi.
  const ReceiptRow.barcode(this.text)
    : bold = false,
      center = true,
      barcode = true;

  final String text;
  final bool bold;
  final bool center;
  final bool barcode;

  @override
  bool operator ==(Object other) =>
      other is ReceiptRow &&
      other.text == text &&
      other.bold == bold &&
      other.center == center &&
      other.barcode == barcode;

  @override
  int get hashCode => Object.hash(text, bold, center, barcode);

  @override
  String toString() => text;
}

/// Chek matnini yasaydi — sof funksiya (printer yo'q, baza yo'q), snapshot
/// testlar bilan (`docs/specs/printing.md`). Matn — joriy tilda; belgilar
/// oddiy ASCII bo'shliq va defis bilan (printer kodlash jadvali uchun).
class ReceiptBuilder {
  ReceiptBuilder(this.l10n, {this.width = PaperWidth.mm58})
    : _fmt = AppFormat(l10n);

  final AppLocalizations l10n;
  final PaperWidth width;
  final AppFormat _fmt;

  int get _w => width.chars;

  List<ReceiptRow> build(ReceiptData data, {bool copy = false}) {
    final rows = <ReceiptRow>[];
    void center(String text, {bool bold = false}) {
      for (final part in wrap(plain(text), _w)) {
        rows.add(ReceiptRow(part, bold: bold, center: true));
      }
    }

    void line(String text, {bool bold = false}) =>
        rows.add(ReceiptRow(text, bold: bold));
    void divider() => line('-' * _w);
    void pair(String left, String right, {bool bold = false}) {
      for (final text in _pair(plain(left), plain(right))) {
        line(text, bold: bold);
      }
    }

    // Sarlavha.
    center(data.storeName, bold: true);
    for (final extra in [
      data.storeAddress,
      data.storePhone,
      ...data.header.split('\n'),
    ]) {
      if (extra.trim().isNotEmpty) center(extra.trim());
    }
    if (copy) center(l10n.receiptCopy, bold: true);
    divider();
    pair('${l10n.receiptCheck}: ${data.number}', _fmt.dateTime(data.soldAt));
    pair('${l10n.receiptCashier}: ${data.cashierName}', '');
    divider();

    // Qatorlar: nom va "miqdor x narx", keyingi qatorda — jami.
    for (final item in data.lines) {
      final qty = item.unit.fractional || item.qtyMilli % 1000 != 0
          ? _fmt.qty(item.qtyMilli, item.unit)
          : _fmt.qtyValue(item.qtyMilli, item.unit);
      pair(item.name, '$qty x ${_fmt.moneyAmount(item.priceTiyin)}');
      if (item.discountTiyin > 0) {
        pair('  ${l10n.receiptDiscount}', _amount(-item.discountTiyin));
      }
      pair('', _amount(item.totalTiyin));
    }
    divider();

    if (data.discountTiyin > 0) {
      pair(l10n.receiptDiscount, _amount(-data.discountTiyin));
    }
    pair(l10n.receiptTotal, _amount(data.totalTiyin), bold: true);
    for (final p in data.payments) {
      final (label, amount) = switch (p.method) {
        'cash' => (l10n.payCash, p.receivedTiyin ?? p.amountTiyin),
        'card' => (l10n.payCard, p.amountTiyin),
        _ => (l10n.payDebt, p.amountTiyin),
      };
      pair(label, _amount(amount));
    }
    if (data.changeTiyin > 0) {
      pair(l10n.changeLabel, _amount(data.changeTiyin));
    }
    final customer = data.customerName;
    if (customer != null) {
      divider();
      pair('${l10n.receiptCustomer}: $customer', '');
      final debt = data.customerDebtTiyin;
      if (debt != null) pair(l10n.receiptDebtNow, _amount(debt));
    }
    divider();

    rows.add(ReceiptRow.barcode(data.number));
    final footer = data.footer.trim().isEmpty
        ? l10n.receiptThanks
        : data.footer.trim();
    footer.split('\n').forEach(center);
    center(l10n.receiptNotFiscal);
    return rows;
  }

  /// Ekranda/testda ko'rinishi: markazdagi qatorlar bo'shliq bilan surilgan.
  static String render(List<ReceiptRow> rows, PaperWidth width) => rows
      .map(
        (r) {
          final text = r.barcode ? '||||| ${r.text} |||||' : r.text;
          return r.center
              ? '${' ' * ((width.chars - text.length) ~/ 2)}$text'
              : text;
        },
      )
      .join('\n');

  /// Oddiy matn: chekda faqat ASCII bo'shliq/defis/tutuq belgisi.
  static String plain(String text) => text
      .replaceAll(RegExp('[   ]'), ' ')
      .replaceAll(RegExp('[−–—]'), '-')
      .replaceAll(RegExp('[ʻʼ‘’`]'), "'");

  String _amount(int tiyin) => plain(_fmt.moneyAmount(tiyin));

  /// Chap va o'ng matn bir qatorda; sig'masa — chap matn o'raladi, o'ng
  /// matn oxirgi qatorning o'ng chetida (yoki alohida qatorda).
  List<String> _pair(String left, String right) {
    if (right.isEmpty) return wrap(left, _w);
    if (left.isEmpty) return [right.padLeft(_w)];
    if (left.length + 1 + right.length <= _w) {
      return [left + right.padLeft(_w - left.length)];
    }
    final wrapped = wrap(left, _w);
    final last = wrapped.last;
    if (last.length + 1 + right.length <= _w) {
      return [
        ...wrapped.take(wrapped.length - 1),
        last + right.padLeft(_w - last.length),
      ];
    }
    return [...wrapped, right.padLeft(_w)];
  }

  /// So'z bo'yicha o'rash; juda uzun so'z — bo'linadi.
  static List<String> wrap(String text, int width) {
    final words = text.trim().split(RegExp(r'\s+'));
    final out = <String>[];
    var current = '';
    for (var word in words) {
      while (word.length > width) {
        if (current.isNotEmpty) {
          out.add(current);
          current = '';
        }
        out.add(word.substring(0, width));
        word = word.substring(width);
      }
      if (current.isEmpty) {
        current = word;
      } else if (current.length + 1 + word.length <= width) {
        current = '$current $word';
      } else {
        out.add(current);
        current = word;
      }
    }
    if (current.isNotEmpty || out.isEmpty) out.add(current);
    return out;
  }
}
