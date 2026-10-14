import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:pos_app/data/remote/api.dart';

/// Narx o'zgarishi (serverdagi `PriceHistory`, `catalog-api.md`).
class PriceChange {
  const PriceChange({
    required this.sellPriceTiyin,
    required this.costPriceTiyin,
    required this.at,
    this.byName,
  });

  final int sellPriceTiyin;
  final int costPriceTiyin;
  final DateTime at;

  /// Kim o'zgartirgan (`null` — tizim yoki import).
  final String? byName;
}

typedef PriceHistoryFetcher = Future<List<PriceChange>> Function(String id);

/// Narx tarixi faqat serverda — onlayn so'raladi (qurilma tokeni bilan,
/// `GET /api/v1/sync/price-history/`). Xato — [ApiFailure] (oflayn:
/// `network`).
final priceHistoryFetcherProvider = Provider<PriceHistoryFetcher>((ref) {
  final tokens = ref.watch(deviceTokenStoreProvider);
  final dio = ref.watch(dioFactoryProvider);
  return (productId) async {
    final token = await tokens.read();
    if (token == null) throw const ApiFailure(ApiFailureKind.unauthorized);
    try {
      final rows = await deviceApi(
        dio,
        token,
      ).sync.syncPriceHistoryList(product: productId);
      return [
        for (final r in rows)
          PriceChange(
            sellPriceTiyin: r.sellPriceTiyin,
            costPriceTiyin: r.costPriceTiyin,
            at: r.at,
            byName: r.changedByName,
          ),
      ];
    } on Object catch (e) {
      throw ApiFailure.from(e);
    }
  };
});

final FutureProviderFamily<List<PriceChange>, String> priceHistoryProvider =
    FutureProvider.autoDispose.family<List<PriceChange>, String>(
      (ref, productId) => ref.read(priceHistoryFetcherProvider)(productId),
    );
