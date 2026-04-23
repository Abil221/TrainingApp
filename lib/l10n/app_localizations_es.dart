// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Training App';

  @override
  String get tabHome => 'Inicio';

  @override
  String get tabProgress => 'Progreso';

  @override
  String get tabSettings => 'Ajustes';

  @override
  String get categoryStrength => 'Fuerza';

  @override
  String get categoryCardio => 'Cardio';

  @override
  String get categoryMobility => 'Movilidad';

  @override
  String get strengthDesc => 'Movimientos básicos de fuerza con peso corporal.';

  @override
  String get cardioDesc =>
      'Formatos intensos para resistencia y quema de grasa.';

  @override
  String get mobilityDesc => 'Estiramiento, control del núcleo y recuperación.';

  @override
  String get homeWorkoutsTitle => 'Entrenamientos en casa';

  @override
  String get homeWorkoutsSubtitle => 'Planes claros sin equipo complejo.';

  @override
  String get emptyCategory => 'Aún no hay entrenamientos en esta categoría.';

  @override
  String get themeSettings => 'Apariencia';

  @override
  String get languageSettings => 'Idioma';

  @override
  String get notificationSettings => 'Notificaciones';

  @override
  String get soundSettings => 'Sonido';

  @override
  String get logOut => 'Cerrar sesión';

  @override
  String get profile => 'Perfil';

  @override
  String get languageFull => 'Español';
}
