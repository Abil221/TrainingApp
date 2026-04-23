import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('ru')
  ];

  /// No description provided for @appTitle.
  ///
  /// In ru, this message translates to:
  /// **'Training App'**
  String get appTitle;

  /// No description provided for @tabHome.
  ///
  /// In ru, this message translates to:
  /// **'Дома'**
  String get tabHome;

  /// No description provided for @tabProgress.
  ///
  /// In ru, this message translates to:
  /// **'Прогресс'**
  String get tabProgress;

  /// No description provided for @tabSettings.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get tabSettings;

  /// No description provided for @categoryStrength.
  ///
  /// In ru, this message translates to:
  /// **'Сила'**
  String get categoryStrength;

  /// No description provided for @categoryCardio.
  ///
  /// In ru, this message translates to:
  /// **'Кардио'**
  String get categoryCardio;

  /// No description provided for @categoryMobility.
  ///
  /// In ru, this message translates to:
  /// **'Мобильность'**
  String get categoryMobility;

  /// No description provided for @strengthDesc.
  ///
  /// In ru, this message translates to:
  /// **'Базовые силовые движения с весом собственного тела.'**
  String get strengthDesc;

  /// No description provided for @cardioDesc.
  ///
  /// In ru, this message translates to:
  /// **'Интенсивные форматы для выносливости и жиросжигания.'**
  String get cardioDesc;

  /// No description provided for @mobilityDesc.
  ///
  /// In ru, this message translates to:
  /// **'Растяжка, контроль корпуса и восстановление.'**
  String get mobilityDesc;

  /// No description provided for @homeWorkoutsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Тренировки дома'**
  String get homeWorkoutsTitle;

  /// No description provided for @homeWorkoutsSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Чёткие планы без сложного оборудования. Выбирай цель и начинай сразу.'**
  String get homeWorkoutsSubtitle;

  /// No description provided for @emptyCategory.
  ///
  /// In ru, this message translates to:
  /// **'Пока нет домашних тренировок в этой категории'**
  String get emptyCategory;

  /// No description provided for @themeSettings.
  ///
  /// In ru, this message translates to:
  /// **'Оформление'**
  String get themeSettings;

  /// No description provided for @languageSettings.
  ///
  /// In ru, this message translates to:
  /// **'Язык'**
  String get languageSettings;

  /// No description provided for @notificationSettings.
  ///
  /// In ru, this message translates to:
  /// **'Уведомления'**
  String get notificationSettings;

  /// No description provided for @soundSettings.
  ///
  /// In ru, this message translates to:
  /// **'Звук'**
  String get soundSettings;

  /// No description provided for @logOut.
  ///
  /// In ru, this message translates to:
  /// **'Выйти'**
  String get logOut;

  /// No description provided for @profile.
  ///
  /// In ru, this message translates to:
  /// **'Профиль'**
  String get profile;

  /// No description provided for @languageFull.
  ///
  /// In ru, this message translates to:
  /// **'Русский'**
  String get languageFull;
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
      <String>['de', 'en', 'es', 'fr', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
