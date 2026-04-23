// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Training App';

  @override
  String get tabHome => 'Zuhause';

  @override
  String get tabProgress => 'Fortschritt';

  @override
  String get tabSettings => 'Einstellungen';

  @override
  String get categoryStrength => 'Kraft';

  @override
  String get categoryCardio => 'Ausdauer';

  @override
  String get categoryMobility => 'Beweglichkeit';

  @override
  String get strengthDesc =>
      'Grundlegende Kraftübungen mit dem eigenen Körpergewicht.';

  @override
  String get cardioDesc =>
      'Intensives Training für Ausdauer und Fettverbrennung.';

  @override
  String get mobilityDesc => 'Dehnung, Rumpfkontrolle und Erholung.';

  @override
  String get homeWorkoutsTitle => 'Workouts zu Hause';

  @override
  String get homeWorkoutsSubtitle =>
      'Klare Pläne ohne komplizierte Ausrüstung.';

  @override
  String get emptyCategory => 'Noch keine Workouts in dieser Kategorie.';

  @override
  String get themeSettings => 'Aussehen';

  @override
  String get languageSettings => 'Sprache';

  @override
  String get notificationSettings => 'Benachrichtigungen';

  @override
  String get soundSettings => 'Ton';

  @override
  String get logOut => 'Abmelden';

  @override
  String get profile => 'Profil';

  @override
  String get languageFull => 'Deutsch';
}
