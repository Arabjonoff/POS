import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos_ui/src/tokens/pos_dimens.dart';
import 'package:pos_ui/src/tokens/pos_palette.dart';
import 'package:pos_ui/src/tokens/pos_typography.dart';

/// Matn maydoni. Yorliq maydon ustida turadi (suzuvchi yorliq emas — kassir
/// nimani yozayotganini doim ko'radi). Xato ikon + matn bilan ko'rsatiladi.
class PosTextField extends StatelessWidget {
  const PosTextField({
    this.controller,
    this.focusNode,
    this.label,
    this.hint,
    this.helper,
    this.errorText,
    this.prefixIcon,
    this.suffix,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.maxLines = 1,
    this.textAlign = TextAlign.start,
    this.large = false,
    this.required = false,
    super.key,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? label;
  final String? hint;
  final String? helper;

  /// Bo'sh bo'lmasa — maydon xato holatida.
  final String? errorText;
  final IconData? prefixIcon;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// Bosilganda (masalan, `readOnly` sana maydoni tanlovchini ochadi).
  final VoidCallback? onTap;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final int maxLines;
  final TextAlign textAlign;

  /// Kassa uchun katta maydon (56 dp, 18 pt matn).
  final bool large;

  /// Majburiy maydon: yorliq yonida qizil `*` (saqlashdan oldin ko'rinsin).
  final bool required;

  @override
  Widget build(BuildContext context) {
    final p = PosPalette.of(context);
    final hasError = errorText != null && errorText!.isNotEmpty;
    final textStyle = (large ? PosTypography.h3 : PosTypography.body).copyWith(
      color: enabled ? p.text : p.disabled,
    );

    final field = TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onTap: onTap,
      obscureText: obscureText,
      enabled: enabled,
      readOnly: readOnly,
      autofocus: autofocus,
      maxLines: maxLines,
      textAlign: textAlign,
      style: textStyle,
      decoration: InputDecoration(
        hintText: hint,
        fillColor: enabled ? p.surface : p.surfaceMuted,
        constraints: BoxConstraints(
          minHeight: large ? PosSizes.cashierMain : PosSizes.touchMin,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: PosSpacing.m,
          vertical: large ? PosSpacing.l : PosSpacing.m,
        ),
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
        suffixIcon: suffix,
        helperText: hasError ? null : helper,
        helperMaxLines: 2,
        error: hasError ? _ErrorLine(text: errorText!) : null,
      ),
    );

    if (label == null) return field;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text.rich(
          TextSpan(
            text: label,
            children: [
              if (required)
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: enabled ? p.dangerText : p.disabled),
                ),
            ],
          ),
          style: PosTypography.smallStrong.copyWith(
            color: enabled ? p.text : p.disabled,
          ),
        ),
        const SizedBox(height: PosSpacing.xs + 2),
        field,
      ],
    );
  }
}

class _ErrorLine extends StatelessWidget {
  const _ErrorLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final p = PosPalette.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            Icons.error_outline,
            size: PosSizes.iconS,
            color: p.dangerText,
          ),
        ),
        const SizedBox(width: PosSpacing.xs),
        Expanded(
          child: Text(
            text,
            style: PosTypography.small.copyWith(color: p.dangerText),
          ),
        ),
      ],
    );
  }
}
