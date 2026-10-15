import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/app/update/app_update.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/features/settings/settings_screen.dart';

import '../helpers/pump_app.dart';
import '../helpers/sqlite.dart';

void main() {
  group('versions', () {
    test('compares semver numerically, ignores build and pre-release', () {
      expect(isNewer('1.0.1', '1.0.0'), isTrue);
      expect(isNewer('1.10.0', '1.9.9'), isTrue);
      expect(isNewer('2', '1.9'), isTrue);
      expect(isNewer('1.0.0', '1.0.0'), isFalse);
      expect(isNewer('1.0.0+5', '1.0.0+4'), isFalse);
      expect(isNewer('0.9.0', '1.0.0'), isFalse);
      expect(isNewer('bad', '1.0.0'), isFalse);
    });

    test('release is stored as JSON or cleared', () {
      expect(encodeRelease(null, null), '');
      expect(encodeRelease('', 'x'), '');
      expect(
        encodeRelease('1.1.0', null),
        '{"latest_version":"1.1.0","download_url":""}',
      );
    });
  });

  Future<AppDatabase> withRelease(String? version, String url) async {
    final db = openTestDatabase();
    addTearDown(db.close);
    await db.writeSetting(appReleaseSettingKey, encodeRelease(version, url));
    return db;
  }

  /// Sozlamalar → "Ilova haqida" kartasi (ro'yxat dangasa quriladi — suramiz).
  Future<Finder> openAbout(WidgetTester tester) async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit6);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    final about = find.byKey(const ValueKey('settings-about'));
    await tester.scrollUntilVisible(
      about,
      300,
      scrollable: find
          .descendant(
            of: find.byType(SettingsScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    return about;
  }

  testWidgets('newer version: status bar and settings show it with the link', (
    tester,
  ) async {
    final db = await withRelease('1.1.0', 'https://x.uz/pos-setup-1.1.0.exe');
    await pumpPosApp(
      tester,
      db: db,
      overrides: [installedVersionProvider.overrideWithValue('1.0.0')],
    );
    expect(find.text('Yangi versiya 1.1.0'), findsOneWidget);
    final about = await openAbout(tester);
    expect(
      find.descendant(of: about, matching: find.text('Versiya: 1.0.0')),
      findsOneWidget,
    );
    expect(find.text('Yangi versiya mavjud: 1.1.0'), findsOneWidget);
    expect(
      find.text('Yuklab olish: https://x.uz/pos-setup-1.1.0.exe'),
      findsOneWidget,
    );
  });

  testWidgets('same or older version: nothing to announce', (tester) async {
    final db = await withRelease('1.0.0', '');
    await pumpPosApp(
      tester,
      db: db,
      overrides: [installedVersionProvider.overrideWithValue('1.0.0')],
    );
    expect(find.textContaining('Yangi versiya'), findsNothing);
    await openAbout(tester);
    expect(find.text("Eng so'nggi versiya o'rnatilgan"), findsOneWidget);
  });
}
