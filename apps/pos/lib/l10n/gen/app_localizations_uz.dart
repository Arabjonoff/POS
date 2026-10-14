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

  @override
  String get setupTitle => 'Kassani ulash';

  @override
  String get setupSubtitle =>
      'Do\'kon egasining telefon raqami va paroli bilan kiring';

  @override
  String get setupPhoneLabel => 'Telefon raqami';

  @override
  String get setupPhoneHint => '90 123 45 67';

  @override
  String get setupPasswordLabel => 'Parol';

  @override
  String get setupNext => 'Davom etish';

  @override
  String get setupDeviceNameTitle => 'Bu kassaga nom bering';

  @override
  String get setupDeviceNameLabel => 'Kassa nomi';

  @override
  String get setupDeviceNameHelper => 'Masalan: Kassa 1, Peshtaxta';

  @override
  String get setupDeviceNameDefault => 'Kassa 1';

  @override
  String get setupConnect => 'Ulash';

  @override
  String get setupSyncTitle => 'Ma\'lumotlar yuklanmoqda';

  @override
  String setupSyncProgress(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ta yozuv yuklandi',
      zero: 'Tayyorlanmoqda…',
    );
    return '$_temp0';
  }

  @override
  String get setupSyncFailed =>
      'Ma\'lumotlarni yuklab bo\'lmadi. Internetni tekshiring.';

  @override
  String get setupErrorInvalidCredentials =>
      'Telefon raqami yoki parol noto\'g\'ri';

  @override
  String get setupErrorNotOwner => 'Kassani faqat do\'kon egasi ulay oladi';

  @override
  String get setupErrorDeviceLimit =>
      'Tarifingizdagi kassalar soni tugagan. Administratorga murojaat qiling.';

  @override
  String get setupErrorNoSubscription =>
      'Obuna topilmadi. Administratorga murojaat qiling.';

  @override
  String get setupErrorDeviceBlocked =>
      'Bu kassa bloklangan. Administratorga murojaat qiling.';

  @override
  String get setupErrorNetwork =>
      'Internet yo\'q yoki server javob bermayapti. Qayta urinib ko\'ring.';

  @override
  String get setupErrorUnknown => 'Nimadir xato ketdi. Qayta urinib ko\'ring.';

  @override
  String get fieldRequired => 'To\'ldiring';

  @override
  String get lockTitle => 'Kim ishlaydi?';

  @override
  String get lockEnterPin => 'PIN kodni kiriting';

  @override
  String get lockSubmit => 'Kirish';

  @override
  String get lockBack => 'Boshqa xodim';

  @override
  String lockWrongPin(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'PIN noto\'g\'ri. Yana $count ta urinish qoldi',
      zero: 'PIN noto\'g\'ri',
    );
    return '$_temp0';
  }

  @override
  String lockLockedOut(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'Juda ko\'p xato. $seconds soniyadan keyin urinib ko\'ring',
    );
    return '$_temp0';
  }

  @override
  String get lockNoPin => 'PIN o\'rnatilmagan';

  @override
  String get lockNoStaffTitle => 'Xodimlar topilmadi';

  @override
  String get lockNoStaffMessage =>
      'Ma\'lumotlar hali yuklanmagan. Internetni tekshirib, qayta urinib ko\'ring.';

  @override
  String get roleOwner => 'Ega';

  @override
  String get roleManager => 'Menejer';

  @override
  String get roleCashier => 'Kassir';

  @override
  String get actionLock => 'Qulflash';

  @override
  String get settingsAutoLock => 'Avtomatik qulflash';

  @override
  String get settingsAutoLockHelper =>
      'Kassada harakat bo\'lmasa, ekran qulflanadi';

  @override
  String get settingsAutoLockOff => 'O\'chiq';

  @override
  String settingsAutoLockMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes daqiqadan keyin',
    );
    return '$_temp0';
  }

  @override
  String get statusSalesReadonly =>
      'Obuna muddati tugagan — savdo to\'xtatilgan';

  @override
  String get statusSalesBlocked => 'Do\'kon bloklangan — savdo to\'xtatilgan';

  @override
  String get statusSalesOffline =>
      'Uzoq vaqt internet yo\'q — savdo to\'xtatilgan';

  @override
  String get statusDeviceBlocked => 'Kassa bloklangan';

  @override
  String get statusClockSkew => 'Kompyuter soati noto\'g\'ri';

  @override
  String statusRejected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ta yozuv qabul qilinmadi',
    );
    return '$_temp0';
  }

  @override
  String get settingsScanner => 'Shtrix-kod skaneri';

  @override
  String get settingsScannerSound => 'Skanerlashda ovoz';

  @override
  String get settingsScannerSpeed => 'Skaner tezligi';

  @override
  String get settingsScannerSpeedNormal => 'Oddiy skaner';

  @override
  String get settingsScannerSpeedSlow => 'Sekin (Bluetooth) skaner';

  @override
  String get settingsScannerSpeedVerySlow => 'Juda sekin skaner';

  @override
  String get scanCamera => 'Kamera bilan skanerlash';

  @override
  String get scanCameraHint => 'Shtrix-kodni ramkaga to\'g\'rilang';

  @override
  String get scanCameraDenied =>
      'Kameraga ruxsat berilmagan. Telefon sozlamalaridan ruxsat bering.';

  @override
  String get scanInvalidCode => 'Kod noto\'g\'ri o\'qildi, qayta skanerlang';

  @override
  String get shiftOpenTitle => 'Smenani oching';

  @override
  String get shiftOpenMessage =>
      'Savdoni boshlash uchun kassadagi naqd pulni kiriting';

  @override
  String get shiftOpeningCash => 'Kassadagi naqd pul';

  @override
  String get shiftOpenAction => 'Smenani ochish';

  @override
  String get shiftTitle => 'Smena';

  @override
  String shiftOpenedInfo(String time, String name) {
    return '$time da $name ochgan';
  }

  @override
  String get shiftXReport => 'X hisobot';

  @override
  String get shiftZReport => 'Z hisobot';

  @override
  String get reportSales => 'Savdolar';

  @override
  String reportChecks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ta chek',
    );
    return '$_temp0';
  }

  @override
  String get reportCash => 'Naqd';

  @override
  String get reportCard => 'Karta';

  @override
  String get reportDebt => 'Nasiya';

  @override
  String get reportRefunds => 'Qaytarishlar';

  @override
  String get reportCashMovements => 'Kassa puli';

  @override
  String get reportCashIn => 'Kiritilgan';

  @override
  String get reportCashOut => 'Olingan';

  @override
  String get reportDebtPayments => 'Qarz to\'lovlari';

  @override
  String get reportCashBalance => 'Naqd hisobi';

  @override
  String get reportOpeningCash => 'Boshlang\'ich naqd';

  @override
  String get reportExpectedCash => 'Kassada bo\'lishi kerak';

  @override
  String get reportCountedCash => 'Sanalgan naqd';

  @override
  String get reportSurplus => 'Ortiqcha';

  @override
  String get reportShortage => 'Kam';

  @override
  String get reportNoDifference => 'Farq yo\'q';

  @override
  String get shiftCloseAction => 'Smenani yopish';

  @override
  String get shiftCloseTitle => 'Kassadagi pulni sanang';

  @override
  String get shiftCloseConfirm => 'Yopish';

  @override
  String get shiftClosedTitle => 'Smena yopildi';

  @override
  String get shiftBackToPos => 'Kassaga qaytish';

  @override
  String get shiftPrintReport => 'Chek chiqarish';
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

  @override
  String get setupTitle => 'Кассани улаш';

  @override
  String get setupSubtitle =>
      'Дўкон эгасининг телефон рақами ва пароли билан киринг';

  @override
  String get setupPhoneLabel => 'Телефон рақами';

  @override
  String get setupPhoneHint => '90 123 45 67';

  @override
  String get setupPasswordLabel => 'Парол';

  @override
  String get setupNext => 'Давом этиш';

  @override
  String get setupDeviceNameTitle => 'Бу кассага ном беринг';

  @override
  String get setupDeviceNameLabel => 'Касса номи';

  @override
  String get setupDeviceNameHelper => 'Масалан: Касса 1, Пештахта';

  @override
  String get setupDeviceNameDefault => 'Касса 1';

  @override
  String get setupConnect => 'Улаш';

  @override
  String get setupSyncTitle => 'Маълумотлар юкланмоқда';

  @override
  String setupSyncProgress(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count та ёзув юкланди',
      zero: 'Тайёрланмоқда…',
    );
    return '$_temp0';
  }

  @override
  String get setupSyncFailed =>
      'Маълумотларни юклаб бўлмади. Интернетни текширинг.';

  @override
  String get setupErrorInvalidCredentials => 'Телефон рақами ёки парол нотўғри';

  @override
  String get setupErrorNotOwner => 'Кассани фақат дўкон эгаси улай олади';

  @override
  String get setupErrorDeviceLimit =>
      'Тарифингиздаги кассалар сони тугаган. Администраторга мурожаат қилинг.';

  @override
  String get setupErrorNoSubscription =>
      'Обуна топилмади. Администраторга мурожаат қилинг.';

  @override
  String get setupErrorDeviceBlocked =>
      'Бу касса блокланган. Администраторга мурожаат қилинг.';

  @override
  String get setupErrorNetwork =>
      'Интернет йўқ ёки сервер жавоб бермаяпти. Қайта уриниб кўринг.';

  @override
  String get setupErrorUnknown => 'Нимадир хато кетди. Қайта уриниб кўринг.';

  @override
  String get fieldRequired => 'Тўлдиринг';

  @override
  String get lockTitle => 'Ким ишлайди?';

  @override
  String get lockEnterPin => 'PIN кодни киритинг';

  @override
  String get lockSubmit => 'Кириш';

  @override
  String get lockBack => 'Бошқа ходим';

  @override
  String lockWrongPin(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'PIN нотўғри. Яна $count та уриниш қолди',
      zero: 'PIN нотўғри',
    );
    return '$_temp0';
  }

  @override
  String lockLockedOut(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'Жуда кўп хато. $seconds сониядан кейин уриниб кўринг',
    );
    return '$_temp0';
  }

  @override
  String get lockNoPin => 'PIN ўрнатилмаган';

  @override
  String get lockNoStaffTitle => 'Ходимлар топилмади';

  @override
  String get lockNoStaffMessage =>
      'Маълумотлар ҳали юкланмаган. Интернетни текшириб, қайта уриниб кўринг.';

  @override
  String get roleOwner => 'Эга';

  @override
  String get roleManager => 'Менежер';

  @override
  String get roleCashier => 'Кассир';

  @override
  String get actionLock => 'Қулфлаш';

  @override
  String get settingsAutoLock => 'Автоматик қулфлаш';

  @override
  String get settingsAutoLockHelper =>
      'Кассада ҳаракат бўлмаса, экран қулфланади';

  @override
  String get settingsAutoLockOff => 'Ўчиқ';

  @override
  String settingsAutoLockMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes дақиқадан кейин',
    );
    return '$_temp0';
  }

  @override
  String get statusSalesReadonly => 'Обуна муддати тугаган — савдо тўхтатилган';

  @override
  String get statusSalesBlocked => 'Дўкон блокланган — савдо тўхтатилган';

  @override
  String get statusSalesOffline => 'Узоқ вақт интернет йўқ — савдо тўхтатилган';

  @override
  String get statusDeviceBlocked => 'Касса блокланган';

  @override
  String get statusClockSkew => 'Компьютер соати нотўғри';

  @override
  String statusRejected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count та ёзув қабул қилинмади',
    );
    return '$_temp0';
  }

  @override
  String get settingsScanner => 'Штрих-код сканери';

  @override
  String get settingsScannerSound => 'Сканерлашда овоз';

  @override
  String get settingsScannerSpeed => 'Сканер тезлиги';

  @override
  String get settingsScannerSpeedNormal => 'Оддий сканер';

  @override
  String get settingsScannerSpeedSlow => 'Секин (Bluetooth) сканер';

  @override
  String get settingsScannerSpeedVerySlow => 'Жуда секин сканер';

  @override
  String get scanCamera => 'Камера билан сканерлаш';

  @override
  String get scanCameraHint => 'Штрих-кодни рамкага тўғриланг';

  @override
  String get scanCameraDenied =>
      'Камерага рухсат берилмаган. Телефон созламаларидан рухсат беринг.';

  @override
  String get scanInvalidCode => 'Код нотўғри ўқилди, қайта сканерланг';

  @override
  String get shiftOpenTitle => 'Сменани очинг';

  @override
  String get shiftOpenMessage =>
      'Савдони бошлаш учун кассадаги нақд пулни киритинг';

  @override
  String get shiftOpeningCash => 'Кассадаги нақд пул';

  @override
  String get shiftOpenAction => 'Сменани очиш';

  @override
  String get shiftTitle => 'Смена';

  @override
  String shiftOpenedInfo(String time, String name) {
    return '$time да $name очган';
  }

  @override
  String get shiftXReport => 'X ҳисобот';

  @override
  String get shiftZReport => 'Z ҳисобот';

  @override
  String get reportSales => 'Савдолар';

  @override
  String reportChecks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count та чек',
    );
    return '$_temp0';
  }

  @override
  String get reportCash => 'Нақд';

  @override
  String get reportCard => 'Карта';

  @override
  String get reportDebt => 'Насия';

  @override
  String get reportRefunds => 'Қайтаришлар';

  @override
  String get reportCashMovements => 'Касса пули';

  @override
  String get reportCashIn => 'Киритилган';

  @override
  String get reportCashOut => 'Олинган';

  @override
  String get reportDebtPayments => 'Қарз тўловлари';

  @override
  String get reportCashBalance => 'Нақд ҳисоби';

  @override
  String get reportOpeningCash => 'Бошланғич нақд';

  @override
  String get reportExpectedCash => 'Кассада бўлиши керак';

  @override
  String get reportCountedCash => 'Саналган нақд';

  @override
  String get reportSurplus => 'Ортиқча';

  @override
  String get reportShortage => 'Кам';

  @override
  String get reportNoDifference => 'Фарқ йўқ';

  @override
  String get shiftCloseAction => 'Сменани ёпиш';

  @override
  String get shiftCloseTitle => 'Кассадаги пулни санаб чиқинг';

  @override
  String get shiftCloseConfirm => 'Ёпиш';

  @override
  String get shiftClosedTitle => 'Смена ёпилди';

  @override
  String get shiftBackToPos => 'Кассага қайтиш';

  @override
  String get shiftPrintReport => 'Чек чиқариш';
}
