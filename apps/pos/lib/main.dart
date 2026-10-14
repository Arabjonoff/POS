import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/app/app.dart';
import 'package:pos_app/app/locale.dart';
import 'package:pos_app/app/session/auto_lock.dart';
import 'package:pos_app/app/session/session.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/data/remote/api.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = AppDatabase.open();
  final tokens = SecureDeviceTokenStore();
  // Birinchi kadrdan to'g'ri til va to'g'ri ekran (ulash / PIN).
  final locale = await loadSavedLocale(db);
  final session = await loadSession(db, tokens);
  final autoLock = await loadAutoLockMinutes(db);
  runApp(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        deviceTokenStoreProvider.overrideWithValue(tokens),
        initialLocaleProvider.overrideWithValue(locale),
        initialSessionProvider.overrideWithValue(session),
        initialAutoLockMinutesProvider.overrideWithValue(autoLock),
      ],
      child: const PosApp(),
    ),
  );
}
