import 'package:flutter/foundation.dart';
import 'package:pos_app/core/money/money.dart';
import 'package:pos_app/data/sales/sale_writer.dart';

/// Chegirma: foiz (bazis punktda, 1% = 100) yoki summa (tiyin).
/// Katta chegirmani menejer/ega tasdiqlasa — [approvedBy] (`auth-roles.md`).
@immutable
class Discount {
  const Discount.percent(this.percentBp, {this.approvedBy}) : amountTiyin = 0;

  const Discount.amount(this.amountTiyin, {this.approvedBy}) : percentBp = 0;

  final int percentBp;
  final int amountTiyin;
  final String? approvedBy;

  bool get isPercent => percentBp > 0;

  /// [base] dan chegirma summasi (base dan oshmaydi).
  int of(int base) {
    final value = isPercent ? Money.percentOf(base, percentBp) : amountTiyin;
    return value.clamp(0, base < 0 ? 0 : base);
  }

  Discount approved(String userId) => isPercent
      ? Discount.percent(percentBp, approvedBy: userId)
      : Discount.amount(amountTiyin, approvedBy: userId);

  Map<String, Object> toJson() => {
    if (isPercent) 'percent_bp': percentBp else 'amount_tiyin': amountTiyin,
    'approved_by': ?approvedBy,
  };

  static Discount? fromJson(Object? json) {
    if (json is! Map) return null;
    final by = json['approved_by'] as String?;
    final bp = json['percent_bp'];
    if (bp is int && bp > 0) return Discount.percent(bp, approvedBy: by);
    final amount = json['amount_tiyin'];
    if (amount is int && amount > 0) {
      return Discount.amount(amount, approvedBy: by);
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is Discount &&
      other.percentBp == percentBp &&
      other.amountTiyin == amountTiyin &&
      other.approvedBy == approvedBy;

  @override
  int get hashCode => Object.hash(percentBp, amountTiyin, approvedBy);
}

/// Savat qatori. Narx va nom — qo'shilgan paytdagi surat (chekda shu chiqadi).
class CartLine {
  const CartLine({
    required this.id,
    required this.productId,
    required this.name,
    required this.unit,
    required this.qtyMilli,
    required this.priceTiyin,
    required this.costTiyin,
    this.weighted = false,
    this.barcode,
    this.discount,
  });

  final String id;
  final String productId;
  final String name;
  final String unit;
  final bool weighted;
  final String? barcode;
  final int qtyMilli;
  final int priceTiyin;
  final int costTiyin;
  final Discount? discount;

  int get grossTiyin => Money.lineTotal(priceTiyin, qtyMilli);

  int get discountTiyin => discount?.of(grossTiyin) ?? 0;

  int get totalTiyin => grossTiyin - discountTiyin;

  CartLine copyWith({
    int? qtyMilli,
    Discount? discount,
    bool clearDiscount = false,
  }) => CartLine(
    id: id,
    productId: productId,
    name: name,
    unit: unit,
    weighted: weighted,
    barcode: barcode,
    qtyMilli: qtyMilli ?? this.qtyMilli,
    priceTiyin: priceTiyin,
    costTiyin: costTiyin,
    discount: clearDiscount ? null : (discount ?? this.discount),
  );

  SaleLineInput toSaleLine() => SaleLineInput(
    productId: productId,
    name: name,
    barcode: barcode,
    qtyMilli: qtyMilli,
    priceTiyin: priceTiyin,
    costTiyin: costTiyin,
    discountTiyin: discountTiyin,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'product': productId,
    'name': name,
    'unit': unit,
    'weighted': weighted,
    'barcode': barcode,
    'qty_milli': qtyMilli,
    'price_tiyin': priceTiyin,
    'cost_tiyin': costTiyin,
    'discount': discount?.toJson(),
  };

  static CartLine? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final product = json['product'];
    final qty = json['qty_milli'];
    final price = json['price_tiyin'];
    if (id is! String || product is! String || qty is! int || price is! int) {
      return null;
    }
    return CartLine(
      id: id,
      productId: product,
      name: json['name'] as String? ?? '',
      unit: json['unit'] as String? ?? '',
      weighted: json['weighted'] == true,
      barcode: json['barcode'] as String?,
      qtyMilli: qty,
      priceTiyin: price,
      costTiyin: json['cost_tiyin'] as int? ?? 0,
      discount: Discount.fromJson(json['discount']),
    );
  }
}

/// Bitta chek (savat). Kassada bir vaqtda 5 tagacha — kechiktirilgan cheklar.
class Cart {
  const Cart({
    required this.id,
    required this.slot,
    this.lines = const [],
    this.customerId,
    this.discount,
  });

  final String id;

  /// Tab tartibi (0..4).
  final int slot;
  final List<CartLine> lines;
  final String? customerId;

  /// Chek chegirmasi.
  final Discount? discount;

  bool get isEmpty => lines.isEmpty;

  int get subtotalTiyin => lines.fold(0, (sum, l) => sum + l.totalTiyin);

  int get discountTiyin => discount?.of(subtotalTiyin) ?? 0;

  int get totalTiyin => subtotalTiyin - discountTiyin;

  /// Qator va chek chegirmalari jami.
  int get allDiscountsTiyin =>
      discountTiyin + lines.fold(0, (sum, l) => sum + l.discountTiyin);

  /// Dona tovarlar soni + vaznli qatorlar (har biri 1).
  int get itemCount => lines.fold(
    0,
    (sum, l) =>
        sum +
        (l.weighted ? 1 : (l.qtyMilli + Money.qtyScale - 1) ~/ Money.qtyScale),
  );

  Cart copyWith({
    List<CartLine>? lines,
    Discount? discount,
    bool clearDiscount = false,
    String? customerId,
    bool clearCustomer = false,
  }) => Cart(
    id: id,
    slot: slot,
    lines: lines ?? this.lines,
    customerId: clearCustomer ? null : (customerId ?? this.customerId),
    discount: clearDiscount ? null : (discount ?? this.discount),
  );

  /// Chegirmani tasdiqlagan menejer/ega (savdoning `approved_by`).
  String? get approvedBy {
    if (discount?.approvedBy != null) return discount!.approvedBy;
    for (final l in lines) {
      if (l.discount?.approvedBy != null) return l.discount!.approvedBy;
    }
    return null;
  }

  List<SaleLineInput> toSaleLines() => [for (final l in lines) l.toSaleLine()];
}
