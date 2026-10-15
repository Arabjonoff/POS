import 'package:flutter/material.dart';
import 'package:pos_ui/src/components/pos_button.dart';
import 'package:pos_ui/src/tokens/pos_breakpoints.dart';
import 'package:pos_ui/src/tokens/pos_dimens.dart';
import 'package:pos_ui/src/tokens/pos_palette.dart';
import 'package:pos_ui/src/tokens/pos_tone.dart';
import 'package:pos_ui/src/tokens/pos_typography.dart';

/// Oyna mazmuni: sarlavha, ixtiyoriy izoh, tana va amallar.
///
/// Telefonda (compact; [compact] berilmasa ekran kengligidan) amallar ustma-ust va to'liq kenglikda (asosiy amal
/// yuqorida), kattaroq ekranda — o'ngda bir qatorda (asosiy amal oxirida).
/// [actions] tartibi: ikkinchi darajali → asosiy.
class PosDialog extends StatelessWidget {
  const PosDialog({
    required this.title,
    this.message,
    this.content,
    this.actions = const [],
    this.icon,
    this.iconTone = PosTone.primary,
    this.compact,
    super.key,
  });

  final String title;
  final String? message;
  final Widget? content;
  final List<Widget> actions;
  final IconData? icon;

  /// Ikon ohangi (masalan, xavfli amalda `danger`).
  final PosTone iconTone;
  final bool? compact;

  @override
  Widget build(BuildContext context) {
    final p = PosPalette.of(context);
    final compact = this.compact ?? PosWindowSize.of(context).isCompact;
    final padding = compact ? PosSpacing.l : PosSpacing.xl;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        padding,
        compact ? 0 : padding,
        padding,
        padding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (icon != null) ...[
            Align(
              alignment: compact ? Alignment.center : Alignment.centerLeft,
              child: Icon(
                icon,
                size: PosSizes.iconXl,
                color: p.tone(iconTone).text,
              ),
            ),
            const SizedBox(height: PosSpacing.m),
          ],
          Semantics(
            header: true,
            // Uzun nom (tovar nomi ≤ 200 belgi) sarlavhani 8 qatorga
            // cho'zib, tugmalarni siqmasin (audit P2-15).
            child: Text(
              title,
              textAlign: compact ? TextAlign.center : TextAlign.start,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: PosTypography.h2.copyWith(color: p.text),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: PosSpacing.s),
            Text(
              message!,
              textAlign: compact ? TextAlign.center : TextAlign.start,
              style: PosTypography.body.copyWith(color: p.textSecondary),
            ),
          ],
          if (content != null) ...[
            const SizedBox(height: PosSpacing.l),
            // Faqat mazmun suriladi: sarlavha va tugmalar har doim ko'rinadi
            // (planshetda baland oyna — tasdiqlash tugmasi ekrandan tushmasin).
            Flexible(child: SingleChildScrollView(child: content)),
          ],
          if (actions.isNotEmpty) ...[
            const SizedBox(height: PosSpacing.xl),
            if (compact)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, action) in actions.reversed.indexed) ...[
                    if (i > 0) const SizedBox(height: PosSpacing.s),
                    action,
                  ],
                ],
              )
            else
              Wrap(
                alignment: WrapAlignment.end,
                spacing: PosSpacing.s,
                runSpacing: PosSpacing.s,
                children: actions,
              ),
          ],
        ],
      ),
    );
  }
}

/// Oyna sirti: 16 radius, chegara va ikkinchi darajali (oyna) soya.
class PosOverlaySurface extends StatelessWidget {
  const PosOverlaySurface({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = PosPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: PosRadius.overlayAll,
        border: Border.all(color: p.border),
        boxShadow: p.overlayShadow,
      ),
      child: ClipRRect(borderRadius: PosRadius.overlayAll, child: child),
    );
  }
}

/// Oynani ochadi: telefonda pastdan chiquvchi panel, planshet/desktopda
/// markazdagi dialog. Esc — yopish (desktop).
Future<T?> showPosDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool dismissible = true,
  double maxWidth = PosSizes.dialogMaxWidth,
}) {
  final p = PosPalette.of(context);
  if (PosWindowSize.of(context).isCompact) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: dismissible,
      enableDrag: dismissible,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: builder(context),
      ),
    );
  }
  return showDialog<T>(
    context: context,
    barrierDismissible: dismissible,
    barrierColor: p.scrim,
    builder: (context) => Dialog(
      insetPadding: const EdgeInsets.all(PosSpacing.xl),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: PosOverlaySurface(child: builder(context)),
      ),
    ),
  );
}

/// Tasdiqlash oynasi — qaytarib bo'lmaydigan yoki xavfli amaldan oldin
/// (o'chirish, bekor qilish). `true` — tasdiqlandi; yopilsa yoki rad etilsa —
/// `false`. Matnlar chaqiruvchidan (tarjima fayllari ilovada).
Future<bool> showPosConfirm({
  required BuildContext context,
  required String title,
  required String confirmLabel,
  required String cancelLabel,
  String? message,
  Widget? content,
  IconData? icon,
  bool danger = false,
}) async {
  final confirmed = await showPosDialog<bool>(
    context: context,
    builder: (context) => PosDialog(
      title: title,
      message: message,
      content: content,
      icon: icon,
      iconTone: danger ? PosTone.danger : PosTone.primary,
      actions: [
        PosButton(
          key: const ValueKey('pos-confirm-cancel'),
          label: cancelLabel,
          variant: PosButtonVariant.secondary,
          shortcut: 'Esc',
          onPressed: () => Navigator.of(context).pop(false),
        ),
        PosButton(
          key: const ValueKey('pos-confirm-ok'),
          label: confirmLabel,
          variant: danger ? PosButtonVariant.danger : PosButtonVariant.primary,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
