import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/workout.dart';
import '../models/workout_plan.dart';
import '../services/workout_plan_service.dart';
import '../widgets/workout_plan_card.dart';

class WorkoutPlansScreen extends StatefulWidget {
  const WorkoutPlansScreen({super.key});

  @override
  State<WorkoutPlansScreen> createState() => _WorkoutPlansScreenState();
}

class _WorkoutPlansScreenState extends State<WorkoutPlansScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<WorkoutPlanService>(
      builder: (context, workoutPlanService, child) {
        final plans = workoutPlanService.userPlans;
        final activePlan = workoutPlanService.activePlan;

        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            title: const Text('Планы тренировок'),
            centerTitle: true,
            elevation: 0,
          ),
          body: plans.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.fitness_center,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Нет планов тренировок',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Создайте первый план прямо сейчас',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: plans.length,
                  itemBuilder: (context, index) {
                    final plan = plans[index];
                    final workoutCount = plan.days?.length ?? 0;
                    final isActive = activePlan?.id == plan.id;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: WorkoutPlanCard(
                        plan: plan,
                        workoutCount: workoutCount,
                        isActive: isActive,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => ChangeNotifierProvider.value(
                                value: workoutPlanService,
                                child: _PlanDetailScreen(planId: plan.id),
                              ),
                            ),
                          );
                        },
                        onEdit: () =>
                            _showEditPlanDialog(context, plan, workoutPlanService),
                        onDelete: () =>
                            _showDeleteConfirmation(context, plan.id, workoutPlanService),
                        onActivate: isActive
                            ? null
                            : () => workoutPlanService.setActivePlan(plan.id),
                      ),
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showCreatePlanDialog(context, workoutPlanService),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  void _showCreatePlanDialog(BuildContext context, WorkoutPlanService service) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    int weeks = 4;

    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Новый план тренировок'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Название плана',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Описание',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('Длительность: $weeks нед.'),
                    Expanded(
                      child: Slider(
                        value: weeks.toDouble(),
                        min: 1,
                        max: 52,
                        divisions: 51,
                        label: '$weeks',
                        onChanged: (value) =>
                            setState(() => weeks = value.toInt()),
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
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  try {
                    await service.createPlan(
                          name: nameController.text,
                          description: descriptionController.text,
                          durationWeeks: weeks,
                        );
                    if (!context.mounted) return;
                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.pop(context);
                    messenger.showSnackBar(
                      const SnackBar(content: Text('План создан!')),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Ошибка: $e')),
                    );
                  }
                }
              },
              child: const Text('Создать'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditPlanDialog(BuildContext context, WorkoutPlan plan, WorkoutPlanService service) {
    final nameController = TextEditingController(text: plan.name);
    final descriptionController =
        TextEditingController(text: plan.description);
    int weeks = plan.durationWeeks;

    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Изменить план'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Название',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Описание',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('Длительность: $weeks нед.'),
                    Expanded(
                      child: Slider(
                        value: weeks.toDouble(),
                        min: 1,
                        max: 52,
                        divisions: 51,
                        label: '$weeks',
                        onChanged: (value) =>
                            setState(() => weeks = value.toInt()),
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
            ElevatedButton(
              onPressed: () {
                service.updatePlan(
                      planId: plan.id,
                      name: nameController.text,
                      description: descriptionController.text,
                      durationWeeks: weeks,
                    );
                Navigator.pop(context);
              },
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String planId, WorkoutPlanService service) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить план?'),
        content: const Text(
          'Это действие нельзя отменить. Все тренировки в этом плане будут удалены.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              service.deletePlan(planId);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}

// ─── Экран деталей плана ─────────────────────────────────────────────────────

class _PlanDetailScreen extends StatefulWidget {
  final String planId;

  const _PlanDetailScreen({required this.planId});

  @override
  State<_PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends State<_PlanDetailScreen> {
  static const _dayNames = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
  static const _dayNamesFull = [
    'Понедельник',
    'Вторник',
    'Среда',
    'Четверг',
    'Пятница',
    'Суббота',
    'Воскресенье',
  ];

  int _selectedDay = 0;
  List<Workout> _availableWorkouts = [];
  bool _loadingWorkouts = true;

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
  }

  Future<void> _loadWorkouts() async {
    final service = context.read<WorkoutPlanService>();
    final workouts = await service.loadAvailableWorkouts();
    if (mounted) {
      setState(() {
        _availableWorkouts = workouts;
        _loadingWorkouts = false;
      });
    }
  }

  WorkoutPlan? _getPlan(WorkoutPlanService service) {
    try {
      return service.userPlans.firstWhere((p) => p.id == widget.planId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkoutPlanService>(
      builder: (context, service, _) {
        final plan = _getPlan(service);
        if (plan == null) {
          return const Scaffold(
            body: Center(child: Text('План не найден')),
          );
        }

        final dayWorkouts = plan.days
                ?.where((d) => d.dayOfWeek == _selectedDay)
                .toList() ??
            [];

        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            title: Text(plan.name),
            centerTitle: true,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () => _showPlanInfo(context, plan),
              ),
            ],
          ),
          body: Column(
            children: [
              _buildDaySelector(plan),
              Expanded(
                child: dayWorkouts.isEmpty
                    ? _buildEmptyDay(context, plan)
                    : _buildDayWorkouts(context, service, dayWorkouts, plan),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _loadingWorkouts
                ? null
                : () => _showAddWorkoutSheet(context, service, plan),
            icon: _loadingWorkouts
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.add),
            label: Text('Добавить в ${_dayNames[_selectedDay]}'),
          ),
        );
      },
    );
  }

  Widget _buildDaySelector(WorkoutPlan plan) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SizedBox(
        height: 64,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 7,
          itemBuilder: (context, day) {
            final isSelected = _selectedDay == day;
            final count =
                plan.days?.where((d) => d.dayOfWeek == day).length ?? 0;

            return GestureDetector(
              onTap: () => setState(() => _selectedDay = day),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 8),
                width: 52,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14),
                  border: isSelected
                      ? null
                      : Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _dayNames[day],
                      style: TextStyle(
                        color:
                            isSelected ? Colors.white : Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    if (count > 0) ...[
                      const SizedBox(height: 4),
                      Container(
                        width: 20,
                        height: 18,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.3)
                              : Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Center(
                          child: Text(
                            '$count',
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.blue.shade700,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyDay(BuildContext context, WorkoutPlan plan) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_available, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Нет тренировок',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _dayNamesFull[_selectedDay],
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadingWorkouts
                ? null
                : () => _showAddWorkoutSheet(
                    context, context.read<WorkoutPlanService>(), plan),
            icon: const Icon(Icons.add),
            label: const Text('Добавить тренировку'),
          ),
        ],
      ),
    );
  }

  Widget _buildDayWorkouts(
    BuildContext context,
    WorkoutPlanService service,
    List<WorkoutPlanDay> dayWorkouts,
    WorkoutPlan plan,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: dayWorkouts.length,
      itemBuilder: (context, index) {
        final planDay = dayWorkouts[index];
        final workout = planDay.workout;

        return Dismissible(
          key: Key(planDay.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.red.shade400,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.delete_outline, color: Colors.white),
          ),
          onDismissed: (_) async {
            final messenger = ScaffoldMessenger.of(context);
            try {
              await service.removeWorkoutFromDay(planDay.id);
            } catch (e) {
              if (mounted) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Ошибка удаления: $e')),
                );
              }
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _categoryColor(workout?.category).withValues(
                    alpha: 0.12,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _categoryIcon(workout?.category),
                  color: _categoryColor(workout?.category),
                ),
              ),
              title: Text(
                workout?.title ?? 'Тренировка',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              subtitle: workout != null
                  ? Text(
                      '${workout.category}  •  ${_formatDuration(workout.duration)}  •  ${workout.caloriesBurned} ккал',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    )
                  : null,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _DifficultyBadge(workout?.difficulty),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.delete_outline,
                        color: Colors.red.shade300, size: 20),
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await service.removeWorkoutFromDay(planDay.id);
                      } catch (e) {
                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(content: Text('Ошибка: $e')),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAddWorkoutSheet(
    BuildContext context,
    WorkoutPlanService service,
    WorkoutPlan plan,
  ) {
    if (_availableWorkouts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нет доступных тренировок')),
      );
      return;
    }

    String? selectedCategory;
    final categories = <String>{
      for (final w in _availableWorkouts) w.category,
    }.toList()
      ..sort();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          final filtered = selectedCategory == null
              ? _availableWorkouts
              : _availableWorkouts
                  .where((w) => w.category == selectedCategory)
                  .toList();

          return DraggableScrollableSheet(
            initialChildSize: 0.75,
            maxChildSize: 0.95,
            minChildSize: 0.5,
            expand: false,
            builder: (_, scrollController) => Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Тренировки на ${_dayNamesFull[_selectedDay]}',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _CategoryChip(
                          label: 'Все',
                          selected: selectedCategory == null,
                          onTap: () =>
                              setSheetState(() => selectedCategory = null),
                        ),
                        ...categories.map(
                          (cat) => _CategoryChip(
                            label: cat,
                            selected: selectedCategory == cat,
                            onTap: () =>
                                setSheetState(() => selectedCategory = cat),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: filtered.length,
                      itemBuilder: (_, index) {
                        final workout = filtered[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 6,
                          ),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: _categoryColor(workout.category)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _categoryIcon(workout.category),
                              color: _categoryColor(workout.category),
                              size: 22,
                            ),
                          ),
                          title: Text(
                            workout.title,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${workout.category}  •  ${_formatDuration(workout.duration)}  •  ${workout.caloriesBurned} ккал',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          trailing: _DifficultyBadge(workout.difficulty),
                          onTap: () async {
                            Navigator.pop(sheetContext);
                            final messenger = ScaffoldMessenger.of(context);
                            try {
                              await service.addWorkoutToDay(
                                planId: plan.id,
                                dayOfWeek: _selectedDay,
                                workoutId: workout.id,
                              );
                              if (mounted) {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '«${workout.title}» добавлена в ${_dayNames[_selectedDay]}',
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                messenger.showSnackBar(
                                  SnackBar(content: Text('Ошибка: $e')),
                                );
                              }
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showPlanInfo(BuildContext context, WorkoutPlan plan) {
    final totalWorkouts = plan.days?.length ?? 0;
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(plan.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (plan.description.isNotEmpty) ...[
              Text(plan.description,
                  style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 16),
            ],
            _InfoRow(
                icon: Icons.calendar_month,
                label: 'Длительность',
                value: '${plan.durationWeeks} недель'),
            _InfoRow(
                icon: Icons.fitness_center,
                label: 'Всего тренировок',
                value: '$totalWorkouts'),
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

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    if (m < 60) return '$m мин';
    return '${m ~/ 60}ч ${m % 60}мин';
  }

  Color _categoryColor(String? category) {
    switch (category) {
      case 'Cardio':
        return Colors.orange;
      case 'Strength':
        return Colors.blue;
      case 'Flexibility':
        return Colors.green;
      case 'Fullbody':
        return Colors.purple;
      default:
        if (category?.startsWith('Split') ?? false) return Colors.red;
        return Colors.teal;
    }
  }

  IconData _categoryIcon(String? category) {
    switch (category) {
      case 'Cardio':
        return Icons.directions_run;
      case 'Strength':
        return Icons.fitness_center;
      case 'Flexibility':
        return Icons.self_improvement;
      case 'Fullbody':
        return Icons.sports_gymnastics;
      default:
        return Icons.sports;
    }
  }
}

// ─── Вспомогательные виджеты ──────────────────────────────────────────────────

class _DifficultyBadge extends StatelessWidget {
  final DifficultyLevel? difficulty;

  const _DifficultyBadge(this.difficulty);

  @override
  Widget build(BuildContext context) {
    if (difficulty == null) return const SizedBox.shrink();
    final (label, color) = switch (difficulty!) {
      DifficultyLevel.easy => ('Легко', Colors.green),
      DifficultyLevel.medium => ('Средне', Colors.orange),
      DifficultyLevel.hard => ('Сложно', Colors.red),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.blue : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.grey.shade700,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          const Spacer(),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
