import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/app/session/session.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/features/pos/cart/cart.dart';

/// Chegirma huquqi (`auth-roles.md`: "katta chegirma" — menejer/ega PIN).
/// Kassir [cashierMaxBp] gacha o'zi beradi, undan katta — tasdiq kerak;
/// menejer va ega — tasdiqsiz. Chegara — lokal sozlama (Q-005).
class DiscountPolicy {
  const DiscountPolicy({required this.role, this.cashierMaxBp = defaultMaxBp});

  /// Standart chegara — 5% (Q-005).
  static const int defaultMaxBp = 500;

  static const String settingKey = 'discount_cashier_max_bp';

  final String? role;
  final int cashierMaxBp;

  static bool canApprove(String role) => role == 'manager' || role == 'owner';

  /// [base] — chegirma qo'llanadigan summa (qator yoki chek).
  bool needsApproval(Discount discount, int base) {
    if (role != null && canApprove(role!)) return false;
    if (discount.approvedBy != null) return false;
    // Yaxlitlashsiz: chegirma / base > max (butun sonlarda).
    return discount.of(base) * 10000 > cashierMaxBp * base;
  }
}

final discountPolicyProvider = FutureProvider<DiscountPolicy>((ref) async {
  final role = ref.watch(sessionProvider.select((s) => s.user?.role));
  final raw = await ref
      .watch(appDatabaseProvider)
      .readSetting(DiscountPolicy.settingKey);
  return DiscountPolicy(
    role: role,
    cashierMaxBp: int.tryParse(raw ?? '') ?? DiscountPolicy.defaultMaxBp,
  );
});
