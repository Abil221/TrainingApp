import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen>
    with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  String? _error;
  final _searchController = TextEditingController();
  String _sortBy = 'created_at';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await Supabase.instance.client
          .from('admin_user_stats')
          .select(
              'id, display_name, email, fitness_level, height, weight, is_online, last_seen, created_at, current_level, total_xp, total_workouts, total_calories, last_workout_at, is_admin')
          .order('created_at', ascending: false);
      if (!mounted) return;
      setState(() {
        _allUsers = List<Map<String, dynamic>>.from(data as List? ?? []);
        _applyFilter();
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _applyFilter() {
    final q = _searchController.text.toLowerCase().trim();
    var result = _allUsers.where((u) {
      if (q.isEmpty) return true;
      final name = (u['display_name'] as String? ?? '').toLowerCase();
      final email = (u['email'] as String? ?? '').toLowerCase();
      return name.contains(q) || email.contains(q);
    }).toList();

    result.sort((a, b) {
      switch (_sortBy) {
        case 'workouts':
          return ((b['total_workouts'] as num?) ?? 0)
              .compareTo((a['total_workouts'] as num?) ?? 0);
        case 'level':
          return ((b['current_level'] as num?) ?? 0)
              .compareTo((a['current_level'] as num?) ?? 0);
        default:
          final aDate = DateTime.tryParse(a['created_at'] as String? ?? '');
          final bDate = DateTime.tryParse(b['created_at'] as String? ?? '');
          if (aDate == null || bDate == null) return 0;
          return bDate.compareTo(aDate);
      }
    });

    setState(() { _filtered = result; });
  }

  Future<void> _showUserDetails(Map<String, dynamic> user) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UserDetailsSheet(user: user, isDark: isDark),
    );
  }

  Future<void> _confirmDeleteUser(Map<String, dynamic> user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить пользователя?'),
        content: Text(
            'Вы уверены, что хотите удалить «${user['display_name']}»?\nЭто действие необратимо.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Отмена')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Удалить')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await Supabase.instance.client
          .from('profiles')
          .delete()
          .eq('id', user['id'] as String);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пользователь удалён')),
      );
      _loadUsers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  Future<void> _toggleAdmin(Map<String, dynamic> user) async {
    final isAdmin = user['is_admin'] == true;
    final userId = user['id'] as String;
    try {
      if (isAdmin) {
        await Supabase.instance.client
            .from('admin_roles')
            .delete()
            .eq('user_id', userId);
      } else {
        await Supabase.instance.client
            .from('admin_roles')
            .insert({'user_id': userId});
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(isAdmin
                ? 'Права администратора отозваны'
                : 'Права администратора выданы')),
      );
      _loadUsers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFFFF6B35)));
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
              Text(_error!, textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                  onPressed: _loadUsers,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Повторить')),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Поиск по имени или email...',
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: Color(0xFFFF6B35)),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                          })
                      : null,
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1A2538) : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                        color: isDark
                            ? const Color(0xFF243041)
                            : const Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                        color: isDark
                            ? const Color(0xFF243041)
                            : const Color(0xFFE5E7EB)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    '${_filtered.length} пользователей',
                    style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? const Color(0xFF64748B)
                            : const Color(0xFF9CA3AF)),
                  ),
                  const Spacer(),
                  _SortChip(
                    label: 'Дата',
                    selected: _sortBy == 'created_at',
                    onTap: () => setState(() { _sortBy = 'created_at'; _applyFilter(); }),
                  ),
                  const SizedBox(width: 6),
                  _SortChip(
                    label: 'Трен.',
                    selected: _sortBy == 'workouts',
                    onTap: () => setState(() { _sortBy = 'workouts'; _applyFilter(); }),
                  ),
                  const SizedBox(width: 6),
                  _SortChip(
                    label: 'Уровень',
                    selected: _sortBy == 'level',
                    onTap: () => setState(() { _sortBy = 'level'; _applyFilter(); }),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: const Color(0xFFFF6B35),
            onRefresh: _loadUsers,
            child: _filtered.isEmpty
                ? ListView(
                    children: [
                      SizedBox(
                        height: 300,
                        child: Center(
                          child: Text(
                            'Пользователи не найдены',
                            style: TextStyle(
                                color: isDark
                                    ? const Color(0xFF64748B)
                                    : const Color(0xFF9CA3AF)),
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      final user = _filtered[index];
                      return _UserCard(
                        user: user,
                        isDark: isDark,
                        onTap: () => _showUserDetails(user),
                        onDelete: () => _confirmDeleteUser(user),
                        onToggleAdmin: () => _toggleAdmin(user),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onToggleAdmin;

  const _UserCard({
    required this.user,
    required this.isDark,
    required this.onTap,
    required this.onDelete,
    required this.onToggleAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final isOnline = user['is_online'] == true;
    final isAdmin = user['is_admin'] == true;
    final level = user['current_level'] ?? 1;
    final workouts = user['total_workouts'] ?? 0;
    final name = user['display_name'] as String? ?? '?';
    final email = user['email'] as String? ?? '';
    final fitnessLevel = user['fitness_level'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: isDark ? const Color(0xFF1A2538) : Colors.white,
        border: Border.all(
          color: isAdmin
              ? const Color(0xFFFF6B35).withValues(alpha: 0.4)
              : isDark
                  ? const Color(0xFF243041)
                  : const Color(0xFFE5E7EB),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor:
                          const Color(0xFFFF6B35).withValues(alpha: 0.15),
                      child: Text(
                        name.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: Color(0xFFFF6B35)),
                      ),
                    ),
                    if (isOnline)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 12,
                          height: 12,
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
                      Row(
                        children: [
                          Flexible(
                            child: Text(name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF111827))),
                          ),
                          if (isAdmin) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF6B35)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: const Text('ADMIN',
                                  style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFFFF6B35),
                                      letterSpacing: 0.5)),
                            ),
                          ],
                        ],
                      ),
                      Text(email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? const Color(0xFF64748B)
                                  : const Color(0xFF9CA3AF))),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _MiniTag('Ур. $level', const Color(0xFF6366F1)),
                          const SizedBox(width: 4),
                          _MiniTag('$workouts трен.', const Color(0xFF10B981)),
                          if (fitnessLevel.isNotEmpty) ...[
                            const SizedBox(width: 4),
                            _MiniTag(fitnessLevel, const Color(0xFF3B82F6)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded,
                      color: isDark
                          ? const Color(0xFF64748B)
                          : const Color(0xFF9CA3AF)),
                  onSelected: (value) {
                    if (value == 'delete') onDelete();
                    if (value == 'admin') onToggleAdmin();
                    if (value == 'details') onTap();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                        value: 'details',
                        child: ListTile(
                            leading: Icon(Icons.info_outline_rounded),
                            title: Text('Подробнее'),
                            contentPadding: EdgeInsets.zero)),
                    PopupMenuItem(
                        value: 'admin',
                        child: ListTile(
                            leading: Icon(isAdmin
                                ? Icons.remove_moderator_outlined
                                : Icons.admin_panel_settings_outlined),
                            title: Text(isAdmin
                                ? 'Отозвать права'
                                : 'Сделать админом'),
                            contentPadding: EdgeInsets.zero)),
                    const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                            leading: Icon(Icons.delete_outline_rounded,
                                color: Colors.red),
                            title: Text('Удалить',
                                style: TextStyle(color: Colors.red)),
                            contentPadding: EdgeInsets.zero)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  final String text;
  final Color color;
  const _MiniTag(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color)),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SortChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: selected
              ? const Color(0xFFFF6B35)
              : const Color(0xFFFF6B35).withValues(alpha: 0.1),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : const Color(0xFFFF6B35))),
      ),
    );
  }
}

class _UserDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> user;
  final bool isDark;
  const _UserDetailsSheet({required this.user, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final name = user['display_name'] as String? ?? '—';
    final email = user['email'] as String? ?? '—';
    final fitnessLevel = user['fitness_level'] as String? ?? '—';
    final height = user['height'] ?? '—';
    final weight = user['weight'] ?? '—';
    final level = user['current_level'] ?? 1;
    final xp = user['total_xp'] ?? 0;
    final workouts = user['total_workouts'] ?? 0;
    final calories = user['total_calories'] ?? 0;
    final isOnline = user['is_online'] == true;
    final createdAt = _formatDate(user['created_at'] as String?);
    final lastWorkout = _formatDate(user['last_workout_at'] as String?);
    final id = user['id'] as String? ?? '—';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1A2E) : const Color(0xFFF8FAFC),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF243041)
                      : const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor:
                    const Color(0xFFFF6B35).withValues(alpha: 0.15),
                child: Text(
                  name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      color: Color(0xFFFF6B35)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(name,
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF111827))),
                        if (isOnline) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                                color:
                                    const Color(0xFF10B981).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6)),
                            child: const Text('онлайн',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF10B981))),
                          ),
                        ],
                      ],
                    ),
                    Text(email,
                        style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? const Color(0xFF64748B)
                                : const Color(0xFF9CA3AF))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _DetailRow('ID', id, isDark, selectable: true),
          _DetailRow('Уровень фитнеса', fitnessLevel, isDark),
          _DetailRow('Рост / Вес', '$height см / $weight кг', isDark),
          _DetailRow('Уровень в приложении', 'Ур. $level  ($xp XP)', isDark),
          _DetailRow('Тренировок выполнено', '$workouts', isDark),
          _DetailRow('Калорий сожжено', '$calories ккал', isDark),
          _DetailRow('Зарегистрирован', createdAt, isDark),
          _DetailRow('Последняя тренировка', lastWorkout, isDark),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Закрыть'),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? raw) {
    if (raw == null) return '—';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final bool selectable;
  const _DetailRow(this.label, this.value, this.isDark,
      {this.selectable = false});

  @override
  Widget build(BuildContext context) {
    final valueWidget = selectable
        ? SelectableText(value,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: isDark ? Colors.white : const Color(0xFF111827)))
        : Text(value,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: isDark ? Colors.white : const Color(0xFF111827)));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(label,
                style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? const Color(0xFF64748B)
                        : const Color(0xFF9CA3AF))),
          ),
          Expanded(child: valueWidget),
        ],
      ),
    );
  }
}
