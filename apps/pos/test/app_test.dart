import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/app/app.dart';
import 'package:pos_app/app/locale.dart';
import 'package:pos_app/data/db/app_database.dart';

import 'helpers/sqlite.dart';

Future<ProviderContainer> pumpApp(WidgetTester tester) async {
  final db = openTestDatabase();
  addTearDown(db.close);
  final container = ProviderContainer(
    overrides: [appDatabaseProvider.overrideWithValue(db)],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const PosApp()),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('opens the POS screen in Uzbek by default', (tester) async {
    await pumpApp(tester);
    expect(find.text('Kassa'), findsOneWidget);
    expect(find.text('Tovarni skanerlang yoki qidiring'), findsOneWidget);
  });

  testWidgets('switches to Uzbek Cyrillic', (tester) async {
    final container = await pumpApp(tester);
    await container.read(localeProvider.notifier).select(AppLocales.uzCyrl);
    await tester.pumpAndSettle();
    expect(find.text('Товарни сканерланг ёки қидиринг'), findsOneWidget);
  });

  testWidgets('switches to Russian', (tester) async {
    final container = await pumpApp(tester);
    await container.read(localeProvider.notifier).select(AppLocales.ru);
    await tester.pumpAndSettle();
    expect(find.text('Отсканируйте товар или найдите его'), findsOneWidget);
  });

  testWidgets('dark theme is available', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await pumpApp(tester);
    final context = tester.element(find.text('Kassa'));
    expect(Theme.of(context).brightness, Brightness.dark);
  });
}
