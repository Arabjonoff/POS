import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show StreamProviderFamily;
import 'package:pos_app/core/time/store_time_zone.dart';
import 'package:pos_app/data/db/app_database.dart';

/// To'lov turi filtri (`sale_payments.method`).
enum SalePaymentFilter {
  all(null),
  cash('cash'),
  card('card'),
  debt('debt')
  ;

  const SalePaymentFilter(this.method);

  final String? method;
}

/// Cheklar tarixi filtri (`receipt-history.md`). [day] — do'kon kuni
/// (devor soati, `DateTime.utc(y, m, d)`); [query] bo'sh bo'lmasa sana
/// qo'llanmaydi.
@immutable
class SaleHistoryFilter {
  const SaleHistoryFilter({
    required this.day,
    this.query = '',
    this.payment = SalePaymentFilter.all,
    this.zone = StoreTimeZone.tashkent,
  });

  final DateTime day;
  final String query;
  final SalePaymentFilter payment;
  final StoreTimeZone zone;

  DateTime get start => day.subtract(zone.offset);
  DateTime get end => start.add(const Duration(days: 1));

  SaleHistoryFilter copyWith({
    DateTime? day,
    String? query,
    SalePaymentFilter? payment,
  }) => SaleHistoryFilter(
    day: day ?? this.day,
    query: query ?? this.query,
    payment: payment ?? this.payment,
    zone: zone,
  );

  @override
  bool operator ==(Object other) =>
      other is SaleHistoryFilter &&
      other.day == day &&
      other.query == query &&
      other.payment == payment &&
      other.zone == zone;

  @override
  int get hashCode => Object.hash(day, query, payment, zone);
}

/// Ro'yxatdagi bitta chek.
@immutable
class SaleHistoryEntry {
  const SaleHistoryEntry({
    required this.id,
    required this.number,
    required this.soldAt,
    required this.cashierName,
    required this.itemCount,
    required this.totalTiyin,
    required this.methods,
    required this.status,
    required this.refundedTiyin,
    this.customerName,
  });

  final String id;
  final String number;
  final DateTime soldAt;
  final String cashierName;
  final String? customerName;

  /// Pozitsiyalar (qatorlar) soni.
  final int itemCount;
  final int totalTiyin;

  /// To'lov turlari (`cash`, `card`, `debt`) — shu tartibda.
  final List<String> methods;

  /// `completed` / `partially_refunded` / `refunded`.
  final String status;
  final int refundedTiyin;

  bool get refunded => status == 'refunded';
  bool get partiallyRefunded => status == 'partially_refunded';
}

/// Filtr natijasi va jami.
@immutable
class SaleHistoryPage {
  const SaleHistoryPage(this.entries);

  final List<SaleHistoryEntry> entries;

  int get totalTiyin => entries.fold(0, (s, e) => s + e.totalTiyin);
  int get refundedTiyin => entries.fold(0, (s, e) => s + e.refundedTiyin);
}

/// Shu kassaning yakunlangan cheklari (lokal baza, oflayn).
class SaleHistory {
  const SaleHistory(this._db);

  final AppDatabase _db;

  /// Qidiruvdagi eng ko'p natija.
  static const int searchLimit = 200;

  /// Savdo, qaytarish yoki to'lov o'zgarsa qayta o'qiladi (`async*` emas:
  /// u `await for` da turganda bekor qilish osilib qoladi).
  Stream<SaleHistoryPage> watch(SaleHistoryFilter filter) => _db
      .customSelect(
        'SELECT 1',
        readsFrom: {_db.sales, _db.salePayments, _db.refunds, _db.customers},
      )
      .watch()
      .asyncMap((_) => load(filter));

  Future<SaleHistoryPage> load(SaleHistoryFilter filter) async {
    final query = filter.query.trim();
    final select = _db.select(_db.sales);
    if (query.isEmpty) {
      select.where(
        (s) =>
            s.soldAt.isBiggerOrEqualValue(filter.start) &
            s.soldAt.isSmallerThanValue(filter.end),
      );
    } else {
      final like = '%${_escape(query)}%';
      final byItem = _db.selectOnly(_db.saleItems)
        ..addColumns([_db.saleItems.saleId])
        ..where(_db.saleItems.nameSnapshot.like(like, escapeChar: r'\'));
      final byCustomer = _db.selectOnly(_db.customers)
        ..addColumns([_db.customers.id])
        ..where(_db.customers.fullName.like(like, escapeChar: r'\'));
      select
        ..where(
          (s) =>
              s.number.like(like, escapeChar: r'\') |
              s.id.isInQuery(byItem) |
              s.customerId.isInQuery(byCustomer),
        )
        ..limit(searchLimit);
    }
    final method = filter.payment.method;
    if (method != null) {
      final paid = _db.selectOnly(_db.salePayments)
        ..addColumns([_db.salePayments.saleId])
        ..where(_db.salePayments.method.equals(method));
      select.where((s) => s.id.isInQuery(paid));
    }
    select.orderBy([(s) => OrderingTerm.desc(s.soldAt)]);
    final sales = await select.get();
    if (sales.isEmpty) return const SaleHistoryPage([]);

    final ids = [for (final s in sales) s.id];
    final payments = await (_db.select(
      _db.salePayments,
    )..where((p) => p.saleId.isIn(ids))).get();
    final methods = <String, List<String>>{};
    for (final p in payments) {
      final list = methods.putIfAbsent(p.saleId, () => []);
      if (!list.contains(p.method)) list.add(p.method);
    }
    // Chekdagi tartib: naqd → karta → nasiya.
    for (final list in methods.values) {
      list.sort(
        (a, b) => _methodOrder.indexOf(a).compareTo(_methodOrder.indexOf(b)),
      );
    }

    final count = _db.saleItems.id.count();
    final itemRows =
        await (_db.selectOnly(_db.saleItems)
              ..addColumns([_db.saleItems.saleId, count])
              ..where(_db.saleItems.saleId.isIn(ids))
              ..groupBy([_db.saleItems.saleId]))
            .get();
    final items = {
      for (final r in itemRows)
        r.read(_db.saleItems.saleId)!: r.read(count) ?? 0,
    };

    final refundSum = _db.refunds.totalTiyin.sum();
    final refundRows =
        await (_db.selectOnly(_db.refunds)
              ..addColumns([_db.refunds.saleId, refundSum])
              ..where(_db.refunds.saleId.isIn(ids))
              ..groupBy([_db.refunds.saleId]))
            .get();
    final refunded = {
      for (final r in refundRows)
        r.read(_db.refunds.saleId)!: r.read(refundSum) ?? 0,
    };

    final staff = {
      for (final u in await (_db.select(
        _db.staffUsers,
      )..where((u) => u.id.isIn({for (final s in sales) s.cashierId}))).get())
        u.id: u.fullName,
    };
    final customerIds = {
      for (final s in sales)
        if (s.customerId != null) s.customerId!,
    };
    final customers = customerIds.isEmpty
        ? const <String, String>{}
        : {
            for (final c in await (_db.select(
              _db.customers,
            )..where((c) => c.id.isIn(customerIds))).get())
              c.id: c.fullName,
          };

    return SaleHistoryPage([
      for (final s in sales)
        SaleHistoryEntry(
          id: s.id,
          number: s.number,
          soldAt: s.soldAt,
          cashierName: staff[s.cashierId] ?? '',
          customerName: s.customerId == null ? null : customers[s.customerId],
          itemCount: items[s.id] ?? 0,
          totalTiyin: s.totalTiyin,
          methods: methods[s.id] ?? const [],
          status: s.status,
          refundedTiyin: refunded[s.id] ?? 0,
        ),
    ]);
  }

  /// Chek raqami (chekdagi shtrix-kod) bo'yicha — skaner uchun.
  Future<String?> idByNumber(String number) async {
    final value = number.trim().toUpperCase();
    if (value.isEmpty) return null;
    final row = await (_db.select(
      _db.sales,
    )..where((s) => s.number.equals(value))).getSingleOrNull();
    return row?.id;
  }

  /// Chekdagi qaytarishlar (yangisi oxirida).
  Future<List<Refund>> refunds(String saleId) =>
      (_db.select(_db.refunds)
            ..where((r) => r.saleId.equals(saleId))
            ..orderBy([(r) => OrderingTerm.asc(r.at)]))
          .get();

  static const List<String> _methodOrder = ['cash', 'card', 'debt'];

  static String _escape(String value) => value
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');
}

final saleHistoryRepositoryProvider = Provider<SaleHistory>(
  (ref) => SaleHistory(ref.watch(appDatabaseProvider)),
);

final StreamProviderFamily<SaleHistoryPage, SaleHistoryFilter>
saleHistoryProvider = StreamProvider.autoDispose
    .family<SaleHistoryPage, SaleHistoryFilter>(
      (ref, filter) => ref.watch(saleHistoryRepositoryProvider).watch(filter),
    );
