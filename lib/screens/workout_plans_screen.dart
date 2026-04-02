import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
                          // Показать детали плана
                          _showPlanDetails(context, plan);
                        },
                        onEdit: () {
                          _showEditPlanDialog(context, plan);
                        },
                        onDelete: () {
                          _showDeleteConfirmation(context, plan.id);
                        },
                        onActivate: isActive
                            ? null
                            : () {
                                workoutPlanService.setActivePlan(plan.id);
                              },
                      ),
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              _showCreatePlanDialog(context);
            },
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  void _showPlanDetails(BuildContext context, WorkoutPlan plan) {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                plan.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                plan.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text(
                          'Длительность',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${plan.durationWeeks} недель',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        const Text(
                          'Упражнений',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${plan.days?.length ?? 0}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Закрыть'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCreatePlanDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    int weeks = 4;

    showDialog(
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
                    const Text('Длительность (недели):'),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Slider(
                        value: weeks.toDouble(),
                        min: 1,
                        max: 52,
                        divisions: 51,
                        label: '$weeks',
                        onChanged: (value) {
                          setState(() {
                            weeks = value.toInt();
                          });
                        },
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
                if (nameController.text.isNotEmpty) {
                  context.read<WorkoutPlanService>().createPlan(
                        userId: '', // Заполняется сервисом
                        name: nameController.text,
                        description: descriptionController.text,
                        durationWeeks: weeks,
                      );
                  Navigator.pop(context);
                }
              },
              child: const Text('Создать'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditPlanDialog(BuildContext context, WorkoutPlan plan) {
    final nameController = TextEditingController(text: plan.name);
    final descriptionController = TextEditingController(text: plan.description);
    int weeks = plan.durationWeeks;

    showDialog(
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
                    const Text('Длительность:'),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Slider(
                        value: weeks.toDouble(),
                        min: 1,
                        max: 52,
                        divisions: 51,
                        label: '$weeks',
                        onChanged: (value) {
                          setState(() {
                            weeks = value.toInt();
                          });
                        },
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
                context.read<WorkoutPlanService>().updatePlan(
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

  void _showDeleteConfirmation(BuildContext context, String planId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить план?'),
        content: const Text(
          'Esta action cannot be undone. All workouts in this plan will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<WorkoutPlanService>().deletePlan(planId);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}
