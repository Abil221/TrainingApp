import 'package:flutter/material.dart';

import '../services/workout_service.dart';
import '../widgets/app_surfaces.dart';
import 'favorites_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final workoutService = WorkoutService();
  String userName = 'Атлет';
  String fitnessLevel = 'Средний';
  int height = 175;
  int weight = 75;

  @override
  Widget build(BuildContext context) {
    final stats = workoutService.getStats();
    final totalWorkouts = stats['totalWorkouts'] ?? 0;
    final totalCalories = stats['totalCalories'] ?? 0;
    final totalDuration = stats['totalDuration'] ?? 0;
    final bmi = (weight / ((height / 100) * (height / 100))).toStringAsFixed(1);
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark 
        ? const Color(0xFF1A2538).withValues(alpha: 0.8)
        : const Color(0xFFF8FAFC);
    final heroGradientStart = isDark ? const Color(0xFF111827) : const Color(0xFFE8EEF5);
    final heroGradientEnd = isDark ? const Color(0xFF283548) : const Color(0xFFD4DDE9);

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
        child: ListView(
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
                              userName,
                              style: TextStyle(
                                color: isDark ? Colors.white : const Color(0xFF111827),
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Уровень подготовки: $fitnessLevel',
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
                    value: '$height см',
                    color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF111827),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    title: 'Вес',
                    value: '$weight кг',
                    color: const Color(0xFFFF6B35),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    title: 'BMI',
                    value: bmi,
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
                      color: isDark ? Colors.white : const Color(0xFF111827),
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
                            builder: (_) => const FavoritesScreen()),
                      );
                    },
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _ActionTile(
                    icon: Icons.edit_rounded,
                    title: 'Редактировать профиль',
                    subtitle: 'Имя, рост, вес и уровень подготовки',
                    color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF111827),
                    onTap: _showEditProfileDialog,
                    isDark: isDark,
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
                            builder: (_) => const SettingsScreen()),
                      );
                    },
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCompact(int value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return '$value';
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: userName);
    final levelController = TextEditingController(text: fitnessLevel);
    final heightController = TextEditingController(text: height.toString());
    final weightController = TextEditingController(text: weight.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                userName = nameController.text.trim().isEmpty
                    ? userName
                    : nameController.text.trim();
                fitnessLevel = levelController.text.trim().isEmpty
                    ? fitnessLevel
                    : levelController.text.trim();
                
                // Update height
                final newHeight = int.tryParse(heightController.text.trim());
                if (newHeight != null && newHeight > 0) {
                  height = newHeight;
                }
                
                // Update weight
                final newWeight = int.tryParse(weightController.text.trim());
                if (newWeight != null && newWeight > 0) {
                  weight = newWeight;
                }
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Профиль обновлён')),
              );
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
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
              color: isDark
                  ? const Color(0xFFD1D5DB)
                  : const Color(0xFF6B7280),
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
              color: isDark
                  ? const Color(0xFF9CA3AF)
                  : const Color(0xFF6B7280),
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
  final VoidCallback onTap;
  final bool isDark;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
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
                    Text(
                      title,
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF111827),
                        fontWeight: FontWeight.w800,
                      ),
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
                color: isDark
                    ? const Color(0xFF6B7280)
                    : const Color(0xFFD1D5DB),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
