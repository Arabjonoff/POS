import 'package:flutter/material.dart';
import 'package:pos_ui/pos_ui.dart';

/// Bo'lim sahifasi karkasi: sarlavha + mazmun.
class SectionPage extends StatelessWidget {
  const SectionPage({required this.title, required this.child, super.key});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = PosPalette.of(context);
    final compact = PosWindowSize.of(context).isCompact;
    final padding = compact ? PosSpacing.l : PosSpacing.xl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(padding, padding, padding, PosSpacing.m),
          child: Semantics(
            header: true,
            child: Text(
              title,
              style: (compact ? PosTypography.h2 : PosTypography.h1).copyWith(
                color: p.text,
              ),
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}
