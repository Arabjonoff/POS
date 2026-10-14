import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/app/app.dart';
import 'package:pos_app/app/session/session.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/data/device/device_info.dart';
import 'package:pos_app/data/remote/api.dart';

import 'sqlite.dart';

const DeviceInfo testDevice = DeviceInfo(
  id: 'device-1',
  number: 3,
  name: 'Kassa 1',
  storeId: 'store-1',
);

const StaffUser testCashier = StaffUser(
  id: 'cashier-1',
  fullName: 'Aziza',
  role: 'cashier',
  isActive: true,
  pinHash:
      r'pbkdf2_sha256$120000$c2FsdHNhbHQ$qxLQ/NshlIkVFl8YCKVHFuksbvylfDpbcG607Ow+G5A=',
);

/// Kassir kirgan holat (qobiq testlari uchun standart).
const Session unlockedSession = Session(
  stage: SessionStage.unlocked,
  device: testDevice,
  user: testCashier,
);

/// Butun ilovani test bazasi bilan ochadi. Qaytaradi: konteyner va baza.
Future<(ProviderContainer, AppDatabase)> pumpPosApp(
  WidgetTester tester, {
  Size size = const Size(1440, 900),
  List<Override> overrides = const [],
  Session session = unlockedSession,
  AppDatabase? db,
  DeviceTokenStore? tokens,
  bool settle = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final database = db ?? openTestDatabase();
  if (db == null) addTearDown(database.close);
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(database),
      deviceTokenStoreProvider.overrideWithValue(
        tokens ?? MemoryDeviceTokenStore(),
      ),
      initialSessionProvider.overrideWithValue(session),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const PosApp()),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump(const Duration(milliseconds: 300));
  }
  return (container, database);
}
