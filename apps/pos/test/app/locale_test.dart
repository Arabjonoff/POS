import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/app/locale.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/features/settings/language_picker.dart';
import 'package:pos_app/l10n/gen/app_localizations.dart';
import 'package:pos_ui/pos_ui.dart';

import '../helpers/sqlite.dart';

void main() {
  group('AppLocales', () {
    test('tag and parse round-trip', () {
      for (final locale in AppLocales.all) {
        expect(AppLocales.parse(AppLocales.tag(locale)), locale);
      }
      expect(AppLocales.tag(AppLocales.uzCyrl), 'uz_Cyrl');
    });

    test('parse accepts server form and rejects unknown', () {
      expect(AppLocales.parse('uz-Cyrl'), AppLocales.uzCyrl);
      expect(AppLocales.parse('RU'), AppLocales.ru);
      expect(AppLocales.parse('en'), isNull);
      expect(AppLocales.parse(null), isNull);
    });
  });

  group('persistence', () {
    late AppDatabase db;

    setUp(() => db = openTestDatabase());
    tearDown(() => db.close());

    test('default is Uzbek Latin when nothing saved', () async {
      expect(await loadSavedLocale(db), AppLocales.uzLatn);
    });

    test('select saves and next start restores', () async {
      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);
      expect(container.read(localeProvider), AppLocales.uzLatn);

      await container.read(localeProvider.notifier).select(AppLocales.ru);
      expect(container.read(localeProvider), AppLocales.ru);
      expect(await db.readSetting('locale'), 'ru');

      // Ilova qayta ochildi.
      final restored = await loadSavedLocale(db);
      final next = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          initialLocaleProvider.overrideWithValue(restored),
        ],
      );
      addTearDown(next.dispose);
      expect(next.read(localeProvider), AppLocales.ru);
    });

    test('corrupt saved value falls back to default', () async {
      await db.writeSetting('locale', 'xx');
      expect(await loadSavedLocale(db), AppLocales.uzLatn);
    });
  });

  testWidgets('LanguagePicker shows native names and switches', (
    tester,
  ) async {
    final db = openTestDatabase();
    addTearDown(db.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: Consumer(
          builder: (context, ref, _) => MaterialApp(
            theme: PosTheme.light(),
            locale: ref.watch(localeProvider),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(
              body: Builder(
                builder: (context) => Column(
                  children: [
                    Text(AppLocalizations.of(context).settingsLanguage),
                    const LanguagePicker(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text("O'zbekcha"), findsOneWidget);
    expect(find.text('Ўзбекча'), findsOneWidget);
    expect(find.text('Русский'), findsOneWidget);
    expect(find.text('Til'), findsOneWidget);

    await tester.tap(find.text('Ўзбекча'));
    await tester.pumpAndSettle();
    expect(find.text('Тил'), findsOneWidget);

    await tester.tap(find.text('Русский'));
    await tester.pumpAndSettle();
    expect(find.text('Язык'), findsOneWidget);
    // Drift yozuvi yakunlansin.
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    expect(await tester.runAsync(() => db.readSetting('locale')), 'ru');
  });
}
