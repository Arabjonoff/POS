import 'package:flutter/material.dart';
import 'package:pos_ui/src/tokens/pos_dimens.dart';
import 'package:pos_ui/src/tokens/pos_palette.dart';

/// Tovar rasmi (kvadrat, yumaloq burchak). Rasm yo'q yoki o'qilmasa —
/// neytral fon va tovar ikoni (placeholder): ro'yxat "bo'sh" ko'rinmaydi.
class PosThumbnail extends StatelessWidget {
  const PosThumbnail({
    this.image,
    this.size = PosSizes.thumbS,
    this.semanticLabel,
    super.key,
  });

  /// `null` — placeholder.
  final ImageProvider? image;
  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final p = PosPalette.of(context);
    final placeholder = Center(
      child: Icon(
        Icons.inventory_2_outlined,
        size: size * 0.45,
        color: p.textMuted,
      ),
    );
    final provider = image;
    return Semantics(
      image: provider != null,
      label: semanticLabel,
      child: SizedBox.square(
        dimension: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: p.surfaceMuted,
            borderRadius: PosRadius.controlAll,
            border: Border.all(color: p.border),
          ),
          child: ClipRRect(
            borderRadius: PosRadius.controlAll,
            child: provider == null
                ? placeholder
                : Image(
                    image: provider,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    // Yuklanayotganda bo'sh kvadrat emas — placeholder.
                    frameBuilder: (_, child, frame, wasSync) =>
                        wasSync || frame != null ? child : placeholder,
                    errorBuilder: (_, _, _) => placeholder,
                  ),
          ),
        ),
      ),
    );
  }
}
