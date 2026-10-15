import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/app/locale.dart';
import 'package:pos_app/app/session/session.dart';
import 'package:pos_app/app/status/app_status.dart';
import 'package:pos_app/data/db/app_database.dart';

import '../helpers/catalog_seed.dart';
import '../helpers/keyboard.dart';
import '../helpers/pump_app.dart';
import '../helpers/report_vectors.dart';
import '../helpers/sqlite.dart';

/// UI tekshiruvi (T-091): har bo'lim va asosiy ichki ekranlar rus va o'zbek
/// (kirill) tilida telefon va planshetda ochiladi — matn sig'maslik
/// (RenderFlex overflow) xatosi testni yiqitadi. Rus matni eng uzun
/// (`design-system.md`, tekshiruv ro'yxati).
const StaffUser _owner = StaffUser(
  id: 'owner-1',
  fullName: 'Dilshod Rahimov',
  role: 'owner',
  isActive: true,
);

const Map<String, Size> _sizes = {
  'phone': Size(390, 844),
  'tablet': Size(1024, 768),
};

const Map<String, Locale> _locales = {
  'ru': AppLocales.ru,
  'uz-Cyrl': AppLocales.uzCyrl,
};

/// Ichki ekranlar: bo'lim tugmasi va ochuvchi tugma kaliti.
const Map<String, (LogicalKeyboardKey, String)> _subScreens = {
  'new product': (LogicalKeyboardKey.digit2, 'products-add'),
  'inventory': (LogicalKeyboardKey.digit2, 'products-inventory'),
  'new receipt': (LogicalKeyboardKey.digit3, 'receiving-new'),
  'new customer': (LogicalKeyboardKey.digit4, 'customers-add'),
};

Future<void> _ctrl(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(key);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pumpAndSettle();
}

Future<void> _open(WidgetTester tester, Size size, Locale locale) async {
  final db = await seedReportVectors(openTestDatabase());
  addTearDown(db.close);
  await seedCatalog(db);
  await pumpPosApp(
    tester,
    size: size,
    db: db,
    session: const Session(
      stage: SessionStage.unlocked,
      device: testDevice,
      user: _owner,
    ),
    overrides: [
      initialLocaleProvider.overrideWithValue(locale),
      clockProvider.overrideWithValue(() => DateTime.utc(2026, 10, 15, 10)),
    ],
  );
}

void main() {
  for (final MapEntry(key: lang, value: locale) in _locales.entries) {
    for (final MapEntry(key: device, value: size) in _sizes.entries) {
      testWidgets('$lang $device: every section and dialog fits', (
        tester,
      ) async {
        await _open(tester, size, locale);
        await scanCode(tester, '4780000000014');
        await scanCode(tester, '4780000000021');
        expect(tester.takeException(), isNull);

        for (final key in [
          LogicalKeyboardKey.digit2, // tovarlar
          LogicalKeyboardKey.digit3, // kirim
          LogicalKeyboardKey.digit4, // mijozlar
          LogicalKeyboardKey.digit5, // hisobotlar
          LogicalKeyboardKey.digit6, // sozlamalar
          LogicalKeyboardKey.digit1, // kassa
        ]) {
          await _ctrl(tester, key);
          expect(tester.takeException(), isNull, reason: '$key');
        }

        // To'lov oynasi (F12) va qaytarish (F8).
        await press(tester, LogicalKeyboardKey.f12);
        expect(tester.takeException(), isNull, reason: 'payment');
        await press(tester, LogicalKeyboardKey.escape);
        await press(tester, LogicalKeyboardKey.f8);
        expect(tester.takeException(), isNull, reason: 'refund');
      });

      for (final MapEntry(key: name, value: (section, button))
          in _subScreens.entries) {
        testWidgets('$lang $device: $name fits', (tester) async {
          await _open(tester, size, locale);
          await _ctrl(tester, section);
          final target = find.byKey(ValueKey(button)).first;
          await tester.ensureVisible(target);
          await tester.pumpAndSettle();
          await tester.tap(target);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
