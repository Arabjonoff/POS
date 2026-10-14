import 'package:flutter/material.dart';
import 'package:pos_ui/src/tokens/pos_dimens.dart';
import 'package:pos_ui/src/tokens/pos_palette.dart';
import 'package:pos_ui/src/tokens/pos_tone.dart';
import 'package:pos_ui/src/tokens/pos_typography.dart';

/// Holat nuqtasi + yozuv. Rang yolg'iz ma'no tashimaydi: [label] doim bor
/// (ko'rinmasa ham ekran o'quvchiga aytiladi).
class PosStatusDot extends StatelessWidget {
  const PosStatusDot({
    required this.label,
    this.tone = PosTone.neutral,
    this.showLabel = true,
    this.size = 10,
    super.key,
  });

  final String label;
  final PosTone tone;
  final bool showLabel;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = PosPalette.of(context);
    final color = tone == PosTone.neutral ? p.textMuted : p.tone(tone).text;
    final dot = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
    if (!showLabel) {
      return Semantics(label: label, child: dot);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        dot,
        const SizedBox(width: PosSpacing.s),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: PosTypography.small.copyWith(color: p.text),
          ),
        ),
      ],
    );
  }
}
