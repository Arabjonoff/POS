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

  @override
  String get posSearchHint => 'Nom, shtrix-kod yoki PLU';

  @override
  String get posQuickAll => 'Hammasi';

  @override
  String get posQuickButtons => 'Tez tugmalar';

  @override
  String get posQuickEmpty => 'Tez tugmalar hali sozlanmagan';

  @override
  String get posNoResults => 'Hech narsa topilmadi';

  @override
  String posCartTab(int number) {
    return 'Chek $number';
  }

  @override
  String get posNewCart => 'Yangi chek';

  @override
  String get posCartLimit => '5 tadan ortiq chek ochib bo\'lmaydi';

  @override
  String posItemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ta tovar',
    );
    return '$_temp0';
  }

  @override
  String get posSubtotal => 'Tovarlar';

  @override
  String get posDiscount => 'Chegirma';

  @override
  String posLineRemoved(String name) {
    return '$name o\'chirildi';
  }

  @override
  String get posQtyTitle => 'Miqdor';

  @override
  String get posWeightTitle => 'Vazn, kg';

  @override
  String get posQtyApply => 'Tayyor';

  @override
  String get posCodeNotFound => 'Bu kod bazada yo\'q';

  @override
  String get posNotSellable =>
      'Bu tovarni sotib bo\'lmaydi: nofaol yoki narxi yo\'q';

  @override
  String get posDiscountLine => 'Qatorga';

  @override
  String get posDiscountCheck => 'Butun chekka';

  @override
  String get posDiscountPercent => 'Foiz';

  @override
  String get posDiscountAmount => 'Summa';

  @override
  String get posDiscountApply => 'Qo\'llash';

  @override
  String get posDiscountRemove => 'Olib tashlash';

  @override
  String posDiscountNeedsApproval(String percent) {
    return '$percent% dan katta chegirma uchun menejer yoki ega tasdiqlashi kerak';
  }

  @override
  String get approvalTitle => 'Tasdiqlash kerak';

  @override
  String get approvalNoManagers => 'Menejer yoki ega uchun PIN o\'rnatilmagan';

  @override
  String get approvalConfirm => 'Tasdiqlash';

  @override
  String get payTitle => 'To\'lov';

  @override
  String get payMixed => 'Aralash';

  @override
  String get payExact => 'Aniq';

  @override
  String get payReceived => 'Olindi';

  @override
  String get payShort => 'Yetmaydi';

  @override
  String get payCardHint => 'Terminalda to\'lovni o\'tkazing, keyin tasdiqlang';

  @override
  String get payComplete => 'Yakunlash';

  @override
  String get payCashRest => 'Naqd (qolgani)';

  @override
  String get payPartsExceed => 'Karta va nasiya jamidan oshib ketdi';

  @override
  String get payScanBlocked => 'Avval to\'lovni yakunlang';

  @override
  String get payChooseCustomer => 'Mijozni tanlang';

  @override
  String get payCustomerSearch => 'Ism yoki telefon';

  @override
  String get payNewCustomer => 'Yangi mijoz';

  @override
  String get payCustomerName => 'Ism';

  @override
  String get payCustomerPhone => 'Telefon';

  @override
  String payCustomerDebt(String amount) {
    return 'Qarzi: $amount';
  }

  @override
  String payCustomerLimit(String amount) {
    return 'Limit: $amount';
  }

  @override
  String get payLimitExceeded =>
      'Qarz limitdan oshadi — menejer yoki ega tasdiqlashi kerak';

  @override
  String get payNoCustomers => 'Mijozlar topilmadi';

  @override
  String get paySaleDone => 'Savdo yakunlandi';

  @override
  String paySaleDoneChange(String amount) {
    return 'Savdo yakunlandi · Qaytim $amount';
  }

  @override
  String get payFailed => 'Savdoni saqlab bo\'lmadi. Qayta urinib ko\'ring';

  @override
  String get posCustomer => 'Mijoz';

  @override
  String get posCustomerRemove => 'Mijozni olib tashlash';

  @override
  String get payCash => 'Naqd';

  @override
  String get payCard => 'Karta';

  @override
  String get payDebt => 'Nasiya';

  @override
  String get payChangeCustomer => 'Boshqa mijoz';

  @override
  String get posCustomerTitle => 'Chek mijozi';

  @override
  String get posCustomerNone => 'Mijoz tanlanmagan';

  @override
  String get receiptCheck => 'Chek';

  @override
  String get receiptCashier => 'Kassir';

  @override
  String get receiptDiscount => 'Chegirma';

  @override
  String get receiptTotal => 'JAMI';

  @override
  String get receiptCustomer => 'Mijoz';

  @override
  String get receiptDebtNow => 'Joriy qarz';

  @override
  String get receiptNotFiscal => 'Fiskal chek emas';

  @override
  String get receiptThanks => 'Xaridingiz uchun rahmat!';

  @override
  String get receiptCopy => 'NUSXA';

  @override
  String get statusPrinterChecking => 'Printer tekshirilmoqda';

  @override
  String get printerTestTitle => 'TEST CHEK';

  @override
  String get printerTestSample =>
      'Lotin: O\'zbekiston. Kirill: Ўзбекистон, Россия';

  @override
  String get printerTestOk => 'Bu matn to\'g\'ri o\'qilsa, printer tayyor';

  @override
  String get settingsPrinter => 'Chek printeri';

  @override
  String get settingsPrinterHelper => 'Termal printer (ESC/POS), 58 yoki 80 mm';

  @override
  String get printerConnection => 'Ulanish';

  @override
  String get printerNone => 'Printersiz';

  @override
  String get printerNetwork => 'Tarmoq (IP)';

  @override
  String get printerWindows => 'Kompyuter printeri';

  @override
  String get printerAddress => 'Printer manzili';

  @override
  String get printerAddressHint => 'Masalan: 192.168.1.50';

  @override
  String get printerNoSystemPrinters => 'Kompyuterda printer topilmadi';

  @override
  String get printerWidth => 'Qog\'oz kengligi';

  @override
  String printerWidthMm(int mm) {
    return '$mm mm';
  }

  @override
  String get printerEncoding => 'Harflar jadvali';

  @override
  String get printerEncodingCp866 => 'Kirill (CP866)';

  @override
  String get printerEncodingUtf8 => 'UTF-8';

  @override
  String get printerAutoPrint => 'Savdodan keyin chekni chiqarish';

  @override
  String get printerCopies => 'Nusxalar soni';

  @override
  String get printerDrawer => 'Naqd to\'lovda pul qutisini ochish';

  @override
  String get printerTest => 'Test chek';

  @override
  String get printerOpenDrawer => 'Pul qutisini ochish';

  @override
  String get printerSent => 'Printerga yuborildi';

  @override
  String get printerFailed =>
      'Printerga ulanib bo\'lmadi. Kabel yoki manzilni tekshiring';

  @override
  String get printerNotConfigured => 'Avval printerni sozlang';

  @override
  String get posReceiptFailed => 'Chek chiqmadi';

  @override
  String get posReprint => 'Qayta chop etish';

  @override
  String get posLastReceipt => 'Oxirgi chek';

  @override
  String posSaleDoneReceiptFailed(String done) {
    return '$done. Chek chiqmadi';
  }

  @override
  String get refundTitle => 'Qaytarish';

  @override
  String get refundFindHint =>
      'Chek raqamini yozing yoki chekdagi shtrix-kodni skanerlang';

  @override
  String get refundNumber => 'Chek raqami';

  @override
  String get refundFind => 'Topish';

  @override
  String get refundRecent => 'Oxirgi cheklar';

  @override
  String get refundNotFound => 'Bunday chek topilmadi';

  @override
  String get refundNoSales => 'Hali savdo yo\'q';

  @override
  String get refundStatusPartial => 'Qisman qaytarilgan';

  @override
  String get refundStatusFull => 'Qaytarilgan';

  @override
  String get refundOtherCheck => 'Boshqa chek';

  @override
  String refundSold(String qty) {
    return 'Sotilgan: $qty';
  }

  @override
  String refundLeft(String qty) {
    return 'Qaytarish mumkin: $qty';
  }

  @override
  String get refundAll => 'Hammasini';

  @override
  String get refundFullyRefunded => 'Bu chek to\'liq qaytarilgan';

  @override
  String get refundReason => 'Sabab';

  @override
  String get refundReasonDefective => 'Sifatsiz';

  @override
  String get refundReasonExpired => 'Muddati o\'tgan';

  @override
  String get refundReasonChangedMind => 'Mijoz fikridan qaytdi';

  @override
  String get refundReasonMistake => 'Xato urilgan';

  @override
  String get refundReasonOther => 'Boshqa sabab';

  @override
  String get refundMethod => 'Pulni qaytarish';

  @override
  String get refundMethodCash => 'Naqd berish';

  @override
  String get refundMethodDebt => 'Qarzdan ayirish';

  @override
  String get refundTotal => 'Qaytariladi';

  @override
  String get refundConfirm => 'Qaytarish';

  @override
  String get refundNeedsApproval =>
      'Qaytarishni menejer yoki ega tasdiqlashi kerak';

  @override
  String get refundChooseItems => 'Qaytariladigan tovarni tanlang';

  @override
  String get refundChooseReason => 'Sababni tanlang';

  @override
  String refundDoneCash(String amount) {
    return 'Qaytarildi · Mijozga $amount bering';
  }

  @override
  String refundDoneDebt(String amount) {
    return 'Qaytarildi · Qarzdan $amount ayirildi';
  }

  @override
  String get refundFailed =>
      'Qaytarishni saqlab bo\'lmadi. Qayta urinib ko\'ring';

  @override
  String get refundNumberHint => 'Masalan: D1-000123';
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

  @override
  String get posSearchHint => 'Ном, штрих-код ёки PLU';

  @override
  String get posQuickAll => 'Ҳаммаси';

  @override
  String get posQuickButtons => 'Тез тугмалар';

  @override
  String get posQuickEmpty => 'Тез тугмалар ҳали созланмаган';

  @override
  String get posNoResults => 'Ҳеч нарса топилмади';

  @override
  String posCartTab(int number) {
    return 'Чек $number';
  }

  @override
  String get posNewCart => 'Янги чек';

  @override
  String get posCartLimit => '5 тадан ортиқ чек очиб бўлмайди';

  @override
  String posItemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count та товар',
    );
    return '$_temp0';
  }

  @override
  String get posSubtotal => 'Товарлар';

  @override
  String get posDiscount => 'Чегирма';

  @override
  String posLineRemoved(String name) {
    return '$name ўчирилди';
  }

  @override
  String get posQtyTitle => 'Миқдор';

  @override
  String get posWeightTitle => 'Вазн, кг';

  @override
  String get posQtyApply => 'Тайёр';

  @override
  String get posCodeNotFound => 'Бу код базада йўқ';

  @override
  String get posNotSellable =>
      'Бу товарни сотиб бўлмайди: нофаол ёки нархи йўқ';

  @override
  String get posDiscountLine => 'Қаторга';

  @override
  String get posDiscountCheck => 'Бутун чекка';

  @override
  String get posDiscountPercent => 'Фоиз';

  @override
  String get posDiscountAmount => 'Сумма';

  @override
  String get posDiscountApply => 'Қўллаш';

  @override
  String get posDiscountRemove => 'Олиб ташлаш';

  @override
  String posDiscountNeedsApproval(String percent) {
    return '$percent% дан катта чегирма учун менежер ёки эга тасдиқлаши керак';
  }

  @override
  String get approvalTitle => 'Тасдиқлаш керак';

  @override
  String get approvalNoManagers => 'Менежер ёки эга учун PIN ўрнатилмаган';

  @override
  String get approvalConfirm => 'Тасдиқлаш';

  @override
  String get payTitle => 'Тўлов';

  @override
  String get payMixed => 'Аралаш';

  @override
  String get payExact => 'Аниқ';

  @override
  String get payReceived => 'Олинди';

  @override
  String get payShort => 'Етмайди';

  @override
  String get payCardHint => 'Терминалда тўловни ўтказинг, кейин тасдиқланг';

  @override
  String get payComplete => 'Якунлаш';

  @override
  String get payCashRest => 'Нақд (қолгани)';

  @override
  String get payPartsExceed => 'Карта ва насия жамидан ошиб кетди';

  @override
  String get payScanBlocked => 'Аввал тўловни якунланг';

  @override
  String get payChooseCustomer => 'Мижозни танланг';

  @override
  String get payCustomerSearch => 'Исм ёки телефон';

  @override
  String get payNewCustomer => 'Янги мижоз';

  @override
  String get payCustomerName => 'Исм';

  @override
  String get payCustomerPhone => 'Телефон';

  @override
  String payCustomerDebt(String amount) {
    return 'Қарзи: $amount';
  }

  @override
  String payCustomerLimit(String amount) {
    return 'Лимит: $amount';
  }

  @override
  String get payLimitExceeded =>
      'Қарз лимитдан ошади — менежер ёки эга тасдиқлаши керак';

  @override
  String get payNoCustomers => 'Мижозлар топилмади';

  @override
  String get paySaleDone => 'Савдо якунланди';

  @override
  String paySaleDoneChange(String amount) {
    return 'Савдо якунланди · Қайтим $amount';
  }

  @override
  String get payFailed => 'Савдони сақлаб бўлмади. Қайта уриниб кўринг';

  @override
  String get posCustomer => 'Мижоз';

  @override
  String get posCustomerRemove => 'Мижозни олиб ташлаш';

  @override
  String get payCash => 'Нақд';

  @override
  String get payCard => 'Карта';

  @override
  String get payDebt => 'Насия';

  @override
  String get payChangeCustomer => 'Бошқа мижоз';

  @override
  String get posCustomerTitle => 'Чек мижози';

  @override
  String get posCustomerNone => 'Мижоз танланмаган';

  @override
  String get receiptCheck => 'Чек';

  @override
  String get receiptCashier => 'Кассир';

  @override
  String get receiptDiscount => 'Чегирма';

  @override
  String get receiptTotal => 'ЖАМИ';

  @override
  String get receiptCustomer => 'Мижоз';

  @override
  String get receiptDebtNow => 'Жорий қарз';

  @override
  String get receiptNotFiscal => 'Фискал чек эмас';

  @override
  String get receiptThanks => 'Харидингиз учун раҳмат!';

  @override
  String get receiptCopy => 'НУСХА';

  @override
  String get statusPrinterChecking => 'Принтер текширилмоқда';

  @override
  String get printerTestTitle => 'ТЕСТ ЧЕК';

  @override
  String get printerTestSample =>
      'Lotin: O\'zbekiston. Kirill: Ўзбекистон, Россия';

  @override
  String get printerTestOk => 'Бу матн тўғри ўқилса, принтер тайёр';

  @override
  String get settingsPrinter => 'Чек принтери';

  @override
  String get settingsPrinterHelper => 'Термал принтер (ESC/POS), 58 ёки 80 мм';

  @override
  String get printerConnection => 'Уланиш';

  @override
  String get printerNone => 'Принтерсиз';

  @override
  String get printerNetwork => 'Тармоқ (IP)';

  @override
  String get printerWindows => 'Компьютер принтери';

  @override
  String get printerAddress => 'Принтер манзили';

  @override
  String get printerAddressHint => 'Масалан: 192.168.1.50';

  @override
  String get printerNoSystemPrinters => 'Компьютерда принтер топилмади';

  @override
  String get printerWidth => 'Қоғоз кенглиги';

  @override
  String printerWidthMm(int mm) {
    return '$mm мм';
  }

  @override
  String get printerEncoding => 'Ҳарфлар жадвали';

  @override
  String get printerEncodingCp866 => 'Кирилл (CP866)';

  @override
  String get printerEncodingUtf8 => 'UTF-8';

  @override
  String get printerAutoPrint => 'Савдодан кейин чекни чиқариш';

  @override
  String get printerCopies => 'Нусхалар сони';

  @override
  String get printerDrawer => 'Нақд тўловда пул қутисини очиш';

  @override
  String get printerTest => 'Тест чек';

  @override
  String get printerOpenDrawer => 'Пул қутисини очиш';

  @override
  String get printerSent => 'Принтерга юборилди';

  @override
  String get printerFailed =>
      'Принтерга уланиб бўлмади. Кабель ёки манзилни текширинг';

  @override
  String get printerNotConfigured => 'Аввал принтерни созланг';

  @override
  String get posReceiptFailed => 'Чек чиқмади';

  @override
  String get posReprint => 'Қайта чоп этиш';

  @override
  String get posLastReceipt => 'Охирги чек';

  @override
  String posSaleDoneReceiptFailed(String done) {
    return '$done. Чек чиқмади';
  }

  @override
  String get refundTitle => 'Қайтариш';

  @override
  String get refundFindHint =>
      'Чек рақамини ёзинг ёки чекдаги штрих-кодни сканерланг';

  @override
  String get refundNumber => 'Чек рақами';

  @override
  String get refundFind => 'Топиш';

  @override
  String get refundRecent => 'Охирги чеклар';

  @override
  String get refundNotFound => 'Бундай чек топилмади';

  @override
  String get refundNoSales => 'Ҳали савдо йўқ';

  @override
  String get refundStatusPartial => 'Қисман қайтарилган';

  @override
  String get refundStatusFull => 'Қайтарилган';

  @override
  String get refundOtherCheck => 'Бошқа чек';

  @override
  String refundSold(String qty) {
    return 'Сотилган: $qty';
  }

  @override
  String refundLeft(String qty) {
    return 'Қайтариш мумкин: $qty';
  }

  @override
  String get refundAll => 'Ҳаммасини';

  @override
  String get refundFullyRefunded => 'Бу чек тўлиқ қайтарилган';

  @override
  String get refundReason => 'Сабаб';

  @override
  String get refundReasonDefective => 'Сифатсиз';

  @override
  String get refundReasonExpired => 'Муддати ўтган';

  @override
  String get refundReasonChangedMind => 'Мижоз фикридан қайтди';

  @override
  String get refundReasonMistake => 'Хато урилган';

  @override
  String get refundReasonOther => 'Бошқа сабаб';

  @override
  String get refundMethod => 'Пулни қайтариш';

  @override
  String get refundMethodCash => 'Нақд бериш';

  @override
  String get refundMethodDebt => 'Қарздан айириш';

  @override
  String get refundTotal => 'Қайтарилади';

  @override
  String get refundConfirm => 'Қайтариш';

  @override
  String get refundNeedsApproval =>
      'Қайтаришни менежер ёки эга тасдиқлаши керак';

  @override
  String get refundChooseItems => 'Қайтариладиган товарни танланг';

  @override
  String get refundChooseReason => 'Сабабни танланг';

  @override
  String refundDoneCash(String amount) {
    return 'Қайтарилди · Мижозга $amount беринг';
  }

  @override
  String refundDoneDebt(String amount) {
    return 'Қайтарилди · Қарздан $amount айирилди';
  }

  @override
  String get refundFailed => 'Қайтаришни сақлаб бўлмади. Қайта уриниб кўринг';

  @override
  String get refundNumberHint => 'Масалан: D1-000123';
}
