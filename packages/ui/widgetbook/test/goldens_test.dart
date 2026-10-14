import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_ui/pos_ui.dart';
import 'package:pos_ui_widgetbook/catalog.dart';
import 'package:pos_ui_widgetbook/galleries/dialog_gallery.dart';

/// Golden o'lchamlari: telefon, planshet, desktop (CLAUDE.md, 5-band).
const Map<String, (Size, TargetPlatform)> devices = {
  'phone': (Size(390, 844), TargetPlatform.android),
  'tablet': (Size(1024, 768), TargetPlatform.android),
  'desktop': (Size(1440, 900), TargetPlatform.windows),
};

/// Golden test: soyalar haqiqiy (xira) chiziladi — flutter_test standartda
/// ularni qattiq to'rtburchak qiladi. O'zgaruvchi test oxirida qaytariladi.
void goldenTest(String name, Future<void> Function(WidgetTester) body) {
  testWidgets(name, (tester) async {
    debugDisableShadows = false;
    try {
      await body(tester);
    } finally {
      debugDisableShadows = true;
    }
  });
}

Future<void> _pumpDevice(
  WidgetTester tester, {
  required Size size,
  required TargetPlatform platform,
  required bool dark,
  required Widget home,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: dark
          ? PosTheme.dark(platform: platform)
          : PosTheme.light(platform: platform),
      home: home,
    ),
  );
  // Skeleton cheksiz animatsiya — pumpAndSettle emas, aniq vaqt.
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  for (final MapEntry(key: device, value: (size, platform))
      in devices.entries) {
    for (final dark in [false, true]) {
      final theme = dark ? 'dark' : 'light';

      group('$device $theme', () {
        for (final MapEntry(key: name, value: builder) in galleries.entries) {
          goldenTest(name, (tester) async {
            await _pumpDevice(
              tester,
              size: size,
              platform: platform,
              dark: dark,
              home: Scaffold(body: Builder(builder: builder)),
            );
            expect(tester.takeException(), isNull);
            await expectLater(
              find.byType(MaterialApp),
              matchesGoldenFile('goldens/$name/${device}_$theme.png'),
            );
          });
        }

        goldenTest('dialog', (tester) async {
          await _pumpDevice(
            tester,
            size: size,
            platform: platform,
            dark: dark,
            home: const DialogGallery(),
          );
          await tester.tap(find.text('Oynani ochish'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile('goldens/dialog/${device}_$theme.png'),
          );
        });
      });
    }
  }
}
