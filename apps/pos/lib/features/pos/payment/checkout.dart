import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/app/session/session.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/data/sales/sale_writer.dart';
import 'package:pos_app/features/pos/cart/cart.dart';
import 'package:pos_app/features/pos/payment/payment_draft.dart';
import 'package:pos_app/features/shift/shift_providers.dart';

/// Yakunlangan savdo: chek raqami va qaytim (xabar uchun).
class CheckoutResult {
  const CheckoutResult({required this.sale, required this.changeTiyin});

  final RecordedSale sale;
  final int changeTiyin;
}

/// Savat + to'lov → savdo. Hammasi `SaleWriter` ning **bitta SQLite
/// tranzaksiyasida** (Sale + qatorlar + to'lovlar + qoldiq + qarz + outbox);
/// xato bo'lsa hech narsa yozilmaydi va savat joyida qoladi.
class Checkout {
  const Checkout(this._writer, {this.storeId});

  final SaleWriter _writer;
  final String? storeId;

  Future<CheckoutResult> complete({
    required Cart cart,
    required PaymentDraft payment,
    required String shiftId,
    required String cashierId,
    String? debtApprovedBy,
  }) async {
    if (payment.totalTiyin != cart.totalTiyin || !payment.isValid) {
      throw const InvalidSaleException('payment_not_ready');
    }
    final sale = await _writer.complete(
      CompletedSaleInput(
        shiftId: shiftId,
        cashierId: cashierId,
        storeId: storeId,
        customerId: payment.debtPart > 0
            ? payment.customerId
            : (payment.customerId ?? cart.customerId),
        // Limitdan oshishni tasdiqlagan — ustun; aks holda chegirmaniki.
        approvedBy: debtApprovedBy ?? cart.approvedBy,
        lines: cart.toSaleLines(),
        discountTiyin: cart.discountTiyin,
        payments: payment.toPayments(),
      ),
    );
    return CheckoutResult(sale: sale, changeTiyin: payment.changeTiyin);
  }
}

/// Ochiq smena va kirgan kassir bilan savdoni yozadi (to'lov oynasi va bir
/// bosishli Naqd/Karta). Smena yoki kassir yo'q — `null` (ekran "saqlab
/// bo'lmadi" deydi); yozish xatosi — istisno (savat joyida qoladi).
Future<CheckoutResult?> checkoutNow(
  WidgetRef ref, {
  required Cart cart,
  required PaymentDraft payment,
  String? debtApprovedBy,
}) async {
  // Smena bazadan (kesh eskirgan bo'lishi mumkin, T-106).
  final shift = await openShiftNow(ref);
  final user = ref.read(sessionProvider).user;
  if (shift == null || user == null) return null;
  return ref
      .read(checkoutProvider)
      .complete(
        cart: cart,
        payment: payment,
        shiftId: shift.id,
        cashierId: user.id,
        debtApprovedBy: debtApprovedBy,
      );
}

final checkoutProvider = Provider<Checkout>((ref) {
  final device = ref.watch(sessionProvider.select((s) => s.device));
  return Checkout(
    SaleWriter(
      ref.watch(appDatabaseProvider),
      deviceNumber: device?.number ?? 0,
    ),
    storeId: device?.storeId,
  );
});
