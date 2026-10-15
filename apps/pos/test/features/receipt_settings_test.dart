import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/app/session/pin_gate.dart';
import 'package:pos_app/app/session/session.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/data/store/store_settings.dart';
import 'package:pos_app/data/sync/outbox.dart';
import 'package:pos_app/data/sync/server_features.dart';
import 'package:pos_app/features/printing/mono_bitmap.dart';
import 'package:pos_app/features/printing/receipt_preview.dart';
import 'package:pos_app/features/settings/settings_screen.dart';

import '../helpers/keyboard.dart';
import '../helpers/pump_app.dart';
import '../helpers/sqlite.dart';

late AppDatabase _db;

const StaffUser owner = StaffUser(
  id: 'owner-1',
  fullName: 'Ega',
  role: 'owner',
  isActive: true,
  pinHash: 'hash',
);

Future<void> open(
  WidgetTester tester, {
  bool asOwner = true,
  bool feature = true,
  GrayImage? pickedLogo,
}) async {
  _db = openTestDatabase();
  addTearDown(_db.close);
  await _db
      .into(_db.stores)
      .insert(StoresCompanion.insert(id: 'store-1', name: 'Baraka'));
  await _db.into(_db.staffUsers).insert(owner);
  await _db.writeSetting(
    serverFeaturesSettingKey,
    encodeFeatures(feature ? [ServerFeature.storeSettings] : []),
  );
  await pumpPosApp(
    tester,
    db: _db,
    session: asOwner
        ? const Session(
            stage: SessionStage.unlocked,
            device: testDevice,
            user: owner,
          )
        : unlockedSession,
    overrides: <Override>[
      logoPickerProvider.overrideWithValue(() async => pickedLogo),
      pinGateProvider.overrideWith(
        (ref) => PinGate(
          ref.watch(appDatabaseProvider),
          verify: (pin, _) async => pin == '1234',
        ),
      ),
    ],
  );
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(LogicalKeyboardKey.digit6);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    find.byKey(const ValueKey('store-tin')),
    300,
    scrollable: find
        .descendant(
          of: find.byType(SettingsScreen),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.pumpAndSettle();
}

Future<void> tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

String previewText(WidgetTester tester) => [
  for (final t in tester.widgetList<Text>(
    find.descendant(
      of: find.byType(ReceiptPreview),
      matching: find.byType(Text),
    ),
  ))
    t.data ?? '',
].join('\n');

Future<void> type(WidgetTester tester, String key, String text) async {
  await tester.enterText(
    find.descendant(
      of: find.byKey(ValueKey(key)),
      matching: find.byType(TextField),
    ),
    text,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('live preview follows edits; owner saves; event is queued', (
    tester,
  ) async {
    await open(tester, pickedLogo: GrayImage(8, 2, Uint8List(16)));
    expect(previewText(tester), isNot(contains('STIR')));

    await type(tester, 'store-legal-name', '"Baraka" MChJ');
    await type(tester, 'store-tin', '123456789');
    // Saqlanmagan o'zgarish ham chek ko'rinishida darhol.
    expect(previewText(tester), contains('STIR: 123456789'));
    expect(previewText(tester), contains('"Baraka" MChJ'));

    // STIR ni yashirish — chekdan yo'qoladi.
    await tap(tester, find.widgetWithText(ListTile, 'STIR yoki JShShIR'));
    expect(previewText(tester), isNot(contains('STIR')));

    await tap(tester, find.byKey(const ValueKey('store-logo-pick')));
    expect(find.byKey(const ValueKey('store-logo-remove')), findsOneWidget);

    await tap(tester, find.byKey(const ValueKey('store-save')));
    expect(
      find.text('Saqlandi — boshqa kassalarda sinxrondan keyin yangilanadi'),
      findsOneWidget,
    );
    final row = await _db.select(_db.stores).getSingle();
    expect((row.tin, row.legalName), ('123456789', '"Baraka" MChJ'));
    expect(row.receiptLogo, isNotEmpty);
    final event = await _db.select(_db.outboxEvents).getSingle();
    expect(event.type, OutboxEventType.storeUpserted);
    final payload = jsonDecode(event.payload) as Map<String, Object?>;
    expect(payload['by'], 'owner-1');
    expect((payload['receipt_options']! as Map)['show_tin'], isFalse);
  });

  testWidgets('wrong STIR is shown, nothing is saved', (tester) async {
    await open(tester);
    await type(tester, 'store-tin', '12345');
    await tap(tester, find.byKey(const ValueKey('store-save')));
    expect(
      find.text('9 raqam (STIR) yoki 14 raqam (JShShIR) kiriting'),
      findsOneWidget,
    );
    expect(await _db.select(_db.outboxEvents).get(), isEmpty);
  });

  testWidgets('a cashier needs a manager PIN to save', (tester) async {
    await open(tester, asOwner: false);
    await type(tester, 'store-tin', '123456789');
    await tap(tester, find.byKey(const ValueKey('store-save')));
    expect(find.text('Tasdiqlash kerak'), findsOneWidget);
    await tester.tap(find.text('Ega'));
    await tester.pumpAndSettle();
    await typeSlowly(tester, '1234');
    await press(tester, LogicalKeyboardKey.enter);
    final payload =
        jsonDecode((await _db.select(_db.outboxEvents).getSingle()).payload)
            as Map<String, Object?>;
    expect(payload['by'], 'owner-1');
  });

  testWidgets('old server: editing is off, a hint is shown', (tester) async {
    await open(tester, feature: false);
    expect(
      find.textContaining('server yangilangach ishlaydi'),
      findsWidgets,
    );
    final field = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const ValueKey('store-tin')),
        matching: find.byType(TextField),
      ),
    );
    expect(field.enabled, isFalse);
  });
}
