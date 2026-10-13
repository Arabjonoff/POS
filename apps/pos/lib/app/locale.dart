import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ilova tillari: o'zbek (lotin, asosiy), o'zbek (kirill), rus.
abstract final class AppLocales {
  static const Locale uzLatn = Locale('uz');
  static const Locale uzCyrl = Locale.fromSubtags(
    languageCode: 'uz',
    scriptCode: 'Cyrl',
  );
  static const Locale ru = Locale('ru');

  static const List<Locale> all = [uzLatn, uzCyrl, ru];
}

/// Tanlangan til. Saqlash (sozlamalarda) T-031 da qo'shiladi.
class LocaleController extends Notifier<Locale> {
  @override
  Locale build() => AppLocales.uzLatn;

  void select(Locale locale) {
    if (state == locale) return;
    state = locale;
  }
}

final localeProvider = NotifierProvider<LocaleController, Locale>(
  LocaleController.new,
);
