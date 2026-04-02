// ИНСТРУКЦИИ ПО ИНТЕГРАЦИИ НОВЫХ ФУНКЦИЙ

// 1. В main.dart добавить импорты:
import 'package:provider/provider.dart';
import 'services/achievement_service.dart';
import 'services/workout_plan_service.dart';
import 'services/goal_service.dart';
import 'screens/achievements_screen.dart';
import 'screens/workout_plans_screen.dart';
import 'screens/goals_and_progress_screen.dart';

// 2. В main.dart обернуть MultiProvider:
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<WorkoutService>(
          create: (_) => WorkoutService(),
        ),
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
      child: // ... вывод вашего MaterialApp
    );
  }
}

// 3. Обновить WorkoutService для интеграции эхивментов
// После логирования тренировки в WorkoutService.logWorkout():

Future<void> logWorkout(...) async {
  // Существующий код логирования...
  
  // Добавить проверку достижений:
  final achievementService = context.read<AchievementService>();
  final newAchievements = await achievementService.checkAndUnlockAchievements(
    userId: auth.currentUser!.id,
    totalWorkouts: totalWorkoutCount,
    totalCalories: totalCaloriesBurned,
    currentStreak: currentStreak,
  );
  
  if (newAchievements.isNotEmpty) {
    // Показать уведомление о новых достижениях
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Разблокировано достижение: ${newAchievements.first.name}'),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// 4. Добавить стандартные достижения в БД (запустить один раз):

INSERT INTO public.achievements VALUES
('550e8400-e29b-41d4-a716-446655440000', 'Первая тренировка', 'Выполните первую тренировку', 'beginner', 'total_workouts', 1, 100),
('550e8400-e29b-41d4-a716-446655440001', 'Марафонец', 'Выполните 10 тренировок', 'runner', 'total_workouts', 10, 250),
('550e8400-e29b-41d4-a716-446655440002', 'Монстр калорий', 'Сожгите 1000 калорий', 'fire', 'calories_burned', 1000, 300),
('550e8400-e29b-41d4-a716-446655440003', 'Инструктор', 'Завершите 50 тренировок', 'trophy', 'total_workouts', 50, 500),
('550e8400-e29b-41d4-a716-446655440004', 'Звезда', 'Завершите 100 тренировок', 'star', 'total_workouts', 100, 1000),
('550e8400-e29b-41d4-a716-446655440005', 'Молния', 'Тренируйтесь 7 дней подряд', 'lightning', 'streak_days', 7, 400)
ON CONFLICT (name) DO NOTHING;

// 5. НАВИГАЦИЯ
// Добавить кнопки/ссылки в домашний экран или боковое меню:

ListTile(
  leading: const Icon(Icons.emoji_events),
  title: const Text('Достижения'),
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const AchievementsScreen()),
  ),
),
ListTile(
  leading: const Icon(Icons.calendar_today),
  title: const Text('Планы тренировок'),
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const WorkoutPlansScreen()),
  ),
),
ListTile(
  leading: const Icon(Icons.trending_up),
  title: const Text('Цели и прогресс'),
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const GoalsScreen()),
  ),
);

// 6. ЗАГРУЗКА ДАННЫХ
// В HomeScreen или главном экране добавить загрузку при инициализации:

@override
void initState() {
  super.initState();
  final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
  
  context.read<AchievementService>().loadAchievements(userId);
  context.read<WorkoutPlanService>().loadPlans(userId);
  context.read<GoalService>().loadGoals(userId);
}

// 7. ИНИЦИАЛИЗАЦИЯ ДОСТИЖЕНИЙ
// При создании нового аккаунта автоматически создать начальный уровень пользователя в профиле:

// В WorkoutService при первом входе:
final levelService = AchievementService();
await levelService.loadAchievements(userId);
