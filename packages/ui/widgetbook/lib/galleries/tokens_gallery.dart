import 'package:flutter/material.dart';
import 'package:pos_ui/pos_ui.dart';
import 'package:pos_ui_widgetbook/galleries/gallery.dart';

/// Ranglar, tipografiya, oraliq va radiuslar.
class TokensGallery extends StatelessWidget {
  const TokensGallery({super.key});

  @override
  Widget build(BuildContext context) {
    final p = PosPalette.of(context);
    final swatches = <String, Color>{
      'background': p.background,
      'surface': p.surface,
      'surfaceMuted': p.surfaceMuted,
      'border': p.borderStrong,
      'text': p.text,
      'textSecondary': p.textSecondary,
      'textMuted': p.textMuted,
      'primary': p.primary,
      'success': p.success,
      'warning': p.warning,
      'danger': p.danger,
      'inverse': p.inverseSurface,
    };
    const type = <String, TextStyle>{
      'display 48': PosTypography.displayLarge,
      'h1 28': PosTypography.h1,
      'h2 22': PosTypography.h2,
      'h3 18': PosTypography.h3,
      'body 16': PosTypography.body,
      'small 14': PosTypography.small,
      'caption 12': PosTypography.caption,
    };

    return GalleryPage(
      sections: [
        GallerySection(
          title: 'Ranglar',
          spacing: PosSpacing.s,
          children: [
            for (final MapEntry(:key, :value) in swatches.entries)
              _Swatch(name: key, color: value),
          ],
        ),
        GallerySection(
          title: 'Ohanglar (soft)',
          spacing: PosSpacing.s,
          children: [
            for (final tone in PosTone.values)
              PosBadge(label: tone.name, tone: tone, large: true),
          ],
        ),
        GallerySection(
          title: 'Tipografiya (Inter)',
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final MapEntry(:key, :value) in type.entries)
                  Text(
                    key == 'display 48'
                        ? '125 000'
                        : '$key — Oʻzbekcha Ўзбекча',
                    style: value.copyWith(color: p.text),
                  ),
              ],
            ),
          ],
        ),
        GallerySection(
          title: 'Radius va soya',
          children: [
            for (final (name, radius, shadow) in [
              ('input 8', PosRadius.input, <BoxShadow>[]),
              ('control 12', PosRadius.control, p.cardShadow),
              ('overlay 16', PosRadius.overlay, p.overlayShadow),
            ])
              Container(
                width: 104,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: p.surface,
                  borderRadius: BorderRadius.circular(radius),
                  border: Border.all(color: p.border),
                  boxShadow: shadow,
                ),
                child: Text(
                  name,
                  style: PosTypography.caption.copyWith(color: p.textSecondary),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.name, required this.color});

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = PosPalette.of(context);
    return SizedBox(
      width: 84,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: PosRadius.inputAll,
              border: Border.all(color: p.border),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: PosTypography.caption.copyWith(color: p.textSecondary),
          ),
        ],
      ),
    );
  }
}
