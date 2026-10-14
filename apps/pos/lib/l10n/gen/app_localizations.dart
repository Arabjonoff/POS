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

  /// Kassa qidiruv maydoni
  ///
  /// In uz, this message translates to:
  /// **'Nom, shtrix-kod yoki PLU'**
  String get posSearchHint;

  /// Tez tugmalar: barcha kategoriyalar
  ///
  /// In uz, this message translates to:
  /// **'Hammasi'**
  String get posQuickAll;

  /// Tez tugmalar paneli/varag'i
  ///
  /// In uz, this message translates to:
  /// **'Tez tugmalar'**
  String get posQuickButtons;

  /// Tez tugmali tovar yo'q
  ///
  /// In uz, this message translates to:
  /// **'Tez tugmalar hali sozlanmagan'**
  String get posQuickEmpty;

  /// Qidiruv natijasi bo'sh
  ///
  /// In uz, this message translates to:
  /// **'Hech narsa topilmadi'**
  String get posNoResults;

  /// Savat tabi
  ///
  /// In uz, this message translates to:
  /// **'Chek {number}'**
  String posCartTab(int number);

  /// Kechiktirib, yangi chek ochish (F6)
  ///
  /// In uz, this message translates to:
  /// **'Yangi chek'**
  String get posNewCart;

  /// Kechiktirilgan cheklar chegarasi
  ///
  /// In uz, this message translates to:
  /// **'5 tadan ortiq chek ochib bo\'lmaydi'**
  String get posCartLimit;

  /// Savatdagi tovarlar soni
  ///
  /// In uz, this message translates to:
  /// **'{count, plural, other{{count} ta tovar}}'**
  String posItemsCount(int count);

  /// Chegirmadan oldingi summa
  ///
  /// In uz, this message translates to:
  /// **'Tovarlar'**
  String get posSubtotal;

  /// Chegirma (F3)
  ///
  /// In uz, this message translates to:
  /// **'Chegirma'**
  String get posDiscount;

  /// Qator o'chirildi (undo bilan)
  ///
  /// In uz, this message translates to:
  /// **'{name} o\'chirildi'**
  String posLineRemoved(String name);

  /// Miqdor oynasi (F2)
  ///
  /// In uz, this message translates to:
  /// **'Miqdor'**
  String get posQtyTitle;

  /// Vaznli tovar miqdori
  ///
  /// In uz, this message translates to:
  /// **'Vazn, kg'**
  String get posWeightTitle;

  /// Miqdorni tasdiqlash
  ///
  /// In uz, this message translates to:
  /// **'Tayyor'**
  String get posQtyApply;

  /// Skanerlangan kod topilmadi
  ///
  /// In uz, this message translates to:
  /// **'Bu kod bazada yo\'q'**
  String get posCodeNotFound;

  /// Nofaol yoki narxi 0
  ///
  /// In uz, this message translates to:
  /// **'Bu tovarni sotib bo\'lmaydi: nofaol yoki narxi yo\'q'**
  String get posNotSellable;

  /// Chegirma turi
  ///
  /// In uz, this message translates to:
  /// **'Qatorga'**
  String get posDiscountLine;

  /// Chegirma turi
  ///
  /// In uz, this message translates to:
  /// **'Butun chekka'**
  String get posDiscountCheck;

  /// Chegirma: foiz
  ///
  /// In uz, this message translates to:
  /// **'Foiz'**
  String get posDiscountPercent;

  /// Chegirma: summa
  ///
  /// In uz, this message translates to:
  /// **'Summa'**
  String get posDiscountAmount;

  /// Chegirmani qo'llash
  ///
  /// In uz, this message translates to:
  /// **'Qo\'llash'**
  String get posDiscountApply;

  /// Chegirmani olib tashlash
  ///
  /// In uz, this message translates to:
  /// **'Olib tashlash'**
  String get posDiscountRemove;

  /// Katta chegirma
  ///
  /// In uz, this message translates to:
  /// **'{percent}% dan katta chegirma uchun menejer yoki ega tasdiqlashi kerak'**
  String posDiscountNeedsApproval(String percent);

  /// Menejer/ega PIN oynasi
  ///
  /// In uz, this message translates to:
  /// **'Tasdiqlash kerak'**
  String get approvalTitle;

  /// Tasdiqlovchi yo'q
  ///
  /// In uz, this message translates to:
  /// **'Menejer yoki ega uchun PIN o\'rnatilmagan'**
  String get approvalNoManagers;

  /// PIN bilan tasdiqlash
  ///
  /// In uz, this message translates to:
  /// **'Tasdiqlash'**
  String get approvalConfirm;

  /// To'lov oynasi sarlavhasi
  ///
  /// In uz, this message translates to:
  /// **'To\'lov'**
  String get payTitle;

  /// Aralash to'lov
  ///
  /// In uz, this message translates to:
  /// **'Aralash'**
  String get payMixed;

  /// Tez summa: aniq to'lov
  ///
  /// In uz, this message translates to:
  /// **'Aniq'**
  String get payExact;

  /// Mijoz bergan naqd
  ///
  /// In uz, this message translates to:
  /// **'Olindi'**
  String get payReceived;

  /// Naqd yetmaydi
  ///
  /// In uz, this message translates to:
  /// **'Yetmaydi'**
  String get payShort;

  /// Karta to'lovi
  ///
  /// In uz, this message translates to:
  /// **'Terminalda to\'lovni o\'tkazing, keyin tasdiqlang'**
  String get payCardHint;

  /// Savdoni yakunlash
  ///
  /// In uz, this message translates to:
  /// **'Yakunlash'**
  String get payComplete;

  /// Aralash: naqd qismi
  ///
  /// In uz, this message translates to:
  /// **'Naqd (qolgani)'**
  String get payCashRest;

  /// Aralash: xato
  ///
  /// In uz, this message translates to:
  /// **'Karta va nasiya jamidan oshib ketdi'**
  String get payPartsExceed;

  /// To'lov paytida skanerlash
  ///
  /// In uz, this message translates to:
  /// **'Avval to\'lovni yakunlang'**
  String get payScanBlocked;

  /// Nasiya: mijoz kerak
  ///
  /// In uz, this message translates to:
  /// **'Mijozni tanlang'**
  String get payChooseCustomer;

  /// Mijoz qidiruvi
  ///
  /// In uz, this message translates to:
  /// **'Ism yoki telefon'**
  String get payCustomerSearch;

  /// Mijozni tez yaratish
  ///
  /// In uz, this message translates to:
  /// **'Yangi mijoz'**
  String get payNewCustomer;

  /// Yangi mijoz ismi
  ///
  /// In uz, this message translates to:
  /// **'Ism'**
  String get payCustomerName;

  /// Yangi mijoz telefoni
  ///
  /// In uz, this message translates to:
  /// **'Telefon'**
  String get payCustomerPhone;

  /// Mijozning joriy qarzi
  ///
  /// In uz, this message translates to:
  /// **'Qarzi: {amount}'**
  String payCustomerDebt(String amount);

  /// Mijozning qarz limiti
  ///
  /// In uz, this message translates to:
  /// **'Limit: {amount}'**
  String payCustomerLimit(String amount);

  /// Nasiya limiti
  ///
  /// In uz, this message translates to:
  /// **'Qarz limitdan oshadi — menejer yoki ega tasdiqlashi kerak'**
  String get payLimitExceeded;

  /// Mijoz qidiruvi bo'sh
  ///
  /// In uz, this message translates to:
  /// **'Mijozlar topilmadi'**
  String get payNoCustomers;

  /// Yakunlash xabari
  ///
  /// In uz, this message translates to:
  /// **'Savdo yakunlandi'**
  String get paySaleDone;

  /// Yakunlash xabari (qaytim bilan)
  ///
  /// In uz, this message translates to:
  /// **'Savdo yakunlandi · Qaytim {amount}'**
  String paySaleDoneChange(String amount);

  /// Savdo yozilmadi
  ///
  /// In uz, this message translates to:
  /// **'Savdoni saqlab bo\'lmadi. Qayta urinib ko\'ring'**
  String get payFailed;

  /// Chek mijozi (F4)
  ///
  /// In uz, this message translates to:
  /// **'Mijoz'**
  String get posCustomer;

  /// Chekdan mijozni olib tashlash
  ///
  /// In uz, this message translates to:
  /// **'Mijozni olib tashlash'**
  String get posCustomerRemove;

  /// To'lov turi: naqd
  ///
  /// In uz, this message translates to:
  /// **'Naqd'**
  String get payCash;

  /// To'lov turi: karta
  ///
  /// In uz, this message translates to:
  /// **'Karta'**
  String get payCard;

  /// To'lov turi: nasiya
  ///
  /// In uz, this message translates to:
  /// **'Nasiya'**
  String get payDebt;

  /// Tanlangan mijozni almashtirish
  ///
  /// In uz, this message translates to:
  /// **'Boshqa mijoz'**
  String get payChangeCustomer;

  /// F4 oynasi sarlavhasi
  ///
  /// In uz, this message translates to:
  /// **'Chek mijozi'**
  String get posCustomerTitle;

  /// Chekda mijoz yo'q
  ///
  /// In uz, this message translates to:
  /// **'Mijoz tanlanmagan'**
  String get posCustomerNone;

  /// Chekda: chek raqami yorlig'i
  ///
  /// In uz, this message translates to:
  /// **'Chek'**
  String get receiptCheck;

  /// Chekda: kassir
  ///
  /// In uz, this message translates to:
  /// **'Kassir'**
  String get receiptCashier;

  /// Chekda: chegirma
  ///
  /// In uz, this message translates to:
  /// **'Chegirma'**
  String get receiptDiscount;

  /// Chekda: jami summa (katta harflar)
  ///
  /// In uz, this message translates to:
  /// **'JAMI'**
  String get receiptTotal;

  /// Chekda: nasiya mijozi
  ///
  /// In uz, this message translates to:
  /// **'Mijoz'**
  String get receiptCustomer;

  /// Chekda: mijozning savdodan keyingi qarzi
  ///
  /// In uz, this message translates to:
  /// **'Joriy qarz'**
  String get receiptDebtNow;

  /// Chek oxiri
  ///
  /// In uz, this message translates to:
  /// **'Fiskal chek emas'**
  String get receiptNotFiscal;

  /// Chek pastki matni (do'konda berilmagan bo'lsa)
  ///
  /// In uz, this message translates to:
  /// **'Xaridingiz uchun rahmat!'**
  String get receiptThanks;

  /// Qayta chop etilgan chek belgisi
  ///
  /// In uz, this message translates to:
  /// **'NUSXA'**
  String get receiptCopy;

  /// Holat qatori: printer tekshirilmoqda
  ///
  /// In uz, this message translates to:
  /// **'Printer tekshirilmoqda'**
  String get statusPrinterChecking;

  /// Test chek sarlavhasi (chekda)
  ///
  /// In uz, this message translates to:
  /// **'TEST CHEK'**
  String get printerTestTitle;

  /// Test chekda harflar sinovi
  ///
  /// In uz, this message translates to:
  /// **'Lotin: O\'zbekiston. Kirill: Ўзбекистон, Россия'**
  String get printerTestSample;

  /// Test chek oxiri
  ///
  /// In uz, this message translates to:
  /// **'Bu matn to\'g\'ri o\'qilsa, printer tayyor'**
  String get printerTestOk;

  /// Sozlamalar: printer bo'limi
  ///
  /// In uz, this message translates to:
  /// **'Chek printeri'**
  String get settingsPrinter;

  /// Printer bo'limi izohi
  ///
  /// In uz, this message translates to:
  /// **'Termal printer (ESC/POS), 58 yoki 80 mm'**
  String get settingsPrinterHelper;

  /// Printer ulanish turi
  ///
  /// In uz, this message translates to:
  /// **'Ulanish'**
  String get printerConnection;

  /// Printer ishlatilmaydi
  ///
  /// In uz, this message translates to:
  /// **'Printersiz'**
  String get printerNone;

  /// Tarmoq printeri
  ///
  /// In uz, this message translates to:
  /// **'Tarmoq (IP)'**
  String get printerNetwork;

  /// Windows'ga o'rnatilgan printer
  ///
  /// In uz, this message translates to:
  /// **'Kompyuter printeri'**
  String get printerWindows;

  /// Tarmoq printeri IP manzili
  ///
  /// In uz, this message translates to:
  /// **'Printer manzili'**
  String get printerAddress;

  /// IP manzil namunasi
  ///
  /// In uz, this message translates to:
  /// **'Masalan: 192.168.1.50'**
  String get printerAddressHint;

  /// Windows printerlari ro'yxati bo'sh
  ///
  /// In uz, this message translates to:
  /// **'Kompyuterda printer topilmadi'**
  String get printerNoSystemPrinters;

  /// Chek qog'ozi kengligi
  ///
  /// In uz, this message translates to:
  /// **'Qog\'oz kengligi'**
  String get printerWidth;

  /// Qog'oz kengligi qiymati
  ///
  /// In uz, this message translates to:
  /// **'{mm} mm'**
  String printerWidthMm(int mm);

  /// Printer kodlash jadvali
  ///
  /// In uz, this message translates to:
  /// **'Harflar jadvali'**
  String get printerEncoding;

  /// CP866 kodlash
  ///
  /// In uz, this message translates to:
  /// **'Kirill (CP866)'**
  String get printerEncodingCp866;

  /// UTF-8 kodlash
  ///
  /// In uz, this message translates to:
  /// **'UTF-8'**
  String get printerEncodingUtf8;

  /// Avtomatik chop etish
  ///
  /// In uz, this message translates to:
  /// **'Savdodan keyin chekni chiqarish'**
  String get printerAutoPrint;

  /// Chek nusxalari soni
  ///
  /// In uz, this message translates to:
  /// **'Nusxalar soni'**
  String get printerCopies;

  /// Pul qutisi
  ///
  /// In uz, this message translates to:
  /// **'Naqd to\'lovda pul qutisini ochish'**
  String get printerDrawer;

  /// Test chek chiqarish tugmasi
  ///
  /// In uz, this message translates to:
  /// **'Test chek'**
  String get printerTest;

  /// Pul qutisini ochish tugmasi
  ///
  /// In uz, this message translates to:
  /// **'Pul qutisini ochish'**
  String get printerOpenDrawer;

  /// Chop etish muvaffaqiyatli
  ///
  /// In uz, this message translates to:
  /// **'Printerga yuborildi'**
  String get printerSent;

  /// Chop etish xatosi
  ///
  /// In uz, this message translates to:
  /// **'Printerga ulanib bo\'lmadi. Kabel yoki manzilni tekshiring'**
  String get printerFailed;

  /// Printer sozlanmagan
  ///
  /// In uz, this message translates to:
  /// **'Avval printerni sozlang'**
  String get printerNotConfigured;

  /// Kassa: chek chop etilmadi
  ///
  /// In uz, this message translates to:
  /// **'Chek chiqmadi'**
  String get posReceiptFailed;

  /// Kassa: chekni qayta chop etish
  ///
  /// In uz, this message translates to:
  /// **'Qayta chop etish'**
  String get posReprint;

  /// Kassa: oxirgi chekni qayta chop etish tugmasi
  ///
  /// In uz, this message translates to:
  /// **'Oxirgi chek'**
  String get posLastReceipt;

  /// Savdo yakunlandi, lekin chek chop etilmadi
  ///
  /// In uz, this message translates to:
  /// **'{done}. Chek chiqmadi'**
  String posSaleDoneReceiptFailed(String done);

  /// Qaytarish oynasi sarlavhasi
  ///
  /// In uz, this message translates to:
  /// **'Qaytarish'**
  String get refundTitle;

  /// Qaytarish: savdoni topish izohi
  ///
  /// In uz, this message translates to:
  /// **'Chek raqamini yozing yoki chekdagi shtrix-kodni skanerlang'**
  String get refundFindHint;

  /// Chek raqami maydoni
  ///
  /// In uz, this message translates to:
  /// **'Chek raqami'**
  String get refundNumber;

  /// Chekni topish tugmasi
  ///
  /// In uz, this message translates to:
  /// **'Topish'**
  String get refundFind;

  /// Oxirgi savdolar ro'yxati
  ///
  /// In uz, this message translates to:
  /// **'Oxirgi cheklar'**
  String get refundRecent;

  /// Chek topilmadi
  ///
  /// In uz, this message translates to:
  /// **'Bunday chek topilmadi'**
  String get refundNotFound;

  /// Savdolar ro'yxati bo'sh
  ///
  /// In uz, this message translates to:
  /// **'Hali savdo yo\'q'**
  String get refundNoSales;

  /// Savdo holati
  ///
  /// In uz, this message translates to:
  /// **'Qisman qaytarilgan'**
  String get refundStatusPartial;

  /// Savdo holati
  ///
  /// In uz, this message translates to:
  /// **'Qaytarilgan'**
  String get refundStatusFull;

  /// Boshqa chekni tanlash
  ///
  /// In uz, this message translates to:
  /// **'Boshqa chek'**
  String get refundOtherCheck;

  /// Qatorda sotilgan miqdor
  ///
  /// In uz, this message translates to:
  /// **'Sotilgan: {qty}'**
  String refundSold(String qty);

  /// Qatorda qolgan miqdor
  ///
  /// In uz, this message translates to:
  /// **'Qaytarish mumkin: {qty}'**
  String refundLeft(String qty);

  /// Hamma qatorlarni to'liq qaytarish
  ///
  /// In uz, this message translates to:
  /// **'Hammasini'**
  String get refundAll;

  /// Chek to'liq qaytarilgan
  ///
  /// In uz, this message translates to:
  /// **'Bu chek to\'liq qaytarilgan'**
  String get refundFullyRefunded;

  /// Qaytarish sababi
  ///
  /// In uz, this message translates to:
  /// **'Sabab'**
  String get refundReason;

  /// Sabab
  ///
  /// In uz, this message translates to:
  /// **'Sifatsiz'**
  String get refundReasonDefective;

  /// Sabab
  ///
  /// In uz, this message translates to:
  /// **'Muddati o\'tgan'**
  String get refundReasonExpired;

  /// Sabab
  ///
  /// In uz, this message translates to:
  /// **'Mijoz fikridan qaytdi'**
  String get refundReasonChangedMind;

  /// Sabab
  ///
  /// In uz, this message translates to:
  /// **'Xato urilgan'**
  String get refundReasonMistake;

  /// Sabab matni maydoni
  ///
  /// In uz, this message translates to:
  /// **'Boshqa sabab'**
  String get refundReasonOther;

  /// Qaytarish usuli
  ///
  /// In uz, this message translates to:
  /// **'Pulni qaytarish'**
  String get refundMethod;

  /// Naqd qaytarish
  ///
  /// In uz, this message translates to:
  /// **'Naqd berish'**
  String get refundMethodCash;

  /// Mijoz qarzidan ayirish
  ///
  /// In uz, this message translates to:
  /// **'Qarzdan ayirish'**
  String get refundMethodDebt;

  /// Qaytariladigan summa
  ///
  /// In uz, this message translates to:
  /// **'Qaytariladi'**
  String get refundTotal;

  /// Qaytarishni tasdiqlash tugmasi
  ///
  /// In uz, this message translates to:
  /// **'Qaytarish'**
  String get refundConfirm;

  /// Qaytarish huquqi
  ///
  /// In uz, this message translates to:
  /// **'Qaytarishni menejer yoki ega tasdiqlashi kerak'**
  String get refundNeedsApproval;

  /// Hech narsa tanlanmagan
  ///
  /// In uz, this message translates to:
  /// **'Qaytariladigan tovarni tanlang'**
  String get refundChooseItems;

  /// Sabab tanlanmagan
  ///
  /// In uz, this message translates to:
  /// **'Sababni tanlang'**
  String get refundChooseReason;

  /// Naqd qaytarish yakunlandi
  ///
  /// In uz, this message translates to:
  /// **'Qaytarildi · Mijozga {amount} bering'**
  String refundDoneCash(String amount);

  /// Qarzdan ayirish yakunlandi
  ///
  /// In uz, this message translates to:
  /// **'Qaytarildi · Qarzdan {amount} ayirildi'**
  String refundDoneDebt(String amount);

  /// Qaytarish yozilmadi
  ///
  /// In uz, this message translates to:
  /// **'Qaytarishni saqlab bo\'lmadi. Qayta urinib ko\'ring'**
  String get refundFailed;

  /// Chek raqami namunasi
  ///
  /// In uz, this message translates to:
  /// **'Masalan: D1-000123'**
  String get refundNumberHint;

  /// Kassa puli oynasi sarlavhasi
  ///
  /// In uz, this message translates to:
  /// **'Kassa puli'**
  String get cashTitle;

  /// Kassaga pul kiritish
  ///
  /// In uz, this message translates to:
  /// **'Pul kiritish'**
  String get cashIn;

  /// Kassadan pul chiqarish
  ///
  /// In uz, this message translates to:
  /// **'Pul chiqarish'**
  String get cashOut;

  /// Kassa puli sababi
  ///
  /// In uz, this message translates to:
  /// **'Sabab'**
  String get cashReason;

  /// Sabab: pulni egasiga topshirish
  ///
  /// In uz, this message translates to:
  /// **'Inkassatsiya'**
  String get cashReasonCollection;

  /// Sabab: xarajat
  ///
  /// In uz, this message translates to:
  /// **'Xarajat'**
  String get cashReasonExpense;

  /// Sabab: qaytim uchun mayda pul
  ///
  /// In uz, this message translates to:
  /// **'Mayda pul'**
  String get cashReasonChange;

  /// Sabab matni
  ///
  /// In uz, this message translates to:
  /// **'Boshqa sabab'**
  String get cashReasonOther;

  /// Kutilgan naqd
  ///
  /// In uz, this message translates to:
  /// **'Kassada: {amount}'**
  String cashAvailable(String amount);

  /// Chiqarish naqddan ko'p
  ///
  /// In uz, this message translates to:
  /// **'Kassada faqat {amount} bor'**
  String cashExceeds(String amount);

  /// Summa kiritilmagan
  ///
  /// In uz, this message translates to:
  /// **'Summani kiriting'**
  String get cashEnterAmount;

  /// Sabab tanlanmagan
  ///
  /// In uz, this message translates to:
  /// **'Sababni tanlang'**
  String get cashChooseReason;

  /// Kiritish yakunlandi
  ///
  /// In uz, this message translates to:
  /// **'Kassaga {amount} kiritildi'**
  String cashDoneIn(String amount);

  /// Chiqarish yakunlandi
  ///
  /// In uz, this message translates to:
  /// **'Kassadan {amount} chiqarildi'**
  String cashDoneOut(String amount);

  /// Smena sahifasidagi ro'yxat
  ///
  /// In uz, this message translates to:
  /// **'Kassa puli harakatlari'**
  String get cashMovementsTitle;

  /// Ro'yxat bo'sh
  ///
  /// In uz, this message translates to:
  /// **'Bu smenada pul kiritilmagan va chiqarilmagan'**
  String get cashNoMovements;

  /// Kassa puli yozilmadi
  ///
  /// In uz, this message translates to:
  /// **'Saqlab bo\'lmadi. Qayta urinib ko\'ring'**
  String get cashFailed;

  /// Hisobot chekida: smena ochilgan vaqt
  ///
  /// In uz, this message translates to:
  /// **'Ochildi'**
  String get receiptShiftOpened;

  /// Hisobot chekida: smena yopilgan vaqt
  ///
  /// In uz, this message translates to:
  /// **'Yopildi'**
  String get receiptShiftClosed;

  /// Hisobot chekida: chop etilgan vaqt
  ///
  /// In uz, this message translates to:
  /// **'Chop etildi'**
  String get receiptPrintedAt;

  /// Tovarlar qidiruvi
  ///
  /// In uz, this message translates to:
  /// **'Nom, shtrix-kod yoki PLU'**
  String get productsSearchHint;

  /// Yangi tovar tugmasi
  ///
  /// In uz, this message translates to:
  /// **'Tovar qo\'shish'**
  String get productsAdd;

  /// Kategoriya filtri: hammasi
  ///
  /// In uz, this message translates to:
  /// **'Hammasi'**
  String get productsAll;

  /// Filtr
  ///
  /// In uz, this message translates to:
  /// **'Kam qolgan'**
  String get productsFilterLow;

  /// Filtr
  ///
  /// In uz, this message translates to:
  /// **'Manfiy qoldiq'**
  String get productsFilterNegative;

  /// Filtr
  ///
  /// In uz, this message translates to:
  /// **'Nofaol'**
  String get productsFilterInactive;

  /// Bo'sh ro'yxat
  ///
  /// In uz, this message translates to:
  /// **'Hali tovar yo\'q'**
  String get productsEmptyTitle;

  /// Bo'sh ro'yxat izohi
  ///
  /// In uz, this message translates to:
  /// **'Tovar qo\'shing yoki shtrix-kodni skanerlang'**
  String get productsEmptyMessage;

  /// Filtr natijasi bo'sh
  ///
  /// In uz, this message translates to:
  /// **'Hech narsa topilmadi'**
  String get productsNotFound;

  /// Ustun
  ///
  /// In uz, this message translates to:
  /// **'Nom'**
  String get productsColName;

  /// Ustun
  ///
  /// In uz, this message translates to:
  /// **'Shtrix-kod'**
  String get productsColBarcode;

  /// Ustun
  ///
  /// In uz, this message translates to:
  /// **'Kategoriya'**
  String get productsColCategory;

  /// Ustun
  ///
  /// In uz, this message translates to:
  /// **'Narx'**
  String get productsColPrice;

  /// Ustun
  ///
  /// In uz, this message translates to:
  /// **'Tannarx'**
  String get productsColCost;

  /// Ustun
  ///
  /// In uz, this message translates to:
  /// **'Qoldiq'**
  String get productsColStock;

  /// Qoldiq belgisi
  ///
  /// In uz, this message translates to:
  /// **'Kam'**
  String get productsBadgeLow;

  /// Qoldiq belgisi
  ///
  /// In uz, this message translates to:
  /// **'Manfiy'**
  String get productsBadgeNegative;

  /// Holat belgisi
  ///
  /// In uz, this message translates to:
  /// **'Nofaol'**
  String get productsBadgeInactive;

  /// Karta sarlavhasi
  ///
  /// In uz, this message translates to:
  /// **'Yangi tovar'**
  String get productNew;

  /// Maydon
  ///
  /// In uz, this message translates to:
  /// **'Nomi'**
  String get productName;

  /// Maydon
  ///
  /// In uz, this message translates to:
  /// **'Kategoriya'**
  String get productCategory;

  /// Kategoriya yo'q
  ///
  /// In uz, this message translates to:
  /// **'Kategoriyasiz'**
  String get productNoCategory;

  /// Maydon
  ///
  /// In uz, this message translates to:
  /// **'Birlik'**
  String get productUnit;

  /// Maydon
  ///
  /// In uz, this message translates to:
  /// **'Sotish narxi, so\'m'**
  String get productSellPrice;

  /// Maydon
  ///
  /// In uz, this message translates to:
  /// **'Tannarx, so\'m'**
  String get productCostPrice;

  /// Ustama foizi
  ///
  /// In uz, this message translates to:
  /// **'Ustama: {percent}'**
  String productMarkup(String percent);

  /// Maydon
  ///
  /// In uz, this message translates to:
  /// **'Vaznli tovar (tarozida tortiladi)'**
  String get productWeighted;

  /// Maydon
  ///
  /// In uz, this message translates to:
  /// **'PLU — tarozi kodi (5 raqam)'**
  String get productPlu;

  /// Maydon
  ///
  /// In uz, this message translates to:
  /// **'Kam qolgan deb belgilash, {unit}'**
  String productMinStock(String unit);

  /// Maydon
  ///
  /// In uz, this message translates to:
  /// **'IKPU (ixtiyoriy, 17 raqam)'**
  String get productIkpu;

  /// Maydon
  ///
  /// In uz, this message translates to:
  /// **'Kassada tez tugma'**
  String get productQuickButton;

  /// Maydon
  ///
  /// In uz, this message translates to:
  /// **'Shtrix-kodlar'**
  String get productBarcodes;

  /// Shtrix-kod qo'shish maydoni
  ///
  /// In uz, this message translates to:
  /// **'Kodni yozing yoki skanerlang'**
  String get productBarcodeAdd;

  /// Asosiy shtrix-kod belgisi
  ///
  /// In uz, this message translates to:
  /// **'Asosiy'**
  String get productBarcodePrimary;

  /// Tooltip
  ///
  /// In uz, this message translates to:
  /// **'Kodni olib tashlash'**
  String get productBarcodeRemove;

  /// Tugma
  ///
  /// In uz, this message translates to:
  /// **'Nofaol qilish'**
  String get productDeactivate;

  /// Tugma
  ///
  /// In uz, this message translates to:
  /// **'Faollashtirish'**
  String get productActivate;

  /// Xabar
  ///
  /// In uz, this message translates to:
  /// **'Saqlandi'**
  String get productSaved;

  /// Huquq
  ///
  /// In uz, this message translates to:
  /// **'Tovarni o\'zgartirishni menejer yoki ega tasdiqlashi kerak'**
  String get productNeedsApproval;

  /// Bo'lim
  ///
  /// In uz, this message translates to:
  /// **'Narx tarixi'**
  String get productPriceHistory;

  /// Oflayn
  ///
  /// In uz, this message translates to:
  /// **'Narx tarixini ko\'rish uchun internet kerak'**
  String get productPriceHistoryOffline;

  /// Bo'sh
  ///
  /// In uz, this message translates to:
  /// **'Narx hali o\'zgarmagan'**
  String get productPriceHistoryEmpty;

  /// Narx tarixi qatori
  ///
  /// In uz, this message translates to:
  /// **'Narx {sell} · Tannarx {cost}'**
  String productPriceHistoryRow(String sell, String cost);

  /// Kartadagi qoldiq
  ///
  /// In uz, this message translates to:
  /// **'Qoldiq: {qty}'**
  String productStockNow(String qty);

  /// Xato
  ///
  /// In uz, this message translates to:
  /// **'Narx 0 dan katta bo\'lishi kerak'**
  String get productErrPrice;

  /// Xato
  ///
  /// In uz, this message translates to:
  /// **'«{code}» — noto\'g\'ri shtrix-kod'**
  String productErrBarcodeFormat(String code);

  /// Xato
  ///
  /// In uz, this message translates to:
  /// **'«{code}» — kod noto\'g\'ri o\'qildi, qayta skanerlang'**
  String productErrBarcodeCheck(String code);

  /// Xato
  ///
  /// In uz, this message translates to:
  /// **'«{code}» ikki marta yozilgan'**
  String productErrBarcodeRepeated(String code);

  /// Xato
  ///
  /// In uz, this message translates to:
  /// **'«{code}» — «{product}» tovarida bor'**
  String productErrBarcodeTaken(String code, String product);

  /// Xato
  ///
  /// In uz, this message translates to:
  /// **'PLU 5 raqamdan iborat bo\'lishi kerak'**
  String get productErrPluFormat;

  /// Xato
  ///
  /// In uz, this message translates to:
  /// **'Bu PLU «{product}» tovarida bor'**
  String productErrPluTaken(String product);

  /// Xato
  ///
  /// In uz, this message translates to:
  /// **'Vaznli tovar uchun kg kabi kasrli birlik tanlang'**
  String get productErrWeightedUnit;

  /// Xato
  ///
  /// In uz, this message translates to:
  /// **'IKPU 17 raqamdan iborat bo\'lishi kerak'**
  String get productErrIkpu;

  /// Minimal qoldiq noto'g'ri
  ///
  /// In uz, this message translates to:
  /// **'Miqdorni to\'g\'ri yozing (masalan, 5 yoki 0,5)'**
  String get productErrQty;

  /// Import oynasi va tugma
  ///
  /// In uz, this message translates to:
  /// **'Excel\'dan yuklash'**
  String get importTitle;

  /// Import izohi
  ///
  /// In uz, this message translates to:
  /// **'Excel (.xlsx) yoki CSV faylni tanlang. Birinchi qator — ustun nomlari. Mavjud tovarlar shtrix-kod bo\'yicha yangilanadi.'**
  String get importIntro;

  /// Tugma
  ///
  /// In uz, this message translates to:
  /// **'Faylni tanlash'**
  String get importPick;

  /// Tugma
  ///
  /// In uz, this message translates to:
  /// **'Shablonni yuklab olish'**
  String get importTemplate;

  /// Xabar
  ///
  /// In uz, this message translates to:
  /// **'Shablon saqlandi'**
  String get importTemplateSaved;

  /// Oflayn
  ///
  /// In uz, this message translates to:
  /// **'Import uchun internet kerak'**
  String get importOffline;

  /// Xato
  ///
  /// In uz, this message translates to:
  /// **'Faylni o\'qib bo\'lmadi: .xlsx yoki .csv, 10 MB gacha'**
  String get importFailed;

  /// Fayl haqida
  ///
  /// In uz, this message translates to:
  /// **'{file} · {count} ta qator'**
  String importRows(String file, int count);

  /// Bosqich sarlavhasi
  ///
  /// In uz, this message translates to:
  /// **'Ustunlarni moslang'**
  String get importMapTitle;

  /// Ustun tanlanmagan
  ///
  /// In uz, this message translates to:
  /// **'— yo\'q —'**
  String get importNoColumn;

  /// Ustun tanlash oynasi
  ///
  /// In uz, this message translates to:
  /// **'Ustunni tanlang'**
  String get importChooseColumn;

  /// Xato
  ///
  /// In uz, this message translates to:
  /// **'Nom va narx ustunlarini tanlang'**
  String get importRequiredMissing;

  /// Tugma
  ///
  /// In uz, this message translates to:
  /// **'Tekshirish'**
  String get importCheck;

  /// Tekshiruv natijasi
  ///
  /// In uz, this message translates to:
  /// **'Yangi: {creates} · Yangilanadi: {updates} · Xato: {errors}'**
  String importSummary(int creates, int updates, int errors);

  /// Xato qatori
  ///
  /// In uz, this message translates to:
  /// **'{row}-qator · {field}: {reason}'**
  String importErrorRow(int row, String field, String reason);

  /// Ko'rsatilmagan xatolar
  ///
  /// In uz, this message translates to:
  /// **'Yana {count} ta xato'**
  String importMoreErrors(int count);

  /// Tugma
  ///
  /// In uz, this message translates to:
  /// **'Import qilish'**
  String get importApply;

  /// Tugma
  ///
  /// In uz, this message translates to:
  /// **'Orqaga'**
  String get importBack;

  /// Huquq
  ///
  /// In uz, this message translates to:
  /// **'Importni menejer yoki ega tasdiqlashi kerak'**
  String get importNeedsApproval;

  /// Import natijasi
  ///
  /// In uz, this message translates to:
  /// **'Qo\'shildi: {created} · Yangilandi: {updated} · O\'tkazib yuborildi: {skipped}'**
  String importDone(int created, int updated, int skipped);

  /// Tugma
  ///
  /// In uz, this message translates to:
  /// **'Tayyor'**
  String get importClose;

  /// Sabab
  ///
  /// In uz, this message translates to:
  /// **'to\'ldirilmagan'**
  String get importErrRequired;

  /// Sabab
  ///
  /// In uz, this message translates to:
  /// **'son emas'**
  String get importErrNumber;

  /// Sabab
  ///
  /// In uz, this message translates to:
  /// **'0 dan katta bo\'lishi kerak'**
  String get importErrPositive;

  /// Sabab
  ///
  /// In uz, this message translates to:
  /// **'noto\'g\'ri shtrix-kod'**
  String get importErrBarcode;

  /// Sabab
  ///
  /// In uz, this message translates to:
  /// **'shtrix-kod nazorat raqami xato'**
  String get importErrCheckDigit;

  /// Sabab
  ///
  /// In uz, this message translates to:
  /// **'faylda takrorlangan'**
  String get importErrDuplicate;

  /// Sabab
  ///
  /// In uz, this message translates to:
  /// **'noma\'lum birlik'**
  String get importErrUnit;

  /// Sabab
  ///
  /// In uz, this message translates to:
  /// **'juda uzun'**
  String get importErrTooLong;

  /// Sabab
  ///
  /// In uz, this message translates to:
  /// **'vaznli tovar uchun kasrli birlik kerak'**
  String get importErrWeighted;
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
