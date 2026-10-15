import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/app/session/pin_gate.dart';
import 'package:pos_app/app/session/session.dart';
import 'package:pos_app/app/status/app_status.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/data/reports/reports.dart';
import 'package:pos_app/data/reports/reports_provider.dart';
import 'package:pos_ui/pos_ui.dart';

import '../helpers/keyboard.dart';
import '../helpers/pump_app.dart';
import '../helpers/report_vectors.dart';
import '../helpers/sqlite.dart';

const StaffUser manager = StaffUser(
  id: 'manager-1',
  fullName: 'Bobur',
  role: 'manager',
  isActive: true,
);

String som(int tiyin) => PosFormat.money(tiyin, currency: "so'm");

Finder inCard(String key, String text) => find.descendant(
  of: find.byKey(ValueKey(key)),
  matching: find.text(text),
);

Future<AppDatabase> open(
  WidgetTester tester, {
  StaffUser user = manager,
  List<Override> overrides = const [],
}) async {
  final db = await seedReportVectors(openTestDatabase());
  addTearDown(db.close);
  await db
      .into(db.staffUsers)
      .insert(
        StaffUsersCompanion.insert(
          id: 'manager-1',
          fullName: 'Bobur Menejer',
          role: 'manager',
          pinHash: const Value('hash'),
        ),
      );
  await pumpPosApp(
    tester,
    db: db,
    session: Session(
      stage: SessionStage.unlocked,
      device: testDevice,
      user: user,
    ),
    overrides: [
      // 15.10.2026 15:00 (Toshkent).
      clockProvider.overrideWithValue(() => DateTime.utc(2026, 10, 15, 10)),
      pinGateProvider.overrideWith(
        (ref) => PinGate(
          ref.watch(appDatabaseProvider),
          verify: (pin, _) async => pin == '1234',
        ),
      ),
      ...overrides,
    ],
  );
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(LogicalKeyboardKey.digit5);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pumpAndSettle();
  return db;
}

Future<void> tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('offline: today from the local db, flagged "this kassa only"', (
    tester,
  ) async {
    await open(tester);
    expect(find.byKey(const ValueKey('reports-local')), findsOneWidget);
    expect(find.text('15.10.2026'), findsOneWidget);
    expect(inCard('reports-revenue', som(4178718)), findsOneWidget);
    expect(inCard('reports-revenue', '↑ 945%'), findsOneWidget);
    expect(inCard('reports-profit', som(1078302)), findsOneWidget);
    expect(inCard('reports-checks', '2'), findsOneWidget);
    expect(inCard('reports-average', som(2652500)), findsOneWidget);
    expect(inCard('reports-payments', som(2305000)), findsOneWidget);
    expect(inCard('reports-payments', som(3000000)), findsOneWidget);
    expect(inCard('reports-top', 'Olma'), findsOneWidget);
    expect(
      inCard(
        'reports-top',
        PosFormat.qtyWithUnit(1250, unit: 'kg', weighted: true),
      ),
      findsOneWidget,
    );
    expect(inCard('reports-cashiers', 'Aziza'), findsOneWidget);
    expect(
      inCard('reports-cashiers', '1 ta chek · 1 ta qaytarish'),
      findsOneWidget,
    );
  });

  testWidgets('period chips: yesterday, last 7 days', (tester) async {
    await open(tester);
    await tap(tester, find.byKey(const ValueKey('reports-period-yesterday')));
    expect(find.text('14.10.2026'), findsOneWidget);
    expect(inCard('reports-revenue', som(400000)), findsOneWidget);
    expect(inCard('reports-checks', '1'), findsOneWidget);
    expect(find.text("Soatlar bo'yicha"), findsOneWidget);

    await tap(tester, find.byKey(const ValueKey('reports-period-last7Days')));
    expect(find.text('09.10.2026 – 15.10.2026'), findsOneWidget);
    expect(inCard('reports-revenue', som(4578718)), findsOneWidget);
    expect(find.text("Kunlar bo'yicha"), findsOneWidget);
  });

  testWidgets('online: server numbers, no offline flag', (tester) async {
    final periods = <ReportPeriod>[];
    await open(
      tester,
      overrides: [
        reportsFetcherProvider.overrideWithValue((period) async {
          periods.add(period);
          return Reports(
            period: period,
            summary: const ReportSummary(
              salesTotalTiyin: 99900000,
              refundsTotalTiyin: 0,
              revenueTiyin: 99900000,
              profitTiyin: 0,
              salesCount: 7,
              averageCheckTiyin: 0,
              paymentsTiyin: {'cash': 0, 'card': 0, 'debt': 0},
              refundsByMethodTiyin: {'cash': 0, 'debt': 0},
              previousRevenueTiyin: 0,
              previousProfitTiyin: 0,
              previousSalesCount: 0,
            ),
            byDay: const [],
            byHour: [
              for (var h = 0; h < 24; h++)
                HourRow(hour: h, revenueTiyin: 0, salesCount: 0),
            ],
            topProducts: const [],
            cashiers: const [],
            totalDebtTiyin: 0,
            debtorsCount: 0,
            topDebtors: const [],
            stockValueTiyin: 0,
            low: const [],
            negative: const [],
            local: false,
          );
        }),
      ],
    );
    expect(find.byKey(const ValueKey('reports-local')), findsNothing);
    expect(inCard('reports-revenue', som(99900000)), findsOneWidget);
    expect(inCard('reports-checks', '7'), findsOneWidget);
    expect(periods.single.fromIso, '2026-10-15');
  });

  testWidgets('cashier: no access until a manager PIN', (tester) async {
    await open(tester, user: testCashier);
    expect(find.text('Hisobotlar ega va menejer uchun'), findsOneWidget);
    expect(find.byKey(const ValueKey('reports-revenue')), findsNothing);
    await tap(tester, find.byKey(const ValueKey('reports-unlock')));
    await tester.tap(find.text('Bobur Menejer'));
    await tester.pumpAndSettle();
    await typeSlowly(tester, '1234');
    await press(tester, LogicalKeyboardKey.enter);
    expect(find.byKey(const ValueKey('reports-revenue')), findsOneWidget);
  });
}
