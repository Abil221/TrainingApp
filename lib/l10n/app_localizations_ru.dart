// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Training App';

  @override
  String get tabHome => 'Дома';

  @override
  String get tabProgress => 'Прогресс';

  @override
  String get tabSettings => 'Настройки';

  @override
  String get categoryStrength => 'Сила';

  @override
  String get categoryCardio => 'Кардио';

  @override
  String get categoryMobility => 'Мобильность';

  @override
  String get strengthDesc =>
      'Базовые силовые движения с весом собственного тела.';

  @override
  String get cardioDesc =>
      'Интенсивные форматы для выносливости и жиросжигания.';

  @override
  String get mobilityDesc => 'Растяжка, контроль корпуса и восстановление.';

  @override
  String get homeWorkoutsTitle => 'Тренировки дома';

  @override
  String get homeWorkoutsSubtitle =>
      'Чёткие планы без сложного оборудования. Выбирай цель и начинай сразу.';

  @override
  String get emptyCategory => 'Пока нет домашних тренировок в этой категории';

  @override
  String get themeSettings => 'Оформление';

  @override
  String get languageSettings => 'Язык';

  @override
  String get notificationSettings => 'Уведомления';

  @override
  String get soundSettings => 'Звук';

  @override
  String get logOut => 'Выйти';

  @override
  String get profile => 'Профиль';

  @override
  String get languageFull => 'Русский';
}
