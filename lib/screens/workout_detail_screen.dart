import 'dart:async';

import 'package:flutter/material.dart';

import '../models/workout_log_entry.dart';
import '../models/workout.dart';
import '../services/workout_service.dart';
import '../widgets/app_surfaces.dart';

class WorkoutDetailScreen extends StatefulWidget {
  final Workout workout;
  const WorkoutDetailScreen({super.key, required this.workout});

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  late int remainingSeconds;
  Timer? timer;
  bool isRunning = false;

  @override
  void initState() {
    super.initState();
    remainingSeconds = widget.workout.duration;
  }

  void startTimer() {
    if (isRunning) return; // Prevent multiple timers
    timer?.cancel();
    setState(() => isRunning = true);
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (remainingSeconds > 0) {
        setState(() => remainingSeconds--);
      } else {
        timer?.cancel();
        setState(() => isRunning = false);
        _showCompletionDialog();
      }
    });
  }

  void pauseTimer() {
    if (timer != null && timer!.isActive) {
      timer?.cancel();
      setState(() => isRunning = false);
    }
  }

  void resetTimer() {
    timer?.cancel();
    setState(() {
      remainingSeconds = widget.workout.duration;
      isRunning = false;
    });
  }

  void _showCompletionDialog() {
    _showWorkoutLogDialog(
      title: 'Отличная работа!',
      subtitle:
          'Зафиксируй результат тренировки, чтобы он попал в календарь и графики.',
      initialDurationSeconds: widget.workout.duration,
    );
  }

  void _showWorkoutLogDialog({
    required String title,
    required String subtitle,
    required int initialDurationSeconds,
  }) {
    final durationMinutes = (initialDurationSeconds / 60).ceil().clamp(1, 600);
    final caloriesController = TextEditingController(
      text: widget.workout.caloriesBurned.toString(),
    );
    final durationController = TextEditingController(
      text: durationMinutes.toString(),
    );
    final progressController = TextEditingController();
    final unitController = TextEditingController(text: _defaultProgressUnit());
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                subtitle,
                style: const TextStyle(height: 1.4),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: durationController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Длительность, мин',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: caloriesController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Калории',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: progressController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Результат',
                        hintText: 'Например 12 или 42.5',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: unitController,
                      decoration: const InputDecoration(
                        labelText: 'Ед. измерения',
                        hintText: 'повт., кг, км',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                minLines: 2,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Комментарий',
                  hintText: 'Самочувствие, темп, рабочий вес',
                  border: OutlineInputBorder(),
                ),
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
            onPressed: () {
              final durationValue =
                  int.tryParse(durationController.text.trim()) ??
                      durationMinutes;
              final caloriesValue =
                  int.tryParse(caloriesController.text.trim()) ??
                      widget.workout.caloriesBurned;
              final progressValue = double.tryParse(
                  progressController.text.trim().replaceAll(',', '.'));

              WorkoutService().completeWorkoutOnDate(
                widget.workout.id,
                DateTime.now(),
                durationSeconds: durationValue.clamp(1, 600) * 60,
                caloriesBurned: caloriesValue.clamp(0, 5000),
                progressValue: progressValue,
                progressUnit: unitController.text.trim(),
                resultNote: noteController.text.trim(),
              );

              if (!mounted) {
                return;
              }

              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Результат тренировки сохранён'),
                ),
              );
              setState(() {});
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  String _defaultProgressUnit() {
    if (widget.workout.title.toLowerCase().contains('бег')) {
      return 'км';
    }
    if (widget.workout.description.contains('x')) {
      return 'повт.';
    }
    return 'ед.';
  }

  int _suggestedDurationSeconds() {
    final elapsed = widget.workout.duration - remainingSeconds;
    if (elapsed > 0) {
      return elapsed;
    }
    return widget.workout.duration;
  }

  String _getDifficultyColor() {
    switch (widget.workout.difficulty) {
      case DifficultyLevel.easy:
        return '#4CAF50';
      case DifficultyLevel.medium:
        return '#FF9800';
      case DifficultyLevel.hard:
        return '#F44336';
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final progress =
        (widget.workout.duration - remainingSeconds) / widget.workout.duration;
    final difficultyColor =
        Color(int.parse('0xFF${_getDifficultyColor().substring(1)}'));
    final recentLogs = WorkoutService()
        .getWorkoutLogsForWorkout(widget.workout.id)
        .reversed
        .take(3)
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.workout.title),
      ),
      body: AppScreenBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: difficultyColor.withValues(alpha: 0.18),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Stack(
                  children: [
                    Image.asset(
                      widget.workout.image,
                      width: double.infinity,
                      height: 280,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: double.infinity,
                          height: 280,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF111827), Color(0xFF374151)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Icon(
                            Icons.fitness_center,
                            size: 56,
                            color: Colors.white70,
                          ),
                        );
                      },
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.08),
                              Colors.black.withValues(alpha: 0.68),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 18,
                      top: 18,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: difficultyColor,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          widget.workout.difficultyString,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.workout.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.workout.description,
                            style: const TextStyle(
                              color: Color(0xFFE5E7EB),
                              fontSize: 16,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _DetailMetricCard(
                    icon: Icons.local_fire_department,
                    label: 'энергия',
                    value: '${widget.workout.caloriesBurned} ккал',
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DetailMetricCard(
                    icon: Icons.timer_outlined,
                    label: 'длительность',
                    value: '${widget.workout.duration ~/ 60} мин',
                    color: const Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DetailMetricCard(
                    icon: Icons.repeat,
                    label: 'завершено',
                    value: '${widget.workout.completedCount}x',
                    color: const Color(0xFF059669),
                  ),
                ),
              ],
            ),
            if (widget.workout.equipment.isNotEmpty) ...[
              const SizedBox(height: 20),
              _DetailSection(
                title: 'Оборудование',
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: widget.workout.equipment
                      .map(
                        (item) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            item,
                            style: TextStyle(
                              color: isDark
                                  ? const Color(0xFFE5E7EB)
                                  : const Color(0xFF374151),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
            const SizedBox(height: 20),
            _DetailSection(
              title: 'Таймер',
              child: Column(
                children: [
                  TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0, end: progress),
                    duration: const Duration(milliseconds: 450),
                    builder: (context, double value, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 170,
                            height: 170,
                            child: CircularProgressIndicator(
                              value: value,
                              strokeWidth: 10,
                              color: const Color(0xFFFF6B35),
                              backgroundColor: isDark
                                  ? const Color(0xFF243041)
                                  : const Color(0xFFE5E7EB),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _formatDuration(remainingSeconds),
                                style: const TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isRunning ? 'ИДЕТ СЕЙЧАС' : 'ГОТОВ К СТАРТУ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isRunning
                                      ? const Color(0xFF059669)
                                      : const Color(0xFFFF6B35),
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: isRunning ? pauseTimer : startTimer,
                          icon:
                              Icon(isRunning ? Icons.pause : Icons.play_arrow),
                          label: Text(isRunning ? 'Пауза' : 'Старт'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: resetTimer,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Сброс'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.colorScheme.onSurface,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFD1D5DB),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _showWorkoutLogDialog(
                          title: 'Записать результат',
                          subtitle:
                              'Сохрани длительность, калории и свой результат по этой тренировке.',
                          initialDurationSeconds: _suggestedDurationSeconds(),
                        );
                      },
                      icon: const Icon(Icons.edit_note_rounded),
                      label: const Text('Записать результат'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.onSurface,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFD1D5DB),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (widget.workout.instructions.isNotEmpty) ...[
              const SizedBox(height: 20),
              _DetailSection(
                title: 'Инструкция',
                child: Text(
                  widget.workout.instructions,
                  style: const TextStyle(height: 1.5, fontSize: 15),
                ),
              ),
            ],
            if (recentLogs.isNotEmpty) ...[
              const SizedBox(height: 20),
              _DetailSection(
                title: 'Последние результаты',
                child: Column(
                  children: recentLogs
                      .map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ResultLogTile(entry: entry),
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}

class _ResultLogTile extends StatelessWidget {
  final WorkoutLogEntry entry;

  const _ResultLogTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateLabel =
        '${entry.completedAt.day.toString().padLeft(2, '0')}.${entry.completedAt.month.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF243041) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                dateLabel,
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF111827),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                '${entry.caloriesBurned} ккал',
                style: const TextStyle(
                  color: Color(0xFFFF6B35),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${entry.durationSeconds ~/ 60} мин',
            style: TextStyle(
              color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF6B7280),
            ),
          ),
          if (entry.progressValue != null) ...[
            const SizedBox(height: 6),
            Text(
              'Результат: ${entry.progressValue} ${entry.progressUnit}'.trim(),
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF111827),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (entry.resultNote.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              entry.resultNote,
              style: TextStyle(
                color:
                    isDark ? const Color(0xFFD1D5DB) : const Color(0xFF6B7280),
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _DetailSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF243041) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _DetailMetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _DetailMetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF243041) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
