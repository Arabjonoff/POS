import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/app/session/pin_gate.dart';
import 'package:pos_app/app/session/session.dart';
import 'package:pos_app/data/db/app_database.dart';

import '../helpers/pump_app.dart';
import '../helpers/sqlite.dart';
import 'golden_helpers.dart';

Future<AppDatabase> _staff() async {
  final db = openTestDatabase();
  for (final (id, name, role, hasPin) in [
    ('u1', 'Aziza Karimova', 'cashier', true),
    ('u2', 'Bobur', 'manager', true),
    ('u3', 'Dilnoza', 'cashier', false),
    ('u4', 'Aziz Rahimov', 'owner', true),
  ]) {
    await db
        .into(db.staffUsers)
        .insert(
          StaffUsersCompanion.insert(
            id: id,
            fullName: name,
            role: role,
            pinHash: Value(hasPin ? 'hash' : null),
          ),
        );
  }
  return db;
}

/// Kirish ekranlari: ulash, xodim tanlash, PIN (xato bilan).
void main() {
  goldenAcrossDevices('auth', 'setup', (tester, size) async {
    await pumpPosApp(
      tester,
      size: size,
      session: const Session(stage: SessionStage.setup),
    );
  });

  goldenAcrossDevices('auth', 'lock_users', (tester, size) async {
    final db = await _staff();
    addTearDown(db.close);
    await pumpPosApp(
      tester,
      size: size,
      db: db,
      session: const Session(stage: SessionStage.locked, device: testDevice),
    );
  });

  goldenAcrossDevices('auth', 'lock_pin', (tester, size) async {
    final db = await _staff();
    addTearDown(db.close);
    await pumpPosApp(
      tester,
      size: size,
      db: db,
      session: const Session(stage: SessionStage.locked, device: testDevice),
      overrides: [
        pinGateProvider.overrideWith(
          (ref) => PinGate(db, verify: (_, _) async => false),
        ),
      ],
    );
    await tester.tap(find.text('Aziza Karimova'));
    await tester.pumpAndSettle();
    for (final d in ['1', '1', '1', '1']) {
      await tester.tap(find.text(d).last);
    }
    await tester.tap(find.bySemanticsLabel('Kirish'));
    await tester.pumpAndSettle();
    expect(find.textContaining("PIN noto'g'ri"), findsOneWidget);
  });
}
