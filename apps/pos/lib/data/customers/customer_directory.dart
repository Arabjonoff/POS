import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/core/text/clean_text.dart';
import 'package:pos_app/core/text/phone.dart';
import 'package:pos_app/core/text/search_key.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/data/ids.dart';
import 'package:pos_app/data/sync/outbox.dart';

/// Kassa uchun mijoz: nasiya va F4.
class CustomerEntry {
  const CustomerEntry({
    required this.id,
    required this.name,
    required this.phone,
    required this.balanceTiyin,
    this.limitTiyin,
  });

  final String id;
  final String name;
  final String phone;

  /// Joriy qarz (+ — mijoz qarzdor).
  final int balanceTiyin;

  /// `null` — cheklovsiz.
  final int? limitTiyin;

  /// `balans + summa ≤ limit` (`customers-api.md`, `check_debt_limit`).
  bool allowsDebt(int amountTiyin) =>
      limitTiyin == null || balanceTiyin + amountTiyin <= limitTiyin!;

  /// Limitgacha qolgan summa (`null` — cheklovsiz).
  int? get availableTiyin =>
      limitTiyin == null ? null : limitTiyin! - balanceTiyin;
}

/// Mijoz kartasi uchun to'liq ma'lumot.
class CustomerDetails {
  const CustomerDetails({
    required this.id,
    required this.name,
    required this.phone,
    required this.note,
    required this.balanceTiyin,
    this.limitTiyin,
  });

  final String id;
  final String name;
  final String phone;
  final String note;
  final int balanceTiyin;
  final int? limitTiyin;
}

/// Qarz daftari yozuvi: `sale` (+), `payment` / `refund` (−),
/// `adjustment` (±).
class DebtRecord {
  const DebtRecord({
    required this.id,
    required this.type,
    required this.amountTiyin,
    required this.at,
    this.method,
    this.note = '',
    this.saleNumber,
    this.byName,
  });

  final String id;
  final String type;
  final int amountTiyin;
  final DateTime at;
  final String? method;
  final String note;
  final String? saleNumber;
  final String? byName;
}

class PurchaseRecord {
  const PurchaseRecord({
    required this.number,
    required this.soldAt,
    required this.totalTiyin,
    required this.status,
  });

  final String number;
  final DateTime soldAt;
  final int totalTiyin;
  final String status;
}

/// To'lov joriy qarzdan ko'p (`payment_exceeds_debt`).
class PaymentExceedsDebtException implements Exception {
  const PaymentExceedsDebtException(this.balanceTiyin);

  final int balanceTiyin;
}

/// Boshlang'ich balans (T-103): [credit] — do'kon mijozga qarzdor (avans),
/// aks holda mijoz do'konga qarzdor. [amountTiyin] > 0. [approvedBy] — avansni
/// tasdiqlagan menejer/ega (kassir kiritsa).
class OpeningBalanceInput {
  const OpeningBalanceInput({
    required this.amountTiyin,
    required this.at,
    this.credit = false,
    this.approvedBy,
  });

  final int amountTiyin;
  final DateTime at;
  final bool credit;
  final String? approvedBy;
}

/// Lokal mijozlar ro'yxati. Balans = qarz daftari yozuvlari yig'indisi
/// (`debts.md`): pull'dan kelganlar + shu kassada oflayn yozilganlar bir
/// jadvalda. Yozuvi umuman yo'q mijozda — serverdagi balans (tarix hali
/// kelmagan bo'lsa).
class CustomerDirectory {
  CustomerDirectory(this._db, {IdGenerator? newId, DateTime Function()? now})
    : _newId = newId ?? _defaultId,
      _now = now ?? _clockNow;

  static String _defaultId() => newId();
  static DateTime _clockNow() => clock.now();

  final AppDatabase _db;
  final IdGenerator _newId;
  final DateTime Function() _now;

  static const String _sql = '''
SELECT c.id, c.full_name, c.phone, c.debt_limit_tiyin, c.balance_tiyin,
       COUNT(d.id) AS entries, COALESCE(SUM(d.amount_tiyin), 0) AS ledger
FROM customers c
LEFT JOIN debt_entries d ON d.customer_id = c.id
WHERE c.deleted_at IS NULL
GROUP BY c.id
ORDER BY c.full_name
''';

  Selectable<CustomerEntry> _all() => _db
      .customSelect(_sql, readsFrom: {_db.customers, _db.debtEntries})
      .map(
        (r) => CustomerEntry(
          id: r.read<String>('id'),
          name: r.read<String>('full_name'),
          phone: r.read<String>('phone'),
          limitTiyin: r.readNullable<int>('debt_limit_tiyin'),
          balanceTiyin: r.read<int>('entries') > 0
              ? r.read<int>('ledger')
              : r.read<int>('balance_tiyin'),
        ),
      );

  Stream<List<CustomerEntry>> watchAll() => _all().watch();

  Future<List<CustomerEntry>> all() => _all().get();

  Future<CustomerEntry?> byId(String id) async {
    for (final c in await all()) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Ism (lotin/kirill farqsiz) yoki telefon raqamlari bo'yicha.
  static List<CustomerEntry> filter(List<CustomerEntry> all, String query) {
    final key = SearchKey.of(query);
    if (key.isEmpty) return all;
    final digits = query.replaceAll(RegExp(r'\D'), '');
    final tokens = key.split(' ');
    return [
      for (final c in all)
        if ((digits.length >= 3 &&
                c.phone.replaceAll(RegExp(r'\D'), '').contains(digits)) ||
            tokens.every(SearchKey.of(c.name).contains))
          c,
    ];
  }

  /// Tez yaratish (kassada): mijoz + `customer.upserted` hodisasi bitta
  /// tranzaksiyada. Limit — cheklovsiz (`null`), egasi keyin belgilaydi.
  ///
  /// [opening] — boshlang'ich balans (T-103): `opening` qarz yozuvi shu
  /// tranzaksiyada va shu hodisada (`opening_balance`). Faqat yaratishda —
  /// [update] uni hech qachon yozmaydi (balans ikki marta qo'shilmaydi).
  Future<CustomerEntry> create({
    required String name,
    required String createdBy,
    String phone = '',
    OpeningBalanceInput? opening,
  }) async {
    final normalized = normalizePhone(phone);
    if (normalized == null) throw ArgumentError.value(phone, 'phone');
    if (opening != null && opening.amountTiyin <= 0) {
      throw ArgumentError.value(opening.amountTiyin, 'opening.amountTiyin');
    }
    final id = _newId();
    final now = _now();
    final openingId = opening == null ? null : _newId();
    final signed = opening == null
        ? 0
        : (opening.credit ? -opening.amountTiyin : opening.amountTiyin);
    await _db.transaction(() async {
      await _db
          .into(_db.customers)
          .insert(
            CustomersCompanion.insert(
              id: id,
              fullName: cleanLine(name),
              phone: Value(normalized),
              updatedAt: Value(now),
            ),
          );
      if (opening != null) {
        await _db
            .into(_db.debtEntries)
            .insert(
              DebtEntriesCompanion.insert(
                id: openingId!,
                customerId: id,
                amountTiyin: signed,
                type: 'opening',
                byUserId: Value(opening.approvedBy ?? createdBy),
                at: opening.at,
              ),
            );
      }
      await _db.enqueueEvent(
        id: _newId(),
        type: OutboxEventType.customerUpserted,
        createdAt: now,
        payload: {
          'id': id,
          'full_name': cleanLine(name),
          'phone': normalized,
          'note': '',
          // Avansni kassir emas, ruxsat bergan menejer kiritgan bo'ladi.
          'by': opening?.approvedBy ?? createdBy,
          if (opening != null)
            'opening_balance': {
              'id': openingId,
              'direction': opening.credit ? 'credit' : 'debt',
              'amount_tiyin': opening.amountTiyin,
              'at': isoUtc(opening.at),
            },
        },
      );
    });
    return CustomerEntry(
      id: id,
      name: cleanLine(name),
      phone: normalized,
      balanceTiyin: signed,
    );
  }

  // ---- Mijoz kartasi (T-060) ------------------------------------------

  Future<CustomerDetails?> details(String id) async {
    final c = await (_db.select(
      _db.customers,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (c == null || c.deletedAt != null) return null;
    final entry = await byId(id);
    return CustomerDetails(
      id: c.id,
      name: c.fullName,
      phone: c.phone,
      note: c.note,
      limitTiyin: c.debtLimitTiyin,
      balanceTiyin: entry?.balanceTiyin ?? 0,
    );
  }

  /// Qarz daftari (yangisi birinchi): savdo raqami va kim bilan.
  Stream<List<DebtRecord>> watchHistory(String customerId) => _db
      .customSelect(
        'SELECT d.id, d.type, d.amount_tiyin, d.method, d.note, d.at, '
        's.number AS sale, u.full_name AS by_name FROM debt_entries d '
        'LEFT JOIN sales s ON s.id = d.sale_id '
        'LEFT JOIN staff_users u ON u.id = d.by_user_id '
        'WHERE d.customer_id = ? ORDER BY d.at DESC',
        variables: [Variable.withString(customerId)],
        readsFrom: {_db.debtEntries, _db.sales, _db.staffUsers},
      )
      .watch()
      .map(
        (rows) => [
          for (final r in rows)
            DebtRecord(
              id: r.read<String>('id'),
              type: r.read<String>('type'),
              amountTiyin: r.read<int>('amount_tiyin'),
              at: r.read<DateTime>('at'),
              method: r.readNullable<String>('method'),
              note: r.read<String>('note'),
              saleNumber: r.readNullable<String>('sale'),
              byName: r.readNullable<String>('by_name'),
            ),
        ],
      );

  /// Shu kassadagi xaridlar (yangisi birinchi).
  Stream<List<PurchaseRecord>> watchPurchases(String customerId) =>
      (_db.select(_db.sales)
            ..where((s) => s.customerId.equals(customerId))
            ..orderBy([(s) => OrderingTerm.desc(s.soldAt)]))
          .watch()
          .map(
            (rows) => [
              for (final s in rows)
                PurchaseRecord(
                  number: s.number,
                  soldAt: s.soldAt,
                  totalTiyin: s.totalTiyin,
                  status: s.status,
                ),
            ],
          );

  /// Qarz to'lovi (`debts.md`): `DebtEntry(−, payment)` + outbox
  /// `debt.paid` bitta tranzaksiyada. Qarzdan ko'p to'lov — xato (avans yo'q,
  /// Q-003).
  Future<void> payDebt({
    required String customerId,
    required int amountTiyin,
    required String method,
    required String by,
    String? shiftId,
    String note = '',
  }) async {
    if (amountTiyin <= 0) throw ArgumentError.value(amountTiyin);
    if (method != 'cash' && method != 'card') throw ArgumentError.value(method);
    await _db.transaction(() async {
      final balance = (await byId(customerId))?.balanceTiyin ?? 0;
      if (amountTiyin > balance) throw PaymentExceedsDebtException(balance);
      final id = _newId();
      final now = _now();
      await _db
          .into(_db.debtEntries)
          .insert(
            DebtEntriesCompanion.insert(
              id: id,
              customerId: customerId,
              amountTiyin: -amountTiyin,
              type: 'payment',
              method: Value(method),
              shiftId: Value(shiftId),
              note: Value(note.trim()),
              byUserId: Value(by),
              at: now,
            ),
          );
      await _db.enqueueEvent(
        id: _newId(),
        type: OutboxEventType.debtPaid,
        createdAt: now,
        payload: {
          'id': id,
          'customer': customerId,
          'amount_tiyin': amountTiyin,
          'method': method,
          'note': note.trim(),
          'shift': ?shiftId,
          'at': isoUtc(now),
          'by': by,
        },
      );
    });
  }

  /// Ism/telefon/izoh; [limitTiyin] berilsa (`clearLimit` — cheklovsiz)
  /// limit ham o'zgaradi — buni server faqat ega/menejerdan qabul qiladi.
  Future<void> update({
    required String id,
    required String name,
    required String by,
    String phone = '',
    String note = '',
    bool changeLimit = false,
    int? limitTiyin,
  }) async {
    if (cleanLine(name).isEmpty) throw ArgumentError.value(name, 'name');
    final normalized = normalizePhone(phone);
    if (normalized == null) throw ArgumentError.value(phone, 'phone');
    if (limitTiyin != null && limitTiyin < 0) {
      throw ArgumentError.value(limitTiyin);
    }
    final now = _now();
    await _db.transaction(() async {
      await (_db.update(_db.customers)..where((c) => c.id.equals(id))).write(
        CustomersCompanion(
          fullName: Value(cleanLine(name)),
          phone: Value(normalized),
          note: Value(note.trim()),
          debtLimitTiyin: changeLimit
              ? Value(limitTiyin)
              : const Value.absent(),
          updatedAt: Value(now),
        ),
      );
      await _db.enqueueEvent(
        id: _newId(),
        type: OutboxEventType.customerUpserted,
        createdAt: now,
        payload: {
          'id': id,
          'full_name': cleanLine(name),
          'phone': normalized,
          'note': note.trim(),
          if (changeLimit) 'debt_limit_tiyin': limitTiyin,
          'by': by,
        },
      );
    });
  }
}

final customerDirectoryProvider = Provider<CustomerDirectory>(
  (ref) => CustomerDirectory(ref.watch(appDatabaseProvider)),
);

final customersProvider = StreamProvider<List<CustomerEntry>>(
  (ref) => ref.watch(customerDirectoryProvider).watchAll(),
);
