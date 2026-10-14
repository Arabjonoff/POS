import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/data/db/app_database.dart';

/// Ilova tillari: o'zbek (lotin, asosiy), o'zbek (kirill), rus.
abstract final class AppLocales {
  static const Locale uzLatn = Locale('uz');
  static const Locale uzCyrl = Locale.fromSubtags(
    languageCode: 'uz',
    scriptCode: 'Cyrl',
  );
  static const Locale ru = Locale('ru');

  static const List<Locale> all = [uzLatn, uzCyrl, ru];

  /// Saqlash uchun teg: `uz`, `uz_Cyrl`, `ru` (server `default_locale`
  /// `uz-Cyrl` ni ham qabul qiladi).
  static String tag(Locale locale) => locale.scriptCode == null
      ? locale.languageCode
      : '${locale.languageCode}_${locale.scriptCode}';

  /// Tegdan tilni topadi; noma'lum yoki bo'sh — `null`.
  static Locale? parse(String? tag) {
    if (tag == null) return null;
    final normalized = tag.replaceAll('-', '_');
    for (final locale in all) {
      if (AppLocales.tag(locale).toLowerCase() == normalized.toLowerCase()) {
        return locale;
      }
    }
    return null;
  }
}

/// Ilova ochilishida saqlangan til (`main` da bazadan o'qiladi, birinchi
/// kadrdayoq to'g'ri tilda chiqishi uchun).
final initialLocaleProvider = Provider<Locale>((ref) => AppLocales.uzLatn);

/// Tanlangan til. Tanlov lokal bazada (`LocalSettings`, kalit `locale`).
class LocaleController extends Notifier<Locale> {
  static const String settingKey = 'locale';

  @override
  Locale build() => ref.read(initialLocaleProvider);

  Future<void> select(Locale locale) async {
    if (!AppLocales.all.contains(locale) || state == locale) return;
    state = locale;
    await ref
        .read(appDatabaseProvider)
        .writeSetting(settingKey, AppLocales.tag(locale));
  }
}

final localeProvider = NotifierProvider<LocaleController, Locale>(
  LocaleController.new,
);

/// Bazadan saqlangan tilni o'qiydi (yo'q bo'lsa — o'zbek lotin).
Future<Locale> loadSavedLocale(AppDatabase db) async =>
    AppLocales.parse(await db.readSetting(LocaleController.settingKey)) ??
    AppLocales.uzLatn;
