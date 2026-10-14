import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/app/locale.dart';

import 'helpers/pump_app.dart';

void main() {
  testWidgets('opens the POS screen in Uzbek by default', (tester) async {
    await pumpPosApp(tester, size: const Size(800, 600));
    expect(find.text('Kassa'), findsWidgets);
    expect(find.text('Tovarni skanerlang yoki qidiring'), findsOneWidget);
  });

  testWidgets('switches to Uzbek Cyrillic', (tester) async {
    final (container, _) = await pumpPosApp(tester);
    await container.read(localeProvider.notifier).select(AppLocales.uzCyrl);
    await tester.pumpAndSettle();
    expect(find.text('Товарни сканерланг ёки қидиринг'), findsOneWidget);
  });

  testWidgets('switches to Russian', (tester) async {
    final (container, _) = await pumpPosApp(tester);
    await container.read(localeProvider.notifier).select(AppLocales.ru);
    await tester.pumpAndSettle();
    expect(find.text('Отсканируйте товар или найдите его'), findsOneWidget);
  });

  testWidgets('dark theme is available', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await pumpPosApp(tester);
    final context = tester.element(
      find.text('Tovarni skanerlang yoki qidiring'),
    );
    expect(Theme.of(context).brightness, Brightness.dark);
  });
}
