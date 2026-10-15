import 'package:drift/drift.dart' show Value;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/app/status/app_status.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/features/pos/payment/payment_dialog.dart';
import 'package:pos_ui/pos_ui.dart';

import '../helpers/catalog_seed.dart';
import '../helpers/keyboard.dart';
import '../helpers/pump_app.dart';
import '../helpers/sqlite.dart';

const Size phone = Size(390, 844);
const Size tablet = Size(1024, 768);

const String emptyCart = 'Tovarni skanerlang yoki qidiring';
const String reportsNoAccess = 'Hisobotlar ega va menejer uchun';

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

    testWidgets('desktop: collapsed 64 dp menu, Ctrl+B and hover open it', (
      tester,
    ) async {
      const sections = [
        'Kassa',
        'Tovarlar',
        'Kirim',
        'Mijozlar',
        'Hisobotlar',
        'Sozlamalar',
      ];
      await pumpPosApp(tester);
      // Yig'ilgan: faqat ikonlar, nomi va tezkor tugmasi — tooltip'da.
      for (final (i, label) in sections.indexed) {
        expect(find.byTooltip('$label · Ctrl+${i + 1}'), findsOneWidget);
      }
      expect(find.text('Ctrl+1'), findsNothing);
      final body = tester.getRect(find.byType(PosSearchField));
      expect(body.left, greaterThan(PosSizes.navCollapsedWidth));
      expect(body.left, lessThan(PosSizes.navCollapsedWidth + 32));
      expect(
        tester.getRect(find.byKey(const ValueKey('nav-toggle'))).right,
        lessThanOrEqualTo(PosSizes.navCollapsedWidth),
      );

      // Ctrl+B — doim ochiq: yozuvlar va tezkor tugmalar, kontent suriladi.
      await ctrl(tester, LogicalKeyboardKey.keyB);
      for (var i = 1; i <= 6; i++) {
        expect(find.text('Ctrl+$i'), findsOneWidget);
      }
      expect(tester.getRect(find.text('Mijozlar')).top, lessThan(400));
      expect(
        tester.getRect(find.byType(PosSearchField)).left,
        greaterThan(PosSizes.sideNavWidth),
      );
      await ctrl(tester, LogicalKeyboardKey.keyB);
      expect(find.text('Ctrl+1'), findsNothing);

      // Sichqoncha olib borilsa — kontent ustida ochiladi, ketsa — yopiladi.
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: const Offset(800, 400));
      await mouse.moveTo(const Offset(32, 300));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.text('Ctrl+6'), findsOneWidget);
      expect(tester.getRect(find.byType(PosSearchField)).left, body.left);
      await mouse.moveTo(const Offset(800, 400));
      await tester.pumpAndSettle();
      expect(find.text('Ctrl+6'), findsNothing);

      await tapNav(tester, 'Sozlamalar');
      expect(find.text('Til'), findsOneWidget);
      expect(find.text('Русский'), findsOneWidget);
    });

    testWidgets('keyboard: back to Kassa from any section, F12 still works', (
      tester,
    ) async {
      // UI tekshiruvi (T-091): bo'lim almashganda fokus yo'qolib, kassaga
      // qaytganda F12 va Ctrl+raqam ishlamay qolardi.
      final db = openTestDatabase();
      addTearDown(db.close);
      await seedCatalog(db);
      await pumpPosApp(tester, db: db);
      await scanCode(tester, '4780000000014');
      for (final key in [
        LogicalKeyboardKey.digit2,
        LogicalKeyboardKey.digit3,
        LogicalKeyboardKey.digit4,
        LogicalKeyboardKey.digit5,
        LogicalKeyboardKey.digit6,
      ]) {
        await ctrl(tester, key);
        await ctrl(tester, LogicalKeyboardKey.digit1);
        await press(tester, LogicalKeyboardKey.f12);
        expect(find.byType(PaymentDialog), findsOneWidget, reason: '$key');
        await press(tester, LogicalKeyboardKey.escape);
        expect(find.byType(PaymentDialog), findsNothing);
      }
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
      expect(find.text(reportsNoAccess), findsOneWidget);

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
      expect(
        tester.getRect(find.byIcon(Icons.inventory_2_outlined)).top,
        greaterThan(760),
      );
      // 6 bo'lim: yozuv faqat tanlanganda (siqilib kesilmasin), qolganlari —
      // ikon + tooltip/ekran o'quvchi nomi.
      expect(find.text('Tovarlar'), findsNothing);
      expect(find.bySemanticsLabel('Tovarlar'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Til'), findsOneWidget);
      // Status bar is on top on phones.
      final status = tester.getRect(find.byType(PosStatusBar));
      expect(status.top, lessThan(100));
    });

    testWidgets('tablet: collapsed menu, status bar at the bottom', (
      tester,
    ) async {
      await pumpPosApp(tester, size: tablet);
      expect(
        tester.getRect(find.byTooltip('Mijozlar · Ctrl+4')).top,
        lessThan(400),
      );
      final status = tester.getRect(find.byType(PosStatusBar));
      expect(status.bottom, tablet.height);
      // 48 dp yozuvlar + yuqori chegara.
      expect(status.height, PosSizes.statusBarHeightLarge + 1);
    });

    testWidgets('language switch from settings updates navigation', (
      tester,
    ) async {
      final (_, db) = await pumpPosApp(tester);
      await tapNav(tester, 'Sozlamalar');
      await tester.tap(find.text('Русский'));
      await tester.pumpAndSettle();
      expect(find.text('Настройки'), findsWidgets);
      expect(find.byTooltip('Товары · Ctrl+2'), findsOneWidget);
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
      // Oflayn — qizil, lekin xotirjam: savdo davom etadi.
      expect(
        find.text("Internet yo'q — oflayn rejimda ishlayapti"),
        findsOneWidget,
      );
      expect(find.text('12 ta yozuv navbatda'), findsOneWidget);
      expect(find.text('Printer ulanmagan'), findsOneWidget);
      expect(find.text('20:15'), findsOneWidget);
      // Kim ishlayapti.
      expect(find.text('Aziza · Kassir'), findsOneWidget);

      // Muammo bosilsa — sozlamalarga.
      await tester.tap(find.text('Printer ulanmagan'));
      await tester.pumpAndSettle();
      expect(find.text('Til'), findsOneWidget);
    });

    testWidgets('shift item shows since when; tapping opens the shift', (
      tester,
    ) async {
      await pumpPosApp(tester);
      final shift = find.textContaining('Smena ochiq · ');
      expect(shift, findsOneWidget);
      // Bosiladigan joy — kamida 48 dp.
      final target = find.ancestor(of: shift, matching: find.byType(InkWell));
      expect(tester.getSize(target.first).height, PosSizes.touchMin);
      await tester.tap(shift);
      await tester.pumpAndSettle();
      expect(find.text('Smenani yopish'), findsWidgets);
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
      expect(find.text('Smena ochiq · 05:00 dan'), findsOneWidget);
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
