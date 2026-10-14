import 'dart:convert';
import 'dart:typed_data';

import 'package:pos_app/core/money/money.dart';

/// Buyurtma ro'yxati qatori (`products.md`, T-054).
class OrderLine {
  const OrderLine({
    required this.name,
    required this.barcode,
    required this.stockMilli,
    required this.minMilli,
    required this.orderMilli,
    required this.costTiyin,
    required this.fractional,
  });

  final String name;
  final String barcode;
  final int stockMilli;
  final int minMilli;
  final int orderMilli;
  final int costTiyin;

  /// Kasrli birlik (kg, l) — miqdor 3 xonagacha.
  final bool fractional;

  int get sumTiyin => Money.lineTotal(costTiyin, orderMilli);
}

/// Buyurtma = `2 × min − qoldiq` (minimal qoldiqning ikki baravariga
/// yetkazish); dona tovarda butun songa yuqoriga yaxlitlanadi.
int orderQtyMilli({
  required int minMilli,
  required int stockMilli,
  required bool fractional,
}) {
  final need = 2 * minMilli - stockMilli;
  if (need <= 0) return 0;
  if (fractional) return need;
  return ((need + 999) ~/ 1000) * 1000;
}

/// Ustun sarlavhalari — tarjimadan.
class OrderListHeaders {
  const OrderListHeaders({
    required this.name,
    required this.barcode,
    required this.stock,
    required this.min,
    required this.order,
    required this.cost,
    required this.sum,
  });

  final String name;
  final String barcode;
  final String stock;
  final String min;
  final String order;
  final String cost;
  final String sum;
}

String _qty(int milli, {required bool fractional}) {
  final sign = milli < 0 ? '-' : '';
  final abs = milli.abs();
  if (!fractional || abs % 1000 == 0) return '$sign${abs ~/ 1000}';
  final frac = (abs % 1000)
      .toString()
      .padLeft(3, '0')
      .replaceFirst(
        RegExp(r'0+$'),
        '',
      );
  return '$sign${abs ~/ 1000},$frac';
}

String _money(int tiyin) {
  final rest = tiyin % 100;
  return rest == 0
      ? '${tiyin ~/ 100}'
      : '${tiyin ~/ 100},${rest.toString().padLeft(2, '0')}';
}

String _cell(String value) => value.contains(RegExp('[;"\r\n]'))
    ? '"${value.replaceAll('"', '""')}"'
    : value;

/// CSV (Excel uchun: UTF-8 BOM, `;`, vergul — kasr belgisi).
Uint8List orderListCsv(List<OrderLine> lines, OrderListHeaders h) {
  final rows = [
    [h.name, h.barcode, h.stock, h.min, h.order, h.cost, h.sum],
    for (final l in lines)
      [
        l.name,
        l.barcode,
        _qty(l.stockMilli, fractional: l.fractional),
        _qty(l.minMilli, fractional: l.fractional),
        _qty(l.orderMilli, fractional: l.fractional),
        _money(l.costTiyin),
        _money(l.sumTiyin),
      ],
  ];
  final text = rows.map((r) => r.map(_cell).join(';')).join('\r\n');
  return Uint8List.fromList([0xef, 0xbb, 0xbf, ...utf8.encode('$text\r\n')]);
}
