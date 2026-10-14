// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Uzbek (`uz`).
class AppLocalizationsUz extends AppLocalizations {
  AppLocalizationsUz([String locale = 'uz']) : super(locale);

  @override
  String get appTitle => 'Kassa';

  @override
  String get posTitle => 'Kassa';

  @override
  String get posEmptyCart => 'Tovarni skanerlang yoki qidiring';

  @override
  String get languageName => 'O\'zbekcha';

  @override
  String get currencySom => 'so\'m';

  @override
  String get unitPcs => 'dona';

  @override
  String get unitKg => 'kg';

  @override
  String get unitG => 'g';

  @override
  String get unitL => 'l';

  @override
  String get unitM => 'm';

  @override
  String get unitPack => 'qadoq';

  @override
  String get navPos => 'Kassa';

  @override
  String get navProducts => 'Tovarlar';

  @override
  String get navReceiving => 'Kirim';

  @override
  String get navCustomers => 'Mijozlar';

  @override
  String get navReports => 'Hisobotlar';

  @override
  String get navSettings => 'Sozlamalar';

  @override
  String get actionSave => 'Saqlash';

  @override
  String get actionCancel => 'Bekor qilish';

  @override
  String get actionUndo => 'Bekor qilish';

  @override
  String get actionClose => 'Yopish';

  @override
  String get actionDelete => 'O\'chirish';

  @override
  String get actionRetry => 'Qayta urinish';

  @override
  String get actionYes => 'Ha';

  @override
  String get actionNo => 'Yo\'q';

  @override
  String get actionClear => 'Tozalash';

  @override
  String get actionBackspace => 'Oxirgi raqamni o\'chirish';

  @override
  String get actionIncrease => 'Ko\'paytirish';

  @override
  String get actionDecrease => 'Kamaytirish';

  @override
  String get actionPay => 'To\'lash';

  @override
  String get searchProductsHint => 'Shtrix-kod yoki tovar nomi';

  @override
  String get totalLabel => 'Jami';

  @override
  String get changeLabel => 'Qaytim';

  @override
  String get statusOnline => 'Internet bor';

  @override
  String get statusOffline => 'Internet yo\'q';

  @override
  String statusQueued(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ta yozuv navbatda',
      zero: 'Hammasi yuborilgan',
    );
    return '$_temp0';
  }

  @override
  String statusOfflineSaving(int count) {
    return 'Internet yo\'q — savdolar saqlanyapti ($count)';
  }

  @override
  String get statusPrinterReady => 'Printer ulangan';

  @override
  String get statusPrinterMissing => 'Printer ulanmagan';

  @override
  String get statusShiftOpen => 'Smena ochiq';

  @override
  String get statusShiftClosed => 'Smena yopiq';

  @override
  String get settingsLanguage => 'Til';

  @override
  String get statusConnectionUnknown => 'Ulanish tekshirilmoqda';

  @override
  String get statusPrinterUnknown => 'Printer sozlanmagan';

  @override
  String get sectionComingSoonTitle => 'Bo\'lim tayyorlanmoqda';

  @override
  String get sectionComingSoonMessage =>
      'Bu bo\'lim keyingi yangilanishda qo\'shiladi';
}

/// The translations for Uzbek, using the Cyrillic script (`uz_Cyrl`).
class AppLocalizationsUzCyrl extends AppLocalizationsUz {
  AppLocalizationsUzCyrl() : super('uz_Cyrl');

  @override
  String get appTitle => 'Касса';

  @override
  String get posTitle => 'Касса';

  @override
  String get posEmptyCart => 'Товарни сканерланг ёки қидиринг';

  @override
  String get languageName => 'Ўзбекча';

  @override
  String get currencySom => 'сўм';

  @override
  String get unitPcs => 'дона';

  @override
  String get unitKg => 'кг';

  @override
  String get unitG => 'г';

  @override
  String get unitL => 'л';

  @override
  String get unitM => 'м';

  @override
  String get unitPack => 'қадоқ';

  @override
  String get navPos => 'Касса';

  @override
  String get navProducts => 'Товарлар';

  @override
  String get navReceiving => 'Кирим';

  @override
  String get navCustomers => 'Мижозлар';

  @override
  String get navReports => 'Ҳисоботлар';

  @override
  String get navSettings => 'Созламалар';

  @override
  String get actionSave => 'Сақлаш';

  @override
  String get actionCancel => 'Бекор қилиш';

  @override
  String get actionUndo => 'Бекор қилиш';

  @override
  String get actionClose => 'Ёпиш';

  @override
  String get actionDelete => 'Ўчириш';

  @override
  String get actionRetry => 'Қайта уриниш';

  @override
  String get actionYes => 'Ҳа';

  @override
  String get actionNo => 'Йўқ';

  @override
  String get actionClear => 'Тозалаш';

  @override
  String get actionBackspace => 'Охирги рақамни ўчириш';

  @override
  String get actionIncrease => 'Кўпайтириш';

  @override
  String get actionDecrease => 'Камайтириш';

  @override
  String get actionPay => 'Тўлаш';

  @override
  String get searchProductsHint => 'Штрих-код ёки товар номи';

  @override
  String get totalLabel => 'Жами';

  @override
  String get changeLabel => 'Қайтим';

  @override
  String get statusOnline => 'Интернет бор';

  @override
  String get statusOffline => 'Интернет йўқ';

  @override
  String statusQueued(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count та ёзув навбатда',
      zero: 'Ҳаммаси юборилган',
    );
    return '$_temp0';
  }

  @override
  String statusOfflineSaving(int count) {
    return 'Интернет йўқ — савдолар сақланяпти ($count)';
  }

  @override
  String get statusPrinterReady => 'Принтер уланган';

  @override
  String get statusPrinterMissing => 'Принтер уланмаган';

  @override
  String get statusShiftOpen => 'Смена очиқ';

  @override
  String get statusShiftClosed => 'Смена ёпиқ';

  @override
  String get settingsLanguage => 'Тил';

  @override
  String get statusConnectionUnknown => 'Уланиш текширилмоқда';

  @override
  String get statusPrinterUnknown => 'Принтер созланмаган';

  @override
  String get sectionComingSoonTitle => 'Бўлим тайёрланмоқда';

  @override
  String get sectionComingSoonMessage =>
      'Бу бўлим кейинги янгиланишда қўшилади';
}
