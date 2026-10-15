import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pos_ui/src/tokens/pos_dimens.dart';
import 'package:pos_ui/src/tokens/pos_palette.dart';

/// Skaner natijasi: tovar qo'shildi (yashil), topilmadi/ogohlantirish
/// (sariq), xato (qizil).
enum PosScanResult { success, warning, error }

/// [PosScanFeedback] ni chaqnatish uchun boshqaruvchi.
class PosScanFeedbackController extends ChangeNotifier {
  PosScanResult? _last;
  int _count = 0;

  PosScanResult? get last => _last;

  /// Har chaqiruvda chaqnash qaytadan boshlanadi (ketma-ket skanerlar).
  void flash(PosScanResult result) {
    _last = result;
    _count++;
    notifyListeners();
  }
}

/// Skanerlashdan keyin hudud *chetini* qisqa chaqnatadi (fon bo'yalmaydi).
/// Jami ≤ 200 ms (design-system: animatsiya ≤ 200 ms): 60 ms to'liq, keyin
/// so'nadi. Faqat skaner natijasi uchun — oddiy bosishga ishlatilmaydi.
class PosScanFeedback extends StatefulWidget {
  const PosScanFeedback({
    required this.controller,
    required this.child,
    this.borderRadius = PosRadius.controlAll,
    super.key,
  });

  final PosScanFeedbackController controller;
  final Widget child;
  final BorderRadius borderRadius;

  @override
  State<PosScanFeedback> createState() => _PosScanFeedbackState();
}

class _PosScanFeedbackState extends State<PosScanFeedback>
    with SingleTickerProviderStateMixin {
    // initState da yaratiladi: dispose paytida (chaqnash bo'lmagan bo'lsa)
  // dangasa yaratish faol bo'lmagan elementdan ticker so'raydi.
  late final AnimationController _animation;
  int _seen = 0;

  late final Animation<double> _opacity = TweenSequence<double>([
    TweenSequenceItem(tween: ConstantTween(1), weight: 60),
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 1,
        end: 0,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 140,
    ),
  ]).animate(_animation);

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(
      vsync: this,
      duration: PosMotion.overlay,
      value: 1,
    );
    _seen = widget.controller._count;
    widget.controller.addListener(_onFlash);
  }

  @override
  void didUpdateWidget(PosScanFeedback oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onFlash);
      widget.controller.addListener(_onFlash);
      _seen = widget.controller._count;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onFlash);
    _animation.dispose();
    super.dispose();
  }

  void _onFlash() {
    if (widget.controller._count == _seen) return;
    _seen = widget.controller._count;
    // Chaqnash — harakat emas, rang o'zgarishi: animatsiyasiz rejimda ham
    // ishlaydi (aks holda kassir natijani ko'rmaydi).
    unawaited(_animation.forward(from: 0));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.controller.last;
    return Stack(
      children: [
        widget.child,
        if (result != null)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _opacity,
                builder: (context, _) => PosScanFeedbackOverlay(
                  result: result,
                  opacity: _animation.isCompleted ? 0 : _opacity.value,
                  borderRadius: widget.borderRadius,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Chaqnash ko'rinishi (galereya va golden testlar uchun ham ochiq).
class PosScanFeedbackOverlay extends StatelessWidget {
  const PosScanFeedbackOverlay({
    required this.result,
    this.opacity = 1,
    this.borderRadius = PosRadius.controlAll,
    super.key,
  });

  final PosScanResult result;
  final double opacity;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    if (opacity <= 0) return const SizedBox.expand();
    final p = PosPalette.of(context);
    final color = switch (result) {
      PosScanResult.success => p.successText,
      PosScanResult.warning => p.warningText,
      PosScanResult.error => p.dangerText,
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(
          color: color.withValues(alpha: opacity),
          width: 2,
        ),
      ),
      child: const SizedBox.expand(),
    );
  }
}
