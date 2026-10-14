import 'package:flutter/material.dart';
import 'package:pos_ui/src/tokens/pos_dimens.dart';
import 'package:pos_ui/src/tokens/pos_palette.dart';

/// Karta: sirt, ingichka chegara, yumshoq soya (yorug' mavzuda).
/// [onTap] bo'lsa — bosiladi va klaviatura bilan fokuslanadi.
class PosCard extends StatelessWidget {
  const PosCard({
    required this.child,
    this.padding = const EdgeInsets.all(PosSpacing.l),
    this.onTap,
    this.selected = false,
    this.muted = false,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  /// Tanlangan: asosiy rangli qalin chegara.
  final bool selected;

  /// Fon kulrang (sirt ichidagi ikkinchi daraja).
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final p = PosPalette.of(context);
    final shape = RoundedRectangleBorder(
      borderRadius: PosRadius.controlAll,
      side: selected
          ? BorderSide(color: p.primary, width: 2)
          : BorderSide(color: p.border),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: PosRadius.controlAll,
        boxShadow: muted ? null : p.cardShadow,
      ),
      child: Material(
        color: muted ? p.surfaceMuted : p.surface,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: onTap == null
            ? Padding(padding: padding, child: child)
            : InkWell(
                onTap: onTap,
                hoverColor: p.text.withValues(alpha: 0.03),
                focusColor: p.primary.withValues(alpha: 0.08),
                child: Padding(padding: padding, child: child),
              ),
      ),
    );
  }
}
