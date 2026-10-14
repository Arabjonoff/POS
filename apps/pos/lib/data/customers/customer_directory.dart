import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  Future<CustomerEntry> create({
    required String name,
    required String createdBy,
    String phone = '',
  }) async {
    final id = _newId();
    final now = _now();
    await _db.transaction(() async {
      await _db
          .into(_db.customers)
          .insert(
            CustomersCompanion.insert(
              id: id,
              fullName: name.trim(),
              phone: Value(phone.trim()),
              updatedAt: Value(now),
            ),
          );
      await _db.enqueueEvent(
        id: _newId(),
        type: OutboxEventType.customerUpserted,
        createdAt: now,
        payload: {
          'id': id,
          'full_name': name.trim(),
          'phone': phone.trim(),
          'note': '',
          'by': createdBy,
        },
      );
    });
    return CustomerEntry(
      id: id,
      name: name.trim(),
      phone: phone.trim(),
      balanceTiyin: 0,
    );
  }
}

final customerDirectoryProvider = Provider<CustomerDirectory>(
  (ref) => CustomerDirectory(ref.watch(appDatabaseProvider)),
);

final customersProvider = StreamProvider<List<CustomerEntry>>(
  (ref) => ref.watch(customerDirectoryProvider).watchAll(),
);
