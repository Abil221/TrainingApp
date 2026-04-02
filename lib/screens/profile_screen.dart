import 'package:flutter/material.dart';

import '../app_settings.dart';
import '../models/user_progress.dart';
import '../services/workout_service.dart';
import '../widgets/app_surfaces.dart';
import 'favorites_screen.dart';
import 'friends_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final workoutService = WorkoutService();
  final appSettings = AppSettings();

  @override
  void initState() {
    super.initState();
    workoutService.refreshSocialData();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? const Color(0xFF1A2538).withValues(alpha: 0.8)
        : const Color(0xFFF8FAFC);
    final heroGradientStart =
        isDark ? const Color(0xFF111827) : const Color(0xFFE8EEF5);
    final heroGradientEnd =
        isDark ? const Color(0xFF283548) : const Color(0xFFD4DDE9);

    return ListenableBuilder(
      listenable: workoutService,
      builder: (context, child) {
        final stats = workoutService.getStats();
        final totalWorkouts = stats['totalWorkouts'] ?? 0;
        final totalCalories = stats['totalCalories'] ?? 0;
        final totalDuration = stats['totalDuration'] ?? 0;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Профиль'),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
            ],
          ),
          body: AppScreenBackground(
            child: ValueListenableBuilder<UserProgress>(
              valueListenable: appSettings.userProgress,
              builder: (context, progress, child) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: LinearGradient(
                      colors: [heroGradientStart, heroGradientEnd],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 34,
                            backgroundColor: isDark
                                ? const Color(0xFFFF6B35)
                                : const Color(0xFF111827),
                            child: Icon(
                              Icons.person_rounded,
                              size: 34,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFFFAF6F1),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  progress.userName,
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF111827),
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Уровень подготовки: ${progress.fitnessLevel}',
                                  style: TextStyle(
                                    color: isDark
                                        ? const Color(0xFFD1D5DB)
                                        : const Color(0xFF525B6A),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(
                            child: _ProfileHeroStat(
                              value: '$totalWorkouts',
                              label: 'тренировок',
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ProfileHeroStat(
                              value: _formatCompact(totalCalories),
                              label: 'калорий',
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ProfileHeroStat(
                              value: '${totalDuration ~/ 3600}ч',
                              label: 'времени',
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        title: 'Рост',
                        value: '${progress.height} см',
                        color: isDark
                            ? const Color(0xFF60A5FA)
                            : const Color(0xFF111827),
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricCard(
                        title: 'Вес',
                        value: '${progress.weight} кг',
                        color: const Color(0xFFFF6B35),
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricCard(
                        title: 'BMI',
                        value: progress.bmi.toStringAsFixed(1),
                        color: const Color(0xFF2A9D8F),
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: cardColor,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Быстрые действия',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color:
                              isDark ? Colors.white : const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _ActionTile(
                        icon: Icons.favorite_rounded,
                        title: 'Избранные тренировки',
                        subtitle: 'Быстрый доступ к сохранённым упражнениям',
                        color: const Color(0xFFE63946),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const FavoritesScreen(),
                            ),
                          );
                        },
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),
                      _ActionTile(
                        icon: Icons.edit_rounded,
                        title: 'Редактировать профиль',
                        subtitle: 'Имя, рост, вес и уровень подготовки',
                        color: isDark
                            ? const Color(0xFF60A5FA)
                            : const Color(0xFF111827),
                        onTap: () => _showEditProfileDialog(progress),
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),
                      ValueListenableBuilder<int>(
                        valueListenable:
                            workoutService.incomingFriendRequestsCount,
                        builder: (context, pendingCount, child) {
                          return _ActionTile(
                            icon: Icons.people_alt_rounded,
                            title: 'Друзья и заявки',
                            subtitle:
                                'Поиск пользователей, входящие заявки и список друзей',
                            color: const Color(0xFF2A9D8F),
                            badgeText:
                                pendingCount > 0 ? '$pendingCount новых' : null,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const FriendsScreen(),
                                ),
                              );
                            },
                            isDark: isDark,
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _ActionTile(
                        icon: Icons.settings_rounded,
                        title: 'Настройки приложения',
                        subtitle: 'Уведомления, язык и параметры интерфейса',
                        color: const Color(0xFFFF6B35),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SettingsScreen(),
                            ),
                          );
                        },
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
              ],
            );
              },
            ),
          ),
        );
      },
    );
  }

  String _formatCompact(int value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return '$value';
  }

  void _showEditProfileDialog(UserProgress currentProgress) {
    final nameController =
        TextEditingController(text: currentProgress.userName);
    final levelController =
        TextEditingController(text: currentProgress.fitnessLevel);
    final heightController =
        TextEditingController(text: currentProgress.height.toString());
    final weightController =
        TextEditingController(text: currentProgress.weight.toString());

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Редактировать профиль'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Имя',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: levelController,
                decoration: const InputDecoration(
                  labelText: 'Уровень подготовки',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: heightController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Рост (см)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: weightController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Вес (кг)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final updatedProgress = currentProgress.copyWith(
                userName: nameController.text.trim().isEmpty
                    ? currentProgress.userName
                    : nameController.text.trim(),
                fitnessLevel: levelController.text.trim().isEmpty
                    ? currentProgress.fitnessLevel
                    : levelController.text.trim(),
                height: _parseMetric(
                  heightController.text,
                  fallback: currentProgress.height,
                  min: 50,
                  max: 260,
                ),
                weight: _parseMetric(
                  weightController.text,
                  fallback: currentProgress.weight,
                  min: 20,
                  max: 400,
                ),
              );

              await appSettings.updateUserProgress(updatedProgress);
              if (!mounted) {
                return;
              }

              Navigator.of(context).pop();
              messenger.showSnackBar(
                const SnackBar(content: Text('Профиль обновлён')),
              );
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  int _parseMetric(
    String rawValue, {
    required int fallback,
    required int min,
    required int max,
  }) {
    final parsedValue = int.tryParse(rawValue.trim());
    if (parsedValue == null || parsedValue < min || parsedValue > max) {
      return fallback;
    }

    return parsedValue;
  }
}

class _ProfileHeroStat extends StatelessWidget {
  final String value;
  final String label;
  final bool isDark;

  const _ProfileHeroStat({
    required this.value,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF111827),
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF6B7280),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final bool isDark;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: isDark
            ? color.withValues(alpha: 0.1)
            : color.withValues(alpha: 0.08),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.2 : 0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final String? badgeText;
  final VoidCallback onTap;
  final bool isDark;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.badgeText,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark
          ? const Color(0xFF1F2937).withValues(alpha: 0.6)
          : const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              color:
                                  isDark ? Colors.white : const Color(0xFF111827),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (badgeText != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              badgeText!,
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFF9CA3AF)
                            : const Color(0xFF6B7280),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color:
                    isDark ? const Color(0xFF6B7280) : const Color(0xFFD1D5DB),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
