import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_ui/pos_ui.dart';

/// WCAG 2.1 nisbiy yorqinlik.
double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

double contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  test('light theme uses design tokens', () {
    final theme = PosTheme.light();
    expect(theme.brightness, Brightness.light);
    expect(theme.colorScheme.primary, PosColors.blue600);
    expect(theme.scaffoldBackgroundColor, PosColors.slate50);
    expect(theme.extension<PosPalette>(), PosPalette.light);
    expect(
      theme.textTheme.bodyMedium!.fontFamily,
      PosTypography.fontFamilyName,
    );
  });

  test('dark theme uses design tokens', () {
    final theme = PosTheme.dark();
    expect(theme.brightness, Brightness.dark);
    expect(theme.scaffoldBackgroundColor, PosColors.night950);
    expect(theme.extension<PosPalette>(), PosPalette.dark);
  });

  test('platform override is passed through', () {
    expect(
      PosTheme.light(platform: TargetPlatform.windows).platform,
      TargetPlatform.windows,
    );
  });

  group('WCAG AA contrast', () {
    for (final (name, p) in [
      ('light', PosPalette.light),
      ('dark', PosPalette.dark),
    ]) {
      final pairs = <String, (Color, Color)>{
        'text/background': (p.text, p.background),
        'text/surface': (p.text, p.surface),
        'textSecondary/background': (p.textSecondary, p.background),
        'textSecondary/surface': (p.textSecondary, p.surface),
        'textMuted/background': (p.textMuted, p.background),
        'textMuted/surface': (p.textMuted, p.surface),
        'text/surfaceMuted': (p.text, p.surfaceMuted),
        'textSecondary/surfaceMuted': (p.textSecondary, p.surfaceMuted),
        'onInverse/inverse': (p.onInverseSurface, p.inverseSurface),
        'inversePrimary/inverse': (p.inversePrimary, p.inverseSurface),
        'onPrimary/primaryHover': (p.onPrimary, p.primaryHover),
        'onDanger/dangerHover': (p.onDanger, p.dangerHover),
        for (final tone in PosTone.values) ...{
          '$tone onFill/fill': (p.tone(tone).onFill, p.tone(tone).fill),
          '$tone text/surface': (p.tone(tone).text, p.surface),
          '$tone text/background': (p.tone(tone).text, p.background),
          '$tone onSoft/soft': (p.tone(tone).onSoft, p.tone(tone).soft),
        },
      };
      for (final MapEntry(key: label, value: (fg, bg)) in pairs.entries) {
        test('$name $label >= 4.5', () {
          expect(contrast(fg, bg), greaterThanOrEqualTo(4.5));
        });
      }

      test('$name category accents: initial on tint, stripe visible', () {
        for (var i = 0; i < 8; i++) {
          final accent = p.categoryAccent(i);
          final dark = p.brightness == Brightness.dark;
          final tint = Color.alphaBlend(
            accent.withValues(alpha: dark ? 0.2 : 0.1),
            p.surface,
          );
          expect(
            contrast(accent, tint),
            greaterThanOrEqualTo(4.5),
            reason: '$i',
          );
          expect(contrast(accent, p.surface), greaterThanOrEqualTo(3));
        }
        expect(p.categoryAccent(8), p.categoryAccent(0));
      });

      test('$name focus ring is visible (>= 3:1)', () {
        expect(contrast(p.focus, p.background), greaterThanOrEqualTo(3));
        expect(contrast(p.focus, p.surface), greaterThanOrEqualTo(3));
      });
    }
  });

  test('palette lerp keeps endpoints', () {
    final mid = PosPalette.light.lerp(PosPalette.dark, 1);
    expect(mid.background, PosPalette.dark.background);
    expect(PosPalette.light.lerp(null, 0.5), PosPalette.light);
  });

  testWidgets('PosPalette.of falls back by brightness', (tester) async {
    late PosPalette palette;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: Brightness.dark),
        home: Builder(
          builder: (context) {
            palette = PosPalette.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(palette, PosPalette.dark);
  });

  group('PosWindowSize', () {
    test('breakpoints', () {
      expect(PosWindowSize.fromWidth(390), PosWindowSize.compact);
      expect(PosWindowSize.fromWidth(599.9), PosWindowSize.compact);
      expect(PosWindowSize.fromWidth(600), PosWindowSize.medium);
      expect(PosWindowSize.fromWidth(899), PosWindowSize.medium);
      expect(PosWindowSize.fromWidth(900), PosWindowSize.expanded);
      expect(PosWindowSize.fromWidth(1024), PosWindowSize.expanded);
      expect(PosWindowSize.fromWidth(1280), PosWindowSize.large);
      expect(PosWindowSize.fromWidth(1440), PosWindowSize.large);
    });

    test('helpers', () {
      expect(PosWindowSize.compact.isCompact, isTrue);
      expect(PosWindowSize.medium.isExpandedUp, isFalse);
      expect(PosWindowSize.expanded.isExpandedUp, isTrue);
      expect(PosWindowSize.large.isExpandedUp, isTrue);
    });
  });

  test('touch targets follow the spec', () {
    expect(PosSizes.touchMin, greaterThanOrEqualTo(48));
    expect(PosSizes.cashierMain, greaterThanOrEqualTo(56));
    expect(PosSizes.keypadKey, greaterThanOrEqualTo(64));
    expect(PosMotion.overlay.inMilliseconds, lessThanOrEqualTo(200));
    expect(PosMotion.press.inMilliseconds, lessThanOrEqualTo(200));
  });
}
