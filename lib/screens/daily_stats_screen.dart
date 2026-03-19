import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/daily_workout.dart';
import '../models/friend_profile.dart';
import '../models/workout.dart';
import '../models/workout_log_entry.dart';
import '../services/workout_service.dart';
import '../widgets/app_surfaces.dart';

class DailyStatsScreen extends StatefulWidget {
  const DailyStatsScreen({super.key});

  @override
  State<DailyStatsScreen> createState() => _DailyStatsScreenState();
}

class _DailyStatsScreenState extends State<DailyStatsScreen> {
  final workoutService = WorkoutService();
  late DateTime _visibleMonth;
  DateTime? _selectedDate;
  String? _selectedProgressWorkoutId;
  String? _selectedFriendId;
  _AnalyticsRange _selectedRange = _AnalyticsRange.last7Days;

  @override
  void initState() {
    super.initState();
    final trainingDates = workoutService.getAllTrainingDates();
    final initialDate = trainingDates.isNotEmpty
        ? _normalizeDate(trainingDates.first)
        : _normalizeDate(DateTime.now());

    _visibleMonth = DateTime(initialDate.year, initialDate.month);
    _selectedDate = initialDate;

    final progressWorkouts = workoutService.getWorkoutsWithProgressLogs();
    if (progressWorkouts.isNotEmpty) {
      _selectedProgressWorkoutId = progressWorkouts.first.id;
    }

    final friends = workoutService.getFriendProfiles();
    if (friends.isNotEmpty) {
      _selectedFriendId = friends.first.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: workoutService,
      builder: (context, child) {
        final trainingDates = workoutService.getAllTrainingDates();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Статистика'),
          ),
          body: AppScreenBackground(
            child: trainingDates.isEmpty
                ? _EmptyStatsState(isDark: isDark)
                : _buildContent(context, isDark, trainingDates),
          ),
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    bool isDark,
    List<DateTime> trainingDates,
  ) {
    final overallStats = workoutService.getStats();
    final range = _resolveRange(_selectedRange);
    final filteredLogs = _filterLogsByRange(range);
    final previousRange = _previousRange(range);
    final previousLogs = _filterLogsByRange(previousRange);
    final selectedDate = _selectedDate ?? _normalizeDate(trainingDates.first);
    final selectedDailyWorkout = workoutService.getDailyWorkout(selectedDate);
    final streak = workoutService.getTrainingStreak();

    final friendProfiles = workoutService.getFriendProfiles();
    final activeFriend = friendProfiles.isNotEmpty
        ? friendProfiles.firstWhere(
            (friend) => friend.id == _selectedFriendId,
            orElse: () => friendProfiles.first,
          )
        : const FriendProfile(id: 'none', name: 'Друг');

    final friendStats = activeFriend.id != 'none'
        ? workoutService.getFriendStats(activeFriend.id)
        : {'totalWorkouts': 0, 'totalCalories': 0, 'totalDuration': 0};
    final friendStreak = activeFriend.id != 'none'
        ? workoutService.getFriendTrainingStreak(activeFriend.id)
        : 0;
    final sharedTrainingDays = activeFriend.id != 'none'
        ? workoutService.getSharedTrainingDays(activeFriend.id)
        : 0;
    final sharedStreak = activeFriend.id != 'none'
        ? workoutService.getSharedTrainingStreak(activeFriend.id)
        : 0;

    final periodMetrics = _calculatePeriodMetrics(filteredLogs);
    final comparison = _buildComparison(periodMetrics, previousLogs);
    final caloriesSeries = _buildRangeSeries(
      range,
      (date) => _logsForExactDate(filteredLogs, date)
          .fold<double>(0, (sum, entry) => sum + entry.caloriesBurned),
    );
    final durationSeries = _buildRangeSeries(
      range,
      (date) => _logsForExactDate(filteredLogs, date)
          .fold<double>(0, (sum, entry) => sum + (entry.durationSeconds / 60)),
    );
    final progressWorkouts = workoutService.getWorkoutsWithProgressLogs();
    final selectedWorkoutId = progressWorkouts.any(
      (workout) => workout.id == _selectedProgressWorkoutId,
    )
        ? _selectedProgressWorkoutId
        : (progressWorkouts.isNotEmpty ? progressWorkouts.first.id : null);
    final selectedWorkout = selectedWorkoutId == null
        ? null
        : workoutService.getWorkoutById(selectedWorkoutId);
    final progressSeries = selectedWorkoutId == null
        ? const <_ChartPoint>[]
        : _buildProgressSeries(
            workoutService
                .getWorkoutLogsForWorkout(selectedWorkoutId)
                .where((entry) => _isWithinRange(entry.completedAt, range))
                .toList(growable: false),
          );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        _StatsHeroCard(
          totalWorkouts: overallStats['totalWorkouts'] ?? 0,
          totalCalories: overallStats['totalCalories'] ?? 0,
          totalDurationSeconds: overallStats['totalDuration'] ?? 0,
          streak: streak,
        ),
        const SizedBox(height: 20),
        _CompetitionCard(
          activeFriend: activeFriend,
          friends: friendProfiles,
          selectedFriendId: _selectedFriendId,
          onFriendChanged: (value) {
            setState(() {
              _selectedFriendId = value;
            });
          },
          totalWorkouts: overallStats['totalWorkouts'] ?? 0,
          friendWorkouts: friendStats['totalWorkouts'] ?? 0,
          totalCalories: overallStats['totalCalories'] ?? 0,
          friendCalories: friendStats['totalCalories'] ?? 0,
          totalDuration: overallStats['totalDuration'] ?? 0,
          friendDuration: friendStats['totalDuration'] ?? 0,
          streak: streak,
          friendStreak: friendStreak,
          sharedDays: sharedTrainingDays,
          sharedStreak: sharedStreak,
        ),
        const SizedBox(height: 20),
        _AnalyticsFilterBar(
          selectedRange: _selectedRange,
          onChanged: (range) {
            setState(() {
              _selectedRange = range;
            });
          },
        ),
        const SizedBox(height: 16),
        _PeriodOverviewCard(
          title: _rangeTitle(_selectedRange),
          metrics: periodMetrics,
          isDark: isDark,
        ),
        const SizedBox(height: 16),
        _PeriodComparisonCard(
          currentRangeTitle: _rangeShortTitle(_selectedRange),
          previousRangeTitle: _previousRangeTitle(_selectedRange),
          comparison: comparison,
          isDark: isDark,
        ),
        const SizedBox(height: 20),
        _CalendarCard(
          visibleMonth: _visibleMonth,
          selectedDate: selectedDate,
          isDark: isDark,
          hasWorkoutOnDate: workoutService.hasWorkoutOnDate,
          onPreviousMonth: () {
            setState(() {
              _visibleMonth =
                  DateTime(_visibleMonth.year, _visibleMonth.month - 1);
            });
          },
          onNextMonth: () {
            setState(() {
              _visibleMonth =
                  DateTime(_visibleMonth.year, _visibleMonth.month + 1);
            });
          },
          onSelectDate: (date) {
            setState(() {
              _selectedDate = date;
            });
          },
        ),
        const SizedBox(height: 20),
        _ChartCard(
          title: 'Калории: ${_rangeShortTitle(_selectedRange)}',
          subtitle: _rangeSubtitle(_selectedRange, 'калорий'),
          child: _LineTrendChart(
            points: caloriesSeries,
            color: const Color(0xFFFF6B35),
            valueLabelBuilder: (value) => '${value.toInt()} ккал',
          ),
        ),
        const SizedBox(height: 16),
        _ChartCard(
          title: 'Длительность: ${_rangeShortTitle(_selectedRange)}',
          subtitle: _rangeSubtitle(_selectedRange, 'нагрузки по времени'),
          child: _BarTrendChart(
            points: durationSeries,
            color: const Color(0xFF2563EB),
            valueLabelBuilder: (value) => '${value.toInt()} мин',
          ),
        ),
        const SizedBox(height: 16),
        _ChartCard(
          title: 'Прогресс по результату',
          subtitle: selectedWorkout == null
              ? 'Сначала сохрани числовой результат в карточке тренировки.'
              : 'График строится по числовому результату выбранного упражнения за выбранный период.',
          trailing: progressWorkouts.isEmpty
              ? null
              : _ProgressWorkoutSelector(
                  workouts: progressWorkouts,
                  selectedWorkoutId: selectedWorkoutId,
                  onChanged: (value) {
                    setState(() {
                      _selectedProgressWorkoutId = value;
                    });
                  },
                ),
          child: progressSeries.isEmpty
              ? const _ChartPlaceholder(
                  message:
                      'Сохрани хотя бы один числовой результат, например повторения, километры или рабочий вес.',
                )
              : _LineTrendChart(
                  points: progressSeries,
                  color: const Color(0xFF2A9D8F),
                  startAtZero: false,
                  valueLabelBuilder: (value) {
                    final unit = progressSeries.last.unit;
                    final normalizedValue = value % 1 == 0
                        ? value.toStringAsFixed(0)
                        : value.toStringAsFixed(1);
                    return '$normalizedValue $unit'.trim();
                  },
                ),
        ),
        const SizedBox(height: 20),
        _SelectedDayCard(
          date: selectedDate,
          dailyWorkout: selectedDailyWorkout,
          isDark: isDark,
          workoutResolver: workoutService.getWorkoutById,
        ),
      ],
    );
  }

  _DateRange _resolveRange(_AnalyticsRange range) {
    final today = _normalizeDate(DateTime.now());
    switch (range) {
      case _AnalyticsRange.last7Days:
        return _DateRange(
          start: today.subtract(const Duration(days: 6)),
          end: today,
        );
      case _AnalyticsRange.last30Days:
        return _DateRange(
          start: today.subtract(const Duration(days: 29)),
          end: today,
        );
      case _AnalyticsRange.thisMonth:
        return _DateRange(
          start: DateTime(today.year, today.month, 1),
          end: today,
        );
      case _AnalyticsRange.lastMonth:
        final start = DateTime(today.year, today.month - 1, 1);
        final end = DateTime(today.year, today.month, 0);
        return _DateRange(start: start, end: _normalizeDate(end));
    }
  }

  _DateRange _previousRange(_DateRange currentRange) {
    final dayCount = currentRange.end.difference(currentRange.start).inDays + 1;
    final previousEnd = currentRange.start.subtract(const Duration(days: 1));
    final previousStart = previousEnd.subtract(Duration(days: dayCount - 1));
    return _DateRange(start: previousStart, end: previousEnd);
  }

  List<WorkoutLogEntry> _filterLogsByRange(_DateRange range) {
    return workoutService
        .getAllWorkoutLogs(descending: false)
        .where((entry) => _isWithinRange(entry.completedAt, range))
        .toList(growable: false);
  }

  bool _isWithinRange(DateTime date, _DateRange range) {
    final normalized = _normalizeDate(date);
    return !normalized.isBefore(range.start) && !normalized.isAfter(range.end);
  }

  Iterable<WorkoutLogEntry> _logsForExactDate(
    List<WorkoutLogEntry> logs,
    DateTime date,
  ) {
    final normalized = _normalizeDate(date);
    return logs
        .where((entry) => _normalizeDate(entry.completedAt) == normalized);
  }

  _PeriodMetrics _calculatePeriodMetrics(List<WorkoutLogEntry> logs) {
    final uniqueDays = <String>{};
    var totalCalories = 0;
    var totalDuration = 0;
    var sessionCount = 0;

    for (final log in logs) {
      uniqueDays.add(_dateKey(log.completedAt));
      totalCalories += log.caloriesBurned;
      totalDuration += log.durationSeconds;
      sessionCount++;
    }

    return _PeriodMetrics(
      trainingDays: uniqueDays.length,
      sessions: sessionCount,
      totalCalories: totalCalories,
      totalDurationSeconds: totalDuration,
    );
  }

  _PeriodComparison _buildComparison(
    _PeriodMetrics currentMetrics,
    List<WorkoutLogEntry> previousLogs,
  ) {
    final previousMetrics = _calculatePeriodMetrics(previousLogs);
    return _PeriodComparison(
      sessions: _MetricDelta.fromValues(
        current: currentMetrics.sessions.toDouble(),
        previous: previousMetrics.sessions.toDouble(),
      ),
      calories: _MetricDelta.fromValues(
        current: currentMetrics.totalCalories.toDouble(),
        previous: previousMetrics.totalCalories.toDouble(),
      ),
      durationMinutes: _MetricDelta.fromValues(
        current: currentMetrics.totalDurationSeconds / 60,
        previous: previousMetrics.totalDurationSeconds / 60,
      ),
    );
  }

  List<_ChartPoint> _buildRangeSeries(
    _DateRange range,
    double Function(DateTime date) valueBuilder,
  ) {
    final totalDays = range.end.difference(range.start).inDays + 1;
    return List.generate(totalDays, (index) {
      final date = range.start.add(Duration(days: index));
      return _ChartPoint(
        label: _axisLabel(date, totalDays),
        value: valueBuilder(date),
      );
    });
  }

  List<_ChartPoint> _buildProgressSeries(List<WorkoutLogEntry> entries) {
    final filteredEntries = entries
        .where((entry) => entry.progressValue != null)
        .toList(growable: false);
    final trimmedEntries = filteredEntries.length > 8
        ? filteredEntries.sublist(filteredEntries.length - 8)
        : filteredEntries;

    return trimmedEntries
        .map(
          (entry) => _ChartPoint(
            label:
                '${entry.completedAt.day.toString().padLeft(2, '0')}.${entry.completedAt.month.toString().padLeft(2, '0')}',
            value: entry.progressValue ?? 0,
            unit: entry.progressUnit,
          ),
        )
        .toList(growable: false);
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  String _dateKey(DateTime date) {
    final normalized = _normalizeDate(date);
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '${normalized.year}-$month-$day';
  }

  String _weekdayShort(int weekday) {
    const labels = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    return labels[weekday - 1];
  }

  String _axisLabel(DateTime date, int totalDays) {
    if (totalDays <= 7) {
      return _weekdayShort(date.weekday);
    }
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}';
  }

  String _rangeTitle(_AnalyticsRange range) {
    switch (range) {
      case _AnalyticsRange.last7Days:
        return 'Сводка за последние 7 дней';
      case _AnalyticsRange.last30Days:
        return 'Сводка за последние 30 дней';
      case _AnalyticsRange.thisMonth:
        return 'Сводка за текущий месяц';
      case _AnalyticsRange.lastMonth:
        return 'Сводка за прошлый месяц';
    }
  }

  String _rangeShortTitle(_AnalyticsRange range) {
    switch (range) {
      case _AnalyticsRange.last7Days:
        return '7 дней';
      case _AnalyticsRange.last30Days:
        return '30 дней';
      case _AnalyticsRange.thisMonth:
        return 'этот месяц';
      case _AnalyticsRange.lastMonth:
        return 'прошлый месяц';
    }
  }

  String _rangeSubtitle(_AnalyticsRange range, String subject) {
    switch (range) {
      case _AnalyticsRange.last7Days:
        return 'Динамика $subject за последнюю неделю.';
      case _AnalyticsRange.last30Days:
        return 'Динамика $subject за последние 30 дней.';
      case _AnalyticsRange.thisMonth:
        return 'Накопление $subject в этом месяце.';
      case _AnalyticsRange.lastMonth:
        return 'Накопление $subject в прошлом месяце.';
    }
  }

  String _previousRangeTitle(_AnalyticsRange range) {
    switch (range) {
      case _AnalyticsRange.last7Days:
        return 'предыдущие 7 дней';
      case _AnalyticsRange.last30Days:
        return 'предыдущие 30 дней';
      case _AnalyticsRange.thisMonth:
        return 'прошлый месяц';
      case _AnalyticsRange.lastMonth:
        return 'месяц до этого';
    }
  }
}

enum _AnalyticsRange { last7Days, last30Days, thisMonth, lastMonth }

class _DateRange {
  final DateTime start;
  final DateTime end;

  const _DateRange({required this.start, required this.end});
}

class _StatsHeroCard extends StatelessWidget {
  final int totalWorkouts;
  final int totalCalories;
  final int totalDurationSeconds;
  final int streak;

  const _StatsHeroCard({
    required this.totalWorkouts,
    required this.totalCalories,
    required this.totalDurationSeconds,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B35).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'PROGRESS HUB',
              style: TextStyle(
                color: Color(0xFFFFB089),
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Календарь, графики и реальный журнал нагрузки',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              height: 1.1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Сохраняй тренировки с калориями, длительностью и личным результатом, а затем смотри прогресс в динамике.',
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
                child: _HeroStatPill(
                  value: '$totalWorkouts',
                  label: 'сессий',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeroStatPill(
                  value: _formatCompact(totalCalories),
                  label: 'ккал',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeroStatPill(
                  value: '${totalDurationSeconds ~/ 3600}ч',
                  label: 'времени',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeroStatPill(
                  value: '$streak',
                  label: 'streak',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatCompact(int value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return '$value';
  }
}

class _CompetitionCard extends StatelessWidget {
  final FriendProfile activeFriend;
  final List<FriendProfile> friends;
  final String? selectedFriendId;
  final ValueChanged<String> onFriendChanged;

  final int totalWorkouts;
  final int friendWorkouts;
  final int totalCalories;
  final int friendCalories;
  final int totalDuration;
  final int friendDuration;
  final int streak;
  final int friendStreak;
  final int sharedDays;
  final int sharedStreak;

  const _CompetitionCard({
    required this.activeFriend,
    required this.friends,
    required this.selectedFriendId,
    required this.onFriendChanged,
    required this.totalWorkouts,
    required this.friendWorkouts,
    required this.totalCalories,
    required this.friendCalories,
    required this.totalDuration,
    required this.friendDuration,
    required this.streak,
    required this.friendStreak,
    required this.sharedDays,
    required this.sharedStreak,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2538) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Соревнование с другом',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedFriendId ?? activeFriend.id,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  items: friends
                      .map(
                        (friend) => DropdownMenuItem<String>(
                          value: friend.id,
                          child: Text(friend.name),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) {
                      onFriendChanged(value);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _SmallMetricTile(
                label: 'Мои тренировки',
                value: '$totalWorkouts',
              ),
              _SmallMetricTile(
                label: '${activeFriend.name}',
                value: '$friendWorkouts',
              ),
              _SmallMetricTile(
                label: 'Калории я',
                value: '$totalCalories',
              ),
              _SmallMetricTile(
                label: 'Калории ${activeFriend.name}',
                value: '$friendCalories',
              ),
              _SmallMetricTile(
                label: 'Свой стрик',
                value: '$streak',
              ),
              _SmallMetricTile(
                label: 'Стрик ${activeFriend.name}',
                value: '$friendStreak',
              ),
              _SmallMetricTile(
                label: 'Вместе дней',
                value: '$sharedDays',
              ),
              _SmallMetricTile(
                label: 'Совм. стрик',
                value: '$sharedStreak',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmallMetricTile extends StatelessWidget {
  final String label;
  final String value;

  const _SmallMetricTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF111827).withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
      ),
      constraints: const BoxConstraints(minWidth: 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }
}

class _HeroStatPill extends StatelessWidget {
  final String value;
  final String label;

  const _HeroStatPill({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
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

class _PeriodOverviewCard extends StatelessWidget {
  final String title;
  final _PeriodMetrics metrics;
  final bool isDark;

  const _PeriodOverviewCard({
    required this.title,
    required this.metrics,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF111827),
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _MetricOverviewTile(
                title: 'Дни',
                value: '${metrics.trainingDays}',
                subtitle: 'активных дней',
                color: const Color(0xFF2A9D8F),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricOverviewTile(
                title: 'Сессии',
                value: '${metrics.sessions}',
                subtitle: 'всего записей',
                color: const Color(0xFFFF6B35),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricOverviewTile(
                title: 'Среднее',
                value: '${metrics.averageCaloriesPerSession} ккал',
                subtitle: 'на сессию',
                color: const Color(0xFF2563EB),
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AnalyticsFilterBar extends StatelessWidget {
  final _AnalyticsRange selectedRange;
  final ValueChanged<_AnalyticsRange> onChanged;

  const _AnalyticsFilterBar({
    required this.selectedRange,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: _AnalyticsRange.values.map((range) {
          final selected = range == selectedRange;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Text(_labelFor(range)),
              selected: selected,
              onSelected: (_) => onChanged(range),
              labelStyle: TextStyle(
                color: selected ? Colors.white : const Color(0xFF111827),
                fontWeight: FontWeight.w700,
              ),
              selectedColor: const Color(0xFF111827),
              backgroundColor: Colors.white.withValues(alpha: 0.86),
              side: BorderSide(
                color: selected
                    ? const Color(0xFF111827)
                    : const Color(0xFFE5E7EB),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          );
        }).toList(growable: false),
      ),
    );
  }

  String _labelFor(_AnalyticsRange range) {
    switch (range) {
      case _AnalyticsRange.last7Days:
        return '7 дней';
      case _AnalyticsRange.last30Days:
        return '30 дней';
      case _AnalyticsRange.thisMonth:
        return 'Этот месяц';
      case _AnalyticsRange.lastMonth:
        return 'Прошлый месяц';
    }
  }
}

class _ProgressWorkoutSelector extends StatelessWidget {
  final List<Workout> workouts;
  final String? selectedWorkoutId;
  final ValueChanged<String> onChanged;

  const _ProgressWorkoutSelector({
    required this.workouts,
    required this.selectedWorkoutId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selectedWorkout = _findSelectedWorkout();

    return SizedBox(
      width: 230,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _showWorkoutPicker(context),
              child: Ink(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.86),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        selectedWorkout?.title ?? 'Выбери упражнение',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.unfold_more_rounded,
                      size: 18,
                      color: Color(0xFF6B7280),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (selectedWorkout != null) ...[
            const SizedBox(height: 8),
            Text(
              selectedWorkout.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Workout? _findSelectedWorkout() {
    for (final workout in workouts) {
      if (workout.id == selectedWorkoutId) {
        return workout;
      }
    }

    return null;
  }

  Future<void> _showWorkoutPicker(BuildContext context) async {
    final searchController = TextEditingController();
    final selectedValue = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).cardTheme.color,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final query = searchController.text.trim().toLowerCase();
            final filteredWorkouts = workouts.where((workout) {
              if (query.isEmpty) {
                return true;
              }

              return workout.title.toLowerCase().contains(query) ||
                  workout.description.toLowerCase().contains(query) ||
                  workout.category.toLowerCase().contains(query);
            }).toList(growable: false);

            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: TextField(
                      controller: searchController,
                      onChanged: (_) => setModalState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Поиск упражнения',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: searchController.text.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  searchController.clear();
                                  setModalState(() {});
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.72),
                      ),
                    ),
                  ),
                  Flexible(
                    child: filteredWorkouts.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.fromLTRB(16, 12, 16, 24),
                            child: Text(
                              'Ничего не найдено по этому запросу.',
                              style: TextStyle(
                                color: Color(0xFF6B7280),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            itemCount: filteredWorkouts.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final workout = filteredWorkouts[index];
                              final selected = workout.id == selectedWorkoutId;

                              return Material(
                                color: Colors.transparent,
                                child: ListTile(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  tileColor: selected
                                      ? const Color(0xFFFF6B35)
                                          .withValues(alpha: 0.12)
                                      : Colors.white.withValues(alpha: 0.7),
                                  title: Text(
                                    workout.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  subtitle: Text(workout.description),
                                  trailing: selected
                                      ? const Icon(
                                          Icons.check_circle_rounded,
                                          color: Color(0xFFFF6B35),
                                        )
                                      : null,
                                  onTap: () => Navigator.pop(context, workout.id),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    searchController.dispose();

    if (selectedValue != null) {
      onChanged(selectedValue);
    }
  }
}

class _MetricOverviewTile extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final bool isDark;

  const _MetricOverviewTile({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: appPanelDecoration(context, accent: color, radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF6B7280),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodComparisonCard extends StatelessWidget {
  final String currentRangeTitle;
  final String previousRangeTitle;
  final _PeriodComparison comparison;
  final bool isDark;

  const _PeriodComparisonCard({
    required this.currentRangeTitle,
    required this.previousRangeTitle,
    required this.comparison,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: appPanelDecoration(
        context,
        accent: const Color(0xFF2A9D8F),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Сравнение периодов',
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF111827),
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$currentRangeTitle против $previousRangeTitle',
            style: TextStyle(
              color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF6B7280),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ComparisonMetricTile(
                  title: 'Сессии',
                  delta: comparison.sessions,
                  suffix: '',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ComparisonMetricTile(
                  title: 'Калории',
                  delta: comparison.calories,
                  suffix: 'ккал',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ComparisonMetricTile(
                  title: 'Время',
                  delta: comparison.durationMinutes,
                  suffix: 'мин',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ComparisonMetricTile extends StatelessWidget {
  final String title;
  final _MetricDelta delta;
  final String suffix;

  const _ComparisonMetricTile({
    required this.title,
    required this.delta,
    required this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = delta.delta >= 0;
    final accent =
        isPositive ? const Color(0xFF2A9D8F) : const Color(0xFFE63946);
    final absoluteValue = delta.delta.abs();
    final formattedAbsolute = absoluteValue % 1 == 0
        ? absoluteValue.toStringAsFixed(0)
        : absoluteValue.toStringAsFixed(1);
    final formattedPercent = delta.percentChange.abs().isInfinite
        ? 'новый'
        : '${delta.percentChange.abs().toStringAsFixed(0)}%';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isPositive
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                color: accent,
                size: 18,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${isPositive ? '+' : '-'}$formattedAbsolute ${suffix.trim()}'
                      .trim(),
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            formattedPercent == 'новый'
                ? 'Новый рост относительно пустого периода'
                : '${isPositive ? '+' : '-'}$formattedPercent к прошлому периоду',
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarCard extends StatelessWidget {
  final DateTime visibleMonth;
  final DateTime selectedDate;
  final bool isDark;
  final bool Function(DateTime) hasWorkoutOnDate;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime> onSelectDate;

  const _CalendarCard({
    required this.visibleMonth,
    required this.selectedDate,
    required this.isDark,
    required this.hasWorkoutOnDate,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onSelectDate,
  });

  @override
  Widget build(BuildContext context) {
    final monthStart = DateTime(visibleMonth.year, visibleMonth.month);
    final nextMonth = DateTime(visibleMonth.year, visibleMonth.month + 1);
    final daysInMonth = nextMonth.subtract(const Duration(days: 1)).day;
    final leadingEmptyDays = monthStart.weekday - 1;
    final today = DateTime.now();
    const weekLabels = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

    final dayCells = <Widget>[
      for (var i = 0; i < leadingEmptyDays; i++) const SizedBox.shrink(),
      for (var day = 1; day <= daysInMonth; day++)
        _CalendarDayCell(
          date: DateTime(visibleMonth.year, visibleMonth.month, day),
          isSelected: _isSameDay(
            DateTime(visibleMonth.year, visibleMonth.month, day),
            selectedDate,
          ),
          isToday: _isSameDay(
            DateTime(visibleMonth.year, visibleMonth.month, day),
            today,
          ),
          hasWorkout: hasWorkoutOnDate(
            DateTime(visibleMonth.year, visibleMonth.month, day),
          ),
          isDark: isDark,
          onTap: () => onSelectDate(
            DateTime(visibleMonth.year, visibleMonth.month, day),
          ),
        ),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: appPanelDecoration(
        context,
        accent: const Color(0xFF111827),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _monthLabel(visibleMonth),
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF111827),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                onPressed: onPreviousMonth,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              IconButton(
                onPressed: onNextMonth,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: weekLabels
                .map(
                  (label) => Expanded(
                    child: Center(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFF9CA3AF)
                              : const Color(0xFF6B7280),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 7,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1,
            children: dayCells,
          ),
        ],
      ),
    );
  }

  String _monthLabel(DateTime date) {
    const months = [
      'Январь',
      'Февраль',
      'Март',
      'Апрель',
      'Май',
      'Июнь',
      'Июль',
      'Август',
      'Сентябрь',
      'Октябрь',
      'Ноябрь',
      'Декабрь',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  bool _isSameDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }
}

class _CalendarDayCell extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final bool isToday;
  final bool hasWorkout;
  final bool isDark;
  final VoidCallback onTap;

  const _CalendarDayCell({
    required this.date,
    required this.isSelected,
    required this.isToday,
    required this.hasWorkout,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isSelected
        ? Colors.white
        : (isDark ? Colors.white : const Color(0xFF111827));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFFF6B35)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.white.withValues(alpha: 0.72)),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isToday
                  ? const Color(0xFF2A9D8F)
                  : (isSelected ? const Color(0xFFFF6B35) : Colors.transparent),
              width: isToday ? 1.2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${date.day}',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: hasWorkout
                      ? (isSelected ? Colors.white : const Color(0xFF2A9D8F))
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: appPanelDecoration(
        context,
        accent: const Color(0xFF111827),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF111827),
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFFD1D5DB)
                            : const Color(0xFF6B7280),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 12),
                Flexible(child: trailing!),
              ],
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _LineTrendChart extends StatelessWidget {
  final List<_ChartPoint> points;
  final Color color;
  final bool startAtZero;
  final String Function(double value) valueLabelBuilder;

  const _LineTrendChart({
    required this.points,
    required this.color,
    required this.valueLabelBuilder,
    this.startAtZero = true,
  });

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty || points.every((point) => point.value == 0)) {
      return const _ChartPlaceholder(
        message: 'Пока недостаточно данных для построения графика.',
      );
    }

    final lastValue = points.last.value;
    final maxValue = points.map((point) => point.value).reduce(math.max);

    return Column(
      children: [
        Row(
          children: [
            _ChartValueBadge(
              label: 'Сейчас',
              value: valueLabelBuilder(lastValue),
              color: color,
            ),
            const SizedBox(width: 12),
            _ChartValueBadge(
              label: 'Пик',
              value: valueLabelBuilder(maxValue),
              color: color.withValues(alpha: 0.75),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 170,
          child: CustomPaint(
            painter: _LineChartPainter(
              points: points,
              color: color,
              startAtZero: startAtZero,
            ),
            child: const SizedBox.expand(),
          ),
        ),
        const SizedBox(height: 12),
        _AxisLabelsRow(points: points),
      ],
    );
  }
}

class _BarTrendChart extends StatelessWidget {
  final List<_ChartPoint> points;
  final Color color;
  final String Function(double value) valueLabelBuilder;

  const _BarTrendChart({
    required this.points,
    required this.color,
    required this.valueLabelBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty || points.every((point) => point.value == 0)) {
      return const _ChartPlaceholder(
        message:
            'Как только появятся записи за несколько дней, здесь появится график.',
      );
    }

    final total = points.fold<double>(0, (sum, point) => sum + point.value);

    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: _ChartValueBadge(
            label: 'Итого',
            value: valueLabelBuilder(total),
            color: color,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 170,
          child: CustomPaint(
            painter: _BarChartPainter(points: points, color: color),
            child: const SizedBox.expand(),
          ),
        ),
        const SizedBox(height: 12),
        _AxisLabelsRow(points: points),
      ],
    );
  }
}

class _AxisLabelsRow extends StatelessWidget {
  final List<_ChartPoint> points;

  const _AxisLabelsRow({required this.points});

  @override
  Widget build(BuildContext context) {
    final visibleIndexes = _visibleIndexes(points.length);

    return Row(
      children: points.asMap().entries.map((entry) {
        final showLabel = visibleIndexes.contains(entry.key);
        return Expanded(
          child: Text(
            showLabel ? entry.value.label : '',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(growable: false),
    );
  }

  Set<int> _visibleIndexes(int length) {
    if (length <= 7) {
      return {for (var i = 0; i < length; i++) i};
    }

    final indexes = <int>{0, length - 1};
    final step = math.max(1, (length / 4).floor());
    for (var index = step; index < length - 1; index += step) {
      indexes.add(index);
    }
    return indexes;
  }
}

class _ChartValueBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ChartValueBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartPlaceholder extends StatelessWidget {
  final String message;

  const _ChartPlaceholder({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          const Icon(Icons.insights_outlined, color: Color(0xFF6B7280)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedDayCard extends StatelessWidget {
  final DateTime date;
  final DailyWorkout? dailyWorkout;
  final bool isDark;
  final Workout? Function(String id) workoutResolver;

  const _SelectedDayCard({
    required this.date,
    required this.dailyWorkout,
    required this.isDark,
    required this.workoutResolver,
  });

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    final selectedWorkout = dailyWorkout;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: appPanelDecoration(
        context,
        accent: const Color(0xFF2A9D8F),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Выбранный день: $formattedDate',
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF111827),
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          if (selectedWorkout == null)
            Text(
              'На эту дату пока нет записанных тренировок.',
              style: TextStyle(
                color:
                    isDark ? const Color(0xFFD1D5DB) : const Color(0xFF6B7280),
              ),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: _MetricOverviewTile(
                    title: 'Тренировки',
                    value: '${selectedWorkout.entries.length}',
                    subtitle: 'сохранено',
                    color: const Color(0xFFFF6B35),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricOverviewTile(
                    title: 'Калории',
                    value: '${selectedWorkout.totalCalories}',
                    subtitle: 'за день',
                    color: const Color(0xFFE63946),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricOverviewTile(
                    title: 'Время',
                    value: '${selectedWorkout.totalDuration ~/ 60} мин',
                    subtitle: 'нагрузки',
                    color: const Color(0xFF2563EB),
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...selectedWorkout.entries.map((entry) {
              final workout = workoutResolver(entry.workoutId);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _LoggedEntryTile(
                  entry: entry,
                  workoutTitle: workout?.title ?? 'Тренировка',
                  workoutDescription: workout?.description ?? '',
                  isDark: isDark,
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _LoggedEntryTile extends StatelessWidget {
  final WorkoutLogEntry entry;
  final String workoutTitle;
  final String workoutDescription;
  final bool isDark;

  const _LoggedEntryTile({
    required this.entry,
    required this.workoutTitle,
    required this.workoutDescription,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final timeLabel =
        '${entry.completedAt.hour.toString().padLeft(2, '0')}:${entry.completedAt.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF243041) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  workoutTitle,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF111827),
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                timeLabel,
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFFD1D5DB)
                      : const Color(0xFF6B7280),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (workoutDescription.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              workoutDescription,
              style: TextStyle(
                color:
                    isDark ? const Color(0xFFD1D5DB) : const Color(0xFF6B7280),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                icon: Icons.local_fire_department,
                label: '${entry.caloriesBurned} ккал',
                color: const Color(0xFFFF6B35),
              ),
              _InfoChip(
                icon: Icons.timer_outlined,
                label: '${entry.durationSeconds ~/ 60} мин',
                color: const Color(0xFF2563EB),
              ),
              if (entry.progressValue != null)
                _InfoChip(
                  icon: Icons.show_chart_rounded,
                  label:
                      '${_formatProgress(entry.progressValue!)} ${entry.progressUnit}'
                          .trim(),
                  color: const Color(0xFF2A9D8F),
                ),
            ],
          ),
          if (entry.resultNote.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              entry.resultNote,
              style: TextStyle(
                color:
                    isDark ? const Color(0xFFD1D5DB) : const Color(0xFF6B7280),
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatProgress(double value) {
    return value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyStatsState extends StatelessWidget {
  final bool isDark;

  const _EmptyStatsState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.insights_rounded,
              size: 68,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.35)
                  : Colors.black.withValues(alpha: 0.25),
            ),
            const SizedBox(height: 18),
            Text(
              'Пока нет данных для календаря',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF111827),
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Заверши тренировку и сохрани результат с калориями, чтобы здесь появились календарь, графики и история прогресса.',
              style: TextStyle(
                color:
                    isDark ? const Color(0xFFD1D5DB) : const Color(0xFF6B7280),
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<_ChartPoint> points;
  final Color color;
  final bool startAtZero;

  const _LineChartPainter({
    required this.points,
    required this.color,
    required this.startAtZero,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const horizontalPadding = 10.0;
    const verticalPadding = 10.0;
    final chartWidth = size.width - horizontalPadding * 2;
    final chartHeight = size.height - verticalPadding * 2;

    final values = points.map((point) => point.value).toList(growable: false);
    final minValue = startAtZero ? 0.0 : values.reduce(math.min);
    var maxValue = values.reduce(math.max);
    if (maxValue <= minValue) {
      maxValue = minValue + 1;
    }

    final gridPaint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..strokeWidth = 1;
    for (var step = 0; step <= 3; step++) {
      final y = verticalPadding + chartHeight * (step / 3);
      canvas.drawLine(
        Offset(horizontalPadding, y),
        Offset(size.width - horizontalPadding, y),
        gridPaint,
      );
    }

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();
    final offsets = <Offset>[];

    for (var index = 0; index < points.length; index++) {
      final x = points.length == 1
          ? size.width / 2
          : horizontalPadding + chartWidth * index / (points.length - 1);
      final normalizedValue =
          (points[index].value - minValue) / (maxValue - minValue);
      final y = size.height - verticalPadding - normalizedValue * chartHeight;
      final offset = Offset(x, y);
      offsets.add(offset);

      if (index == 0) {
        path.moveTo(offset.dx, offset.dy);
        fillPath.moveTo(offset.dx, size.height - verticalPadding);
        fillPath.lineTo(offset.dx, offset.dy);
      } else {
        path.lineTo(offset.dx, offset.dy);
        fillPath.lineTo(offset.dx, offset.dy);
      }
    }

    if (offsets.isNotEmpty) {
      fillPath.lineTo(offsets.last.dx, size.height - verticalPadding);
      fillPath.close();
      canvas.drawPath(fillPath, fillPaint);
      canvas.drawPath(path, linePaint);
    }

    final pointPaint = Paint()..color = color;
    for (final offset in offsets) {
      canvas.drawCircle(offset, 4.5, pointPaint);
      canvas.drawCircle(offset, 2, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _BarChartPainter extends CustomPainter {
  final List<_ChartPoint> points;
  final Color color;

  const _BarChartPainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const horizontalPadding = 10.0;
    const verticalPadding = 10.0;
    final chartWidth = size.width - horizontalPadding * 2;
    final chartHeight = size.height - verticalPadding * 2;
    final maxValue = math.max(
      points.map((point) => point.value).reduce(math.max),
      1,
    );

    final gridPaint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..strokeWidth = 1;
    for (var step = 0; step <= 3; step++) {
      final y = verticalPadding + chartHeight * (step / 3);
      canvas.drawLine(
        Offset(horizontalPadding, y),
        Offset(size.width - horizontalPadding, y),
        gridPaint,
      );
    }

    final spacing = 10.0;
    final barWidth =
        (chartWidth - spacing * (points.length - 1)) / points.length;
    final barPaint = Paint()..color = color;

    for (var index = 0; index < points.length; index++) {
      final left = horizontalPadding + index * (barWidth + spacing);
      final barHeight = points[index].value / maxValue * chartHeight;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          left,
          size.height - verticalPadding - barHeight,
          barWidth,
          barHeight,
        ),
        const Radius.circular(12),
      );
      canvas.drawRRect(rect, barPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _PeriodMetrics {
  final int trainingDays;
  final int sessions;
  final int totalCalories;
  final int totalDurationSeconds;

  const _PeriodMetrics({
    required this.trainingDays,
    required this.sessions,
    required this.totalCalories,
    required this.totalDurationSeconds,
  });

  int get averageCaloriesPerSession {
    if (sessions == 0) {
      return 0;
    }
    return (totalCalories / sessions).round();
  }
}

class _PeriodComparison {
  final _MetricDelta sessions;
  final _MetricDelta calories;
  final _MetricDelta durationMinutes;

  const _PeriodComparison({
    required this.sessions,
    required this.calories,
    required this.durationMinutes,
  });
}

class _MetricDelta {
  final double current;
  final double previous;
  final double delta;
  final double percentChange;

  const _MetricDelta({
    required this.current,
    required this.previous,
    required this.delta,
    required this.percentChange,
  });

  factory _MetricDelta.fromValues({
    required double current,
    required double previous,
  }) {
    final delta = current - previous;
    final percentChange = previous == 0
        ? (current == 0 ? 0.0 : double.infinity)
        : (delta / previous) * 100;

    return _MetricDelta(
      current: current,
      previous: previous,
      delta: delta,
      percentChange: percentChange,
    );
  }
}

class _ChartPoint {
  final String label;
  final double value;
  final String unit;

  const _ChartPoint({
    required this.label,
    required this.value,
    this.unit = '',
  });
}
