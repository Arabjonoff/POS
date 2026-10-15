import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/data/catalog/product_images.dart';
import 'package:pos_ui/pos_ui.dart';

/// Tovar rasmi (lokal fayl). Fayl hali yuklab olinmagan yoki rasm yo'q —
/// placeholder; ekran tarmoqni kutmaydi.
class ProductThumbnail extends ConsumerWidget {
  const ProductThumbnail({
    required this.imageId,
    this.size = PosSizes.thumbS,
    super.key,
  });

  final String? imageId;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = imageId;
    final file = id == null
        ? null
        : ref.watch(productImageFileProvider(id)).value;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return PosThumbnail(
      size: size,
      // Xotirani tejash: rasm ko'rinish o'lchamida dekodlanadi.
      image: file == null
          ? null
          : ResizeImage(FileImage(file), width: (size * dpr).round()),
    );
  }
}
