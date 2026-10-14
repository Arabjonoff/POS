import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/app/app.dart';
import 'package:pos_app/data/db/app_database.dart';

import 'sqlite.dart';

/// Butun ilovani test bazasi bilan ochadi. Qaytaradi: konteyner va baza.
Future<(ProviderContainer, AppDatabase)> pumpPosApp(
  WidgetTester tester, {
  Size size = const Size(1440, 900),
  List<Override> overrides = const [],
  bool settle = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final db = openTestDatabase();
  addTearDown(db.close);
  final container = ProviderContainer(
    overrides: [appDatabaseProvider.overrideWithValue(db), ...overrides],
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
  return (container, db);
}
