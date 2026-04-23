import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_goal.dart';
import '../services/goal_service.dart';
import '../widgets/goal_card.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GoalService>(
      builder: (context, goalService, child) {
        final activeGoals = goalService.activeGoals;
        final completedGoals = goalService.completedGoals;
        final weightHistory = goalService.weightHistory;

        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            title: const Text('Цели и Прогресс'),
            centerTitle: true,
            elevation: 0,
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Активные'),
                Tab(text: 'Завершённые'),
                Tab(text: 'Вес'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              // Active Goals
              _buildGoalsList(
                context,
                activeGoals,
                isEmpty: activeGoals.isEmpty,
              ),

              // Completed Goals
              _buildGoalsList(
                context,
                completedGoals,
                isEmpty: completedGoals.isEmpty,
              ),

              // Weight Tracker
              _buildWeightTracker(context, weightHistory, goalService),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              if (_tabController.index == 0) {
                _showCreateGoalDialog(context);
              } else if (_tabController.index == 2) {
                _showRecordWeightDialog(context);
              }
            },
            child: Icon(
              _tabController.index == 2 ? Icons.add : Icons.add,
            ),
          ),
        );
      },
    );
  }

  Widget _buildGoalsList(
    BuildContext context,
    List<UserGoal> goals, {
    required bool isEmpty,
  }) {
    if (isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.flag_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Нет целей',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: goals.length,
      itemBuilder: (context, index) {
        final goal = goals[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GoalCard(
            goal: goal,
            onEdit: () {
              _showEditGoalDialog(context, goal);
            },
            onDelete: () {
              _showDeleteConfirmation(context, goal.id);
            },
          ),
        );
      },
    );
  }

  Widget _buildWeightTracker(
    BuildContext context,
    List<dynamic> weightHistory,
    GoalService goalService,
  ) {
    if (weightHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.scale,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Нет записей о весе',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Добавьте первую запись',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    final change = goalService.getWeightChange();
    final avgWeight7 = goalService.getAverageWeight(7);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Statistics Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade400, Colors.blue.shade600],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Статистика',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Текущий вес',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${weightHistory.first.weight} кг',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Изменение',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        change != null
                            ? '${change > 0 ? '+' : ''}${change.toStringAsFixed(1)} кг'
                            : 'Нет данных',
                        style: TextStyle(
                          color: change != null && change < 0
                              ? Colors.greenAccent
                              : Colors.red.shade200,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ср. за 7 дней',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${avgWeight7.toStringAsFixed(1)} кг',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'История',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        ...weightHistory.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${entry.weight} кг',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (entry.notes != null && entry.notes!.isNotEmpty)
                        Text(
                          entry.notes!,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                  Text(
                    _formatDate(entry.recordedAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  void _showCreateGoalDialog(BuildContext context) {
    String goalType = GoalType.weightLoss.value;
    String name = '';
    String description = '';
    int targetValue = 0;
    int currentValue = 0;
    String unit = 'кг';
    DateTime deadline = DateTime.now().add(const Duration(days: 30));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Новая цель'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<String>(
                  value: goalType,
                  isExpanded: true,
                  items: [
                    DropdownMenuItem(
                      value: GoalType.weightLoss.value,
                      child: Text(GoalType.weightLoss.displayName),
                    ),
                    DropdownMenuItem(
                      value: GoalType.muscleGain.value,
                      child: Text(GoalType.muscleGain.displayName),
                    ),
                    DropdownMenuItem(
                      value: GoalType.endurance.value,
                      child: Text(GoalType.endurance.displayName),
                    ),
                    DropdownMenuItem(
                      value: GoalType.strength.value,
                      child: Text(GoalType.strength.displayName),
                    ),
                    DropdownMenuItem(
                      value: GoalType.flexibility.value,
                      child: Text(GoalType.flexibility.displayName),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        goalType = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Название',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => name = v,
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Описание',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => description = v,
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Текущее',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (v) => currentValue = int.tryParse(v) ?? 0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Цель',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (v) => targetValue = int.tryParse(v) ?? 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final selectedDate = await showDatePicker(
                      context: context,
                      initialDate: deadline,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (selectedDate != null) {
                      setState(() {
                        deadline = selectedDate;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Дедлайн: ${deadline.day}.${deadline.month}.${deadline.year}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const Icon(Icons.calendar_today, size: 20),
                      ],
                    ),
                  ),
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
                if (name.isNotEmpty && targetValue > 0) {
                  try {
                    await context.read<GoalService>().createGoal(
                          goalType: GoalType.fromString(goalType),
                          name: name,
                          description: description,
                          targetValue: targetValue.toDouble(),
                          currentValue: currentValue.toDouble(),
                          unit: unit,
                          deadline: deadline,
                        );
                    if (!context.mounted) {
                      return;
                    }
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Цель создана!')),
                    );
                  } catch (e) {
                    if (!context.mounted) {
                      return;
                    }
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

  void _showEditGoalDialog(BuildContext context, UserGoal goal) {
    String name = goal.name;
    String description = goal.description;
    int currentValue = goal.currentValue.toInt();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Обновить прогресс'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: TextEditingController(text: name),
              decoration: const InputDecoration(
                labelText: 'Название',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => name = v,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: TextEditingController(text: currentValue.toString()),
              decoration: const InputDecoration(
                labelText: 'Текущее значение',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (v) => currentValue = int.tryParse(v) ?? 0,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await context.read<GoalService>().updateGoal(
                      goalId: goal.id,
                      name: name,
                      currentValue: currentValue.toDouble(),
                      description: description,
                    );
                if (!context.mounted) {
                  return;
                }
                Navigator.pop(context);
              } catch (e) {
                if (!context.mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Ошибка: $e')),
                );
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  void _showRecordWeightDialog(BuildContext context) {
    int weight = 0;
    String notes = '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Записать вес'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Вес (кг)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (v) => weight = int.tryParse(v) ?? 0,
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Заметки (опционально)',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => notes = v,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (weight > 0) {
                try {
                  await context.read<GoalService>().recordWeight(
                        null,
                        weight,
                        notes: notes.isNotEmpty ? notes : null,
                      );
                  if (!context.mounted) {
                    return;
                  }
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Вес записан!')),
                  );
                } catch (e) {
                  if (!context.mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ошибка: $e')),
                  );
                }
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String goalId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить цель?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<GoalService>().deleteGoal(goalId);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Сегодня';
    }
    return '${date.day}.${date.month}.${date.year}';
  }
}
