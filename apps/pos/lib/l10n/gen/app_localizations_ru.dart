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

  @override
  String get statusConnectionUnknown => 'Проверка соединения';

  @override
  String get statusPrinterUnknown => 'Принтер не настроен';

  @override
  String get sectionComingSoonTitle => 'Раздел в разработке';

  @override
  String get sectionComingSoonMessage =>
      'Раздел появится в следующем обновлении';

  @override
  String get setupTitle => 'Подключение кассы';

  @override
  String get setupSubtitle => 'Войдите по телефону и паролю владельца магазина';

  @override
  String get setupPhoneLabel => 'Номер телефона';

  @override
  String get setupPhoneHint => '90 123 45 67';

  @override
  String get setupPasswordLabel => 'Пароль';

  @override
  String get setupNext => 'Продолжить';

  @override
  String get setupDeviceNameTitle => 'Назовите эту кассу';

  @override
  String get setupDeviceNameLabel => 'Название кассы';

  @override
  String get setupDeviceNameHelper => 'Например: Касса 1, Прилавок';

  @override
  String get setupDeviceNameDefault => 'Касса 1';

  @override
  String get setupConnect => 'Подключить';

  @override
  String get setupSyncTitle => 'Загрузка данных';

  @override
  String setupSyncProgress(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Загружено $count записи',
      many: 'Загружено $count записей',
      few: 'Загружено $count записи',
      one: 'Загружена $count запись',
      zero: 'Подготовка…',
    );
    return '$_temp0';
  }

  @override
  String get setupSyncFailed =>
      'Не удалось загрузить данные. Проверьте интернет.';

  @override
  String get setupErrorInvalidCredentials => 'Неверный телефон или пароль';

  @override
  String get setupErrorNotOwner => 'Подключить кассу может только владелец';

  @override
  String get setupErrorDeviceLimit =>
      'Лимит касс по тарифу исчерпан. Обратитесь к администратору.';

  @override
  String get setupErrorNoSubscription =>
      'Подписка не найдена. Обратитесь к администратору.';

  @override
  String get setupErrorDeviceBlocked =>
      'Эта касса заблокирована. Обратитесь к администратору.';

  @override
  String get setupErrorNetwork =>
      'Нет интернета или сервер не отвечает. Попробуйте ещё раз.';

  @override
  String get setupErrorUnknown => 'Что-то пошло не так. Попробуйте ещё раз.';

  @override
  String get fieldRequired => 'Заполните поле';

  @override
  String get lockTitle => 'Кто работает?';

  @override
  String get lockEnterPin => 'Введите PIN-код';

  @override
  String get lockSubmit => 'Войти';

  @override
  String get lockBack => 'Другой сотрудник';

  @override
  String lockWrongPin(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Неверный PIN. Осталось $count попытки',
      many: 'Неверный PIN. Осталось $count попыток',
      few: 'Неверный PIN. Осталось $count попытки',
      one: 'Неверный PIN. Осталась $count попытка',
      zero: 'Неверный PIN',
    );
    return '$_temp0';
  }

  @override
  String lockLockedOut(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'Слишком много ошибок. Повторите через $seconds секунды',
      many: 'Слишком много ошибок. Повторите через $seconds секунд',
      few: 'Слишком много ошибок. Повторите через $seconds секунды',
      one: 'Слишком много ошибок. Повторите через $seconds секунду',
    );
    return '$_temp0';
  }

  @override
  String get lockNoPin => 'PIN не задан';

  @override
  String get lockNoStaffTitle => 'Сотрудники не найдены';

  @override
  String get lockNoStaffMessage =>
      'Данные ещё не загружены. Проверьте интернет и повторите.';

  @override
  String get roleOwner => 'Владелец';

  @override
  String get roleManager => 'Менеджер';

  @override
  String get roleCashier => 'Кассир';

  @override
  String get actionLock => 'Заблокировать';

  @override
  String get settingsAutoLock => 'Автоблокировка';

  @override
  String get settingsAutoLockHelper =>
      'Экран блокируется, если касса не используется';

  @override
  String get settingsAutoLockOff => 'Выключена';

  @override
  String settingsAutoLockMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'Через $minutes минуты',
      many: 'Через $minutes минут',
      few: 'Через $minutes минуты',
      one: 'Через $minutes минуту',
    );
    return '$_temp0';
  }

  @override
  String get statusSalesReadonly => 'Подписка истекла — продажи остановлены';

  @override
  String get statusSalesBlocked => 'Магазин заблокирован — продажи остановлены';

  @override
  String get statusSalesOffline => 'Долго нет интернета — продажи остановлены';

  @override
  String get statusDeviceBlocked => 'Касса заблокирована';

  @override
  String get statusClockSkew => 'Неверное время на компьютере';

  @override
  String statusRejected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count записи не приняты',
      many: '$count записей не принято',
      few: '$count записи не приняты',
      one: '$count запись не принята',
    );
    return '$_temp0';
  }

  @override
  String get settingsScanner => 'Сканер штрихкодов';

  @override
  String get settingsScannerSound => 'Звук при сканировании';

  @override
  String get settingsScannerSpeed => 'Скорость сканера';

  @override
  String get settingsScannerSpeedNormal => 'Обычный сканер';

  @override
  String get settingsScannerSpeedSlow => 'Медленный (Bluetooth) сканер';

  @override
  String get settingsScannerSpeedVerySlow => 'Очень медленный сканер';

  @override
  String get scanCamera => 'Сканировать камерой';

  @override
  String get scanCameraHint => 'Наведите камеру на штрихкод';

  @override
  String get scanCameraDenied =>
      'Нет доступа к камере. Разрешите его в настройках телефона.';

  @override
  String get scanInvalidCode => 'Код считан неверно, отсканируйте ещё раз';

  @override
  String get shiftOpenTitle => 'Откройте смену';

  @override
  String get shiftOpenMessage =>
      'Чтобы начать продажи, введите наличные в кассе';

  @override
  String get shiftOpeningCash => 'Наличные в кассе';

  @override
  String get shiftOpenAction => 'Открыть смену';

  @override
  String get shiftTitle => 'Смена';

  @override
  String shiftOpenedInfo(String time, String name) {
    return 'Открыта в $time, $name';
  }

  @override
  String get shiftXReport => 'X-отчёт';

  @override
  String get shiftZReport => 'Z-отчёт';

  @override
  String get reportSales => 'Продажи';

  @override
  String reportChecks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count чека',
      many: '$count чеков',
      few: '$count чека',
      one: '$count чек',
    );
    return '$_temp0';
  }

  @override
  String get reportCash => 'Наличные';

  @override
  String get reportCard => 'Карта';

  @override
  String get reportDebt => 'В долг';

  @override
  String get reportRefunds => 'Возвраты';

  @override
  String get reportCashMovements => 'Движение денег';

  @override
  String get reportCashIn => 'Внесено';

  @override
  String get reportCashOut => 'Изъято';

  @override
  String get reportDebtPayments => 'Погашение долгов';

  @override
  String get reportCashBalance => 'Учёт наличных';

  @override
  String get reportOpeningCash => 'Начальный остаток';

  @override
  String get reportExpectedCash => 'Должно быть в кассе';

  @override
  String get reportCountedCash => 'Пересчитано';

  @override
  String get reportSurplus => 'Излишек';

  @override
  String get reportShortage => 'Недостача';

  @override
  String get reportNoDifference => 'Без расхождений';

  @override
  String get shiftCloseAction => 'Закрыть смену';

  @override
  String get shiftCloseTitle => 'Пересчитайте наличные';

  @override
  String get shiftCloseConfirm => 'Закрыть';

  @override
  String get shiftClosedTitle => 'Смена закрыта';

  @override
  String get shiftBackToPos => 'Вернуться к кассе';

  @override
  String get shiftPrintReport => 'Печать отчёта';

  @override
  String get posSearchHint => 'Название, штрихкод или PLU';

  @override
  String get posQuickAll => 'Все';

  @override
  String get posQuickButtons => 'Быстрые кнопки';

  @override
  String get posQuickEmpty => 'Быстрые кнопки ещё не настроены';

  @override
  String get posNoResults => 'Ничего не найдено';

  @override
  String posCartTab(int number) {
    return 'Чек $number';
  }

  @override
  String get posNewCart => 'Новый чек';

  @override
  String get posCartLimit => 'Нельзя открыть больше 5 чеков';

  @override
  String posItemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count товара',
      many: '$count товаров',
      few: '$count товара',
      one: '$count товар',
    );
    return '$_temp0';
  }

  @override
  String get posSubtotal => 'Товары';

  @override
  String get posDiscount => 'Скидка';

  @override
  String posLineRemoved(String name) {
    return '$name: удалено';
  }

  @override
  String get posQtyTitle => 'Количество';

  @override
  String get posWeightTitle => 'Вес, кг';

  @override
  String get posQtyApply => 'Готово';

  @override
  String get posCodeNotFound => 'Этого кода нет в базе';

  @override
  String get posNotSellable =>
      'Этот товар нельзя продать: неактивен или без цены';

  @override
  String get posDiscountLine => 'На строку';

  @override
  String get posDiscountCheck => 'На весь чек';

  @override
  String get posDiscountPercent => 'Процент';

  @override
  String get posDiscountAmount => 'Сумма';

  @override
  String get posDiscountApply => 'Применить';

  @override
  String get posDiscountRemove => 'Убрать';

  @override
  String posDiscountNeedsApproval(String percent) {
    return 'Скидку больше $percent% подтверждает менеджер или владелец';
  }

  @override
  String get approvalTitle => 'Нужно подтверждение';

  @override
  String get approvalNoManagers => 'У менеджера и владельца не задан PIN';

  @override
  String get approvalConfirm => 'Подтвердить';

  @override
  String get payTitle => 'Оплата';

  @override
  String get payMixed => 'Смешанная';

  @override
  String get payExact => 'Без сдачи';

  @override
  String get payReceived => 'Получено';

  @override
  String get payShort => 'Не хватает';

  @override
  String get payCardHint => 'Проведите оплату на терминале и подтвердите';

  @override
  String get payComplete => 'Завершить';

  @override
  String get payCashRest => 'Наличные (остаток)';

  @override
  String get payPartsExceed => 'Карта и долг больше суммы чека';

  @override
  String get payScanBlocked => 'Сначала завершите оплату';

  @override
  String get payChooseCustomer => 'Выберите клиента';

  @override
  String get payCustomerSearch => 'Имя или телефон';

  @override
  String get payNewCustomer => 'Новый клиент';

  @override
  String get payCustomerName => 'Имя';

  @override
  String get payCustomerPhone => 'Телефон';

  @override
  String payCustomerDebt(String amount) {
    return 'Долг: $amount';
  }

  @override
  String payCustomerLimit(String amount) {
    return 'Лимит: $amount';
  }

  @override
  String get payLimitExceeded =>
      'Долг превысит лимит — нужно подтверждение менеджера или владельца';

  @override
  String get payNoCustomers => 'Клиенты не найдены';

  @override
  String get paySaleDone => 'Продажа завершена';

  @override
  String paySaleDoneChange(String amount) {
    return 'Продажа завершена · Сдача $amount';
  }

  @override
  String get payFailed => 'Не удалось сохранить продажу. Попробуйте ещё раз';

  @override
  String get posCustomer => 'Клиент';

  @override
  String get posCustomerRemove => 'Убрать клиента';

  @override
  String get payCash => 'Наличные';

  @override
  String get payCard => 'Карта';

  @override
  String get payDebt => 'В долг';

  @override
  String get payChangeCustomer => 'Другой клиент';

  @override
  String get posCustomerTitle => 'Клиент чека';

  @override
  String get posCustomerNone => 'Клиент не выбран';
}
