# 📖 ПОШАГОВОЕ РУКОВОДСТВО ПО ИНТЕГРАЦИИ

## ⏱️ Приблизительное время: 45 минут

---

## ШАГ 1: Подготовка проекта (5 минут)

### 1.1 Обновить pubspec.yaml

```bash
# Проверить, есть ли provider
flutter pub get
```

Если `provider` не установлен:
```bash
flutter pub add provider
```

Убедитесь, что в pubspec.yaml есть:
```yaml
dependencies:
  provider: ^6.0.0
  supabase_flutter: ^2.9.1  # уже есть
```

---

## ШАГ 2: Миграция базы данных (10 минут)

### 2.1 Скопировать все таблицы

1. Откройте [Supabase Console](https://app.supabase.com)
2. Перейдите в **SQL Editor**
3. Создайте новый запрос
4. Скопируйте ВСЕ команды из `supabase/schema.sql` (все 370+ строк)
5. Выполните запрос

**Проверка:**
- ✅ Все таблицы созданы
- ✅ RLS политики применены
- ✅ Индексы созданы

### 2.2 Добавить стандартные достижения (опционально)

В Supabase SQL Editor:
```sql
INSERT INTO public.achievements VALUES
('550e8400-e29b-41d4-a716-446655440000', 'Первая тренировка', 'Выполните вашу первую тренировку', 'beginner', 'total_workouts', 1, 100),
('550e8400-e29b-41d4-a716-446655440001', 'Марафонец', 'Выполните 10 тренировок', 'runner', 'total_workouts', 10, 250),
('550e8400-e29b-41d4-a716-446655440002', 'Завтрак чемпиона', 'Сожгите 1000 калорий', 'fire', 'calories_burned', 1000, 300),
('550e8400-e29b-41d4-a716-446655440003', 'Инструктор', 'Завершите 50 тренировок', 'trophy', 'total_workouts', 50, 500),
('550e8400-e29b-41d4-a716-446655440004', 'Звезда', 'Завершите 100 тренировок', 'star', 'total_workouts', 100, 1000),
('550e8400-e29b-41d4-a716-446655440005', 'Молния', 'Тренируйтесь 7 дней подряд', 'lightning', 'streak_days', 7, 400)
ON CONFLICT (name) DO NOTHING;
```

---

## ШАГ 3: Скопировать файлы (10 минут)

### 3.1 Models

Скопируйте в `lib/models/`:
- ✅ achievement.dart
- ✅ user_level.dart
- ✅ workout_plan.dart
- ✅ user_goal.dart
- ✅ weight_entry.dart

### 3.2 Services

Скопируйте в `lib/services/`:
- ✅ achievement_service.dart
- ✅ workout_plan_service.dart
- ✅ goal_service.dart

### 3.3 Widgets

Скопируйте в `lib/widgets/`:
- ✅ achievement_card.dart
- ✅ level_progress_card.dart
- ✅ goal_card.dart
- ✅ workout_plan_card.dart

### 3.4 Screens

Скопируйте в `lib/screens/`:
- ✅ achievements_screen.dart
- ✅ workout_plans_screen.dart
- ✅ goals_and_progress_screen.dart

---

## ШАГ 4: Обновить main.dart (10 минут)

### 4.1 Добавить импорты

Вверху файла добавить:

```dart
import 'package:provider/provider.dart';
import 'services/achievement_service.dart';
import 'services/workout_plan_service.dart';
import 'services/goal_service.dart';
```

### 4.2 Обновить main() функцию

Найдите текущую функцию main() и оставьте как есть:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
  await AppSettings().load();
  await WorkoutService().load();
  runApp(const MyApp());
}
```

### 4.3 Обновить MyApp класс

Найдите класс MyApp и обновите build():

```dart
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appSettings = AppSettings();

    return MultiProvider(
      providers: [
        Provider<AchievementService>(
          create: (_) => AchievementService(),
        ),
        Provider<WorkoutPlanService>(
          create: (_) => WorkoutPlanService(),
        ),
        Provider<GoalService>(
          create: (_) => GoalService(),
        ),
      ],
      child: AnimatedBuilder(
        animation: Listenable.merge([
          appSettings.themeMode,
          appSettings.language,
          appSettings.onboardingCompleted,
        ]),
        builder: (context, child) {
          return MaterialApp(
            title: 'Workout Tracker',
            debugShowCheckedModeBanner: false,
            themeMode: appSettings.themeMode.value,
            theme: _buildTheme(Brightness.light),
            darkTheme: _buildTheme(Brightness.dark),
            locale: appSettings.locale,
            supportedLocales: appSettings.supportedLocales,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            // ... остальной код
          );
        },
      ),
    );
  }
}
```

---

## ШАГ 5: Инициализировать сервисы (5 минут)

### 5.1 В HomeScreen или главном экране

Найдите initState и добавьте:

```dart
@override
void initState() {
  super.initState();
  _initializeServices();
}

Future<void> _initializeServices() async {
  try {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    
    final userId = user.id;
    
    // Загрузить все данные
    context.read<AchievementService>().loadAchievements(userId);
    context.read<WorkoutPlanService>().loadPlans(userId);
    context.read<GoalService>().loadGoals(userId);
  } catch (e) {
    debugPrint('Error initializing services: $e');
  }
}
```

---

## ШАГ 6: Добавить навигацию (5 минут)

### 6.1 В главное меню приложения

Добавьте ссылки в ваше меню/drawer:

```dart
// Достижения
ListTile(
  leading: const Icon(Icons.emoji_events),
  title: const Text('Достижения'),
  onTap: () => Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const AchievementsScreen()),
  ),
),

// Планы тренировок
ListTile(
  leading: const Icon(Icons.calendar_today),
  title: const Text('Планы тренировок'),
  onTap: () => Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const WorkoutPlansScreen()),
  ),
),

// Цели и прогресс
ListTile(
  leading: const Icon(Icons.trending_up),
  title: const Text('Цели и прогресс'),
  onTap: () => Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const GoalsScreen()),
  ),
),
```

### 6.2 Импорты для экранов

Добавьте в файл, где вы добавляете ссылки:

```dart
import '../screens/achievements_screen.dart';
import '../screens/workout_plans_screen.dart';
import '../screens/goals_and_progress_screen.dart';
```

---

## ШАГ 7: Интеграция с логированием тренировок (5 минут)

### 7.1 В WorkoutService.logWorkout()

После успешного логирования тренировки добавить:

```dart
// Получить текущего пользователя и его статистику
final userId = Supabase.instance.client.auth.currentUser?.id;
if (userId == null) return;

// Получить общую статистику
final stats = _calculateUserStats(); // ваша функция

// Проверить и разблокировать достижения
final achievementService = AchievementService();
await achievementService.loadAchievements(userId);

final newAchievements = await achievementService
    .checkAndUnlockAchievements(
      userId,
      totalWorkouts: stats.totalCount,
      totalCalories: stats.totalCalories,
      currentStreak: stats.streakDays,
    );

// Показать уведомление о новых достижениях
if (newAchievements.isNotEmpty) {
  for (final achievement in newAchievements) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🏆 Новое достижение: ${achievement.name}'),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
```

---

## ПРОВЕРКА: Все работает?

### ✅ Тест 1: Запуск приложения

```bash
flutter run
```

- ✅ Приложение не падает
- ✅ Консоль чистая (нет ошибок)

### ✅ Тест 2: Открыть экран достижений

1. Войти в приложение
2. Открыть меню
3. Нажать на "Достижения"
4. Должно показать: Уровень, разблокированные/заблокированные достижения

### ✅ Тест 3: Открыть экран планов

1. Нажать на "Планы тренировок"
2. Нажать FAB "+"
3. Создать новый план
4. План должен появиться в списке

### ✅ Тест 4: Открыть экран целей

1. Нажать на "Цели и прогресс"
2. Нажать FAB "+"
3. Создать новую цель
4. Цель должна появиться в списке

### ✅ Тест 5: Запись веса

1. На экране целей перейти на вкладку "Вес"
2. Нажать FAB
3. Записать вес
4. Вес должен появиться в истории

---

## 🐛 РЕШЕНИЕ ПРОБЛЕМ

### Проблема: "Missing Provider"
**Решение:** Убедитесь, что MultiProvider оборачивает MaterialApp в main.dart

### Проблема: "Type mismatch в Provider"
**Решение:** Проверьте импорты - убедитесь, что импортируете правильные сервисы

### Проблема: "RLS violation error"
**Решение:** Убедитесь, что миграции БД выполнены полностью

### Проблема: "Service not loaded"
**Решение:** Вызовите loadXXX() методы в initState главного экрана

### Проблема: "Данные не обновляются"
**Решение:** Используйте Consumer<> или context.read<>() вместо прямого доступа

---

## 📊 КОНТРОЛЬНЫЙ СПИСОК ИНТЕГРАЦИИ

- [ ] pubspec.yaml обновлен (provider добавлен)
- [ ] Миграции БД выполнены (schema.sql)
- [ ] Все models скопированы
- [ ] Все services скопированы
- [ ] Все widgets скопированы
- [ ] Все screens скопированы
- [ ] main.dart обновлен с MultiProvider
- [ ] Импорты добавлены в main.dart
- [ ] Сервисы инициализированы в initState
- [ ] Навигация добавлена в меню
- [ ] Достижения добавлены в БД (опционально)
- [ ] Приложение запущено - тестирование пройдено

---

## 🎉 ГОТОВО!

Если все пункты выше выполнены, приложение полностью готово к работе с новыми функциями!

**При возникновении вопросов обратитесь к:**
- `QUICK_REFERENCE.md` - для API справки
- `IMPLEMENTATION_SUMMARY.md` - для обзора функциональности
- Исходному коду файлов - для деталей реализации

---

**Успешной интеграции! 🚀**
