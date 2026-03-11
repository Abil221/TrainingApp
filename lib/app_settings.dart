import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _themeModeKey = 'theme_mode';
const _languageKey = 'language';
const _notificationsKey = 'notifications_enabled';
const _soundKey = 'sound_enabled';
const _onboardingCompletedKey = 'onboarding_completed';

class AppSettings {
  AppSettings._internal();

  static final AppSettings _instance = AppSettings._internal();

  factory AppSettings() => _instance;

  final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.light);
  final ValueNotifier<String> language = ValueNotifier('Русский');
  final ValueNotifier<bool> notificationsEnabled = ValueNotifier(true);
  final ValueNotifier<bool> soundEnabled = ValueNotifier(true);
  final ValueNotifier<bool> onboardingCompleted = ValueNotifier(false);

  bool get isDarkMode => themeMode.value == ThemeMode.dark;

  String get selectedLanguage => language.value;

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    final savedThemeMode = preferences.getString(_themeModeKey);
    final savedLanguage = preferences.getString(_languageKey);

    if (savedThemeMode == ThemeMode.dark.name) {
      themeMode.value = ThemeMode.dark;
    } else {
      themeMode.value = ThemeMode.light;
    }

    if (savedLanguage != null && savedLanguage.isNotEmpty) {
      language.value = savedLanguage;
    }

    notificationsEnabled.value = preferences.getBool(_notificationsKey) ?? true;
    soundEnabled.value = preferences.getBool(_soundKey) ?? true;
    onboardingCompleted.value =
        preferences.getBool(_onboardingCompletedKey) ?? false;
  }

  Future<void> setDarkMode(bool enabled) async {
    themeMode.value = enabled ? ThemeMode.dark : ThemeMode.light;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_themeModeKey, themeMode.value.name);
  }

  Future<void> setLanguage(String value) async {
    language.value = value;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_languageKey, value);
  }

  Future<void> setNotificationsEnabled(bool value) async {
    notificationsEnabled.value = value;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_notificationsKey, value);
  }

  Future<void> setSoundEnabled(bool value) async {
    soundEnabled.value = value;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_soundKey, value);
  }

  Future<void> completeOnboarding() async {
    onboardingCompleted.value = true;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_onboardingCompletedKey, true);
  }
}
