import 'package:flutter/foundation.dart';
import 'package:pos_app/core/format/app_format.dart';
import 'package:pos_app/core/format/unit_code.dart';
import 'package:pos_app/core/text/phone.dart';
import 'package:pos_app/data/shifts/shift_service.dart';
import 'package:pos_app/features/printing/mono_bitmap.dart';
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

/// Chekda ko'rsat/yashir (do'kon sozlamasi, `stores.receipt_options`).
/// Yo'q kalit — ko'rsatiladi (standart to'liq chek).
class ReceiptOptions {
  const ReceiptOptions({
    this.showLogo = true,
    this.showLegalName = true,
    this.showAddress = true,
    this.showPhone = true,
    this.showTin = true,
    this.showCashier = true,
    this.showBarcode = true,
    this.showHeader = true,
    this.showFooter = true,
    this.vatPayer = false,
  });

  factory ReceiptOptions.fromJson(Map<String, Object?> json) {
    bool flag(String key) {
      final value = json[key];
      return value is! bool || value;
    }

    return ReceiptOptions(
      showLogo: flag('show_logo'),
      showLegalName: flag('show_legal_name'),
      showAddress: flag('show_address'),
      showPhone: flag('show_phone'),
      showTin: flag('show_tin'),
      showCashier: flag('show_cashier'),
      showBarcode: flag('show_barcode'),
      showHeader: flag('show_header'),
      showFooter: flag('show_footer'),
      // Standart — yo'q (QQS to'lamaydigan do'kon ko'p).
      vatPayer: json['vat_payer'] == true,
    );
  }

  final bool showLogo;
  final bool showLegalName;
  final bool showAddress;
  final bool showPhone;
  final bool showTin;
  final bool showCashier;
  final bool showBarcode;
  final bool showHeader;
  final bool showFooter;

  /// Do'kon QQS to'lovchi: kassa ekranida "QQS (12%, ichida)" qatori
  /// (qaror 0014). Chekka hozircha chiqmaydi.
  final bool vatPayer;

  Map<String, bool> toJson() => {
    'show_logo': showLogo,
    'show_legal_name': showLegalName,
    'show_address': showAddress,
    'show_phone': showPhone,
    'show_tin': showTin,
    'show_cashier': showCashier,
    'show_barcode': showBarcode,
    'show_header': showHeader,
    'show_footer': showFooter,
    'vat_payer': vatPayer,
  };

  ReceiptOptions copyWith({
    bool? showLogo,
    bool? showLegalName,
    bool? showAddress,
    bool? showPhone,
    bool? showTin,
    bool? showCashier,
    bool? showBarcode,
    bool? showHeader,
    bool? showFooter,
    bool? vatPayer,
  }) => ReceiptOptions(
    showLogo: showLogo ?? this.showLogo,
    showLegalName: showLegalName ?? this.showLegalName,
    showAddress: showAddress ?? this.showAddress,
    showPhone: showPhone ?? this.showPhone,
    showTin: showTin ?? this.showTin,
    showCashier: showCashier ?? this.showCashier,
    showBarcode: showBarcode ?? this.showBarcode,
    showHeader: showHeader ?? this.showHeader,
    showFooter: showFooter ?? this.showFooter,
    vatPayer: vatPayer ?? this.vatPayer,
  );
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
    this.legalName = '',
    this.tin = '',
    this.logo,
    this.options = const ReceiptOptions(),
  });

  final String storeName;

  /// Yuridik nomi va STIR/JShShIR — faqat kiritilgan bo'lsa chiqadi.
  final String legalName;
  final String tin;

  /// Logotip (kulrang); chop etishda qog'oz kengligiga moslanadi.
  final GrayImage? logo;
  final ReceiptOptions options;
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

  /// Do'kon qismi almashtirilgan nusxa (sozlamada saqlanmagan o'zgarishlar
  /// chek ko'rinishida darhol ko'rinsin).
  ReceiptData withStore({
    required String storeName,
    required String storeAddress,
    required String storePhone,
    required String header,
    required String footer,
    required String legalName,
    required String tin,
    required GrayImage? logo,
    required ReceiptOptions options,
  }) => ReceiptData(
    storeName: storeName,
    storeAddress: storeAddress,
    storePhone: storePhone,
    header: header,
    footer: footer,
    legalName: legalName,
    tin: tin,
    logo: logo,
    options: options,
    number: number,
    soldAt: soldAt,
    cashierName: cashierName,
    lines: lines,
    discountTiyin: discountTiyin,
    totalTiyin: totalTiyin,
    payments: payments,
    customerName: customerName,
    customerDebtTiyin: customerDebtTiyin,
  );
}

/// Chek kengligi (`printing.md`): 58 mm — 32 belgi, 80 mm — 48 belgi;
/// ba'zi 80 mm printerlar (512 nuqta) 42 belgi sig'diradi.
enum PaperWidth {
  mm58(32, 58),
  mm80(48, 80),
  mm80narrow(42, 80)
  ;

  const PaperWidth(this.chars, this.mm);

  final int chars;
  final int mm;
}

/// Chek qatori va uning ko'rinishi (ESC/POS kodlovchi uchun).
@immutable
class ReceiptRow {
  const ReceiptRow(
    this.text, {
    this.bold = false,
    this.center = false,
    this.barcode = false,
    this.tall = false,
  }) : image = null;

  /// Chek raqami shtrix-kodi (CODE128): qaytarishda skanerlanadi.
  const ReceiptRow.barcode(this.text)
    : bold = false,
      center = true,
      barcode = true,
      tall = false,
      image = null;

  /// Rasm (logotip): markazda, printer kengligidan oshmaydi.
  const ReceiptRow.image(MonoBitmap this.image)
    : text = '',
      bold = false,
      center = true,
      barcode = false,
      tall = false;

  /// Logotip (`GS v 0`) — matn emas.
  final MonoBitmap? image;

  final String text;
  final bool bold;
  final bool center;
  final bool barcode;

  /// Ikki barobar baland (JAMI) — kenglik o'zgarmaydi, ustunlar buzilmaydi.
  final bool tall;

  @override
  bool operator ==(Object other) =>
      other is ReceiptRow &&
      other.text == text &&
      other.bold == bold &&
      other.center == center &&
      other.barcode == barcode &&
      other.tall == tall &&
      identical(other.image, image);

  @override
  int get hashCode => Object.hash(text, bold, center, barcode, tall, image);

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

  /// Printerning chop etish kengligi (nuqta): 58 mm — 384, 80 mm — 576.
  int get dots => width.mm == 58 ? 384 : 576;

  List<ReceiptRow> build(ReceiptData data, {bool copy = false}) {
    final rows = <ReceiptRow>[];
    void center(String text, {bool bold = false}) {
      for (final part in wrap(plain(text), _w)) {
        rows.add(ReceiptRow(part, bold: bold, center: true));
      }
    }

    void line(String text, {bool bold = false, bool tall = false}) =>
        rows.add(ReceiptRow(text, bold: bold, tall: tall));
    void divider() => line('-' * _w);
    void pair(
      String left,
      String right, {
      bool bold = false,
      bool tall = false,
    }) {
      for (final text in _pair(plain(left), plain(right))) {
        line(text, bold: bold, tall: tall);
      }
    }

    // Sarlavha: bo'sh va yashirilgan maydonlar chiqmaydi. Soliq raqami —
    // faqat kiritilgan bo'lsa (hech qachon taxmin qilinmaydi).
    final o = data.options;
    final logo = data.logo;
    if (o.showLogo && logo != null) {
      rows.add(ReceiptRow.image(MonoBitmap.fromGray(logo, maxDots: dots)));
    }
    if (data.storeName.trim().isNotEmpty) center(data.storeName, bold: true);
    final tin = data.tin.trim();
    for (final extra in [
      if (o.showLegalName) data.legalName,
      if (o.showAddress) data.storeAddress,
      if (o.showPhone) displayPhone(data.storePhone),
      if (o.showTin && tin.isNotEmpty)
        '${tin.length == 14 ? l10n.receiptPinfl : l10n.receiptTin}: $tin',
      if (o.showHeader) ...data.header.split('\n'),
    ]) {
      if (extra.trim().isNotEmpty) center(extra.trim());
    }
    if (copy) center(l10n.receiptCopy, bold: true);
    divider();
    pair('${l10n.receiptCheck}: ${data.number}', _fmt.dateTime(data.soldAt));
    if (o.showCashier && data.cashierName.trim().isNotEmpty) {
      pair('${l10n.receiptCashier}: ${data.cashierName}', '');
    }
    divider();

    // Qatorlar: nom va "miqdor x narx", keyingi qatorda — jami. Birlik —
    // donadan boshqa hamma birlikda (kg, g, l, qadoq): "250 x 100" emas.
    for (final item in data.lines) {
      final qty = item.unit != UnitCode.pcs || item.qtyMilli % 1000 != 0
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
      // Chegirmadan oldingi summa — xaridor hisobni tekshira olsin.
      pair(
        l10n.receiptSubtotal,
        _amount(data.totalTiyin + data.discountTiyin),
      );
      pair(l10n.receiptDiscount, _amount(-data.discountTiyin));
    }
    pair(
      l10n.receiptTotal,
      _amount(data.totalTiyin),
      bold: true,
      tall: true,
    );
    // To'lovlar — chekka tushgan summa (yig'indisi JAMI ga teng); naqd
    // berilgan pul va qaytim — alohida.
    for (final p in data.payments) {
      final label = switch (p.method) {
        'cash' => l10n.payCash,
        'card' => l10n.payCard,
        _ => l10n.payDebt,
      };
      pair(label, _amount(p.amountTiyin));
    }
    final received = data.payments
        .where((p) => p.method == 'cash' && p.receivedTiyin != null)
        .fold(0, (sum, p) => sum + p.receivedTiyin!);
    if (data.changeTiyin > 0 && received > 0) {
      pair(l10n.receiptReceived, _amount(received));
    }
    if (data.changeTiyin > 0) {
      pair(l10n.changeLabel, _amount(data.changeTiyin));
    }
    final customer = data.customerName;
    if (customer != null) {
      divider();
      pair('${l10n.receiptCustomer}: $customer', '');
      final debt = data.customerDebtTiyin;
      if (debt != null) pair(l10n.receiptDebtAfter, _amount(debt));
    }
    divider();

    if (o.showBarcode) rows.add(ReceiptRow.barcode(data.number));
    if (o.showFooter) {
      final footer = data.footer.trim().isEmpty
          ? l10n.receiptThanks
          : data.footer.trim();
      footer.split('\n').forEach(center);
    }
    center(l10n.receiptNotFiscal);
    return rows;
  }

  /// X/Z hisobot cheki (smena sahifasidagi hisobot bilan bir xil raqamlar).
  List<ReceiptRow> buildShift(
    ShiftReport report, {
    required String storeName,
    required String cashierName,
    required DateTime printedAt,
  }) {
    final rows = <ReceiptRow>[];
    void center(String text, {bool bold = false}) {
      for (final part in wrap(plain(text), _w)) {
        rows.add(ReceiptRow(part, bold: bold, center: true));
      }
    }

    void divider() => rows.add(ReceiptRow('-' * _w));
    void pair(String left, String right, {bool bold = false}) {
      for (final text in _pair(plain(left), plain(right))) {
        rows.add(ReceiptRow(text, bold: bold));
      }
    }

    void money(String label, int tiyin, {bool bold = false}) =>
        pair(label, _amount(tiyin), bold: bold);
    void title(String text) => rows.add(ReceiptRow(plain(text), bold: true));

    final shift = report.shift;
    if (storeName.trim().isNotEmpty) center(storeName, bold: true);
    center(report.isOpen ? l10n.shiftXReport : l10n.shiftZReport, bold: true);
    divider();
    pair(l10n.receiptShiftOpened, _fmt.dateTime(shift.openedAt));
    final closedAt = shift.closedAt;
    if (closedAt != null) {
      pair(l10n.receiptShiftClosed, _fmt.dateTime(closedAt));
    } else {
      pair(l10n.receiptPrintedAt, _fmt.dateTime(printedAt));
    }
    if (cashierName.trim().isNotEmpty) {
      pair('${l10n.receiptCashier}: $cashierName', '');
    }
    divider();

    title('${l10n.reportSales} · ${l10n.reportChecks(report.salesCount)}');
    money(l10n.receiptTotal, report.salesTotal, bold: true);
    money(l10n.reportCash, report.paymentsCash);
    money(l10n.reportCard, report.paymentsCard);
    money(l10n.reportDebt, report.paymentsDebt);
    divider();
    title(
      '${l10n.reportRefunds} · ${l10n.reportChecks(report.refundsCount)}',
    );
    money(l10n.reportCash, report.refundsCash);
    money(l10n.reportDebt, report.refundsDebt);
    divider();
    title(l10n.reportCashMovements);
    money(l10n.reportCashIn, report.cashIn);
    money(l10n.reportCashOut, report.cashOut);
    divider();
    title(l10n.reportDebtPayments);
    money(l10n.reportCash, report.debtPaymentsCash);
    money(l10n.reportCard, report.debtPaymentsCard);
    divider();
    title(l10n.reportCashBalance);
    money(l10n.reportOpeningCash, report.openingCash);
    money(l10n.reportExpectedCash, report.expectedCash, bold: true);
    final counted = report.countedCash;
    final difference = report.difference;
    if (counted != null) money(l10n.reportCountedCash, counted);
    if (difference != null) {
      money(
        difference == 0
            ? l10n.reportNoDifference
            : (difference > 0 ? l10n.reportSurplus : l10n.reportShortage),
        difference,
        bold: true,
      );
    }
    divider();
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

  /// Oddiy matn — printer jadvalida bor belgilar: bo'shliq, defis, tutuq
  /// belgisi; qo'shtirnoq, ko'p nuqta, ×, urg'uli lotin harflari — eng
  /// yaqiniga (aks holda qog'ozda `?`); boshqaruv belgilari va emoji
  /// olib tashlanadi (ustunlar surilmasin, printer buyrug'iga aylanmasin).
  static String plain(String text) {
    final out = StringBuffer();
    for (final rune in text.runes) {
      if (rune < 0x20 || (rune >= 0x7f && rune < 0xa0) || rune > 0xffff) {
        continue;
      }
      final ch = String.fromCharCode(rune);
      out.write(_plainMap[ch] ?? ch);
    }
    return out.toString();
  }

  static const Map<String, String> _plainMap = {
    '\u00a0': ' ',
    '\u202f': ' ',
    '\u2007': ' ',
    '\u2009': ' ',
    '\u2212': '-',
    '\u2013': '-',
    '\u2014': '-',
    '\u00b7': '-',
    '\u2022': '-',
    '\u02bb': "'",
    '\u02bc': "'",
    '\u2018': "'",
    '\u2019': "'",
    '`': "'",
    '\u00b4': "'",
    '\u201b': "'",
    '\u00ab': '"',
    '\u00bb': '"',
    '\u201c': '"',
    '\u201d': '"',
    '\u201e': '"',
    '\u2033': '"',
    '\u2026': '...',
    '\u00d7': 'x',
    '\u00e0': 'a',
    '\u00e1': 'a',
    '\u00e2': 'a',
    '\u00e3': 'a',
    '\u00e4': 'a',
    '\u00e5': 'a',
    '\u00e8': 'e',
    '\u00e9': 'e',
    '\u00ea': 'e',
    '\u00eb': 'e',
    '\u00ec': 'i',
    '\u00ed': 'i',
    '\u00ee': 'i',
    '\u00ef': 'i',
    '\u0131': 'i',
    '\u00f2': 'o',
    '\u00f3': 'o',
    '\u00f4': 'o',
    '\u00f5': 'o',
    '\u00f6': 'o',
    '\u00f9': 'u',
    '\u00fa': 'u',
    '\u00fb': 'u',
    '\u00fc': 'u',
    '\u00e7': 'c',
    '\u00f1': 'n',
    '\u015f': 's',
    '\u011f': 'g',
    '\u00c0': 'A',
    '\u00c1': 'A',
    '\u00c2': 'A',
    '\u00c4': 'A',
    '\u00c9': 'E',
    '\u00c8': 'E',
    '\u00d6': 'O',
    '\u00dc': 'U',
    '\u00c7': 'C',
    '\u015e': 'S',
    '\u011e': 'G',
    '\u0130': 'I',
    '\u00d1': 'N',
  };

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
