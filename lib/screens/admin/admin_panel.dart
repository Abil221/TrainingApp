import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../widgets/app_surfaces.dart';
import 'admin_dashboard_screen.dart';
import 'admin_users_screen.dart';
import 'admin_workouts_screen.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _isAdmin = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkAdmin();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkAdmin() async {
    try {
      final result =
          await Supabase.instance.client.rpc('is_admin') as bool? ?? false;
      if (mounted) setState(() { _isAdmin = result; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _isAdmin = false; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final orange = const Color(0xFFFF6B35);

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Админ-панель')),
        body: AppScreenBackground(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: orange.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.lock_outline_rounded,
                      size: 56, color: orange),
                ),
                const SizedBox(height: 20),
                Text('Доступ запрещён',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF111827))),
                const SizedBox(height: 8),
                Text('У вас нет прав администратора',
                    style: TextStyle(
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF6B7280))),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('ADMIN',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: orange,
                      letterSpacing: 1)),
            ),
            const SizedBox(width: 10),
            const Text('Панель управления',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: orange,
          labelColor: orange,
          unselectedLabelColor:
              isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
          tabs: const [
            Tab(icon: Icon(Icons.bar_chart_rounded), text: 'Дашборд'),
            Tab(icon: Icon(Icons.people_outline_rounded), text: 'Пользователи'),
            Tab(icon: Icon(Icons.fitness_center_rounded), text: 'Тренировки'),
          ],
        ),
      ),
      body: AppScreenBackground(
        child: TabBarView(
          controller: _tabController,
          children: const [
            AdminDashboardScreen(),
            AdminUsersScreen(),
            AdminWorkoutsScreen(),
          ],
        ),
      ),
    );
  }
}
