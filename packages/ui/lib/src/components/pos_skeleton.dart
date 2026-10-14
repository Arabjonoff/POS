import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pos_ui/src/tokens/pos_dimens.dart';
import 'package:pos_ui/src/tokens/pos_palette.dart';

/// Yuklanish o'rni (skeleton): sekin "nafas oluvchi" kulrang blok.
/// Tizimda animatsiyalar o'chirilgan bo'lsa — harakatsiz.
class PosSkeleton extends StatefulWidget {
  const PosSkeleton({
    this.width,
    this.height = 16,
    this.radius = PosRadius.input,
    super.key,
  });

  /// Doira (avatar o'rni).
  const PosSkeleton.circle({required double size, super.key})
    : width = size,
      height = size,
      radius = PosRadius.pill;

  final double? width;
  final double height;
  final double radius;

  @override
  State<PosSkeleton> createState() => _PosSkeletonState();
}

class _PosSkeletonState extends State<PosSkeleton>
    with SingleTickerProviderStateMixin {
  // Bir sikl (yorishib-qorayish) 1,2 s; har o'tish ≤ 200 ms qoidasiga
  // tushmaydi, chunki bu foydalanuvchi harakatiga javob emas, fon holati.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      unawaited(_controller.repeat(reverse: true));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = PosPalette.of(context);
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Color.lerp(
              p.surfaceMuted,
              p.border,
              Curves.easeInOut.transform(_controller.value),
            ),
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        ),
      ),
    );
  }
}

/// Ro'yxat qatori o'rnidagi skeleton (avatar + ikki qator matn).
class PosSkeletonListTile extends StatelessWidget {
  const PosSkeletonListTile({this.showLeading = true, super.key});

  final bool showLeading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: PosSizes.cashierMain + PosSpacing.s,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: PosSpacing.l),
        child: Row(
          children: [
            if (showLeading) ...[
              const PosSkeleton.circle(size: 40),
              const SizedBox(width: PosSpacing.m),
            ],
            const Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FractionallySizedBox(
                    widthFactor: 0.6,
                    child: PosSkeleton(height: 14),
                  ),
                  SizedBox(height: PosSpacing.s),
                  FractionallySizedBox(
                    widthFactor: 0.35,
                    child: PosSkeleton(height: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: PosSpacing.l),
            const PosSkeleton(width: 72),
          ],
        ),
      ),
    );
  }
}
