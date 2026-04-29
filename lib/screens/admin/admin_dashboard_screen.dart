import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with AutomaticKeepAliveClientMixin {
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _recentUsers = [];
  List<Map<String, dynamic>> _topWorkouts = [];
  bool _loading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final client = Supabase.instance.client;
      final statsRaw = await client.rpc('get_admin_stats');
      final usersRaw = await client
          .from('admin_user_stats')
          .select('id, display_name, email, created_at, current_level, total_workouts, is_online')
          .order('created_at', ascending: false)
          .limit(6);
      final workoutsRaw = await client
          .from('admin_workout_stats')
          .select('id, title, category, total_completions, unique_users, is_active')
          .order('total_completions', ascending: false)
          .limit(5);

      if (!mounted) return;
      setState(() {
        _stats = Map<String, dynamic>.from(statsRaw as Map? ?? {});
        _recentUsers = List<Map<String, dynamic>>.from(usersRaw as List? ?? []);
        _topWorkouts = List<Map<String, dynamic>>.from(workoutsRaw as List? ?? []);
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B35)));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              const Text('Ошибка загрузки', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Повторить'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFFFF6B35),
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _buildSectionTitle('Общая статистика', Icons.bar_chart_rounded, isDark),
          const SizedBox(height: 10),
          _buildStatsGrid(isDark),
          const SizedBox(height: 20),
          _buildSectionTitle('Активность (7 дней)', Icons.timeline_rounded, isDark),
          const SizedBox(height: 10),
          _buildActivityRow(isDark),
          const SizedBox(height: 20),
          _buildSectionTitle('Новые пользователи', Icons.person_add_rounded, isDark),
          const SizedBox(height: 10),
          _buildRecentUsers(isDark),
          const SizedBox(height: 20),
          _buildSectionTitle('Популярные тренировки', Icons.trending_up_rounded, isDark),
          const SizedBox(height: 10),
          _buildTopWorkouts(isDark),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFFFF6B35)),
        const SizedBox(width: 8),
        Text(title,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF111827))),
      ],
    );
  }

  Widget _buildStatsGrid(bool isDark) {
    final cards = [
      _StatCard(label: 'Пользователей', value: '${_stats['total_users'] ?? 0}',
          icon: Icons.people_rounded, color: const Color(0xFF6366F1)),
      _StatCard(label: 'Тренировок', value: '${_stats['active_workouts'] ?? 0}',
          icon: Icons.fitness_center_rounded, color: const Color(0xFFFF6B35)),
      _StatCard(label: 'Выполнений', value: '${_stats['total_logs'] ?? 0}',
          icon: Icons.check_circle_rounded, color: const Color(0xFF10B981)),
      _StatCard(label: 'Онлайн сейчас', value: '${_stats['online_users'] ?? 0}',
          icon: Icons.circle, color: const Color(0xFF34D399)),
      _StatCard(label: 'Дружб', value: '${_stats['total_friends'] ?? 0}',
          icon: Icons.handshake_rounded, color: const Color(0xFFF59E0B)),
      _StatCard(label: 'Сообщений', value: '${_stats['total_messages'] ?? 0}',
          icon: Icons.chat_rounded, color: const Color(0xFF3B82F6)),
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.05,
      children: cards.map((c) => _buildStatCard(c, isDark)).toList(),
    );
  }

  Widget _buildStatCard(_StatCard card, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: isDark ? const Color(0xFF1A2538) : Colors.white,
        border: Border.all(
          color: card.color.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: card.color.withValues(alpha: isDark ? 0.1 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: card.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(card.icon, color: card.color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(card.value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF111827))),
          const SizedBox(height: 2),
          Text(card.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 10,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF6B7280))),
        ],
      ),
    );
  }

  Widget _buildActivityRow(bool isDark) {
    final bgCard = isDark ? const Color(0xFF1A2538) : Colors.white;
    final items = [
      _ActivityItem(
          label: 'Тренировок\nза неделю',
          value: '${_stats['logs_week'] ?? 0}',
          color: const Color(0xFF6366F1)),
      _ActivityItem(
          label: 'Тренировок\nсегодня',
          value: '${_stats['logs_today'] ?? 0}',
          color: const Color(0xFFFF6B35)),
      _ActivityItem(
          label: 'Новых\nпользователей',
          value: '${_stats['new_users_week'] ?? 0}',
          color: const Color(0xFF10B981)),
      _ActivityItem(
          label: 'Калорий\nза неделю',
          value: _formatNumber((_stats['calories_week'] ?? 0) as num),
          color: const Color(0xFFF59E0B)),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: bgCard,
        border: Border.all(
          color: isDark
              ? const Color(0xFF243041)
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: items
            .map((item) => Expanded(
                  child: _buildActivityItem(item, isDark),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildActivityItem(_ActivityItem item, bool isDark) {
    return Column(
      children: [
        Text(item.value,
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: item.color)),
        const SizedBox(height: 4),
        Text(item.label,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 10,
                height: 1.4,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF6B7280))),
      ],
    );
  }

  Widget _buildRecentUsers(bool isDark) {
    if (_recentUsers.isEmpty) {
      return _buildEmptyCard('Нет пользователей', isDark);
    }

    return Column(
      children: _recentUsers.map((u) {
        final isOnline = u['is_online'] == true;
        final level = u['current_level'] ?? 1;
        final workouts = u['total_workouts'] ?? 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isDark ? const Color(0xFF1A2538) : Colors.white,
            border: Border.all(
              color: isDark ? const Color(0xFF243041) : const Color(0xFFE5E7EB),
            ),
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFFFF6B35).withValues(alpha: 0.15),
                    child: Text(
                      (u['display_name'] as String? ?? '?')
                          .substring(0, 1)
                          .toUpperCase(),
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFFF6B35)),
                    ),
                  ),
                  if (isOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: isDark
                                  ? const Color(0xFF1A2538)
                                  : Colors.white,
                              width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(u['display_name'] ?? '—',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: isDark ? Colors.white : const Color(0xFF111827))),
                    Text(u['email'] ?? '',
                        style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? const Color(0xFF64748B)
                                : const Color(0xFF9CA3AF))),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildBadge('Ур. $level', const Color(0xFF6366F1)),
                  const SizedBox(height: 4),
                  Text('$workouts трен.',
                      style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? const Color(0xFF64748B)
                              : const Color(0xFF9CA3AF))),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTopWorkouts(bool isDark) {
    if (_topWorkouts.isEmpty) {
      return _buildEmptyCard('Нет тренировок', isDark);
    }

    final categoryColors = {
      'chest': const Color(0xFFEF4444),
      'back': const Color(0xFF3B82F6),
      'legs': const Color(0xFF10B981),
      'shoulders': const Color(0xFFF59E0B),
      'arms': const Color(0xFF8B5CF6),
      'cardio': const Color(0xFFFF6B35),
      'core': const Color(0xFF06B6D4),
      'home': const Color(0xFF14B8A6),
    };

    return Column(
      children: _topWorkouts.asMap().entries.map((entry) {
        final idx = entry.key;
        final w = entry.value;
        final completions = w['total_completions'] ?? 0;
        final uniqueUsers = w['unique_users'] ?? 0;
        final cat = (w['category'] as String? ?? '').toLowerCase();
        final catColor = categoryColors[cat] ?? const Color(0xFFFF6B35);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isDark ? const Color(0xFF1A2538) : Colors.white,
            border: Border.all(
              color: isDark ? const Color(0xFF243041) : const Color(0xFFE5E7EB),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: idx == 0
                      ? const Color(0xFFFBBF24)
                      : idx == 1
                          ? const Color(0xFF94A3B8)
                          : idx == 2
                              ? const Color(0xFFB45309)
                              : isDark
                                  ? const Color(0xFF243041)
                                  : const Color(0xFFF3F4F6),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text('${idx + 1}',
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          color: idx < 3 ? Colors.white : (isDark ? Colors.white : const Color(0xFF6B7280)))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(w['title'] ?? '—',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: isDark ? Colors.white : const Color(0xFF111827))),
                    const SizedBox(height: 2),
                    _buildBadge(w['category'] ?? '', catColor),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$completions',
                      style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: Color(0xFFFF6B35))),
                  Text('$uniqueUsers польз.',
                      style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? const Color(0xFF64748B)
                              : const Color(0xFF9CA3AF))),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color)),
    );
  }

  Widget _buildEmptyCard(String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? const Color(0xFF1A2538) : Colors.white,
      ),
      child: Center(
        child: Text(text,
            style: TextStyle(
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF9CA3AF))),
      ),
    );
  }

  String _formatNumber(num value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toString();
  }
}

class _StatCard {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});
}

class _ActivityItem {
  final String label;
  final String value;
  final Color color;
  const _ActivityItem({required this.label, required this.value, required this.color});
}
