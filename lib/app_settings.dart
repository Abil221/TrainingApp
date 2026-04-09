import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/user_progress.dart';

const _themeModeKey = 'theme_mode';
const _languageKey = 'language';
const _notificationsKey = 'notifications_enabled';
const _soundKey = 'sound_enabled';
const _onboardingCompletedKey = 'onboarding_completed';
const _userProgressKey = 'user_progress';

class AppSettings {
  AppSettings._internal();

  static final AppSettings _instance = AppSettings._internal();

  factory AppSettings() => _instance;

  SharedPreferences? _preferences;
  bool _loaded = false;
  String? _activeUserId;

  final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.light);
  final ValueNotifier<String> language = ValueNotifier('Русский');
  final ValueNotifier<bool> notificationsEnabled = ValueNotifier(true);
  final ValueNotifier<bool> soundEnabled = ValueNotifier(true);
  final ValueNotifier<bool> onboardingCompleted = ValueNotifier(false);
  final ValueNotifier<UserProgress> userProgress =
      ValueNotifier(const UserProgress());

  bool get isDarkMode => themeMode.value == ThemeMode.dark;

  String get selectedLanguage => language.value;

  Locale get locale => _languageToLocale(language.value);

  List<Locale> get supportedLocales => const [
        Locale('ru'),
        Locale('en'),
        Locale('es'),
        Locale('fr'),
        Locale('de'),
      ];

  Future<void> load() async {
    if (_loaded) {
      return;
    }

    _preferences = await SharedPreferences.getInstance();
    final savedThemeMode = _preferences!.getString(_themeModeKey);
    final savedLanguage = _preferences!.getString(_languageKey);

    if (savedThemeMode == ThemeMode.dark.name) {
      themeMode.value = ThemeMode.dark;
    } else {
      themeMode.value = ThemeMode.light;
    }

    if (savedLanguage != null && savedLanguage.isNotEmpty) {
      language.value = savedLanguage;
    }

    notificationsEnabled.value =
        _preferences!.getBool(_notificationsKey) ?? true;
    soundEnabled.value = _preferences!.getBool(_soundKey) ?? true;

    _loaded = true;
    await _loadStateForCurrentUser();

    Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      _handleAuthStateChanged();
    });
  }

  Future<void> setDarkMode(bool enabled) async {
    themeMode.value = enabled ? ThemeMode.dark : ThemeMode.light;
    await _preferences?.setString(_themeModeKey, themeMode.value.name);
  }

  Future<void> setLanguage(String value) async {
    language.value = value;
    await _preferences?.setString(_languageKey, value);
  }

  Future<void> setNotificationsEnabled(bool value) async {
    notificationsEnabled.value = value;
    await _preferences?.setBool(_notificationsKey, value);
  }

  Future<void> setSoundEnabled(bool value) async {
    soundEnabled.value = value;
    await _preferences?.setBool(_soundKey, value);
  }

  Future<void> completeOnboarding() async {
    onboardingCompleted.value = true;
    await _preferences?.setBool(_userScopedKey(_onboardingCompletedKey), true);
  }

  Future<void> updateUserProgress(UserProgress value) async {
    userProgress.value = value;
    await _cacheUserProgress(value);

    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      return;
    }

    try {
      await Supabase.instance.client.from('profiles').upsert({
        'id': currentUser.id,
        'email': currentUser.email,
        'display_name': value.userName,
        'fitness_level': value.fitnessLevel,
        'height': value.height,
        'weight': value.weight,
      });
    } catch (e) {
      // Log error but keep local value
      debugPrint('Error updating profile: $e');
    }
  }

  Future<void> _syncUserProgressFromSupabase() async {
    final currentUser = Supabase.instance.client.auth.currentUser;

    if (currentUser == null) {
      userProgress.value = const UserProgress();
      return;
    }

    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('display_name, fitness_level, height, weight')
          .eq('id', currentUser.id)
          .maybeSingle();

      if (response == null) {
        return;
      }

      final remoteProgress = UserProgress(
        userName: response['display_name'] as String? ?? 'Атлет',
        fitnessLevel: response['fitness_level'] as String? ?? 'Средний',
        height: response['height'] as int? ?? 175,
        weight: response['weight'] as int? ?? 75,
      );

      userProgress.value = remoteProgress;
      await _cacheUserProgress(remoteProgress);
    } catch (_) {
      // Keep local cache if network sync is unavailable.
    }
  }

  Future<void> _cacheUserProgress(UserProgress value) async {
    await _preferences?.setString(
      _userScopedKey(_userProgressKey),
      jsonEncode(value.toJson()),
    );
  }

  Future<void> _handleAuthStateChanged() async {
    await _loadStateForCurrentUser();
  }

  Future<void> _loadStateForCurrentUser() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    final currentUserId = currentUser?.id;

    _activeUserId = currentUserId;
    onboardingCompleted.value = _preferences
            ?.getBool(_userScopedKey(_onboardingCompletedKey, currentUserId)) ??
        false;

    final savedUserProgress = _preferences
        ?.getString(_userScopedKey(_userProgressKey, currentUserId));
    if (savedUserProgress != null && savedUserProgress.isNotEmpty) {
      userProgress.value = UserProgress.fromJson(
        jsonDecode(savedUserProgress) as Map<String, dynamic>,
      );
    } else {
      userProgress.value = const UserProgress();
    }

    await _syncUserProgressFromSupabase();
  }

  String _userScopedKey(String baseKey, [String? userId]) {
    final resolvedUserId = userId ?? _activeUserId;
    if (resolvedUserId == null || resolvedUserId.isEmpty) {
      return baseKey;
    }
    return '$baseKey:$resolvedUserId';
  }

  Locale _languageToLocale(String value) {
    switch (value) {
      case 'English':
        return const Locale('en');
      case 'Spanish':
        return const Locale('es');
      case 'French':
        return const Locale('fr');
      case 'German':
        return const Locale('de');
      case 'Русский':
      default:
        return const Locale('ru');
    }
  }
}
