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
  String get loadFailedTitle => 'Не удалось загрузить данные';

  @override
  String get loadFailedMessage =>
      'Попробуйте ещё раз. Если повторится, перезапустите приложение.';

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
  String get phoneInvalid => 'Неверный номер. Например: 90 123 45 67';

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

  @override
  String get receiptCheck => 'Чек';

  @override
  String get receiptCashier => 'Кассир';

  @override
  String get receiptDiscount => 'Скидка';

  @override
  String get receiptTotal => 'ИТОГО';

  @override
  String get receiptCustomer => 'Клиент';

  @override
  String get receiptSubtotal => 'Сумма';

  @override
  String get receiptReceived => 'Получено наличными';

  @override
  String get receiptDebtAfter => 'Долг после покупки';

  @override
  String get printerWidthNarrow => '80 мм (42 символа)';

  @override
  String get printerAdvanced => 'Дополнительно';

  @override
  String get printerCodePage => 'Номер кодовой страницы (ESC t)';

  @override
  String get printerCodePageHint =>
      'Обычно 17. Если кириллица печатается неверно — найдите номер PC866 в инструкции принтера.';

  @override
  String get printerCancelKanji => 'Отключать китайский режим';

  @override
  String get printerCut => 'Отрезать бумагу';

  @override
  String get printerFeed => 'Пустых строк перед отрезом';

  @override
  String get receiptPreviewTitle => 'Вид чека';

  @override
  String get receiptPreviewHint =>
      'Принтер напечатает именно так: ширина, буквы и столбцы совпадают.';

  @override
  String get receiptPreviewSample => 'Образец (продаж ещё нет)';

  @override
  String get receiptPreviewLast => 'Последняя продажа';

  @override
  String get receiptSampleItem1 => 'Подсолнечное масло «Олтин» 5 л';

  @override
  String get receiptSampleItem2 => 'Яблоки красные';

  @override
  String get receiptSampleItem3 => 'Хлеб';

  @override
  String get receiptSampleStore => 'Название магазина';

  @override
  String get printerTestReceipt => 'Тестовый чек';

  @override
  String get receiptTin => 'ИНН';

  @override
  String get receiptPinfl => 'ПИНФЛ';

  @override
  String get storeSettingsTitle => 'Реквизиты и вид чека';

  @override
  String get storeSettingsHint =>
      'Одинаково на всех кассах. Чек справа — именно так напечатает принтер.';

  @override
  String get storeName => 'Название магазина';

  @override
  String get storeLegalName => 'Юридическое название';

  @override
  String get storeLegalNameHint => 'Например: ООО «Барака» или ИП Каримов А.';

  @override
  String get storeTin => 'ИНН или ПИНФЛ';

  @override
  String get storeTinHint => '9 или 14 цифр. Печатается, только если указан.';

  @override
  String get storeTinError => 'Введите 9 цифр (ИНН) или 14 цифр (ПИНФЛ)';

  @override
  String get storeAddress => 'Адрес';

  @override
  String get storePhone => 'Телефон';

  @override
  String get storeHeader => 'Заголовок чека';

  @override
  String get storeHeaderHint => 'Например: Ежедневно 08:00–23:00';

  @override
  String get storeFooter => 'Текст внизу';

  @override
  String get storeFooterHint => 'Если пусто: Спасибо за покупку!';

  @override
  String get storeLogo => 'Логотип';

  @override
  String get storeLogoHint => 'PNG или JPG. На чеке будет чёрно-белым.';

  @override
  String get storeLogoPick => 'Выбрать логотип';

  @override
  String get storeLogoReplace => 'Заменить';

  @override
  String get storeLogoRemove => 'Удалить';

  @override
  String get storeLogoError =>
      'Не удалось прочитать картинку. Выберите другой PNG или JPG.';

  @override
  String get storeLogoTooLarge => 'Логотип слишком сложный. Выберите проще.';

  @override
  String get storeShowTitle => 'Показывать на чеке';

  @override
  String get storeShowCashier => 'Имя кассира';

  @override
  String get storeShowBarcode => 'Штрихкод чека (для возврата)';

  @override
  String get storeSave => 'Сохранить реквизиты';

  @override
  String get storeSaved =>
      'Сохранено — на других кассах обновится после синхронизации';

  @override
  String get storeNeedsApproval =>
      'Реквизиты чека меняет менеджер или владелец';

  @override
  String get storeUnavailable =>
      'Изменение реквизитов заработает после обновления сервера (подключитесь к интернету).';

  @override
  String get productImage => 'Фото';

  @override
  String get productImageHint =>
      'Видно в списке и в поиске на кассе. Сохраняется и без интернета.';

  @override
  String get productImageAdd => 'Добавить фото';

  @override
  String get productImageReplace => 'Заменить';

  @override
  String get productImageRemove => 'Удалить';

  @override
  String get productImageNotUploaded => 'Ещё не загружено';

  @override
  String get productImageUnsupported =>
      'Не удалось прочитать фото. Выберите JPG или PNG.';

  @override
  String get productImageTooLarge => 'Фото слишком большое (больше 20 МБ).';

  @override
  String productSameName(String name) {
    return 'Товар «$name» уже есть. Это он?';
  }

  @override
  String get productGone => 'Товар не найден — возможно, он удалён';

  @override
  String get productSaveFailed => 'Не удалось сохранить. Попробуйте ещё раз.';

  @override
  String get actionFailed => 'Не удалось выполнить. Попробуйте ещё раз.';

  @override
  String get payDebtNeedsShift =>
      'Чтобы принять наличные, откройте смену (для верного учёта кассы)';

  @override
  String get inventoryDeleteTitle => 'Удалить пересчёт?';

  @override
  String get receiptDebtNow => 'Текущий долг';

  @override
  String get receiptNotFiscal => 'Не фискальный чек';

  @override
  String get receiptThanks => 'Спасибо за покупку!';

  @override
  String get receiptCopy => 'КОПИЯ';

  @override
  String get statusPrinterChecking => 'Проверка принтера';

  @override
  String get printerTestTitle => 'ТЕСТОВЫЙ ЧЕК';

  @override
  String get printerTestSample =>
      'Lotin: O\'zbekiston. Kirill: Ўзбекистон, Россия';

  @override
  String get printerTestOk => 'Если текст читается, принтер готов';

  @override
  String get settingsPrinter => 'Принтер чеков';

  @override
  String get settingsPrinterHelper => 'Термопринтер (ESC/POS), 58 или 80 мм';

  @override
  String get printerConnection => 'Подключение';

  @override
  String get printerNone => 'Без принтера';

  @override
  String get printerNetwork => 'Сеть (IP)';

  @override
  String get printerWindows => 'Принтер компьютера';

  @override
  String get printerAddress => 'Адрес принтера';

  @override
  String get printerAddressHint => 'Например: 192.168.1.50';

  @override
  String get printerNoSystemPrinters => 'Принтеры не найдены';

  @override
  String get printerWidth => 'Ширина бумаги';

  @override
  String printerWidthMm(int mm) {
    return '$mm мм';
  }

  @override
  String get printerEncoding => 'Кодировка';

  @override
  String get printerEncodingCp866 => 'Кириллица (CP866)';

  @override
  String get printerEncodingUtf8 => 'UTF-8';

  @override
  String get printerAutoPrint => 'Печатать чек после продажи';

  @override
  String get printerCopies => 'Количество копий';

  @override
  String get printerDrawer => 'Открывать денежный ящик при оплате наличными';

  @override
  String get printerTest => 'Тестовый чек';

  @override
  String get printerOpenDrawer => 'Открыть денежный ящик';

  @override
  String get printerSent => 'Отправлено на принтер';

  @override
  String get printerFailed =>
      'Не удалось подключиться к принтеру. Проверьте кабель или адрес';

  @override
  String get printerNotConfigured => 'Сначала настройте принтер';

  @override
  String get posReceiptFailed => 'Чек не напечатан';

  @override
  String get posReprint => 'Напечатать снова';

  @override
  String get posLastReceipt => 'Последний чек';

  @override
  String posSaleDoneReceiptFailed(String done) {
    return '$done. Чек не напечатан';
  }

  @override
  String get refundTitle => 'Возврат';

  @override
  String get refundFindHint =>
      'Введите номер чека или отсканируйте штрихкод на чеке';

  @override
  String get refundNumber => 'Номер чека';

  @override
  String get refundFind => 'Найти';

  @override
  String get refundRecent => 'Последние чеки';

  @override
  String get refundNotFound => 'Чек не найден';

  @override
  String get refundNoSales => 'Продаж пока нет';

  @override
  String get refundStatusPartial => 'Частично возвращён';

  @override
  String get refundStatusFull => 'Возвращён';

  @override
  String get refundOtherCheck => 'Другой чек';

  @override
  String refundSold(String qty) {
    return 'Продано: $qty';
  }

  @override
  String refundLeft(String qty) {
    return 'Можно вернуть: $qty';
  }

  @override
  String get refundAll => 'Всё';

  @override
  String get refundFullyRefunded => 'Этот чек уже полностью возвращён';

  @override
  String get refundReason => 'Причина';

  @override
  String get refundReasonDefective => 'Брак';

  @override
  String get refundReasonExpired => 'Просрочен';

  @override
  String get refundReasonChangedMind => 'Клиент передумал';

  @override
  String get refundReasonMistake => 'Ошибка кассира';

  @override
  String get refundReasonOther => 'Другая причина';

  @override
  String get refundMethod => 'Как вернуть деньги';

  @override
  String get refundMethodCash => 'Наличными';

  @override
  String get refundMethodDebt => 'Списать с долга';

  @override
  String get refundTotal => 'К возврату';

  @override
  String get refundConfirm => 'Вернуть';

  @override
  String get refundNeedsApproval =>
      'Возврат должен подтвердить менеджер или владелец';

  @override
  String get refundChooseItems => 'Выберите товар для возврата';

  @override
  String get refundChooseReason => 'Укажите причину';

  @override
  String refundDoneCash(String amount) {
    return 'Возврат оформлен · Выдайте клиенту $amount';
  }

  @override
  String refundDoneDebt(String amount) {
    return 'Возврат оформлен · Долг уменьшен на $amount';
  }

  @override
  String get refundFailed => 'Не удалось сохранить возврат. Попробуйте ещё раз';

  @override
  String get refundNumberHint => 'Например: D1-000123';

  @override
  String get cashTitle => 'Деньги в кассе';

  @override
  String get cashIn => 'Внести';

  @override
  String get cashOut => 'Изъять';

  @override
  String get cashReason => 'Причина';

  @override
  String get cashReasonCollection => 'Инкассация';

  @override
  String get cashReasonExpense => 'Расход';

  @override
  String get cashReasonChange => 'Размен';

  @override
  String get cashReasonOther => 'Другая причина';

  @override
  String cashAvailable(String amount) {
    return 'В кассе: $amount';
  }

  @override
  String cashExceeds(String amount) {
    return 'В кассе только $amount';
  }

  @override
  String get cashEnterAmount => 'Введите сумму';

  @override
  String get cashChooseReason => 'Укажите причину';

  @override
  String cashDoneIn(String amount) {
    return 'В кассу внесено $amount';
  }

  @override
  String cashDoneOut(String amount) {
    return 'Из кассы изъято $amount';
  }

  @override
  String get cashMovementsTitle => 'Внесения и изъятия';

  @override
  String get cashNoMovements => 'В этой смене не было внесений и изъятий';

  @override
  String get cashFailed => 'Не удалось сохранить. Попробуйте ещё раз';

  @override
  String get receiptShiftOpened => 'Открыта';

  @override
  String get receiptShiftClosed => 'Закрыта';

  @override
  String get receiptPrintedAt => 'Напечатано';

  @override
  String get productsSearchHint => 'Название, штрихкод или PLU';

  @override
  String get productsAdd => 'Добавить товар';

  @override
  String get productsAll => 'Все';

  @override
  String get productsFilterLow => 'Заканчивается';

  @override
  String get productsFilterNegative => 'Отрицательный остаток';

  @override
  String get productsFilterInactive => 'Неактивные';

  @override
  String get productsEmptyTitle => 'Товаров пока нет';

  @override
  String get productsEmptyMessage => 'Добавьте товар или отсканируйте штрихкод';

  @override
  String get productsNotFound => 'Ничего не найдено';

  @override
  String get productsColName => 'Название';

  @override
  String get productsColBarcode => 'Штрихкод';

  @override
  String get productsColCategory => 'Категория';

  @override
  String get productsColPrice => 'Цена';

  @override
  String get productsColCost => 'Себестоимость';

  @override
  String get productsColStock => 'Остаток';

  @override
  String get productsBadgeLow => 'Мало';

  @override
  String get productsBadgeNegative => 'Минус';

  @override
  String get productsBadgeInactive => 'Неактивен';

  @override
  String get productNew => 'Новый товар';

  @override
  String get productName => 'Название';

  @override
  String get productCategory => 'Категория';

  @override
  String get productNoCategory => 'Без категории';

  @override
  String get productUnit => 'Единица';

  @override
  String get productSellPrice => 'Цена продажи, сум';

  @override
  String get productCostPrice => 'Себестоимость, сум';

  @override
  String productMarkup(String percent) {
    return 'Наценка: $percent';
  }

  @override
  String get productWeighted => 'Весовой товар';

  @override
  String get productPlu => 'PLU — код весов (5 цифр)';

  @override
  String productMinStock(String unit) {
    return 'Минимальный остаток, $unit';
  }

  @override
  String get productIkpu => 'ИКПУ (необязательно, 17 цифр)';

  @override
  String get productQuickButton => 'Быстрая кнопка на кассе';

  @override
  String get productBarcodes => 'Штрихкоды';

  @override
  String get productBarcodeAdd => 'Введите или отсканируйте код';

  @override
  String get productBarcodePrimary => 'Основной';

  @override
  String get productBarcodeRemove => 'Удалить код';

  @override
  String get productDeactivate => 'Сделать неактивным';

  @override
  String get productActivate => 'Активировать';

  @override
  String get productSaved => 'Сохранено';

  @override
  String get productNeedsApproval =>
      'Изменение товара должен подтвердить менеджер или владелец';

  @override
  String get productPriceHistory => 'История цен';

  @override
  String get productPriceHistoryOffline => 'Для истории цен нужен интернет';

  @override
  String get productPriceHistoryEmpty => 'Цена ещё не менялась';

  @override
  String productPriceHistoryRow(String sell, String cost) {
    return 'Цена $sell · Себестоимость $cost';
  }

  @override
  String productStockNow(String qty) {
    return 'Остаток: $qty';
  }

  @override
  String productErrNameTooLong(int max) {
    return 'Название — не длиннее $max символов';
  }

  @override
  String productErrTooManyBarcodes(int max) {
    return 'Не больше $max штрихкодов';
  }

  @override
  String get productErrPrice => 'Цена должна быть больше 0';

  @override
  String productErrBarcodeFormat(String code) {
    return '«$code» — неверный штрихкод';
  }

  @override
  String productErrBarcodeCheck(String code) {
    return '«$code» — код считан с ошибкой, отсканируйте снова';
  }

  @override
  String productErrBarcodeRepeated(String code) {
    return '«$code» указан дважды';
  }

  @override
  String productErrBarcodeTaken(String code, String product) {
    return '«$code» уже у товара «$product»';
  }

  @override
  String get productErrPluFormat => 'PLU должен состоять из 5 цифр';

  @override
  String productErrPluTaken(String product) {
    return 'Этот PLU уже у товара «$product»';
  }

  @override
  String get productErrWeightedUnit =>
      'Для весового товара выберите дробную единицу, например кг';

  @override
  String get productErrIkpu => 'ИКПУ должен состоять из 17 цифр';

  @override
  String get productErrQty =>
      'Введите количество правильно (например, 5 или 0,5)';

  @override
  String get importTitle => 'Загрузка из Excel';

  @override
  String get importIntro =>
      'Выберите файл Excel (.xlsx) или CSV. Первая строка — названия столбцов. Существующие товары обновляются по штрихкоду.';

  @override
  String get importPick => 'Выбрать файл';

  @override
  String get importTemplate => 'Скачать шаблон';

  @override
  String get importTemplateSaved => 'Шаблон сохранён';

  @override
  String get importOffline => 'Для импорта нужен интернет';

  @override
  String get importFailed =>
      'Не удалось прочитать файл: .xlsx или .csv, до 10 МБ';

  @override
  String importRows(String file, int count) {
    return '$file · строк: $count';
  }

  @override
  String get importMapTitle => 'Сопоставьте столбцы';

  @override
  String get importNoColumn => '— нет —';

  @override
  String get importChooseColumn => 'Выберите столбец';

  @override
  String get importRequiredMissing => 'Выберите столбцы названия и цены';

  @override
  String get importCheck => 'Проверить';

  @override
  String importSummary(int creates, int updates, int errors) {
    return 'Новых: $creates · Обновится: $updates · Ошибок: $errors';
  }

  @override
  String importErrorRow(int row, String field, String reason) {
    return 'Строка $row · $field: $reason';
  }

  @override
  String importMoreErrors(int count) {
    return 'Ещё ошибок: $count';
  }

  @override
  String get importApply => 'Импортировать';

  @override
  String get importBack => 'Назад';

  @override
  String get importNeedsApproval =>
      'Импорт должен подтвердить менеджер или владелец';

  @override
  String importDone(int created, int updated, int skipped) {
    return 'Добавлено: $created · Обновлено: $updated · Пропущено: $skipped';
  }

  @override
  String get importClose => 'Готово';

  @override
  String get importErrRequired => 'не заполнено';

  @override
  String get importErrNumber => 'не число';

  @override
  String get importErrPositive => 'должно быть больше 0';

  @override
  String get importErrBarcode => 'неверный штрихкод';

  @override
  String get importErrCheckDigit => 'неверная контрольная цифра';

  @override
  String get importErrDuplicate => 'повторяется в файле';

  @override
  String get importErrUnit => 'неизвестная единица';

  @override
  String get importErrTooLong => 'слишком длинно';

  @override
  String get importErrWeighted => 'весовому товару нужна дробная единица';

  @override
  String get receivingNew => 'Новый приход';

  @override
  String get receivingEmptyTitle => 'Приходов пока нет';

  @override
  String get receivingEmptyMessage => 'Принимайте товар от поставщика сканером';

  @override
  String get receivingDraft => 'Черновик';

  @override
  String get receivingPostedBadge => 'Проведён';

  @override
  String receivingLines(int count) {
    return 'Строк: $count';
  }

  @override
  String receivingTitle(String date) {
    return 'Приход · $date';
  }

  @override
  String get receivingBack => 'Приходы';

  @override
  String get receivingSupplier => 'Поставщик';

  @override
  String get receivingNoSupplier => 'Без поставщика';

  @override
  String get receivingNewSupplier => 'Новый поставщик';

  @override
  String get receivingNote => 'Комментарий';

  @override
  String get receivingSearchHint => 'Название или штрихкод (сканируйте)';

  @override
  String get receivingEmptyLines => 'Отсканируйте или найдите товар';

  @override
  String get receivingCost => 'Себестоимость';

  @override
  String get receivingSell => 'Цена продажи';

  @override
  String receivingTotal(String amount) {
    return 'Итого себестоимость: $amount';
  }

  @override
  String get receivingSellBelowCost => 'Цена ниже себестоимости';

  @override
  String get receivingPost => 'Провести';

  @override
  String get receivingStateCorrected => 'Исправлен';

  @override
  String get receivingStateCancelled => 'Отменён';

  @override
  String get receivingCorrectionBadge => 'Исправление';

  @override
  String get receivingCorrectionDraft => 'Черновик исправления';

  @override
  String get receivingEdit => 'Изменить';

  @override
  String get receivingCancelReceipt => 'Отменить приход';

  @override
  String get receivingEditNeedsApproval =>
      'Изменить приход может менеджер или владелец';

  @override
  String get receivingCorrectionBanner =>
      'Приход исправляется. При сохранении старый приход отменяется и действует эта версия — остаток изменится на разницу.';

  @override
  String get receivingCorrectedBanner =>
      'Этот приход исправлен — действует новая версия.';

  @override
  String get receivingOpenNewVersion => 'Открыть новую версию';

  @override
  String get receivingCancelledBanner =>
      'Этот приход отменён — его влияние на остаток снято.';

  @override
  String get receivingDraftExistsBanner =>
      'У этого прихода есть несохранённое исправление.';

  @override
  String get receivingContinueCorrection => 'Продолжить';

  @override
  String get receivingSaveCorrection => 'Сохранить исправление';

  @override
  String get receivingDiscardCorrection => 'Отказаться от исправления';

  @override
  String get receivingConfirmCorrectionTitle => 'Сохранить исправление?';

  @override
  String get receivingConfirmCorrectionMessage =>
      'Остаток изменится так. Старый приход останется в истории.';

  @override
  String get receivingNoChanges =>
      'Количество не изменилось — обновятся только цены или комментарий.';

  @override
  String receivingNegativeStock(String name, String qty) {
    return 'Остаток станет отрицательным: $name ($qty)';
  }

  @override
  String get receivingCancelTitle => 'Отменить приход?';

  @override
  String get receivingCancelMessage =>
      'Товары прихода будут списаны с остатка. Документ останется в истории как «Отменён», цены не изменятся.';

  @override
  String get receivingCancelledToast => 'Приход отменён';

  @override
  String get receivingCorrectedToast => 'Приход исправлен';

  @override
  String get receivingDeleteDraftTitle => 'Удалить черновик?';

  @override
  String get receivingDeleteDraftMessage =>
      'Строки черновика будут удалены. Остаток не изменится.';

  @override
  String get receivingDiscardCorrectionMessage =>
      'Исправление не сохранится, исходный приход останется без изменений.';

  @override
  String get receivingNotEditable =>
      'Этот приход нельзя изменить — он уже исправлен или отменён.';

  @override
  String get receivingCorrectionEmpty =>
      'В исправлении нет товаров. Чтобы убрать приход целиком, используйте «Отменить приход».';

  @override
  String get receivingCorrectionUnavailable =>
      'Изменение прихода заработает после обновления сервера (подключитесь к интернету).';

  @override
  String get actionKeep => 'Назад';

  @override
  String get customerOpeningSection => 'Начальный баланс';

  @override
  String get customerOpeningNone => 'Нет';

  @override
  String get customerOpeningDebt => 'Долг клиента';

  @override
  String get customerOpeningCredit => 'Аванс клиента';

  @override
  String get customerOpeningNoneHint =>
      'Новый клиент — нет ни долга, ни аванса.';

  @override
  String get customerOpeningDebtHint =>
      'Клиент должен магазину эту сумму (например, из старой тетради).';

  @override
  String get customerOpeningCreditHint =>
      'Магазин должен клиенту эту сумму: клиент заплатил заранее. Следующие покупки в долг вычитаются из неё.';

  @override
  String customerOpeningAmount(String currency) {
    return 'Сумма, $currency';
  }

  @override
  String get customerOpeningDate => 'На какую дату';

  @override
  String get customerOpeningAmountRequired => 'Введите сумму (больше 0)';

  @override
  String get customerOpeningNeedsApproval =>
      'Аванс клиента вносит менеджер или владелец';

  @override
  String get debtOpeningDebt => 'Начальный долг';

  @override
  String get debtOpeningCredit => 'Начальный аванс';

  @override
  String get customerCredit => 'Аванс клиента';

  @override
  String customerCreditShort(String amount) {
    return 'Аванс: $amount';
  }

  @override
  String fieldOptional(String label) {
    return '$label (необязательно)';
  }

  @override
  String get receivingDelete => 'Удалить черновик';

  @override
  String get receivingRemoveLine => 'Удалить строку';

  @override
  String get receivingPostedToast => 'Приход проведён: остатки увеличены';

  @override
  String get receivingNeedsApproval =>
      'Приход должен подтвердить менеджер или владелец';

  @override
  String get receivingEmptyPost => 'Нельзя провести пустой приход';

  @override
  String get inventoryTitle => 'Инвентаризация';

  @override
  String get inventoryNew => 'Новая инвентаризация';

  @override
  String get inventoryEmptyTitle => 'Инвентаризаций пока нет';

  @override
  String get inventoryEmptyMessage =>
      'Пересчитайте товар сканером — остатки станут равны фактическим';

  @override
  String get inventoryScopeTitle => 'Что считаем?';

  @override
  String get inventoryScopeAll => 'Все товары';

  @override
  String inventoryCount(String date) {
    return 'Инвентаризация · $date';
  }

  @override
  String inventorySummary(int counted, int left, int surplus, int shortage) {
    return 'Посчитано: $counted · Не посчитано: $left · Излишек: $surplus · Недостача: $shortage';
  }

  @override
  String inventorySystem(String qty) {
    return 'В системе: $qty';
  }

  @override
  String inventoryDiff(String qty) {
    return 'Разница: $qty';
  }

  @override
  String inventoryUncounted(int count) {
    return 'Не посчитаны ($count)';
  }

  @override
  String get inventoryUncountedNote =>
      'Остатки непосчитанных товаров не меняются. Нажмите, чтобы добавить.';

  @override
  String get inventoryEmptyLines => 'Сканируйте товар: каждый скан — +1';

  @override
  String get inventoryPost => 'Провести';

  @override
  String get inventoryDelete => 'Удалить черновик';

  @override
  String get inventoryPostedToast =>
      'Инвентаризация проведена: остатки равны посчитанным';

  @override
  String get inventoryNeedsApproval =>
      'Инвентаризацию должен подтвердить менеджер или владелец';

  @override
  String get inventoryEmptyPost => 'Ничего не посчитано';

  @override
  String get inventoryBack => 'Инвентаризации';

  @override
  String get inventoryNotFound => 'Код не найден — сначала добавьте товар';

  @override
  String inventoryCountedUnit(String unit) {
    return 'Посчитано, $unit';
  }

  @override
  String receivingQtyUnit(String unit) {
    return 'Кол-во, $unit';
  }

  @override
  String get productStockHistory => 'История движения';

  @override
  String get stockHistoryOffline => 'Для полной истории нужен интернет';

  @override
  String get stockHistoryEmpty => 'Движений пока нет';

  @override
  String get stockHistoryPending => 'Не отправлено';

  @override
  String get moveReceipt => 'Приход';

  @override
  String get moveSale => 'Продажа';

  @override
  String get moveRefund => 'Возврат';

  @override
  String get moveAdjustment => 'Корректировка';

  @override
  String get moveInventory => 'Инвентаризация';

  @override
  String get productsOrderList => 'Список заказа';

  @override
  String get orderListSaved => 'Список заказа сохранён';

  @override
  String get orderListEmpty => 'Нет заканчивающихся товаров';

  @override
  String get orderFileName => 'zakaz';

  @override
  String get orderColName => 'Название';

  @override
  String get orderColBarcode => 'Штрихкод';

  @override
  String get orderColStock => 'Остаток';

  @override
  String get orderColMin => 'Мин. остаток';

  @override
  String get orderColOrder => 'Заказать';

  @override
  String get orderColCost => 'Себестоимость';

  @override
  String get orderColSum => 'Сумма';

  @override
  String get customersSearchHint => 'Имя или телефон';

  @override
  String get customersAdd => 'Новый клиент';

  @override
  String get customersDebtorsOnly => 'С долгом';

  @override
  String get customersAll => 'Все';

  @override
  String customersTotalDebt(String amount) {
    return 'Общий долг: $amount';
  }

  @override
  String get customersEmptyTitle => 'Клиентов пока нет';

  @override
  String get customersEmptyMessage =>
      'Клиент добавляется при продаже в долг или здесь';

  @override
  String get customersNotFound => 'Никого не найдено';

  @override
  String get customerDebt => 'Долг';

  @override
  String get customerNoDebt => 'Долга нет';

  @override
  String customerLimit(String amount) {
    return 'Лимит: $amount';
  }

  @override
  String get customerNoLimit => 'Лимит: без ограничений';

  @override
  String get customerPay => 'Погасить долг';

  @override
  String get customerEdit => 'Изменить';

  @override
  String get customerHistory => 'История долга';

  @override
  String get customerPurchases => 'Покупки (на этой кассе)';

  @override
  String get customerHistoryEmpty => 'Записей пока нет';

  @override
  String get debtSale => 'Продажа в долг';

  @override
  String get debtPayment => 'Оплата';

  @override
  String get debtRefund => 'Возврат';

  @override
  String get debtAdjustment => 'Корректировка';

  @override
  String get payDebtTitle => 'Погашение долга';

  @override
  String get payDebtFull => 'Полностью';

  @override
  String get payDebtCash => 'Наличные';

  @override
  String get payDebtCard => 'Карта';

  @override
  String get payDebtConfirm => 'Принять';

  @override
  String payDebtTooMuch(String amount) {
    return 'Не больше долга: $amount';
  }

  @override
  String payDebtDone(String amount, String left) {
    return 'Принято $amount · Остаток долга: $left';
  }

  @override
  String get customerNote => 'Комментарий';

  @override
  String get customerLimitField => 'Лимит долга, сум (пусто — без лимита)';

  @override
  String get customerLimitNeedsApproval => 'Лимит меняет менеджер или владелец';

  @override
  String get customerSaved => 'Сохранено';

  @override
  String get customerBack => 'Клиенты';

  @override
  String get reportsToday => 'Сегодня';

  @override
  String get reportsYesterday => 'Вчера';

  @override
  String get reportsLast7Days => '7 дней';

  @override
  String get reportsThisMonth => 'Этот месяц';

  @override
  String get reportsLastMonth => 'Прошлый месяц';

  @override
  String reportsPeriodRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String get reportsRevenue => 'Выручка';

  @override
  String get reportsProfit => 'Прибыль';

  @override
  String get reportsChecks => 'Чеки';

  @override
  String get reportsAverageCheck => 'Средний чек';

  @override
  String reportsChangeUp(String percent) {
    return '↑ $percent';
  }

  @override
  String reportsChangeDown(String percent) {
    return '↓ $percent';
  }

  @override
  String reportsPrevious(String amount) {
    return 'Ранее: $amount';
  }

  @override
  String get reportsByHour => 'По часам';

  @override
  String get reportsByDay => 'По дням';

  @override
  String get reportsPayments => 'Способы оплаты';

  @override
  String get reportsTopProducts => 'Топ товаров';

  @override
  String get reportsCashiers => 'Кассиры';

  @override
  String reportsCashierRefunds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count возвратов',
      few: '$count возврата',
      one: '$count возврат',
    );
    return '$_temp0';
  }

  @override
  String get reportsDebts => 'Долги';

  @override
  String reportsDebtors(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count должников',
      few: '$count должника',
      one: '$count должник',
    );
    return '$_temp0';
  }

  @override
  String get reportsStock => 'Склад';

  @override
  String get reportsStockValue => 'Стоимость склада (себестоимость)';

  @override
  String get reportsLowStock => 'Заканчиваются';

  @override
  String get reportsNegativeStock => 'Отрицательный остаток';

  @override
  String reportsStockLine(String qty, String min) {
    return '$qty · минимум $min';
  }

  @override
  String get reportsNothing => 'Нет';

  @override
  String get reportsNoSales => 'За этот период продаж нет';

  @override
  String get reportsLocalOnly => 'Нет интернета — только данные этой кассы';

  @override
  String get reportsNoAccessTitle => 'Отчёты — для владельца и менеджера';

  @override
  String get reportsNoAccessMessage =>
      'Для просмотра менеджер должен ввести PIN';

  @override
  String get reportsUnlock => 'PIN менеджера';

  @override
  String get reportsUnlockReason => 'Просмотр отчётов';

  @override
  String get reportsLoadFailed => 'Не удалось открыть отчёт';

  @override
  String reportsCashierLine(String checks, String refunds) {
    return '$checks · $refunds';
  }

  @override
  String subTrial(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Пробный период: ещё $days дней',
      few: 'Пробный период: ещё $days дня',
      one: 'Пробный период: ещё $days день',
    );
    return '$_temp0';
  }

  @override
  String subExpiring(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Подписка закончится через $days дней — не забудьте оплатить',
      few: 'Подписка закончится через $days дня — не забудьте оплатить',
      one: 'Подписка заканчивается сегодня — не забудьте оплатить',
    );
    return '$_temp0';
  }

  @override
  String subGrace(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other:
          'Срок оплаты прошёл — оплатите в течение $days дней, иначе продажи остановятся',
      few:
          'Срок оплаты прошёл — оплатите в течение $days дней, иначе продажи остановятся',
      one: 'Срок оплаты прошёл — оплатите сегодня, иначе продажи остановятся',
    );
    return '$_temp0';
  }

  @override
  String get subGraceUnknown =>
      'Срок оплаты прошёл — оплатите и подключитесь к интернету';

  @override
  String subContact(String phone) {
    return 'Связь: $phone';
  }

  @override
  String get subContactAdmin => 'Свяжитесь с администратором';

  @override
  String get salesHelpReadonly =>
      'Просмотр, отчёты и синхронизация работают. Чтобы возобновить продажи, оплатите подписку.';

  @override
  String get salesHelpBlocked => 'Просмотр, отчёты и синхронизация работают.';

  @override
  String get salesHelpOffline =>
      'Подключитесь к интернету — после синхронизации продажи продолжатся. Все данные сохранены.';

  @override
  String salesBlockedAction(String reason) {
    return 'Сейчас нельзя провести: $reason';
  }

  @override
  String statusUpdate(String version) {
    return 'Новая версия $version';
  }

  @override
  String get settingsAbout => 'О приложении';

  @override
  String settingsVersion(String version) {
    return 'Версия: $version';
  }

  @override
  String settingsUpdateAvailable(String version) {
    return 'Доступна новая версия: $version';
  }

  @override
  String settingsUpdateDownload(String url) {
    return 'Скачать: $url';
  }

  @override
  String get settingsUpdateAskAdmin =>
      'Для установки свяжитесь с администратором';

  @override
  String get settingsUpToDate => 'Установлена последняя версия';
}
