import 'workout.dart';

class DailyWorkout {
  final DateTime date;
  final List<Workout> exercises;
  final int totalCalories;
  final int totalDuration;

  DailyWorkout({
    required this.date,
    required this.exercises,
    required this.totalCalories,
    required this.totalDuration,
  });

  // Get formatted date (e.g., "12 марта")
  String getFormattedDate() {
    const months = [
      'января',
      'февраля',
      'марта',
      'апреля',
      'мая',
      'июня',
      'июля',
      'августа',
      'сентября',
      'октября',
      'ноября',
      'декабря'
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  // Get day of week (e.g., "Пн", "Вт")
  String getDayOfWeek() {
    const daysOfWeek = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    return daysOfWeek[date.weekday - 1];
  }
}
