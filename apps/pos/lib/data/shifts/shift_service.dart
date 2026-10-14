import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/data/ids.dart';
import 'package:pos_app/data/sync/outbox.dart';

/// Qurilmada smena allaqachon ochiq.
class ShiftAlreadyOpenException implements Exception {
  const ShiftAlreadyOpenException();
}

/// Smena yopilgan yoki topilmadi.
class ShiftNotOpenException implements Exception {
  const ShiftNotOpenException();
}

/// X hisobot (ochiq smena) yoki Z hisobot (yopilgan). Formula serverdagi
/// `apps/sales/services/shifts.py` `shift_report` / `expected_cash` bilan
/// bir xil (`docs/specs/sales-api.md`).
class ShiftReport {
  const ShiftReport({
    required this.shift,
    required this.salesCount,
    required this.salesTotal,
    required this.paymentsCash,
    required this.paymentsCard,
    required this.paymentsDebt,
    required this.refundsCount,
    required this.refundsCash,
    required this.refundsDebt,
    required this.cashIn,
    required this.cashOut,
    required this.debtPaymentsCash,
    required this.debtPaymentsCard,
    required this.expectedCash,
  });

  final Shift shift;
  final int salesCount;
  final int salesTotal;
  final int paymentsCash;
  final int paymentsCard;
  final int paymentsDebt;
  final int refundsCount;
  final int refundsCash;
  final int refundsDebt;
  final int cashIn;
  final int cashOut;
  final int debtPaymentsCash;
  final int debtPaymentsCard;

  /// Kassada bo'lishi kerak bo'lgan naqd: boshlang'ich + naqd savdo −
  /// naqd qaytarish + kiritilgan − chiqarilgan + naqd qarz to'lovlari.
  final int expectedCash;

  bool get isOpen => shift.closedAt == null;
  int get openingCash => shift.openingCashTiyin;
  int? get countedCash => shift.countedCashTiyin;

  /// Sanalgan − kutilgan (musbat — ortiqcha, manfiy — kam).
  int? get difference =>
      countedCash == null ? null : countedCash! - expectedCash;
}

/// Smena: ochilmaguncha savdo yo'q (`docs/specs/shifts.md`). Ochish va
/// yopish — lokal tranzaksiya + outbox (oflaynda ham).
class ShiftService {
  ShiftService(this._db, {IdGenerator? newId, DateTime Function()? now})
    : _newId = newId ?? _defaultId,
      _now = now ?? _clockNow;

  static String _defaultId() => newId();
  static DateTime _clockNow() => clock.now();

  final AppDatabase _db;
  final IdGenerator _newId;
  final DateTime Function() _now;

  SimpleSelectStatement<$ShiftsTable, Shift> _openQuery(String deviceId) =>
      _db.select(_db.shifts)
        ..where((s) => s.deviceId.equals(deviceId) & s.closedAt.isNull());

  Future<Shift?> currentShift(String deviceId) =>
      _openQuery(deviceId).getSingleOrNull();

  Stream<Shift?> watchCurrentShift(String deviceId) =>
      _openQuery(deviceId).watchSingleOrNull();

  /// Taklif: oxirgi yopilgan smenada sanalgan naqd (kassada qolgan pul).
  Future<int> suggestedOpeningCash(String deviceId) async {
    final last =
        await (_db.select(_db.shifts)
              ..where(
                (s) => s.deviceId.equals(deviceId) & s.closedAt.isNotNull(),
              )
              ..orderBy([
                (s) => OrderingTerm(
                  expression: s.closedAt,
                  mode: OrderingMode.desc,
                ),
              ])
              ..limit(1))
            .getSingleOrNull();
    return last?.countedCashTiyin ?? 0;
  }

  Future<Shift> open({
    required String deviceId,
    required String storeId,
    required String cashierId,
    required int openingCashTiyin,
  }) {
    if (openingCashTiyin < 0) throw ArgumentError.value(openingCashTiyin);
    return _db.transaction(() async {
      if (await currentShift(deviceId) != null) {
        throw const ShiftAlreadyOpenException();
      }
      final id = _newId();
      final now = _now();
      await _db
          .into(_db.shifts)
          .insert(
            ShiftsCompanion.insert(
              id: id,
              storeId: storeId,
              deviceId: deviceId,
              openedBy: cashierId,
              openedAt: now,
              openingCashTiyin: openingCashTiyin,
            ),
          );
      await _db.enqueueEvent(
        id: _newId(),
        type: OutboxEventType.shiftOpened,
        createdAt: now,
        payload: {
          'id': id,
          'cashier': cashierId,
          'opening_cash_tiyin': openingCashTiyin,
          'opened_at': isoUtc(now),
        },
      );
      return (_db.select(
        _db.shifts,
      )..where((s) => s.id.equals(id))).getSingle();
    });
  }

  /// Yopadi: kutilgan naqd shu paytdagi hisobotdan saqlanadi (Z hisobot).
  Future<ShiftReport> close({
    required String shiftId,
    required String closedBy,
    required int countedCashTiyin,
  }) {
    if (countedCashTiyin < 0) throw ArgumentError.value(countedCashTiyin);
    return _db.transaction(() async {
      final shift = await (_db.select(
        _db.shifts,
      )..where((s) => s.id.equals(shiftId))).getSingleOrNull();
      if (shift == null || shift.closedAt != null) {
        throw const ShiftNotOpenException();
      }
      final now = _now();
      final expected = (await report(shiftId)).expectedCash;
      await (_db.update(_db.shifts)..where((s) => s.id.equals(shiftId))).write(
        ShiftsCompanion(
          closedBy: Value(closedBy),
          closedAt: Value(now),
          countedCashTiyin: Value(countedCashTiyin),
          expectedCashTiyin: Value(expected),
        ),
      );
      await _db.enqueueEvent(
        id: _newId(),
        type: OutboxEventType.shiftClosed,
        createdAt: now,
        payload: {
          'id': shiftId,
          'closed_by': closedBy,
          'counted_cash_tiyin': countedCashTiyin,
          'closed_at': isoUtc(now),
        },
      );
      return report(shiftId);
    });
  }

  Future<ShiftReport> report(String shiftId) async {
    final shift = await (_db.select(
      _db.shifts,
    )..where((s) => s.id.equals(shiftId))).getSingle();

    Future<int> scalar(String sql, List<Variable<Object>> args) async {
      final row = await _db.customSelect(sql, variables: args).getSingle();
      return row.read<int>('v');
    }

    final id = Variable<String>(shiftId);
    final salesCount = await scalar(
      'SELECT COUNT(*) AS v FROM sales WHERE shift_id = ?',
      [id],
    );
    final salesTotal = await scalar(
      'SELECT COALESCE(SUM(total_tiyin), 0) AS v FROM sales WHERE shift_id = ?',
      [id],
    );
    Future<int> payments(String method) => scalar(
      'SELECT COALESCE(SUM(p.amount_tiyin), 0) AS v FROM sale_payments p '
      'JOIN sales s ON s.id = p.sale_id WHERE s.shift_id = ? AND p.method = ?',
      [id, Variable<String>(method)],
    );
    Future<int> refunds(String method) => scalar(
      'SELECT COALESCE(SUM(total_tiyin), 0) AS v FROM refunds '
      'WHERE shift_id = ? AND method = ?',
      [id, Variable<String>(method)],
    );
    Future<int> movements(String type) => scalar(
      'SELECT COALESCE(SUM(amount_tiyin), 0) AS v FROM cash_movements '
      'WHERE shift_id = ? AND type = ?',
      [id, Variable<String>(type)],
    );
    // Qarz to'lovi yozuvlari manfiy (`amount_tiyin < 0`).
    Future<int> debtPaid(String method) => scalar(
      'SELECT COALESCE(-SUM(amount_tiyin), 0) AS v FROM debt_entries '
      "WHERE shift_id = ? AND type = 'payment' AND method = ?",
      [id, Variable<String>(method)],
    );

    final cash = await payments('cash');
    final refundsCash = await refunds('cash');
    final cashIn = await movements('in');
    final cashOut = await movements('out');
    final debtCash = await debtPaid('cash');
    final open = shift.closedAt == null;
    final expected = open || shift.expectedCashTiyin == null
        ? shift.openingCashTiyin +
              cash -
              refundsCash +
              cashIn -
              cashOut +
              debtCash
        : shift.expectedCashTiyin!;

    return ShiftReport(
      shift: shift,
      salesCount: salesCount,
      salesTotal: salesTotal,
      paymentsCash: cash,
      paymentsCard: await payments('card'),
      paymentsDebt: await payments('debt'),
      refundsCount: await scalar(
        'SELECT COUNT(*) AS v FROM refunds WHERE shift_id = ?',
        [id],
      ),
      refundsCash: refundsCash,
      refundsDebt: await refunds('debt'),
      cashIn: cashIn,
      cashOut: cashOut,
      debtPaymentsCash: debtCash,
      debtPaymentsCard: await debtPaid('card'),
      expectedCash: expected,
    );
  }
}
