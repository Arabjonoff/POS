// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Касса';

  @override
  String get posTitle => 'Касса';

  @override
  String get posEmptyCart => 'Отсканируйте товар или найдите его';

  @override
  String get languageName => 'Русский';

  @override
  String get currencySom => 'сум';

  @override
  String get unitPcs => 'шт';

  @override
  String get unitKg => 'кг';

  @override
  String get unitG => 'г';

  @override
  String get unitL => 'л';

  @override
  String get unitM => 'м';

  @override
  String get unitPack => 'уп.';

  @override
  String get navPos => 'Касса';

  @override
  String get navProducts => 'Товары';

  @override
  String get navReceiving => 'Приход';

  @override
  String get navCustomers => 'Клиенты';

  @override
  String get navReports => 'Отчёты';

  @override
  String get navSettings => 'Настройки';

  @override
  String get actionSave => 'Сохранить';

  @override
  String get actionCancel => 'Отмена';

  @override
  String get actionUndo => 'Отменить';

  @override
  String get actionClose => 'Закрыть';

  @override
  String get actionDelete => 'Удалить';

  @override
  String get actionRetry => 'Повторить';

  @override
  String get actionYes => 'Да';

  @override
  String get actionNo => 'Нет';

  @override
  String get actionClear => 'Очистить';

  @override
  String get actionBackspace => 'Стереть последнюю цифру';

  @override
  String get actionIncrease => 'Увеличить';

  @override
  String get actionDecrease => 'Уменьшить';

  @override
  String get actionPay => 'Оплатить';

  @override
  String get searchProductsHint => 'Штрихкод или название товара';

  @override
  String get totalLabel => 'Итого';

  @override
  String get changeLabel => 'Сдача';

  @override
  String get statusOnline => 'Интернет есть';

  @override
  String get statusOffline => 'Нет интернета';

  @override
  String statusQueued(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count записи в очереди',
      many: '$count записей в очереди',
      few: '$count записи в очереди',
      one: '$count запись в очереди',
      zero: 'Всё отправлено',
    );
    return '$_temp0';
  }

  @override
  String statusOfflineSaving(int count) {
    return 'Нет интернета — продажи сохраняются ($count)';
  }

  @override
  String get statusPrinterReady => 'Принтер подключён';

  @override
  String get statusPrinterMissing => 'Принтер не подключён';

  @override
  String get statusShiftOpen => 'Смена открыта';

  @override
  String get statusShiftClosed => 'Смена закрыта';

  @override
  String get settingsLanguage => 'Язык';
}
