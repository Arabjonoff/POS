import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pos_ui/src/components/pos_text_field.dart';

/// Sana maydoni: bosilganda kalendar ochiladi, qo'lda yozilmaydi (format
/// xatosi bo'lmaydi). [format] — ilova tilidagi ko'rinish (`15.10.2026`).
class PosDateField extends StatefulWidget {
  const PosDateField({
    required this.value,
    required this.firstDate,
    required this.lastDate,
    required this.format,
    required this.onChanged,
    this.label,
    this.errorText,
    super.key,
  });

  final DateTime value;
  final DateTime firstDate;
  final DateTime lastDate;
  final String Function(DateTime) format;
  final ValueChanged<DateTime> onChanged;
  final String? label;
  final String? errorText;

  @override
  State<PosDateField> createState() => _PosDateFieldState();
}

class _PosDateFieldState extends State<PosDateField> {
  late final _text = TextEditingController(text: widget.format(widget.value));

  @override
  void didUpdateWidget(PosDateField old) {
    super.didUpdateWidget(old);
    final text = widget.format(widget.value);
    if (_text.text != text) _text.text = text;
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.value,
      firstDate: widget.firstDate,
      lastDate: widget.lastDate,
    );
    if (picked != null) widget.onChanged(picked);
  }

  @override
  Widget build(BuildContext context) => PosTextField(
    controller: _text,
    label: widget.label,
    errorText: widget.errorText,
    readOnly: true,
    suffix: const Icon(Icons.calendar_today_outlined),
    onTap: () => unawaited(_pick()),
  );
}
