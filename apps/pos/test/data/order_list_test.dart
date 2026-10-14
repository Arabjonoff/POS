import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/data/catalog/order_list.dart';

const OrderListHeaders headers = OrderListHeaders(
  name: 'Nomi',
  barcode: 'Shtrix-kod',
  stock: 'Qoldiq',
  min: 'Minimal qoldiq',
  order: 'Buyurtma',
  cost: 'Tannarx',
  sum: 'Summa',
);

void main() {
  test('order qty: up to twice the minimum; pieces rounded up', () {
    expect(
      orderQtyMilli(minMilli: 5000, stockMilli: 3000, fractional: false),
      7000,
    );
    expect(
      orderQtyMilli(minMilli: 5000, stockMilli: -2000, fractional: false),
      12000,
    );
    expect(
      orderQtyMilli(minMilli: 5000, stockMilli: 3500, fractional: false),
      7000,
    );
    expect(
      orderQtyMilli(minMilli: 2000, stockMilli: 1250, fractional: true),
      2750,
    );
    expect(
      orderQtyMilli(minMilli: 5000, stockMilli: 12000, fractional: false),
      0,
    );
  });

  test('csv: BOM, semicolons, decimal comma, quoted names', () {
    final bytes = orderListCsv(const [
      OrderLine(
        name: 'Sut 1 L',
        barcode: '4600000000015',
        stockMilli: 3000,
        minMilli: 5000,
        orderMilli: 7000,
        costTiyin: 950000,
        fractional: false,
      ),
      OrderLine(
        name: 'Olma "qizil"; navli',
        barcode: '',
        stockMilli: 1250,
        minMilli: 2000,
        orderMilli: 2750,
        costTiyin: 1100050,
        fractional: true,
      ),
    ], headers);
    expect(bytes.take(3), [0xef, 0xbb, 0xbf]);
    expect(
      utf8.decode(bytes.sublist(3)),
      [
        'Nomi;Shtrix-kod;Qoldiq;Minimal qoldiq;Buyurtma;Tannarx;Summa',
        'Sut 1 L;4600000000015;3;5;7;9500;66500',
        '"Olma ""qizil""; navli";;1,25;2;2,75;11000,50;30251,38',
        '',
      ].join('\r\n'),
    );
  });
}
