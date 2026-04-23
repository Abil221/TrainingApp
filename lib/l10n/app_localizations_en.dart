// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Training App';

  @override
  String get tabHome => 'Home';

  @override
  String get tabProgress => 'Progress';

  @override
  String get tabSettings => 'Settings';

  @override
  String get categoryStrength => 'Strength';

  @override
  String get categoryCardio => 'Cardio';

  @override
  String get categoryMobility => 'Mobility';

  @override
  String get strengthDesc => 'Basic bodyweight strength movements.';

  @override
  String get cardioDesc => 'High intensity formats for endurance.';

  @override
  String get mobilityDesc => 'Stretching, core control, and recovery.';

  @override
  String get homeWorkoutsTitle => 'Home Workouts';

  @override
  String get homeWorkoutsSubtitle =>
      'Clear plans, no complex equipment. Pick a goal and start.';

  @override
  String get emptyCategory =>
      'No home workouts available in this category yet.';

  @override
  String get themeSettings => 'Appearance';

  @override
  String get languageSettings => 'Language';

  @override
  String get notificationSettings => 'Notifications';

  @override
  String get soundSettings => 'Sound';

  @override
  String get logOut => 'Log Out';

  @override
  String get profile => 'Profile';

  @override
  String get languageFull => 'English';
}
