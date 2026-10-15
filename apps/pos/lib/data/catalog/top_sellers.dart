import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/data/db/app_database.dart';

/// Shu kassada [since] dan beri eng ko'p sotilgan tovarlar (chek
/// qatorlari soni bo'yicha) — kassa ekranidagi "Sevimlilar" uchun.
Selectable<String> topSellersQuery(
  AppDatabase db, {
  required DateTime since,
  int limit = 24,
}) {
  final lines = db.saleItems.id.count();
  final query =
      db.selectOnly(db.saleItems).join([
          innerJoin(db.sales, db.sales.id.equalsExp(db.saleItems.saleId)),
        ])
        ..addColumns([db.saleItems.productId, lines])
        ..where(db.sales.soldAt.isBiggerOrEqualValue(since))
        ..groupBy([db.saleItems.productId])
        ..orderBy([
          OrderingTerm.desc(lines),
          OrderingTerm.asc(db.saleItems.productId),
        ])
        ..limit(limit);
  return query.map((row) => row.read(db.saleItems.productId)!);
}

/// Tovar ID lari (eng ko'p sotilgani birinchi); har savdodan keyin yangilanadi.
final topSellersProvider = StreamProvider<List<String>>((ref) {
  final since = clock.now().subtract(const Duration(days: 30));
  return topSellersQuery(ref.watch(appDatabaseProvider), since: since).watch();
});
