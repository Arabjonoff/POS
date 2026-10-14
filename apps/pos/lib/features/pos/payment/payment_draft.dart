import 'package:pos_app/data/sales/sale_writer.dart';

/// To'lov turi (oynadagi tab).
enum PayMode { cash, card, debt, mixed }

/// To'lov nega tasdiqlanmaydi (ekran sababni ko'rsatadi).
enum PaymentProblem {
  /// Naqd olingan summa yetmaydi.
  notEnoughCash,

  /// Aralash: karta + nasiya jamidan oshib ketdi.
  partsExceedTotal,

  /// Nasiya bor, mijoz tanlanmagan.
  customerRequired,
}

/// To'lov oynasi holati — sof hisob (pul faqat tiyin, `docs/specs/pos-screen.md`).
///
/// - Naqd: butun summa naqd; [receivedTiyin] `null` — "Aniq" (qaytimsiz).
/// - Karta: butun summa karta (terminalda to'landi).
/// - Nasiya: butun summa mijoz qarziga.
/// - Aralash: [cardTiyin] + [debtTiyin], qolgani naqd.
class PaymentDraft {
  const PaymentDraft({
    required this.totalTiyin,
    this.mode = PayMode.cash,
    this.receivedTiyin,
    this.cardTiyin = 0,
    this.debtTiyin = 0,
    this.customerId,
  });

  final int totalTiyin;
  final PayMode mode;

  /// Mijoz bergan naqd (`null` — aniq summa).
  final int? receivedTiyin;
  final int cardTiyin;
  final int debtTiyin;
  final String? customerId;

  /// Tez summalar (so'm): naqd uchun "Aniq" dan keyin.
  static const List<int> quickCashSom = [50000, 100000, 200000];

  int get cardPart => switch (mode) {
    PayMode.card => totalTiyin,
    PayMode.mixed => cardTiyin,
    _ => 0,
  };

  int get debtPart => switch (mode) {
    PayMode.debt => totalTiyin,
    PayMode.mixed => debtTiyin,
    _ => 0,
  };

  /// Naqd to'lanishi kerak bo'lgan qism.
  int get cashDue => switch (mode) {
    PayMode.cash => totalTiyin,
    PayMode.mixed => totalTiyin - cardTiyin - debtTiyin,
    _ => 0,
  };

  int get received => receivedTiyin ?? cashDue;

  int get changeTiyin {
    final due = cashDue;
    return due > 0 && received > due ? received - due : 0;
  }

  PaymentProblem? get problem {
    if (mode == PayMode.mixed &&
        (cardTiyin < 0 || debtTiyin < 0 || cashDue < 0)) {
      return PaymentProblem.partsExceedTotal;
    }
    if (cashDue > 0 && received < cashDue) return PaymentProblem.notEnoughCash;
    if (debtPart > 0 && customerId == null) {
      return PaymentProblem.customerRequired;
    }
    return null;
  }

  bool get isValid => totalTiyin > 0 && problem == null;

  /// `SaleWriter` uchun to'lovlar (nol qismlarsiz).
  List<SalePaymentInput> toPayments() => [
    if (cashDue > 0)
      SalePaymentInput.cash(amountTiyin: cashDue, receivedTiyin: received),
    if (cardPart > 0) SalePaymentInput.card(amountTiyin: cardPart),
    if (debtPart > 0) SalePaymentInput.debt(amountTiyin: debtPart),
  ];

  PaymentDraft copyWith({
    PayMode? mode,
    int? receivedTiyin,
    bool exact = false,
    int? cardTiyin,
    int? debtTiyin,
    String? customerId,
    bool clearCustomer = false,
  }) => PaymentDraft(
    totalTiyin: totalTiyin,
    mode: mode ?? this.mode,
    receivedTiyin: exact ? null : (receivedTiyin ?? this.receivedTiyin),
    cardTiyin: cardTiyin ?? this.cardTiyin,
    debtTiyin: debtTiyin ?? this.debtTiyin,
    customerId: clearCustomer ? null : (customerId ?? this.customerId),
  );
}
