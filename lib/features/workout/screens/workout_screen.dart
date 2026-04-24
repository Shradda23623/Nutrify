import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/n_theme.dart';
import '../models/workout_model.dart';
import '../services/workout_service.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen>
    with SingleTickerProviderStateMixin {
  final WorkoutService _service = WorkoutService();
  List<WorkoutSession> _sessions = [];
  Map<String, dynamic> _weeklyStats = {};
  bool _loading = true;
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final sessions = await _service.getSessions();
    final stats    = await _service.getWeeklyStats();
    if (mounted) {
      setState(() {
        _sessions    = sessions;
        _weeklyStats = stats;
        _loading     = false;
      });
    }
  }

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddWorkoutSheet(
        onSaved: () {
          Navigator.pop(context);
          _load();
        },
        service: _service,
      ),
    );
  }

  Future<void> _delete(String id) async {
    await _service.deleteSession(id);
    _load();
  }

  String _formatDate(DateTime dt) {
    const days   = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return 'Today';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (dt.year == yesterday.year &&
        dt.month == yesterday.month &&
        dt.day == yesterday.day) {
      return 'Yesterday';
    }
    return '${days[dt.weekday - 1]}, ${months[dt.month - 1]} ${dt.day}';
  }

  Color _moodColor(int m) {
    switch (m) {
      case 1: return Colors.redAccent;
      case 2: return AppColors.orange;
      case 3: return AppColors.yellow;
      case 4: return AppColors.green;
      case 5: return AppColors.blue;
      default: return context.textHint;
    }
  }

  String _moodLabel(int m) {
    switch (m) {
      case 1: return 'Tough';
      case 2: return 'Hard';
      case 3: return 'OK';
      case 4: return 'Good';
      case 5: return 'Beast';
      default: return '';
    }
  }

  Color _categoryColor(String cat) {
    switch (cat) {
      case 'Chest':       return Colors.redAccent;
      case 'Back':        return Colors.teal;
      case 'Legs':        return Colors.deepOrange;
      case 'Shoulders':   return Colors.purple;
      case 'Arms':        return AppColors.blue;
      case 'Core':        return AppColors.orange;
      case 'Cardio':      return AppColors.green;
      case 'Flexibility': return Colors.pink;
      default:            return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.pageBg,
      appBar: AppBar(
        backgroundColor: context.pageBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text('Workout Tracker',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: context.textPrimary)),
        actions: [
          GestureDetector(
            onTap: _showAddSheet,
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.green
                    .withOpacity(context.isDark ? 0.18 : 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, size: 16, color: AppColors.green),
                  const SizedBox(width: 4),
                  Text('Log Workout',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.green)),
                ],
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppColors.green,
          unselectedLabelColor: context.textMuted,
          indicatorColor: AppColors.green,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: 'History'),
            Tab(text: 'Exercises'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _buildHistoryTab(),
                _buildExercisesTab(),
              ],
            ),
    );
  }

  // ── History tab ────────────────────────────────────────────────────────────

  Widget _buildHistoryTab() {
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.green,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatsCard(),
            const SizedBox(height: 20),
            if (_sessions.isNotEmpty) ...[
              _sectionLabel('Recent Workouts'),
              const SizedBox(height: 12),
              ..._sessions.map((s) => _buildSessionTile(s)),
            ] else
              _buildEmptyState(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    final sessions = _weeklyStats['sessions'] ?? 0;
    final minutes  = _weeklyStats['totalMinutes'] ?? 0;
    final calories = _weeklyStats['totalCalories'] ?? 0;
    final avgDur   = _weeklyStats['avgDuration'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A2E1A), Color(0xFF1A2E20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
              color: AppColors.green.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: AppColors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.fitness_center_rounded,
                    color: AppColors.green, size: 22),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('This Week',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.white38,
                          fontWeight: FontWeight.w500)),
                  Text('Workout Summary',
                      style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _statPill(Icons.repeat_rounded, '$sessions',
                  'sessions', AppColors.green),
              const SizedBox(width: 10),
              _statPill(Icons.timer_rounded,
                  '${(minutes / 60).toStringAsFixed(1)}h',
                  'total', AppColors.blue),
              const SizedBox(width: 10),
              _statPill(Icons.local_fire_department_rounded, '$calories',
                  'kcal burned', AppColors.orange),
            ],
          ),
          if (sessions > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.trending_up_rounded,
                      size: 14, color: AppColors.green),
                  const SizedBox(width: 6),
                  Text(
                    'Avg session: ${avgDur} min',
                    style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statPill(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: color)),
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: Colors.white38)),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionTile(WorkoutSession s) {
    final mc = _moodColor(s.mood);
    final exerciseCount = s.exercises.length;

    return Dismissible(
      key: Key(s.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.redAccent),
      ),
      onDismissed: (_) => _delete(s.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: context.cardDecoration(radius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.green.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.fitness_center_rounded,
                      color: AppColors.green, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.name,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: context.textPrimary)),
                      Text(_formatDate(s.date),
                          style: TextStyle(
                              fontSize: 11, color: context.textMuted)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: mc.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_moodLabel(s.mood),
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: mc)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _sessionStat(Icons.timer_rounded,
                    '${s.totalDurationMinutes} min', context.textMuted),
                const SizedBox(width: 16),
                _sessionStat(Icons.local_fire_department_rounded,
                    '${s.totalCaloriesBurned} kcal', AppColors.orange),
                const SizedBox(width: 16),
                _sessionStat(Icons.fitness_center_rounded,
                    '$exerciseCount exercises', AppColors.blue),
              ],
            ),
            if (s.exercises.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: s.exercises
                    .map((e) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _categoryColor(e.category)
                                .withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(e.name,
                              style: TextStyle(
                                  fontSize: 10,
                                  color: _categoryColor(e.category),
                                  fontWeight: FontWeight.w600)),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sessionStat(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(text,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: context.cardDecoration(radius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Icon(Icons.fitness_center_outlined,
              size: 52, color: context.textHint),
          const SizedBox(height: 16),
          Text('No workouts logged yet',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary)),
          const SizedBox(height: 6),
          Text('Tap "Log Workout" to start tracking\nyour training sessions',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: context.textMuted)),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _showAddSheet,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.green,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text('Log Workout',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Exercise library tab ───────────────────────────────────────────────────

  Widget _buildExercisesTab() {
    final categories = ExerciseLibrary.categories;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: categories.length,
      itemBuilder: (_, i) {
        final cat = categories[i];
        final exs = ExerciseLibrary.byCategory(cat);
        final color = _categoryColor(cat);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 6, height: 20,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(cat,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: context.textPrimary)),
                  const Spacer(),
                  Text('${exs.length} exercises',
                      style: TextStyle(
                          fontSize: 11, color: context.textMuted)),
                ],
              ),
            ),
            ...exs.map((e) => _exerciseTile(e, color)),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _exerciseTile(ExerciseTemplate e, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: context.cardDecoration(radius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.fitness_center_rounded,
                color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.name,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimary)),
                Text(e.muscleGroup,
                    style: TextStyle(
                        fontSize: 10, color: context.textMuted)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${e.caloriesPerMinute.toInt()} kcal/min',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.orange)),
              if (e.defaultSets > 0 && e.defaultReps > 0)
                Text('${e.defaultSets}×${e.defaultReps}',
                    style: TextStyle(
                        fontSize: 10, color: context.textHint)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: context.textPrimary,
            letterSpacing: -0.3),
      );
}

// ── Add Workout Bottom Sheet ───────────────────────────────────────────────

class _AddWorkoutSheet extends StatefulWidget {
  final VoidCallback onSaved;
  final WorkoutService service;

  const _AddWorkoutSheet(
      {required this.onSaved, required this.service});

  @override
  State<_AddWorkoutSheet> createState() => _AddWorkoutSheetState();
}

class _AddWorkoutSheetState extends State<_AddWorkoutSheet> {
  final _nameCtrl   = TextEditingController(text: 'Morning Workout');
  final _searchCtrl = TextEditingController();
  int _mood = 3;
  int _durationMinutes = 45;
  List<WorkoutExercise> _selected = [];
  String _searchQuery = '';
  String _filterCategory = 'All';
  bool _saving = false;

  List<ExerciseTemplate> get _filteredExercises {
    var list = _filterCategory == 'All'
        ? ExerciseLibrary.exercises
        : ExerciseLibrary.byCategory(_filterCategory);
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((e) =>
              e.name.toLowerCase().contains(q) ||
              e.muscleGroup.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  int get _totalCalories {
    return _selected.fold<int>(0, (s, e) => s + e.caloriesBurned);
  }

  void _toggleExercise(ExerciseTemplate tmpl) {
    final existing = _selected
        .indexWhere((e) => e.name == tmpl.name);
    if (existing >= 0) {
      setState(() => _selected.removeAt(existing));
    } else {
      final cals = (tmpl.caloriesPerMinute *
              (tmpl.defaultDuration > 0
                  ? tmpl.defaultDuration.toDouble()
                  : tmpl.defaultSets * tmpl.defaultReps * 0.3))
          .round();
      setState(() => _selected.add(WorkoutExercise(
            name: tmpl.name,
            category: tmpl.category,
            sets: tmpl.defaultSets,
            reps: tmpl.defaultReps,
            durationMinutes: tmpl.defaultDuration,
            caloriesBurned: cals,
          )));
    }
  }

  bool _isSelected(String name) =>
      _selected.any((e) => e.name == name);

  Future<void> _save() async {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one exercise')),
      );
      return;
    }
    setState(() => _saving = true);
    final session = WorkoutSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      name: _nameCtrl.text.trim().isEmpty
          ? 'Workout'
          : _nameCtrl.text.trim(),
      exercises: _selected,
      totalDurationMinutes: _durationMinutes,
      totalCaloriesBurned: _totalCalories,
      mood: _mood,
    );
    await widget.service.addSession(session);
    widget.onSaved();
  }

  Color _categoryColor(String cat) {
    switch (cat) {
      case 'Chest':       return Colors.redAccent;
      case 'Back':        return Colors.teal;
      case 'Legs':        return Colors.deepOrange;
      case 'Shoulders':   return Colors.purple;
      case 'Arms':        return AppColors.blue;
      case 'Core':        return AppColors.orange;
      case 'Cardio':      return AppColors.green;
      case 'Flexibility': return Colors.pink;
      default:            return AppColors.primary;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cats = ['All', ...ExerciseLibrary.categories];

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: context.surfaceElevated,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: context.textHint,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          // Header
          Padding(
            padding:
                const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color:
                        AppColors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.fitness_center_rounded,
                      color: AppColors.green, size: 18),
                ),
                const SizedBox(width: 12),
                Text('Log Workout',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: context.textPrimary)),
                const Spacer(),
                if (_selected.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.green
                          .withOpacity(0.12),
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_selected.length} added',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.green),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Name + duration row
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameCtrl,
                    style: TextStyle(
                        fontSize: 14,
                        color: context.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Workout name',
                      hintStyle: TextStyle(
                          fontSize: 13,
                          color: context.textHint),
                      prefixIcon: Icon(
                          Icons.edit_rounded,
                          size: 16,
                          color: context.textMuted),
                      filled: true,
                      fillColor: context.inputFill,
                      contentPadding:
                          const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12),
                      border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: AppColors.green,
                              width: 1.5)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _DurationPicker(
                  value: _durationMinutes,
                  onChanged: (v) =>
                      setState(() => _durationMinutes = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Mood
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text('Intensity: ',
                    style: TextStyle(
                        fontSize: 12,
                        color: context.textMuted,
                        fontWeight: FontWeight.w600)),
                ...List.generate(5, (i) {
                  final q = i + 1;
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _mood = q),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(
                        _mood >= q
                            ? Icons.bolt_rounded
                            : Icons.bolt_outlined,
                        size: 22,
                        color: _mood >= q
                            ? AppColors.yellow
                            : context.textHint,
                      ),
                    ),
                  );
                }),
                const SizedBox(width: 4),
                Text(['', 'Easy', 'Light', 'Moderate', 'Hard', 'Max'][_mood],
                    style: TextStyle(
                        fontSize: 11,
                        color: AppColors.yellow,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Search
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) =>
                  setState(() => _searchQuery = v),
              style: TextStyle(
                  fontSize: 13, color: context.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search exercises...',
                hintStyle: TextStyle(
                    fontSize: 13, color: context.textHint),
                prefixIcon: Icon(Icons.search_rounded,
                    size: 18, color: context.textMuted),
                suffixIcon: _searchQuery.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                        child: Icon(Icons.close_rounded,
                            size: 16,
                            color: context.textMuted),
                      )
                    : null,
                filled: true,
                fillColor: context.inputFill,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: AppColors.green,
                        width: 1.5)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Category filter
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: cats.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final cat = cats[i];
                final sel = _filterCategory == cat;
                final color = cat == 'All'
                    ? AppColors.green
                    : _categoryColor(cat);
                return GestureDetector(
                  onTap: () =>
                      setState(() => _filterCategory = cat),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: sel
                          ? color
                          : color.withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                    child: Text(cat,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: sel
                                ? Colors.white
                                : color)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // Exercise list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _filteredExercises.length,
              itemBuilder: (_, i) {
                final e = _filteredExercises[i];
                final sel = _isSelected(e.name);
                final color = _categoryColor(e.category);
                return GestureDetector(
                  onTap: () => _toggleExercise(e),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: sel
                          ? AppColors.green.withOpacity(0.1)
                          : context.surface,
                      borderRadius:
                          BorderRadius.circular(12),
                      border: Border.all(
                          color: sel
                              ? AppColors.green
                                  .withOpacity(0.4)
                              : context.cardBorder,
                          width: sel ? 1.5 : 1),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius:
                                BorderRadius.circular(8),
                          ),
                          child: Icon(
                              Icons.fitness_center_rounded,
                              color: color,
                              size: 15),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(e.name,
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight:
                                          FontWeight.w700,
                                      color: context
                                          .textPrimary)),
                              Text(e.muscleGroup,
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: context
                                          .textMuted)),
                            ],
                          ),
                        ),
                        Text(
                            e.defaultSets > 0 &&
                                    e.defaultReps > 0
                                ? '${e.defaultSets}×${e.defaultReps}'
                                : '${e.defaultDuration}min',
                            style: TextStyle(
                                fontSize: 10,
                                color: context.textHint)),
                        const SizedBox(width: 8),
                        Icon(
                          sel
                              ? Icons.check_circle_rounded
                              : Icons.add_circle_outline_rounded,
                          size: 20,
                          color: sel
                              ? AppColors.green
                              : context.textHint,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Save button
          Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20,
                MediaQuery.of(context).viewInsets.bottom + 20),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white))
                    : Text(
                        _selected.isEmpty
                            ? 'Select exercises to log'
                            : 'Save Workout · ${_durationMinutes}min · ~$_totalCalories kcal',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Duration picker widget ────────────────────────────────────────────────────

class _DurationPicker extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _DurationPicker(
      {required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: context.inputFill,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.timer_rounded,
                size: 15, color: AppColors.blue),
            const SizedBox(width: 6),
            Text('${value}m',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary)),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    final options = [15, 20, 30, 45, 60, 75, 90, 120];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: context.surfaceElevated,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Duration',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimary)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: options.map((o) {
                final sel = o == value;
                return GestureDetector(
                  onTap: () {
                    onChanged(o);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: sel
                          ? AppColors.green
                          : AppColors.green.withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                    child: Text('${o}min',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: sel
                                ? Colors.white
                                : AppColors.green)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
