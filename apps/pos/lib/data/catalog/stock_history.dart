import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/data/remote/api.dart';

/// Qoldiq harakati: `receipt` / `sale` / `refund` / `adjustment` /
/// `inventory`; [qtyMilli] — ishorasi bilan.
class StockMove {
  const StockMove({
    required this.type,
    required this.qtyMilli,
    required this.at,
    this.byName,
    this.pending = false,
  });

  final String type;
  final int qtyMilli;
  final DateTime at;
  final String? byName;

  /// Hali serverga yuborilmagan (shu kassada).
  final bool pending;
}

/// Tarix: yuborilmagan lokal harakatlar + server (barcha kassalar).
class StockHistory {
  const StockHistory({required this.pending, this.server});

  final List<StockMove> pending;

  /// `null` — server javob bermadi (oflayn).
  final List<StockMove>? server;

  bool get offline => server == null;
  List<StockMove> get all => [...pending, ...?server];
}

typedef StockHistoryFetcher = Future<List<StockMove>> Function(String id);

/// Server tarixi: `GET /api/v1/sync/stock-movements/` (qurilma tokeni).
final stockHistoryFetcherProvider = Provider<StockHistoryFetcher>((ref) {
  final tokens = ref.watch(deviceTokenStoreProvider);
  final dio = ref.watch(dioFactoryProvider);
  return (productId) async {
    final token = await tokens.read();
    if (token == null) throw const ApiFailure(ApiFailureKind.unauthorized);
    try {
      final rows = await deviceApi(
        dio,
        token,
      ).sync.syncStockMovementsList(product: productId);
      return [
        for (final r in rows)
          StockMove(
            type: r.type.json ?? '',
            qtyMilli: r.qtyMilli,
            at: r.at,
            byName: r.createdByName,
          ),
      ];
    } on Object catch (e) {
      throw ApiFailure.from(e);
    }
  };
});

/// Shu kassaning hali yuborilmagan harakatlari (eng yangisi birinchi).
Future<List<StockMove>> pendingMoves(AppDatabase db, String productId) async {
  final rows = await db
      .customSelect(
        'SELECT m.type, m.qty_milli, m.at FROM stock_movements m '
        'LEFT JOIN outbox_events e ON e.id = m.outbox_event_id '
        "WHERE m.product_id = ? AND (e.status IS NULL OR e.status != 'sent') "
        'ORDER BY m.at DESC',
        variables: [Variable.withString(productId)],
        readsFrom: {db.stockMovements, db.outboxEvents},
      )
      .get();
  return [
    for (final r in rows)
      StockMove(
        type: r.read<String>('type'),
        qtyMilli: r.read<int>('qty_milli'),
        at: r.read<DateTime>('at'),
        pending: true,
      ),
  ];
}

final FutureProviderFamily<StockHistory, String> stockHistoryProvider =
    FutureProvider.autoDispose.family<StockHistory, String>((
      ref,
      productId,
    ) async {
      final pending = await pendingMoves(
        ref.read(appDatabaseProvider),
        productId,
      );
      try {
        final server = await ref.read(stockHistoryFetcherProvider)(productId);
        return StockHistory(pending: pending, server: server);
      } on ApiFailure {
        return StockHistory(pending: pending);
      }
    });
