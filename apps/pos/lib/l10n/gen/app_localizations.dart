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
