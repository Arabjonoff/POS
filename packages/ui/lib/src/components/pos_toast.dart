import 'package:flutter/material.dart';
import 'package:pos_ui/src/tokens/pos_breakpoints.dart';
import 'package:pos_ui/src/tokens/pos_dimens.dart';
import 'package:pos_ui/src/tokens/pos_palette.dart';
import 'package:pos_ui/src/tokens/pos_tone.dart';
import 'package:pos_ui/src/tokens/pos_typography.dart';

/// Qisqa xabar (toast) ko'rinishi: teskari rangli sirt, ohang ikoni, matn va
/// ixtiyoriy amal ("Bekor qilish"). Rang yolg'iz ma'no tashimaydi — ikon bor.
class PosToast extends StatelessWidget {
  const PosToast({
    required this.message,
    this.tone = PosTone.neutral,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String message;
  final PosTone tone;
  final String? actionLabel;
  final VoidCallback? onAction;

  static IconData iconFor(PosTone tone) => switch (tone) {
    PosTone.neutral => Icons.info_outline,
    PosTone.primary => Icons.info_outline,
    PosTone.success => Icons.check_circle_outline,
    PosTone.warning => Icons.warning_amber_rounded,
    PosTone.danger => Icons.error_outline,
  };

  @override
  Widget build(BuildContext context) {
    final p = PosPalette.of(context);
    // Teskari sirtda ohang ikoni: qorong'i fonda och, och fonda to'q rang.
    final inverse = p.brightness == Brightness.light
        ? PosPalette.dark
        : PosPalette.light;
    final iconColor = tone == PosTone.neutral
        ? p.onInverseSurface
        : inverse.tone(tone).text;

    return Semantics(
      liveRegion: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: PosSizes.cashierMain),
        padding: const EdgeInsets.only(left: PosSpacing.l, right: PosSpacing.s),
        decoration: BoxDecoration(
          color: p.inverseSurface,
          borderRadius: PosRadius.controlAll,
          boxShadow: p.overlayShadow,
        ),
        child: Row(
          children: [
            Icon(iconFor(tone), color: iconColor, size: PosSizes.iconL),
            const SizedBox(width: PosSpacing.m),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: PosSpacing.m),
                child: Text(
                  message,
                  style: PosTypography.body.copyWith(
                    color: p.onInverseSurface,
                  ),
                ),
              ),
            ),
            if (actionLabel != null) ...[
              const SizedBox(width: PosSpacing.s),
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  foregroundColor: p.inversePrimary,
                  minimumSize: const Size(
                    PosSizes.touchMin,
                    PosSizes.touchMin,
                  ),
                  textStyle: PosTypography.label,
                ),
                child: Text(actionLabel!),
              ),
            ] else
              const SizedBox(width: PosSpacing.s),
          ],
        ),
      ),
    );
  }
}

/// Toast ko'rsatadi (standart 5 s — "Bekor qilish" uchun yetarli vaqt).
/// Eng yaqin `Scaffold` kerak (`PosResponsiveScaffold` uni beradi).
ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showPosToast(
  BuildContext context, {
  required String message,
  PosTone tone = PosTone.neutral,
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(seconds: 5),
}) {
  final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
  final compact = PosWindowSize.of(context).isCompact;
  return messenger.showSnackBar(
    SnackBar(
      content: PosToast(
        message: message,
        tone: tone,
        actionLabel: actionLabel,
        onAction: onAction == null
            ? null
            : () {
                messenger.hideCurrentSnackBar(
                  reason: SnackBarClosedReason.action,
                );
                onAction();
              },
      ),
      duration: duration,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      padding: EdgeInsets.zero,
      width: compact ? null : PosSizes.dialogMaxWidth,
      margin: compact ? const EdgeInsets.all(PosSpacing.s) : null,
    ),
  );
}
