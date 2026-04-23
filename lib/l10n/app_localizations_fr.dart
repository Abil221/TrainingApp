// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Training App';

  @override
  String get tabHome => 'Accueil';

  @override
  String get tabProgress => 'Progrès';

  @override
  String get tabSettings => 'Paramètres';

  @override
  String get categoryStrength => 'Force';

  @override
  String get categoryCardio => 'Cardio';

  @override
  String get categoryMobility => 'Mobilité';

  @override
  String get strengthDesc => 'Mouvements de base de force au poids du corps.';

  @override
  String get cardioDesc =>
      'Formats intenses pour l\'endurance et la perte de graisse.';

  @override
  String get mobilityDesc => 'Étirements, contrôle du tronc et récupération.';

  @override
  String get homeWorkoutsTitle => 'Entraînements';

  @override
  String get homeWorkoutsSubtitle =>
      'Des plans clairs sans équipement complexe.';

  @override
  String get emptyCategory =>
      'Aucun entraînement pour l\'instant dans cette catégorie.';

  @override
  String get themeSettings => 'Apparence';

  @override
  String get languageSettings => 'Langue';

  @override
  String get notificationSettings => 'Notifications';

  @override
  String get soundSettings => 'Son';

  @override
  String get logOut => 'Se déconnecter';

  @override
  String get profile => 'Profil';

  @override
  String get languageFull => 'Français';
}
