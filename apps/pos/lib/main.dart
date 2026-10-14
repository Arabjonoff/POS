import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/app/app.dart';
import 'package:pos_app/app/locale.dart';
import 'package:pos_app/data/db/app_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = AppDatabase.open();
  final locale = await loadSavedLocale(db);
  runApp(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        initialLocaleProvider.overrideWithValue(locale),
      ],
      child: const PosApp(),
    ),
  );
}
