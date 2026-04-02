# 🔧 QUICK REFERENCE API

## AchievementService

```dart
// Загрузить достижения пользователя
await achievementService.loadAchievements(userId);

// Добавить опыт
await achievementService.addXp(userId, 100);

// Разблокировать достижение
await achievementService.unlockAchievement(userId, achievementId);

// Проверить и разблокировать достижения по критериям
List<Achievement> unlockedAchievements = 
    await achievementService.checkAndUnlockAchievements(
      userId,
      totalWorkouts: 10,
      totalCalories: 5000,
      currentStreak: 7,
    );

// Свойства
int xp = achievementService.currentXp;
int level = achievementService.currentLevel;
List<Achievement> allAchievements = achievementService.allAchievements;
List<UserAchievement> userAchievements = achievementService.userAchievements;
```

## WorkoutPlanService

```dart
// Загрузить планы пользователя
await workoutPlanService.loadPlans(userId);

// Создать новый план
WorkoutPlan plan = await workoutPlanService.createPlan(
  userId: userId,
  name: 'Недельный сплит',
  description: 'Программа для роста мышц',
  durationWeeks: 4,
);

// Обновить план
await workoutPlanService.updatePlan(
  planId: planId,
  name: 'Новое название',
  description: 'Новое описание',
  durationWeeks: 6,
);

// Установить активный план
await workoutPlanService.setActivePlan(planId);

// Удалить план
await workoutPlanService.deletePlan(planId);

// Добавить упражнение на день
WorkoutPlanDay day = await workoutPlanService.addWorkoutToDay(
  planId: planId,
  dayOfWeek: 0,  // Понедельник
  workoutId: workoutId,
);

// Удалить упражнение
await workoutPlanService.removeWorkoutFromDay(dayId);

// Получить упражнения на день
List<WorkoutPlanDay> dayWorkouts = 
    workoutPlanService.getWorkoutsForDay(0);

// Свойства
List<WorkoutPlan> plans = workoutPlanService.userPlans;
WorkoutPlan? activePlan = workoutPlanService.activePlan;
```

## GoalService

```dart
// Загрузить цели пользователя
await goalService.loadGoals(userId);

// Создать новую цель
UserGoal goal = await goalService.createGoal(
  userId: userId,
  goalType: GoalType.weightLoss,
  name: 'Похудеть',
  description: 'Достичь здорового веса',
  targetValue: 80.0,
  currentValue: 90.0,
  unit: 'кг',
  deadline: DateTime.now().add(Duration(days: 90)),
);

// Обновить прогресс цели
await goalService.updateGoal(
  goalId: goalId,
  currentValue: 85.0,
  description: 'Обновленное описание',
);

// Завершить цель
await goalService.completeGoal(goalId);

// Удалить цель
await goalService.deleteGoal(goalId);

// Записать вес
WeightEntry entry = await goalService.recordWeight(
  userId,
  85,  // вес в кг
  notes: 'После тренировки',
);

// Получить изменение веса
double? change = goalService.getWeightChange();  // +5 или -3

// Получить средний вес за период
double avgWeight = goalService.getAverageWeight(7);  // за 7 дней

// Свойства
List<UserGoal> activeGoals = goalService.activeGoals;
List<UserGoal> completedGoals = goalService.completedGoals;
List<WeightEntry> weightHistory = goalService.weightHistory;
```

---

## 🎯 ТИПЫ ДАННЫХ

### GoalType
```dart
enum GoalType {
  weightLoss('weight_loss', 'Снижение веса'),
  muscleGain('muscle_gain', 'Набор мышц'),
  endurance('endurance', 'Выносливость'),
  strength('strength', 'Сила'),
  flexibility('flexibility', 'Гибкость'),
}
```

### AchievementCriteria
```dart
enum AchievementCriteria {
  totalWorkouts('total_workouts'),
  caloriesBurned('calories_burned'),
  streakDays('streak_days'),
  specificWorkout('specific_workout'),
  levelReached('level_reached'),
}
```

---

## 🎨 КОМПОНЕНТЫ UI

### AchievementCard
```dart
AchievementCard(
  achievement: userAchievement,
  details: achievement,
  onTap: () { /* ... */ },
)
```

### LevelProgressCard
```dart
LevelProgressCard(
  userLevel: userLevel,
  showDetails: true,
)
```

### GoalCard
```dart
GoalCard(
  goal: userGoal,
  onTap: () { /* ... */ },
  onEdit: () { /* ... */ },
  onDelete: () { /* ... */ },
)
```

### WorkoutPlanCard
```dart
WorkoutPlanCard(
  plan: workoutPlan,
  workoutCount: 5,
  isActive: true,
  onTap: () { /* ... */ },
  onEdit: () { /* ... */ },
  onDelete: () { /* ... */ },
  onActivate: () { /* ... */ },
)
```

---

## 📱 ЭКРАНЫ

### AchievementsScreen
```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const AchievementsScreen()),
);
```

### WorkoutPlansScreen
```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const WorkoutPlansScreen()),
);
```

### GoalsAndProgressScreen
```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const GoalsScreen()),
);
```

---

## 🔌 СОБЫТИЯ И СОСТОЯНИЕ

Все сервисы наследуют **ChangeNotifier**, поэтому:

```dart
// Слушать изменения
Consumer<AchievementService>(
  builder: (context, service, child) {
    return Text('Level: ${service.currentLevel}');
  },
)

// Или через Provider.of
final xp = Provider.of<AchievementService>(context).currentXp;

// Обновить UI
achievementService.notifyListeners();
```

---

## ⚠️ ВАЖНЫЕ ЗАМЕЧАНИЯ

1. **Инициализация**: Вызовите `load()` методы при входе пользователя
2. **Контекст**: Используйте `context.read<>()` в обработчиках событий
3. **RLS**: Все операции защищены политиками на уровне БД
4. **Реактивность**: Все компоненты автоматически обновляются через Provider
5. **Ошибки**: Обрабатываются try-catch, логируются в консоль

---

## 🧪 ПРИМЕРЫ ИНТЕГРАЦИИ

### В HomeScreen
```dart
@override
void initState() {
  super.initState();
  final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
  
  // Загрузить все данные
  context.read<AchievementService>().loadAchievements(userId);
  context.read<WorkoutPlanService>().loadPlans(userId);
  context.read<GoalService>().loadGoals(userId);
}
```

### После тренировки
```dart
// Логирование тренировки
await workoutService.logWorkout(...);

// Проверка достижений
final newAchievements = await achievementService
    .checkAndUnlockAchievements(
      userId,
      totalWorkouts: stats.totalCount,
      totalCalories: stats.totalCalories,
      currentStreak: stats.streak,
    );

// Уведомление
if (newAchievements.isNotEmpty) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('🏆 ${newAchievements.first.name}')),
  );
}
```

### Отслеживание цели
```dart
// Запись веса
await goalService.recordWeight(userId, 85);

// Обновление цели
await goalService.updateGoal(
  goalId: goalId,
  currentValue: 85.0,
  description: null,
);
```

---

## 🎪 ТЕСТИРОВАНИЕ

```dart
// Быстрое добавление XP
await achievementService.addXp(userId, 1000);

// Быстрое создание цели
await goalService.createGoal(
  userId: userId,
  goalType: GoalType.weightLoss,
  name: 'Test',
  description: '',
  targetValue: 80,
  currentValue: 90,
  unit: 'kg',
  deadline: DateTime.now().add(Duration(days: 30)),
);

// Быстрое добавление веса
await goalService.recordWeight(userId, 85);
```

---

Готово! Используйте этот документ как справку при интеграции! 🚀
