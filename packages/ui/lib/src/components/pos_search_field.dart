import 'package:flutter/material.dart';
import 'package:pos_ui/src/components/pos_button.dart';
import 'package:pos_ui/src/tokens/pos_dimens.dart';
import 'package:pos_ui/src/tokens/pos_palette.dart';
import 'package:pos_ui/src/tokens/pos_typography.dart';

/// Qidiruv maydoni: lupa ikoni, tozalash tugmasi va bo'sh paytda tezkor
/// tugma yorlig'i (`F1`).
class PosSearchField extends StatefulWidget {
  const PosSearchField({
    required this.hint,
    required this.clearTooltip,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.shortcut,
    this.autofocus = false,
    this.large = false,
    super.key,
  });

  final String hint;

  /// Tozalash tugmasining nomi (tarjimadan).
  final String clearTooltip;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// Maydon bo'sh paytda o'ngda ko'rinadigan yorliq, masalan `F1`.
  final String? shortcut;
  final bool autofocus;

  /// Kassa uchun katta maydon (56 dp).
  final bool large;

  @override
  State<PosSearchField> createState() => _PosSearchFieldState();
}

class _PosSearchFieldState extends State<PosSearchField> {
  TextEditingController? _ownController;

  TextEditingController get _controller =>
      widget.controller ?? (_ownController ??= TextEditingController());

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onText);
  }

  @override
  void didUpdateWidget(PosSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      (oldWidget.controller ?? _ownController)?.removeListener(_onText);
      _controller.addListener(_onText);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onText);
    _ownController?.dispose();
    super.dispose();
  }

  void _onText() => setState(() {});

  void _clear() {
    _controller.clear();
    widget.onChanged?.call('');
    widget.focusNode?.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final p = PosPalette.of(context);
    final empty = _controller.text.isEmpty;
    final height = widget.large ? PosSizes.cashierMain : PosSizes.touchMin;

    Widget? suffix;
    if (!empty) {
      suffix = IconButton(
        tooltip: widget.clearTooltip,
        onPressed: _clear,
        icon: const Icon(Icons.close),
        style: IconButton.styleFrom(
          minimumSize: const Size.square(PosSizes.touchMin),
        ),
      );
    } else if (widget.shortcut != null) {
      suffix = Padding(
        padding: const EdgeInsets.only(right: PosSpacing.m),
        child: Center(
          widthFactor: 1,
          child: PosKeycap(label: widget.shortcut!),
        ),
      );
    }

    return TextField(
      controller: _controller,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      textInputAction: TextInputAction.search,
      style: (widget.large ? PosTypography.h3 : PosTypography.body).copyWith(
        color: p.text,
      ),
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: (widget.large ? PosTypography.h3 : PosTypography.body)
            .copyWith(color: p.textMuted, fontWeight: FontWeight.w400),
        constraints: BoxConstraints(minHeight: height),
        contentPadding: EdgeInsets.symmetric(
          horizontal: PosSpacing.m,
          vertical: widget.large ? PosSpacing.l : PosSpacing.m,
        ),
        prefixIcon: const Icon(Icons.search),
        suffixIcon: suffix,
      ),
    );
  }
}
