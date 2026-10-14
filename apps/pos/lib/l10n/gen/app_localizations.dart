import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ru.dart';
import 'app_localizations_uz.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('uz'),
    Locale('ru'),
    Locale.fromSubtags(languageCode: 'uz', scriptCode: 'Cyrl'),
  ];

  /// Ilova nomi (oyna sarlavhasi)
  ///
  /// In uz, this message translates to:
  /// **'Kassa'**
  String get appTitle;

  /// Kassa bo'limi nomi
  ///
  /// In uz, this message translates to:
  /// **'Kassa'**
  String get posTitle;

  /// Bo'sh savat holati
  ///
  /// In uz, this message translates to:
  /// **'Tovarni skanerlang yoki qidiring'**
  String get posEmptyCart;

  /// Shu tilning o'z nomi (til tanlashda)
  ///
  /// In uz, this message translates to:
  /// **'O\'zbekcha'**
  String get languageName;

  /// Valyuta nomi summadan keyin: 125 000 so'm
  ///
  /// In uz, this message translates to:
  /// **'so\'m'**
  String get currencySom;

  /// Birlik: dona (pcs)
  ///
  /// In uz, this message translates to:
  /// **'dona'**
  String get unitPcs;

  /// Birlik: kilogramm
  ///
  /// In uz, this message translates to:
  /// **'kg'**
  String get unitKg;

  /// Birlik: gramm
  ///
  /// In uz, this message translates to:
  /// **'g'**
  String get unitG;

  /// Birlik: litr
  ///
  /// In uz, this message translates to:
  /// **'l'**
  String get unitL;

  /// Birlik: metr
  ///
  /// In uz, this message translates to:
  /// **'m'**
  String get unitM;

  /// Birlik: qadoq (pack)
  ///
  /// In uz, this message translates to:
  /// **'qadoq'**
  String get unitPack;

  /// Navigatsiya: kassa bo'limi
  ///
  /// In uz, this message translates to:
  /// **'Kassa'**
  String get navPos;

  /// Navigatsiya: tovarlar bo'limi
  ///
  /// In uz, this message translates to:
  /// **'Tovarlar'**
  String get navProducts;

  /// Navigatsiya: tovar qabul qilish (kirim)
  ///
  /// In uz, this message translates to:
  /// **'Kirim'**
  String get navReceiving;

  /// Navigatsiya: mijozlar va nasiya
  ///
  /// In uz, this message translates to:
  /// **'Mijozlar'**
  String get navCustomers;

  /// Navigatsiya: hisobotlar
  ///
  /// In uz, this message translates to:
  /// **'Hisobotlar'**
  String get navReports;

  /// Navigatsiya: sozlamalar
  ///
  /// In uz, this message translates to:
  /// **'Sozlamalar'**
  String get navSettings;

  /// Tugma: saqlash
  ///
  /// In uz, this message translates to:
  /// **'Saqlash'**
  String get actionSave;

  /// Tugma: oynani/amalni bekor qilish
  ///
  /// In uz, this message translates to:
  /// **'Bekor qilish'**
  String get actionCancel;

  /// Toast tugmasi: oxirgi amalni qaytarish (undo)
  ///
  /// In uz, this message translates to:
  /// **'Bekor qilish'**
  String get actionUndo;

  /// Tugma: yopish
  ///
  /// In uz, this message translates to:
  /// **'Yopish'**
  String get actionClose;

  /// Tugma: o'chirish
  ///
  /// In uz, this message translates to:
  /// **'O\'chirish'**
  String get actionDelete;

  /// Tugma: qayta urinish
  ///
  /// In uz, this message translates to:
  /// **'Qayta urinish'**
  String get actionRetry;

  /// Tasdiq: ha
  ///
  /// In uz, this message translates to:
  /// **'Ha'**
  String get actionYes;

  /// Tasdiq: yo'q
  ///
  /// In uz, this message translates to:
  /// **'Yo\'q'**
  String get actionNo;

  /// Qidiruv maydonini tozalash
  ///
  /// In uz, this message translates to:
  /// **'Tozalash'**
  String get actionClear;

  /// Raqamli klaviaturada o'chirish tugmasi nomi
  ///
  /// In uz, this message translates to:
  /// **'Oxirgi raqamni o\'chirish'**
  String get actionBackspace;

  /// Miqdorni bittaga oshirish
  ///
  /// In uz, this message translates to:
  /// **'Ko\'paytirish'**
  String get actionIncrease;

  /// Miqdorni bittaga kamaytirish
  ///
  /// In uz, this message translates to:
  /// **'Kamaytirish'**
  String get actionDecrease;

  /// Kassa: to'lov oynasini ochish
  ///
  /// In uz, this message translates to:
  /// **'To\'lash'**
  String get actionPay;

  /// Tovar qidiruv maydoni ichidagi izoh
  ///
  /// In uz, this message translates to:
  /// **'Shtrix-kod yoki tovar nomi'**
  String get searchProductsHint;

  /// Chek jami summasi yorlig'i
  ///
  /// In uz, this message translates to:
  /// **'Jami'**
  String get totalLabel;

  /// Xaridorga qaytariladigan pul
  ///
  /// In uz, this message translates to:
  /// **'Qaytim'**
  String get changeLabel;

  /// Holat qatori: internet bor
  ///
  /// In uz, this message translates to:
  /// **'Internet bor'**
  String get statusOnline;

  /// Holat qatori: internet yo'q
  ///
  /// In uz, this message translates to:
  /// **'Internet yo\'q'**
  String get statusOffline;

  /// Holat qatori: serverga yuborilmagan yozuvlar soni
  ///
  /// In uz, this message translates to:
  /// **'{count, plural, =0{Hammasi yuborilgan} other{{count} ta yozuv navbatda}}'**
  String statusQueued(int count);

  /// Internet yo'qligida tushuntirish: savdolar lokal saqlanmoqda
  ///
  /// In uz, this message translates to:
  /// **'Internet yo\'q — savdolar saqlanyapti ({count})'**
  String statusOfflineSaving(int count);

  /// Holat qatori: printer ishlayapti
  ///
  /// In uz, this message translates to:
  /// **'Printer ulangan'**
  String get statusPrinterReady;

  /// Holat qatori: printer topilmadi
  ///
  /// In uz, this message translates to:
  /// **'Printer ulanmagan'**
  String get statusPrinterMissing;

  /// Holat qatori: smena ochiq
  ///
  /// In uz, this message translates to:
  /// **'Smena ochiq'**
  String get statusShiftOpen;

  /// Holat qatori: smena yopiq
  ///
  /// In uz, this message translates to:
  /// **'Smena yopiq'**
  String get statusShiftClosed;

  /// Sozlamalar: ilova tili
  ///
  /// In uz, this message translates to:
  /// **'Til'**
  String get settingsLanguage;

  /// Holat qatori: internet holati hali aniqlanmagan
  ///
  /// In uz, this message translates to:
  /// **'Ulanish tekshirilmoqda'**
  String get statusConnectionUnknown;

  /// Holat qatori: printer tanlanmagan
  ///
  /// In uz, this message translates to:
  /// **'Printer sozlanmagan'**
  String get statusPrinterUnknown;

  /// Hali qurilmagan bo'lim sarlavhasi
  ///
  /// In uz, this message translates to:
  /// **'Bo\'lim tayyorlanmoqda'**
  String get sectionComingSoonTitle;

  /// Hali qurilmagan bo'lim izohi
  ///
  /// In uz, this message translates to:
  /// **'Bu bo\'lim keyingi yangilanishda qo\'shiladi'**
  String get sectionComingSoonMessage;

  /// Birinchi ishga tushirish sarlavhasi
  ///
  /// In uz, this message translates to:
  /// **'Kassani ulash'**
  String get setupTitle;

  /// Ulash ekrani izohi
  ///
  /// In uz, this message translates to:
  /// **'Do\'kon egasining telefon raqami va paroli bilan kiring'**
  String get setupSubtitle;

  /// Maydon nomi
  ///
  /// In uz, this message translates to:
  /// **'Telefon raqami'**
  String get setupPhoneLabel;

  /// Telefon namunasi
  ///
  /// In uz, this message translates to:
  /// **'90 123 45 67'**
  String get setupPhoneHint;

  /// Maydon nomi
  ///
  /// In uz, this message translates to:
  /// **'Parol'**
  String get setupPasswordLabel;

  /// Tugma: keyingi qadam
  ///
  /// In uz, this message translates to:
  /// **'Davom etish'**
  String get setupNext;

  /// Qurilma nomi qadami sarlavhasi
  ///
  /// In uz, this message translates to:
  /// **'Bu kassaga nom bering'**
  String get setupDeviceNameTitle;

  /// Maydon nomi
  ///
  /// In uz, this message translates to:
  /// **'Kassa nomi'**
  String get setupDeviceNameLabel;

  /// Maydon izohi
  ///
  /// In uz, this message translates to:
  /// **'Masalan: Kassa 1, Peshtaxta'**
  String get setupDeviceNameHelper;

  /// Standart kassa nomi
  ///
  /// In uz, this message translates to:
  /// **'Kassa 1'**
  String get setupDeviceNameDefault;

  /// Tugma: qurilmani ro'yxatdan o'tkazish
  ///
  /// In uz, this message translates to:
  /// **'Ulash'**
  String get setupConnect;

  /// Birinchi sinxron sarlavhasi
  ///
  /// In uz, this message translates to:
  /// **'Ma\'lumotlar yuklanmoqda'**
  String get setupSyncTitle;

  /// Birinchi sinxron jarayoni
  ///
  /// In uz, this message translates to:
  /// **'{count, plural, =0{Tayyorlanmoqda…} other{{count} ta yozuv yuklandi}}'**
  String setupSyncProgress(int count);

  /// Birinchi sinxron xatosi
  ///
  /// In uz, this message translates to:
  /// **'Ma\'lumotlarni yuklab bo\'lmadi. Internetni tekshiring.'**
  String get setupSyncFailed;

  /// Kirish xatosi
  ///
  /// In uz, this message translates to:
  /// **'Telefon raqami yoki parol noto\'g\'ri'**
  String get setupErrorInvalidCredentials;

  /// Kirish xatosi
  ///
  /// In uz, this message translates to:
  /// **'Kassani faqat do\'kon egasi ulay oladi'**
  String get setupErrorNotOwner;

  /// Ulash xatosi
  ///
  /// In uz, this message translates to:
  /// **'Tarifingizdagi kassalar soni tugagan. Administratorga murojaat qiling.'**
  String get setupErrorDeviceLimit;

  /// Ulash xatosi
  ///
  /// In uz, this message translates to:
  /// **'Obuna topilmadi. Administratorga murojaat qiling.'**
  String get setupErrorNoSubscription;

  /// Ulash xatosi
  ///
  /// In uz, this message translates to:
  /// **'Bu kassa bloklangan. Administratorga murojaat qiling.'**
  String get setupErrorDeviceBlocked;

  /// Ulash xatosi
  ///
  /// In uz, this message translates to:
  /// **'Internet yo\'q yoki server javob bermayapti. Qayta urinib ko\'ring.'**
  String get setupErrorNetwork;

  /// Ulash xatosi
  ///
  /// In uz, this message translates to:
  /// **'Nimadir xato ketdi. Qayta urinib ko\'ring.'**
  String get setupErrorUnknown;

  /// Bo'sh majburiy maydon
  ///
  /// In uz, this message translates to:
  /// **'To\'ldiring'**
  String get fieldRequired;

  /// Qulf ekrani: xodim tanlash
  ///
  /// In uz, this message translates to:
  /// **'Kim ishlaydi?'**
  String get lockTitle;

  /// Qulf ekrani: PIN so'rovi
  ///
  /// In uz, this message translates to:
  /// **'PIN kodni kiriting'**
  String get lockEnterPin;

  /// PIN tasdiqlash tugmasi
  ///
  /// In uz, this message translates to:
  /// **'Kirish'**
  String get lockSubmit;

  /// Xodim tanlashga qaytish
  ///
  /// In uz, this message translates to:
  /// **'Boshqa xodim'**
  String get lockBack;

  /// Noto'g'ri PIN
  ///
  /// In uz, this message translates to:
  /// **'{count, plural, =0{PIN noto\'g\'ri} other{PIN noto\'g\'ri. Yana {count} ta urinish qoldi}}'**
  String lockWrongPin(int count);

  /// 5 marta xatodan keyin kutish
  ///
  /// In uz, this message translates to:
  /// **'{seconds, plural, other{Juda ko\'p xato. {seconds} soniyadan keyin urinib ko\'ring}}'**
  String lockLockedOut(int seconds);

  /// Xodimda PIN yo'q
  ///
  /// In uz, this message translates to:
  /// **'PIN o\'rnatilmagan'**
  String get lockNoPin;

  /// Qulf ekrani: bo'sh
  ///
  /// In uz, this message translates to:
  /// **'Xodimlar topilmadi'**
  String get lockNoStaffTitle;

  /// Qulf ekrani: bo'sh izoh
  ///
  /// In uz, this message translates to:
  /// **'Ma\'lumotlar hali yuklanmagan. Internetni tekshirib, qayta urinib ko\'ring.'**
  String get lockNoStaffMessage;

  /// Rol
  ///
  /// In uz, this message translates to:
  /// **'Ega'**
  String get roleOwner;

  /// Rol
  ///
  /// In uz, this message translates to:
  /// **'Menejer'**
  String get roleManager;

  /// Rol
  ///
  /// In uz, this message translates to:
  /// **'Kassir'**
  String get roleCashier;

  /// Ekranni qulflash
  ///
  /// In uz, this message translates to:
  /// **'Qulflash'**
  String get actionLock;

  /// Sozlama nomi
  ///
  /// In uz, this message translates to:
  /// **'Avtomatik qulflash'**
  String get settingsAutoLock;

  /// Sozlama izohi
  ///
  /// In uz, this message translates to:
  /// **'Kassada harakat bo\'lmasa, ekran qulflanadi'**
  String get settingsAutoLockHelper;

  /// Avtomatik qulflash o'chiq
  ///
  /// In uz, this message translates to:
  /// **'O\'chiq'**
  String get settingsAutoLockOff;

  /// Avtomatik qulflash vaqti
  ///
  /// In uz, this message translates to:
  /// **'{minutes, plural, other{{minutes} daqiqadan keyin}}'**
  String settingsAutoLockMinutes(int minutes);

  /// Holat qatori: obuna readonly
  ///
  /// In uz, this message translates to:
  /// **'Obuna muddati tugagan — savdo to\'xtatilgan'**
  String get statusSalesReadonly;

  /// Holat qatori: tenant bloklangan
  ///
  /// In uz, this message translates to:
  /// **'Do\'kon bloklangan — savdo to\'xtatilgan'**
  String get statusSalesBlocked;

  /// Holat qatori: oflayn muddati o'tdi
  ///
  /// In uz, this message translates to:
  /// **'Uzoq vaqt internet yo\'q — savdo to\'xtatilgan'**
  String get statusSalesOffline;

  /// Holat qatori: qurilma bloklangan
  ///
  /// In uz, this message translates to:
  /// **'Kassa bloklangan'**
  String get statusDeviceBlocked;

  /// Holat qatori: qurilma soati serverdan farq qiladi
  ///
  /// In uz, this message translates to:
  /// **'Kompyuter soati noto\'g\'ri'**
  String get statusClockSkew;

  /// Holat qatori: server rad etgan yozuvlar
  ///
  /// In uz, this message translates to:
  /// **'{count, plural, other{{count} ta yozuv qabul qilinmadi}}'**
  String statusRejected(int count);

  /// Sozlamalar bo'limi
  ///
  /// In uz, this message translates to:
  /// **'Shtrix-kod skaneri'**
  String get settingsScanner;

  /// Ovoz signali yoqilgan
  ///
  /// In uz, this message translates to:
  /// **'Skanerlashda ovoz'**
  String get settingsScannerSound;

  /// Belgilar orasidagi interval sozlamasi
  ///
  /// In uz, this message translates to:
  /// **'Skaner tezligi'**
  String get settingsScannerSpeed;

  /// Interval 35 ms
  ///
  /// In uz, this message translates to:
  /// **'Oddiy skaner'**
  String get settingsScannerSpeedNormal;

  /// Interval 60 ms
  ///
  /// In uz, this message translates to:
  /// **'Sekin (Bluetooth) skaner'**
  String get settingsScannerSpeedSlow;

  /// Interval 100 ms
  ///
  /// In uz, this message translates to:
  /// **'Juda sekin skaner'**
  String get settingsScannerSpeedVerySlow;

  /// Kamera skaneri tugmasi
  ///
  /// In uz, this message translates to:
  /// **'Kamera bilan skanerlash'**
  String get scanCamera;

  /// Kamera ekrani izohi
  ///
  /// In uz, this message translates to:
  /// **'Shtrix-kodni ramkaga to\'g\'rilang'**
  String get scanCameraHint;

  /// Kamera ruxsati yo'q
  ///
  /// In uz, this message translates to:
  /// **'Kameraga ruxsat berilmagan. Telefon sozlamalaridan ruxsat bering.'**
  String get scanCameraDenied;

  /// Nazorat raqami xato
  ///
  /// In uz, this message translates to:
  /// **'Kod noto\'g\'ri o\'qildi, qayta skanerlang'**
  String get scanInvalidCode;

  /// Smena yopiq: kassa ekrani kartasi
  ///
  /// In uz, this message translates to:
  /// **'Smenani oching'**
  String get shiftOpenTitle;

  /// Smena ochish izohi
  ///
  /// In uz, this message translates to:
  /// **'Savdoni boshlash uchun kassadagi naqd pulni kiriting'**
  String get shiftOpenMessage;

  /// Boshlang'ich naqd maydoni
  ///
  /// In uz, this message translates to:
  /// **'Kassadagi naqd pul'**
  String get shiftOpeningCash;

  /// Tugma
  ///
  /// In uz, this message translates to:
  /// **'Smenani ochish'**
  String get shiftOpenAction;

  /// Smena sahifasi sarlavhasi
  ///
  /// In uz, this message translates to:
  /// **'Smena'**
  String get shiftTitle;

  /// Smena kim va qachon ochgani
  ///
  /// In uz, this message translates to:
  /// **'{time} da {name} ochgan'**
  String shiftOpenedInfo(String time, String name);

  /// Ochiq smena hisoboti
  ///
  /// In uz, this message translates to:
  /// **'X hisobot'**
  String get shiftXReport;

  /// Yopilgan smena hisoboti
  ///
  /// In uz, this message translates to:
  /// **'Z hisobot'**
  String get shiftZReport;

  /// Hisobot qatori
  ///
  /// In uz, this message translates to:
  /// **'Savdolar'**
  String get reportSales;

  /// Cheklar soni
  ///
  /// In uz, this message translates to:
  /// **'{count, plural, other{{count} ta chek}}'**
  String reportChecks(int count);

  /// To'lov turi
  ///
  /// In uz, this message translates to:
  /// **'Naqd'**
  String get reportCash;

  /// To'lov turi
  ///
  /// In uz, this message translates to:
  /// **'Karta'**
  String get reportCard;

  /// To'lov turi
  ///
  /// In uz, this message translates to:
  /// **'Nasiya'**
  String get reportDebt;

  /// Hisobot qatori
  ///
  /// In uz, this message translates to:
  /// **'Qaytarishlar'**
  String get reportRefunds;

  /// Hisobot bo'limi
  ///
  /// In uz, this message translates to:
  /// **'Kassa puli'**
  String get reportCashMovements;

  /// Kassaga kiritilgan pul
  ///
  /// In uz, this message translates to:
  /// **'Kiritilgan'**
  String get reportCashIn;

  /// Kassadan olingan pul
  ///
  /// In uz, this message translates to:
  /// **'Olingan'**
  String get reportCashOut;

  /// Hisobot qatori
  ///
  /// In uz, this message translates to:
  /// **'Qarz to\'lovlari'**
  String get reportDebtPayments;

  /// Hisobot bo'limi
  ///
  /// In uz, this message translates to:
  /// **'Naqd hisobi'**
  String get reportCashBalance;

  /// Hisobot qatori
  ///
  /// In uz, this message translates to:
  /// **'Boshlang\'ich naqd'**
  String get reportOpeningCash;

  /// Kutilgan naqd
  ///
  /// In uz, this message translates to:
  /// **'Kassada bo\'lishi kerak'**
  String get reportExpectedCash;

  /// Hisobot qatori
  ///
  /// In uz, this message translates to:
  /// **'Sanalgan naqd'**
  String get reportCountedCash;

  /// Farq: ko'p
  ///
  /// In uz, this message translates to:
  /// **'Ortiqcha'**
  String get reportSurplus;

  /// Farq: kam
  ///
  /// In uz, this message translates to:
  /// **'Kam'**
  String get reportShortage;

  /// Farq nol
  ///
  /// In uz, this message translates to:
  /// **'Farq yo\'q'**
  String get reportNoDifference;

  /// Tugma
  ///
  /// In uz, this message translates to:
  /// **'Smenani yopish'**
  String get shiftCloseAction;

  /// Yopish oynasi sarlavhasi
  ///
  /// In uz, this message translates to:
  /// **'Kassadagi pulni sanang'**
  String get shiftCloseTitle;

  /// Yopishni tasdiqlash
  ///
  /// In uz, this message translates to:
  /// **'Yopish'**
  String get shiftCloseConfirm;

  /// Z hisobot sarlavhasi
  ///
  /// In uz, this message translates to:
  /// **'Smena yopildi'**
  String get shiftClosedTitle;

  /// Tugma
  ///
  /// In uz, this message translates to:
  /// **'Kassaga qaytish'**
  String get shiftBackToPos;

  /// Z hisobotni chop etish
  ///
  /// In uz, this message translates to:
  /// **'Chek chiqarish'**
  String get shiftPrintReport;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ru', 'uz'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'uz':
      {
        switch (locale.scriptCode) {
          case 'Cyrl':
            return AppLocalizationsUzCyrl();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ru':
      return AppLocalizationsRu();
    case 'uz':
      return AppLocalizationsUz();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
