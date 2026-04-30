import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/workout_service.dart';
import '../../widgets/workout_image.dart';

class AdminWorkoutsScreen extends StatefulWidget {
  const AdminWorkoutsScreen({super.key});

  @override
  State<AdminWorkoutsScreen> createState() => _AdminWorkoutsScreenState();
}

class _AdminWorkoutsScreenState extends State<AdminWorkoutsScreen>
    with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _allWorkouts = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  String? _error;
  final _searchController = TextEditingController();
  String? _categoryFilter;

  // Категории должны точно совпадать со значениями в WorkoutService
  // Дом: Strength / Cardio / Flexibility
  // Зал: Split: Грудь / Split: Спина / Split: Ноги / Split: Плечи / Split: Руки / Fullbody
  static const _categories = [
    'Strength',
    'Cardio',
    'Flexibility',
    'Split: Грудь',
    'Split: Спина',
    'Split: Ноги',
    'Split: Плечи',
    'Split: Руки',
    'Fullbody',
  ];

  static const _categoryLabels = {
    'Strength':    'Сила (дом)',
    'Cardio':      'Кардио (дом)',
    'Flexibility': 'Гибкость (дом)',
    'Split: Грудь':  'Грудь',
    'Split: Спина':  'Спина',
    'Split: Ноги':   'Ноги',
    'Split: Плечи':  'Плечи',
    'Split: Руки':   'Руки',
    'Fullbody':    'Fullbody',
  };

  static const _categoryColors = {
    'Strength':    Color(0xFF10B981),
    'Cardio':      Color(0xFFFF6B35),
    'Flexibility': Color(0xFF2A9D8F),
    'Split: Грудь':  Color(0xFFEF4444),
    'Split: Спина':  Color(0xFF3B82F6),
    'Split: Ноги':   Color(0xFF10B981),
    'Split: Плечи':  Color(0xFFF59E0B),
    'Split: Руки':   Color(0xFF8B5CF6),
    'Fullbody':    Color(0xFF6366F1),
  };

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadWorkouts() async {
    setState(() { _loading = true; _error = null; });
    try {
      // The view has stats but no image_url — fetch it separately from workouts.
      final results = await Future.wait([
        Supabase.instance.client
            .from('admin_workout_stats')
            .select(
                'id, title, category, difficulty, duration_seconds, calories_burned, equipment, is_active, created_at, total_completions, unique_users, description, instructions')
            .order('total_completions', ascending: false),
        Supabase.instance.client
            .from('workouts')
            .select('id, image_url'),
      ]);

      final statsRows = List<Map<String, dynamic>>.from(results[0] as List? ?? []);
      final imageRows = List<Map<String, dynamic>>.from(results[1] as List? ?? []);

      final imageById = {
        for (final row in imageRows)
          row['id'] as String: row['image_url'] as String?,
      };

      if (!mounted) return;
      setState(() {
        _allWorkouts = statsRows.map((w) {
          final id = w['id'] as String? ?? '';
          return {...w, 'image_url': imageById[id]};
        }).toList();
        _applyFilter();
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _applyFilter() {
    final q = _searchController.text.toLowerCase().trim();
    var result = _allWorkouts.where((w) {
      final titleMatch = q.isEmpty ||
          (w['title'] as String? ?? '').toLowerCase().contains(q);
      final catMatch = _categoryFilter == null ||
          (w['category'] as String? ?? '') == _categoryFilter;
      return titleMatch && catMatch;
    }).toList();
    setState(() { _filtered = result; });
  }

  Future<void> _toggleActive(Map<String, dynamic> workout) async {
    final newVal = !(workout['is_active'] == true);
    try {
      await Supabase.instance.client
          .from('workouts')
          .update({'is_active': newVal})
          .eq('id', workout['id'] as String);
      _loadWorkouts();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> workout) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить тренировку?'),
        content: Text(
            'Удалить «${workout['title']}»?\nВсе связанные логи станут недоступны.'),
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
          .from('workouts')
          .delete()
          .eq('id', workout['id'] as String);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Тренировка удалена')));
      _loadWorkouts();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  void _openWorkoutForm({Map<String, dynamic>? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WorkoutFormSheet(
        existing: existing,
        categories: _categories,
        categoryColors: _categoryColors,
        categoryLabels: _categoryLabels,
        onSaved: _loadWorkouts,
      ),
    );
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
                  onPressed: _loadWorkouts,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Повторить')),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Поиск по названию...',
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: Color(0xFFFF6B35)),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () => _searchController.clear())
                          : null,
                      filled: true,
                      fillColor:
                          isDark ? const Color(0xFF1A2538) : Colors.white,
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
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 32,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _FilterChip(
                          label: 'Все',
                          selected: _categoryFilter == null,
                          color: const Color(0xFF6B7280),
                          onTap: () =>
                              setState(() { _categoryFilter = null; _applyFilter(); }),
                        ),
                        ..._categories.map((cat) {
                          final color = _categoryColors[cat] ??
                              const Color(0xFFFF6B35);
                          return Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: _FilterChip(
                              label: _categoryLabels[cat] ?? cat,
                              selected: _categoryFilter == cat,
                              color: color,
                              onTap: () => setState(() {
                                _categoryFilter =
                                    _categoryFilter == cat ? null : cat;
                                _applyFilter();
                              }),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('${_filtered.length} тренировок',
                          style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? const Color(0xFF64748B)
                                  : const Color(0xFF9CA3AF))),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFFFF6B35),
                onRefresh: _loadWorkouts,
                child: _filtered.isEmpty
                    ? ListView(children: [
                        SizedBox(
                          height: 300,
                          child: Center(
                            child: Text('Тренировки не найдены',
                                style: TextStyle(
                                    color: isDark
                                        ? const Color(0xFF64748B)
                                        : const Color(0xFF9CA3AF))),
                          ),
                        ),
                      ])
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                        itemCount: _filtered.length,
                        itemBuilder: (context, index) {
                          final w = _filtered[index];
                          return _WorkoutCard(
                            workout: w,
                            isDark: isDark,
                            categoryColors: _categoryColors,
                            onEdit: () => _openWorkoutForm(existing: w),
                            onDelete: () => _confirmDelete(w),
                            onToggleActive: () => _toggleActive(w),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 20,
          child: FloatingActionButton.extended(
            onPressed: () => _openWorkoutForm(),
            backgroundColor: const Color(0xFFFF6B35),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Добавить',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  final Map<String, dynamic> workout;
  final bool isDark;
  final Map<String, Color> categoryColors;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleActive;

  const _WorkoutCard({
    required this.workout,
    required this.isDark,
    required this.categoryColors,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = workout['is_active'] == true;
    final cat = (workout['category'] as String? ?? '').toLowerCase();
    final catColor = categoryColors[cat] ?? const Color(0xFFFF6B35);
    final completions = workout['total_completions'] ?? 0;
    final uniqueUsers = workout['unique_users'] ?? 0;
    final difficulty = workout['difficulty'] as String? ?? '';
    final durationSecs = (workout['duration_seconds'] as num?) ?? 0;
    final durationMin = (durationSecs / 60).round();

    final diffColor = difficulty == 'easy'
        ? const Color(0xFF10B981)
        : difficulty == 'medium'
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: isDark ? const Color(0xFF1A2538) : Colors.white,
        border: Border.all(
          color: isActive
              ? (isDark ? const Color(0xFF243041) : const Color(0xFFE5E7EB))
              : Colors.red.withValues(alpha: 0.3),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.fitness_center_rounded,
                      color: catColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(workout['title'] ?? '—',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: isDark
                                        ? (isActive ? Colors.white : Colors.white38)
                                        : (isActive ? const Color(0xFF111827) : const Color(0xFF9CA3AF)))),
                          ),
                          if (!isActive) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: const Text('СКРЫТА',
                                  style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.red,
                                      letterSpacing: 0.5)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _Tag(cat, catColor),
                          const SizedBox(width: 4),
                          _Tag(difficulty, diffColor),
                          const SizedBox(width: 4),
                          _Tag('$durationMin мин', const Color(0xFF6366F1)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('$completions выполнений · $uniqueUsers польз.',
                          style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? const Color(0xFF64748B)
                                  : const Color(0xFF9CA3AF))),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded,
                      color: isDark
                          ? const Color(0xFF64748B)
                          : const Color(0xFF9CA3AF)),
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'toggle') onToggleActive();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                            leading: Icon(Icons.edit_outlined),
                            title: Text('Редактировать'),
                            contentPadding: EdgeInsets.zero)),
                    PopupMenuItem(
                        value: 'toggle',
                        child: ListTile(
                            leading: Icon(isActive
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined),
                            title: Text(isActive ? 'Скрыть' : 'Показать'),
                            contentPadding: EdgeInsets.zero)),
                    const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                            leading:
                                Icon(Icons.delete_outline_rounded, color: Colors.red),
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

class _Tag extends StatelessWidget {
  final String text;
  final Color color;
  const _Tag(this.text, this.color);

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
              fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label,
      required this.selected,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: selected ? color : color.withValues(alpha: 0.1),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : color)),
      ),
    );
  }
}

// ─── Form Sheet ──────────────────────────────────────────────────────────────

class _WorkoutFormSheet extends StatefulWidget {
  final Map<String, dynamic>? existing;
  final List<String> categories;
  final Map<String, Color> categoryColors;
  final Map<String, String> categoryLabels;
  final VoidCallback onSaved;

  const _WorkoutFormSheet({
    this.existing,
    required this.categories,
    required this.categoryColors,
    required this.categoryLabels,
    required this.onSaved,
  });

  @override
  State<_WorkoutFormSheet> createState() => _WorkoutFormSheetState();
}

class _WorkoutFormSheetState extends State<_WorkoutFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _instructCtrl;
  late final TextEditingController _durationCtrl;
  late final TextEditingController _caloriesCtrl;
  String _category = 'Strength';
  String _difficulty = 'medium';
  bool _isActive = true;
  bool _saving = false;
  String? _imageUrl;
  bool _uploadingImage = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl = TextEditingController(text: e?['title'] as String? ?? '');
    _descCtrl = TextEditingController(text: e?['description'] as String? ?? '');
    _instructCtrl =
        TextEditingController(text: e?['instructions'] as String? ?? '');
    final durationSecs = (e?['duration_seconds'] as num?) ?? 0;
    _durationCtrl = TextEditingController(
        text: durationSecs > 0 ? (durationSecs ~/ 60).toString() : '');
    _caloriesCtrl = TextEditingController(
        text: ((e?['calories_burned'] as num?) ?? 0).toString());
    final existingCat = e?['category'] as String?;
    _category = (existingCat != null && widget.categories.contains(existingCat))
        ? existingCat
        : widget.categories.first;
    _difficulty = e?['difficulty'] as String? ?? 'medium';
    _isActive = e?['is_active'] as bool? ?? true;
    _imageUrl = e?['image_url'] as String?;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _instructCtrl.dispose();
    _durationCtrl.dispose();
    _caloriesCtrl.dispose();
    super.dispose();
  }

  // Maps file extensions to standard MIME types for Supabase Storage.
  static String _mimeType(String ext) {
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'heic':
        return 'image/heic';
      default:
        return 'image/jpeg';
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 900,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    setState(() => _uploadingImage = true);
    try {
      final bytes = await picked.readAsBytes();
      if (bytes.isEmpty) throw Exception('Файл пустой или не читается');

      final ext = picked.name.split('.').last.toLowerCase();
      final mime = _mimeType(ext);
      final storageExt = (ext == 'jpg') ? 'jpeg' : ext;
      final fileName =
          'workout_${DateTime.now().millisecondsSinceEpoch}.$storageExt';

      await Supabase.instance.client.storage
          .from('workout-images')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(contentType: mime, upsert: true),
          );

      // Append a timestamp to bust Supabase CDN cache for the new file.
      final rawUrl = Supabase.instance.client.storage
          .from('workout-images')
          .getPublicUrl(fileName);
      final publicUrl = '$rawUrl?t=${DateTime.now().millisecondsSinceEpoch}';

      if (!mounted) return;
      setState(() {
        _imageUrl = publicUrl;
        _uploadingImage = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingImage = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки изображения: $e')),
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _saving = true; });

    // Strip the cache-busting query param before saving to DB.
    final cleanImageUrl = _imageUrl?.split('?').first;

    final payload = {
      'title': _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'instructions': _instructCtrl.text.trim(),
      'duration_seconds': (int.tryParse(_durationCtrl.text.trim()) ?? 0) * 60,
      'calories_burned': int.tryParse(_caloriesCtrl.text.trim()) ?? 0,
      'category': _category,
      'difficulty': _difficulty,
      'is_active': _isActive,
      if (cleanImageUrl != null && cleanImageUrl.isNotEmpty)
        'image_url': cleanImageUrl,
      // legacy_id is required by workout_service to display the workout in the app
      if (widget.existing == null)
        'legacy_id': 'admin_${DateTime.now().millisecondsSinceEpoch}',
    };

    try {
      final client = Supabase.instance.client;
      if (widget.existing != null) {
        await client
            .from('workouts')
            .update(payload)
            .eq('id', widget.existing!['id'] as String);
      } else {
        await client.from('workouts').insert(payload);
      }
      if (!mounted) return;
      Navigator.pop(context);
      widget.onSaved();
      // Обновляем каталог в WorkoutService, чтобы новая тренировка сразу
      // отобразилась во всём приложении без перезапуска
      unawaited(WorkoutService().reloadWorkoutCatalog());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(widget.existing != null
                ? 'Тренировка обновлена'
                : 'Тренировка добавлена')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    } finally {
      if (mounted) setState(() { _saving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEdit = widget.existing != null;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1A2E) : const Color(0xFFF8FAFC),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
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
              Text(isEdit ? 'Редактировать тренировку' : 'Новая тренировка',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF111827))),
              const SizedBox(height: 16),
              _buildField('Название *', _titleCtrl, isDark,
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? 'Введите название' : null),
              const SizedBox(height: 16),
              _buildImageSection(isDark),
              const SizedBox(height: 12),
              _buildField('Описание', _descCtrl, isDark, maxLines: 2),
              const SizedBox(height: 12),
              _buildField('Инструкции', _instructCtrl, isDark, maxLines: 3),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildField('Длительность (мин)', _durationCtrl,
                        isDark,
                        keyboardType: TextInputType.number),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildField('Калорий (ккал)', _caloriesCtrl, isDark,
                        keyboardType: TextInputType.number),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text('Категория',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF6B7280))),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: widget.categories.map((cat) {
                  final color =
                      widget.categoryColors[cat] ?? const Color(0xFFFF6B35);
                  final sel = _category == cat;
                  return GestureDetector(
                    onTap: () => setState(() { _category = cat; }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(9),
                        color: sel ? color : color.withValues(alpha: 0.1),
                        border:
                            Border.all(color: color.withValues(alpha: 0.3)),
                      ),
                      child: Text(widget.categoryLabels[cat] ?? cat,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: sel ? Colors.white : color)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              Text('Сложность',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF6B7280))),
              const SizedBox(height: 8),
              Row(
                children: [
                  _DiffButton('easy', 'Лёгкая', const Color(0xFF10B981),
                      _difficulty, (v) => setState(() { _difficulty = v; })),
                  const SizedBox(width: 8),
                  _DiffButton('medium', 'Средняя', const Color(0xFFF59E0B),
                      _difficulty, (v) => setState(() { _difficulty = v; })),
                  const SizedBox(width: 8),
                  _DiffButton('hard', 'Тяжёлая', const Color(0xFFEF4444),
                      _difficulty, (v) => setState(() { _difficulty = v; })),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text('Активна',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF111827))),
                  const Spacer(),
                  Switch(
                    value: _isActive,
                    onChanged: (v) => setState(() { _isActive = v; }),
                    activeThumbColor: const Color(0xFFFF6B35),
                    activeTrackColor: const Color(0xFFFF6B35).withValues(alpha: 0.4),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(isEdit ? 'Сохранить изменения' : 'Добавить тренировку'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Изображение',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF6B7280))),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              if (_imageUrl != null)
                WorkoutImage(src: _imageUrl, height: 160)
              else
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1A2538)
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: isDark
                            ? const Color(0xFF243041)
                            : const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_outlined,
                          size: 36,
                          color: isDark
                              ? const Color(0xFF475569)
                              : const Color(0xFFD1D5DB)),
                      const SizedBox(height: 6),
                      Text('Нет изображения',
                          style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? const Color(0xFF475569)
                                  : const Color(0xFFD1D5DB))),
                    ],
                  ),
                ),
              if (_imageUrl != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => setState(() => _imageUrl = null),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded,
                          color: Colors.white, size: 16),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _uploadingImage ? null : _pickAndUploadImage,
            icon: _uploadingImage
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.photo_library_outlined),
            label: Text(_uploadingImage
                ? 'Загрузка...'
                : (_imageUrl != null
                    ? 'Заменить изображение'
                    : 'Выбрать изображение')),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                  color: isDark
                      ? const Color(0xFF243041)
                      : const Color(0xFFE5E7EB)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, bool isDark,
      {int maxLines = 1,
      TextInputType? keyboardType,
      String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: isDark ? const Color(0xFF1A2538) : Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: isDark ? const Color(0xFF243041) : const Color(0xFFE5E7EB)),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

class _DiffButton extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final String current;
  final ValueChanged<String> onChanged;
  const _DiffButton(
      this.value, this.label, this.color, this.current, this.onChanged);

  @override
  Widget build(BuildContext context) {
    final sel = current == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: sel ? color : color.withValues(alpha: 0.1),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: sel ? Colors.white : color)),
          ),
        ),
      ),
    );
  }
}
