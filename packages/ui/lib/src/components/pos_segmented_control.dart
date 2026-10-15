import 'package:flutter/material.dart';
import 'package:pos_ui/src/components/pos_button.dart';
import 'package:pos_ui/src/tokens/pos_dimens.dart';
import 'package:pos_ui/src/tokens/pos_palette.dart';
import 'package:pos_ui/src/tokens/pos_typography.dart';

/// Bitta variant.
class PosSegment<T> {
  const PosSegment({required this.value, required this.label, this.key});

  final T value;
  final String label;
  final Key? key;
}

/// Bir nechta variantdan bittasini tanlash (masalan, "Yo'q / Qarz / Avans").
/// Tanlangani — asosiy rang, qolganlari — ikkinchi darajali tugma; tor
/// ekranda keyingi qatorga o'tadi. Ekran o'quvchi uchun "tanlangan" holati.
class PosSegmentedControl<T> extends StatelessWidget {
  const PosSegmentedControl({
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.label,
    this.helper,
    super.key,
  });

  final List<PosSegment<T>> segments;
  final T selected;
  final ValueChanged<T>? onChanged;
  final String? label;

  /// Tanlangan variant ma'nosi (masalan, "Mijoz do'konga qarzdor").
  final String? helper;

  @override
  Widget build(BuildContext context) {
    final p = PosPalette.of(context);
    final options = Wrap(
      spacing: PosSpacing.xs,
      runSpacing: PosSpacing.xs,
      children: [
        for (final s in segments)
          // Tugmaning o'z semantik tuguni bor — holat unga qo'shilsin.
          MergeSemantics(
            child: Semantics(
              selected: s.value == selected,
              inMutuallyExclusiveGroup: true,
              child: PosButton(
                key: s.key,
                label: s.label,
                size: PosButtonSize.s,
                variant: s.value == selected
                    ? PosButtonVariant.primary
                    : PosButtonVariant.secondary,
                onPressed: onChanged == null ? null : () => onChanged!(s.value),
              ),
            ),
          ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: PosTypography.smallStrong.copyWith(color: p.text),
          ),
          const SizedBox(height: PosSpacing.xs + 2),
        ],
        options,
        if (helper != null) ...[
          const SizedBox(height: PosSpacing.xs),
          Text(
            helper!,
            style: PosTypography.small.copyWith(color: p.textSecondary),
          ),
        ],
      ],
    );
  }
}
