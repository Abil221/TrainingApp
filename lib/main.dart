import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_settings.dart';
import 'screens/auth_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/daily_stats_screen.dart';
import 'screens/search_screen.dart';
import 'services/workout_service.dart';
import 'services/achievement_service.dart';
import 'services/goal_service.dart';
import 'services/workout_plan_service.dart';
import 'supabase_config.dart';
import 'widgets/app_surfaces.dart';

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
    final appSettings = AppSettings();

    return AnimatedBuilder(
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
          home: const AuthGate(),
        );
      },
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final background =
        isDark ? const Color(0xFF0B1220) : const Color(0xFFFAF6F1);
    final surface = isDark ? const Color(0xFF121A2B) : Colors.white;
    final primaryText = isDark ? Colors.white : const Color(0xFF111827);
    final secondaryText =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFFF6B35),
        brightness: brightness,
        primary: isDark ? const Color(0xFFFF8A5B) : const Color(0xFF111827),
        secondary: const Color(0xFFFF6B35),
        surface: surface,
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: primaryText,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor:
            isDark ? const Color(0xFF1E293B) : const Color(0xFF111827),
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isDark ? const Color(0xFFFF6B35) : const Color(0xFF111827),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      textTheme: ThemeData(brightness: brightness).textTheme.apply(
            bodyColor: primaryText,
            displayColor: primaryText,
          ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      dividerColor: isDark ? const Color(0xFF243041) : const Color(0xFFE5E7EB),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface.withValues(alpha: isDark ? 0.9 : 0.82),
        indicatorColor:
            const Color(0xFFFF6B35).withValues(alpha: isDark ? 0.2 : 0.14),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? primaryText : secondaryText,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? const Color(0xFFFF6B35) : secondaryText,
          );
        }),
        height: 72,
        elevation: 0,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _LiftPageTransitionsBuilder(),
          TargetPlatform.iOS: _LiftPageTransitionsBuilder(),
          TargetPlatform.windows: _LiftPageTransitionsBuilder(),
          TargetPlatform.macOS: _LiftPageTransitionsBuilder(),
          TargetPlatform.linux: _LiftPageTransitionsBuilder(),
        },
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Supabase.instance.client.auth;
    final appSettings = AppSettings();

    return StreamBuilder<AuthState>(
      stream: auth.onAuthStateChange,
      initialData: AuthState(AuthChangeEvent.initialSession,
          auth.currentSession),
      builder: (context, snapshot) {
        final session = snapshot.data?.session;

        if (session == null) {
          return const AuthScreen();
        }

        final userId = session.user.id;

        return _ProvidersWrapper(
          userId: userId,
          child: appSettings.onboardingCompleted.value
              ? const MainTabs()
              : const OnboardingScreen(),
        );
      },
    );
  }
}

class _ProvidersWrapper extends StatelessWidget {
  final String userId;
  final Widget child;

  const _ProvidersWrapper({
    required this.userId,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AchievementService()..loadAchievements(userId),
        ),
        ChangeNotifierProvider(
          create: (_) => GoalService()..loadGoals(userId),
        ),
        ChangeNotifierProvider(
          create: (_) => WorkoutPlanService()..loadPlans(userId),
        ),
      ],
      child: child,
    );
  }
}

class MainTabs extends StatefulWidget {
  const MainTabs({super.key});

  @override
  State<MainTabs> createState() => _MainTabsState();
}

class _MainTabsState extends State<MainTabs> {
  int _selectedIndex = 0;
  final WorkoutService _workoutService = WorkoutService();

  final List<Widget> _screens = const [
    HomeScreen(),
    SearchScreen(),
    DailyStatsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _workoutService.socialNotificationMessage.addListener(
      _handleSocialNotification,
    );
  }

  @override
  void dispose() {
    _workoutService.socialNotificationMessage.removeListener(
      _handleSocialNotification,
    );
    super.dispose();
  }

  void _handleSocialNotification() {
    final message = _workoutService.socialNotificationMessage.value;
    if (message == null || !mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    _workoutService.clearSocialNotification();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppScreenBackground(
        child: IndexedStack(
          index: _selectedIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home_rounded),
            label: 'Меню',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_rounded),
            label: 'Поиск',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_rounded),
            label: 'За день',
          ),
          NavigationDestination(
            icon: ValueListenableBuilder<int>(
              valueListenable: _workoutService.incomingFriendRequestsCount,
              builder: (context, count, child) {
                if (count <= 0) {
                  return child!;
                }

                return Badge(
                  label: Text('$count'),
                  child: child,
                );
              },
              child: const Icon(Icons.person_rounded),
            ),
            label: 'Профиль',
          ),
        ],
      ),
    );
  }
}

class _LiftPageTransitionsBuilder extends PageTransitionsBuilder {
  const _LiftPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.04),
      end: Offset.zero,
    ).animate(curvedAnimation);

    return FadeTransition(
      opacity: curvedAnimation,
      child: SlideTransition(position: offsetAnimation, child: child),
    );
  }
}
