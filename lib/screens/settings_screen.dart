import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_settings.dart';
import '../widgets/app_surfaces.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool notificationsEnabled;
  late bool soundEnabled;
  late bool darkMode;
  late String selectedLanguage;

  @override
  void initState() {
    super.initState();
    final appSettings = AppSettings();
    notificationsEnabled = appSettings.notificationsEnabled.value;
    soundEnabled = appSettings.soundEnabled.value;
    darkMode = appSettings.isDarkMode;
    selectedLanguage = appSettings.selectedLanguage;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
      ),
      body: AppScreenBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  colors: [Color(0xFF111827), Color(0xFF283548)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Настройки под твой режим',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Настрой приложение под свой ритм: уведомления, язык и интерфейс.',
                    style: TextStyle(
                      color: Color(0xFFD1D5DB),
                      fontSize: 15,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _HeroSettingStat(
                          value: notificationsEnabled ? 'ON' : 'OFF',
                          label: 'напоминания',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _HeroSettingStat(
                          value: soundEnabled ? 'ON' : 'OFF',
                          label: 'звук',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _HeroSettingStat(
                          value: selectedLanguage,
                          label: 'язык',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _FeaturePill(
                    icon: Icons.notifications_active_outlined,
                    label: 'Уведомления',
                    color: const Color(0xFFFF6B35),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _FeaturePill(
                    icon: Icons.language_rounded,
                    label: 'Язык',
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _FeaturePill(
                    icon: Icons.tune_rounded,
                    label: 'Интерфейс',
                    color: const Color(0xFF2A9D8F),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _settingsSection(
              title: 'Уведомления',
              children: [
                _switchTile(
                  title: 'Напоминания о тренировках',
                  subtitle: 'Получать уведомления о запланированных занятиях',
                  value: notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      notificationsEnabled = value;
                    });
                    AppSettings().setNotificationsEnabled(value);
                  },
                ),
                _switchTile(
                  title: 'Звук завершения',
                  subtitle: 'Сигнал после окончания тренировки',
                  value: soundEnabled,
                  onChanged: (value) {
                    setState(() {
                      soundEnabled = value;
                    });
                    AppSettings().setSoundEnabled(value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _settingsSection(
              title: 'Интерфейс',
              children: [
                _switchTile(
                  title: 'Тёмная тема',
                  subtitle: 'Переключает приложение на тёмную спортивную тему',
                  value: darkMode,
                  onChanged: (value) {
                    setState(() {
                      darkMode = value;
                    });
                    AppSettings().setDarkMode(value);
                  },
                ),
                ListTile(
                  title: const Text('Язык'),
                  subtitle: Text(selectedLanguage),
                  trailing:
                      const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: _showLanguageDialog,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _settingsSection(
              title: 'Аккаунт',
              children: [
                ListTile(
                  title: const Text('Текущий пользователь'),
                  subtitle: Text(
                    Supabase.instance.client.auth.currentUser?.email ??
                        'Не авторизован',
                  ),
                ),
                ListTile(
                  title: const Text('Выйти из аккаунта'),
                  subtitle: const Text('Завершить текущую сессию Supabase'),
                  trailing:
                      const Icon(Icons.logout_rounded, color: Color(0xFFE63946)),
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await Supabase.instance.client.auth.signOut();
                    if (!mounted) {
                      return;
                    }
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Вы вышли из аккаунта'),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _settingsSection(
              title: 'О приложении',
              children: [
                const ListTile(
                  title: Text('Версия приложения'),
                  subtitle: Text('1.0.0'),
                ),
                ListTile(
                  title: const Text('Политика конфиденциальности'),
                  trailing:
                      const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Раздел будет добавлен позже')),
                    );
                  },
                ),
                ListTile(
                  title: const Text('Условия использования'),
                  trailing:
                      const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Раздел будет добавлен позже')),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выбери язык'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _languageOption('Русский'),
            _languageOption('English'),
            _languageOption('Spanish'),
            _languageOption('French'),
            _languageOption('German'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  Widget _settingsSection(
      {required String title, required List<Widget> children}) {
    return Container(
      decoration: appPanelDecoration(
        context,
        accent: const Color(0xFF111827),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 6),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF111827),
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _switchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      activeThumbColor: const Color(0xFFFF6B35),
    );
  }

  Widget _languageOption(String language) {
    return ListTile(
      title: Text(language),
      trailing: selectedLanguage == language
          ? const Icon(Icons.check, color: Color(0xFFFF6B35))
          : null,
      onTap: () {
        setState(() {
          selectedLanguage = language;
        });
        AppSettings().setLanguage(language);
        Navigator.pop(context);
      },
    );
  }
}

class _HeroSettingStat extends StatelessWidget {
  final String value;
  final String label;

  const _HeroSettingStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFD1D5DB),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _FeaturePill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }
}
