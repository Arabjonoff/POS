import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/app/status/app_status.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_ui/pos_ui.dart';

import '../helpers/pump_app.dart';

const Size phone = Size(390, 844);
const Size tablet = Size(1024, 768);

const String emptyCart = 'Tovarni skanerlang yoki qidiring';
const String comingSoon = "Bo'lim tayyorlanmoqda";

Future<void> ctrl(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(key);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pumpAndSettle();
}

void main() {
  group('navigation', () {
    testWidgets('opens on the POS screen', (tester) async {
      await pumpPosApp(tester);
      expect(find.text(emptyCart), findsOneWidget);
    });

    testWidgets('desktop: side panel with all sections and shortcuts', (
      tester,
    ) async {
      await pumpPosApp(tester);
      for (final label in [
        'Kassa',
        'Tovarlar',
        'Kirim',
        'Mijozlar',
        'Hisobotlar',
        'Sozlamalar',
      ]) {
        expect(find.text(label), findsWidgets, reason: label);
      }
      for (var i = 1; i <= 6; i++) {
        expect(find.text('Ctrl+$i'), findsOneWidget);
      }
      expect(tester.getRect(find.text('Mijozlar')).top, lessThan(400));

      await tester.tap(find.text('Sozlamalar'));
      await tester.pumpAndSettle();
      expect(find.text('Til'), findsOneWidget);
      expect(find.text('Русский'), findsOneWidget);
    });

    testWidgets('keyboard: Ctrl+1..6 switch sections', (tester) async {
      await pumpPosApp(tester);
      await ctrl(tester, LogicalKeyboardKey.digit2);
      expect(find.text("Hali tovar yo'q"), findsOneWidget);
      expect(find.text(emptyCart), findsNothing);

      await ctrl(tester, LogicalKeyboardKey.digit3);
      expect(find.text("Hali kirim yo'q"), findsOneWidget);

      await ctrl(tester, LogicalKeyboardKey.digit4);
      expect(find.text("Hali mijoz yo'q"), findsOneWidget);

      await ctrl(tester, LogicalKeyboardKey.digit5);
      expect(find.text(comingSoon), findsOneWidget);

      await ctrl(tester, LogicalKeyboardKey.digit6);
      expect(find.text('Til'), findsOneWidget);

      await ctrl(tester, LogicalKeyboardKey.digit1);
      expect(find.text(emptyCart), findsOneWidget);
    });

    testWidgets('keyboard: Tab inside a section, Enter activates', (
      tester,
    ) async {
      // Bo'limlar orasida — Ctrl+1..6; bo'lim ichida — Tab/Enter.
      await pumpPosApp(tester);
      await ctrl(tester, LogicalKeyboardKey.digit6);
      for (var i = 0; i < 3; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('Язык'), findsOneWidget);
    });

    testWidgets('phone: bottom navigation', (tester) async {
      await pumpPosApp(tester, size: phone);
      // Pastki panel ekran pastida.
      expect(tester.getRect(find.text('Tovarlar')).top, greaterThan(760));
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Til'), findsOneWidget);
      // Status bar is on top on phones.
      final status = tester.getRect(find.byType(PosStatusBar));
      expect(status.top, lessThan(100));
    });

    testWidgets('tablet: side panel, status bar at the bottom', (
      tester,
    ) async {
      await pumpPosApp(tester, size: tablet);
      expect(tester.getRect(find.text('Mijozlar')).top, lessThan(400));
      expect(tester.getRect(find.byType(PosStatusBar)).bottom, tablet.height);
    });

    testWidgets('language switch from settings updates navigation', (
      tester,
    ) async {
      final (_, db) = await pumpPosApp(tester);
      await tester.tap(find.text('Sozlamalar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Русский'));
      await tester.pumpAndSettle();
      expect(find.text('Настройки'), findsWidgets);
      expect(find.text('Товары'), findsOneWidget);
      expect(await tester.runAsync(() => db.readSetting('locale')), 'ru');
    });
  });

  group('status bar', () {
    testWidgets('defaults before sync/printer are set up', (tester) async {
      await pumpPosApp(tester, withOpenShift: false);
      expect(find.text('Ulanish tekshirilmoqda'), findsOneWidget);
      expect(find.text('Hammasi yuborilgan'), findsOneWidget);
      expect(find.text('Printer sozlanmagan'), findsOneWidget);
      expect(find.text('Smena yopiq'), findsOneWidget);
    });

    testWidgets('offline with queued records, printer and shift', (
      tester,
    ) async {
      await pumpPosApp(
        tester,
        overrides: [
          connectionStatusProvider.overrideWithValue(ConnectionStatus.offline),
          printerStatusProvider.overrideWithValue(PrinterStatus.missing),
          pendingEventsProvider.overrideWith((ref) => Stream.value(12)),
          clockProvider.overrideWithValue(
            () => DateTime.utc(2026, 10, 14, 15, 15),
          ),
        ],
      );
      expect(
        find.text("Internet yo'q — savdolar saqlanyapti (12)"),
        findsOneWidget,
      );
      expect(find.text('12 ta yozuv navbatda'), findsOneWidget);
      expect(find.text('Printer ulanmagan'), findsOneWidget);
      expect(find.text('20:15'), findsOneWidget);
    });

    testWidgets('shift and queue come from the local database', (
      tester,
    ) async {
      final (_, db) = await pumpPosApp(tester, withOpenShift: false);
      {
        final t = DateTime.utc(2026, 10, 14);
        await db
            .into(db.shifts)
            .insert(
              ShiftsCompanion.insert(
                id: 's1',
                storeId: testDevice.storeId,
                deviceId: testDevice.id,
                openedBy: 'u',
                openedAt: t,
                openingCashTiyin: 0,
              ),
            );
        await db
            .into(db.outboxEvents)
            .insert(
              OutboxEventsCompanion.insert(
                id: 'e1',
                type: 'shift.opened',
                payload: '{}',
                createdAt: t,
              ),
            );
      }
      await tester.pumpAndSettle();
      expect(find.text('Smena ochiq'), findsOneWidget);
      expect(find.text('1 ta yozuv navbatda'), findsOneWidget);

      await tester.runAsync(
        () => db
            .update(db.shifts)
            .write(
              ShiftsCompanion(closedAt: Value(DateTime.utc(2026, 10, 15))),
            ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Smena yopiq'), findsOneWidget);
    });
  });
}
