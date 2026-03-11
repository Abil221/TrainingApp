import 'package:flutter/material.dart';

import '../services/workout_service.dart';
import '../widgets/app_surfaces.dart';
import '../widgets/workout_card.dart';

class GymScreen extends StatelessWidget {
  const GymScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final workoutService = WorkoutService();

    return Scaffold(
      appBar: AppBar(title: const Text('Зал')),
      body: AppScreenBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: const LinearGradient(
                  colors: [Color(0xFF111827), Color(0xFF283548)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B35).withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'GYM MODE',
                      style: TextStyle(
                        color: Color(0xFFFFB089),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Тренировки в зале',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Переходи в Split для точечной работы по мышечным группам или выбирай Fullbody для полной нагрузки на всё тело.',
                    style: TextStyle(
                      color: Color(0xFFD1D5DB),
                      fontSize: 15,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _GymStatCard(
                          value: '${workoutService.getGymSplitGroups().length}',
                          label: 'split-групп',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _GymStatCard(
                          value:
                              '${workoutService.getFullBodyWorkouts().length}',
                          label: 'fullbody',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _ModeCard(
              title: 'Split',
              subtitle: 'Разделение по мышечным группам',
              icon: Icons.view_carousel_outlined,
              color: const Color(0xFF111827),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const GymSplitScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _ModeCard(
              title: 'Fullbody',
              subtitle: 'Комплексные тренировки на все группы мышц',
              icon: Icons.all_inclusive,
              color: const Color(0xFFFF6B35),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const GymWorkoutListScreen(
                      title: 'Fullbody',
                      description: 'Тренировки с нагрузкой на все группы мышц.',
                      mode: GymWorkoutListMode.fullbody,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class GymSplitScreen extends StatelessWidget {
  const GymSplitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final splitGroups = WorkoutService().getGymSplitGroups();

    return Scaffold(
      appBar: AppBar(title: const Text('Split тренировки')),
      body: AppScreenBackground(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          itemCount: splitGroups.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final group = splitGroups[index];
            return _SplitGroupTile(
              title: group,
              subtitle: _groupSubtitle(group),
              icon: _groupIcon(group),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GymWorkoutListScreen(
                      title: group,
                      description:
                          'Подборка упражнений для группы мышц: $group.',
                      mode: GymWorkoutListMode.split,
                      splitGroup: group,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  IconData _groupIcon(String group) {
    switch (group) {
      case 'Грудь':
        return Icons.fitness_center;
      case 'Спина':
        return Icons.accessibility_new;
      case 'Ноги':
        return Icons.directions_run;
      case 'Плечи':
        return Icons.pan_tool_alt_outlined;
      case 'Руки':
        return Icons.sports_martial_arts;
      default:
        return Icons.sports_gymnastics;
    }
  }

  String _groupSubtitle(String group) {
    switch (group) {
      case 'Грудь':
        return 'Жимы, разводки и работа на верх груди';
      case 'Спина':
        return 'Тяги для ширины и толщины спины';
      case 'Ноги':
        return 'Базовые движения на квадрицепс, бицепс бедра и ягодицы';
      case 'Плечи':
        return 'Жимы и махи для передней, средней и задней дельты';
      case 'Руки':
        return 'Отдельная нагрузка на бицепс и трицепс';
      default:
        return 'Тренировка по мышечной группе';
    }
  }
}

enum GymWorkoutListMode { split, fullbody }

class GymWorkoutListScreen extends StatefulWidget {
  final String title;
  final String description;
  final GymWorkoutListMode mode;
  final String? splitGroup;

  const GymWorkoutListScreen({
    super.key,
    required this.title,
    required this.description,
    required this.mode,
    this.splitGroup,
  });

  @override
  State<GymWorkoutListScreen> createState() => _GymWorkoutListScreenState();
}

class _GymWorkoutListScreenState extends State<GymWorkoutListScreen> {
  final workoutService = WorkoutService();

  @override
  Widget build(BuildContext context) {
    final workouts = widget.mode == GymWorkoutListMode.fullbody
        ? workoutService.getFullBodyWorkouts()
        : workoutService.getSplitWorkoutsByGroup(widget.splitGroup ?? '');

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: AppScreenBackground(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: appPanelDecoration(
                  context,
                  accent: const Color(0xFF111827),
                  radius: 22,
                ),
                child: Text(
                  widget.description,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: Color(0xFF4B5563),
                  ),
                ),
              ),
            ),
            Expanded(
              child: workouts.isEmpty
                  ? const Center(
                      child: Text(
                        'Пока нет тренировок в этом разделе',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: workouts.length,
                      itemBuilder: (context, index) => WorkoutCard(
                        workout: workouts[index],
                        onFavoriteTap: () {
                          setState(() {
                            workoutService.toggleFavorite(workouts[index].id);
                          });
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Ink(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(
              colors: [color, color.withValues(alpha: 0.84)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFFF3F4F6),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class _SplitGroupTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _SplitGroupTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        tileColor: Colors.white,
        leading: CircleAvatar(
          radius: 26,
          backgroundColor: const Color(0xFFFF6B35).withValues(alpha: 0.12),
          child: Icon(icon, color: const Color(0xFFFF6B35)),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            subtitle,
            style: const TextStyle(height: 1.4),
          ),
        ),
        trailing: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.chevron_right, color: Colors.white),
        ),
        onTap: onTap,
      ),
    );
  }
}

class _GymStatCard extends StatelessWidget {
  final String value;
  final String label;

  const _GymStatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Color(0xFFD1D5DB), fontSize: 12),
          ),
        ],
      ),
    );
  }
}
