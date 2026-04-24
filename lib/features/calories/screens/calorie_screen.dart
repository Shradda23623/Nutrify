import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/data/indian_food_database.dart';
import '../../../core/data/world_food_database.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/n_theme.dart';
import '../../../core/widgets/progress_ring.dart';
import '../models/calorie_model.dart';
import '../services/calorie_service.dart';
import '../widgets/calorie_chart.dart';

class CalorieScreen extends StatefulWidget {
  const CalorieScreen({super.key});

  @override
  State<CalorieScreen> createState() => _CalorieScreenState();
}

class _CalorieScreenState extends State<CalorieScreen>
    with SingleTickerProviderStateMixin {
  final CalorieService _service = CalorieService();
  CalorieModel? _model;
  List<CalorieEntry> _recentFoods = [];
  late TabController _tabCtrl;

  static const _meals = ['All', 'Breakfast', 'Lunch', 'Dinner', 'Snacks'];
  String _selectedMeal = 'All';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _meals.length, vsync: this);
    _load();
  }

  Future<void> _load() async {
    final data = await _service.load();
    final recent = await _service.getRecentFoods();
    if (mounted) {
      setState(() {
        _model = data;
        _recentFoods = recent;
      });
    }
  }

  List<CalorieEntry> get _filteredEntries {
    if (_model == null) return [];
    if (_selectedMeal == 'All') return _model!.entries;
    return _model!.entries
        .where((e) => _mealFromTime(e.time) == _selectedMeal)
        .toList();
  }

  String _mealFromTime(DateTime t) {
    final h = t.hour;
    if (h < 11) return 'Breakfast';
    if (h < 15) return 'Lunch';
    if (h < 19) return 'Dinner';
    return 'Snacks';
  }

  IconData _mealIcon(String meal) {
    switch (meal) {
      case 'Breakfast': return Icons.free_breakfast_rounded;
      case 'Lunch': return Icons.lunch_dining_rounded;
      case 'Dinner': return Icons.dinner_dining_rounded;
      case 'Snacks': return Icons.cookie_rounded;
      default: return Icons.restaurant_rounded;
    }
  }

  Color _mealColor(String meal) {
    switch (meal) {
      case 'Breakfast': return Colors.amber;
      case 'Lunch': return Colors.deepOrange;
      case 'Dinner': return Colors.indigo;
      case 'Snacks': return Colors.teal;
      default: return AppColors.green;
    }
  }

  void _showAddDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddFoodSheet(
        onSaved: () {
          Navigator.pop(ctx);
          _load();
        },
        service: _service,
      ),
    );
  }

  Widget _field(BuildContext ctx, TextEditingController ctrl, String hint, IconData icon,
      {bool isNum = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNum
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      style: TextStyle(fontSize: 14, color: ctx.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 12, color: ctx.textHint),
        prefixIcon: Icon(icon, size: 17, color: AppColors.green),
        filled: true,
        fillColor: ctx.inputFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: ctx.isDark
                ? BorderSide(color: ctx.mutedBorder, width: 1)
                : BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: ctx.isDark
                ? BorderSide(color: ctx.mutedBorder, width: 1)
                : BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: BorderSide(color: AppColors.green, width: 1.5)),
      ),
    );
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_model == null) {
      return Scaffold(
        backgroundColor: context.pageBg,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final m = _model!;
    final remaining = m.remaining;
    final overGoal = m.totalCalories > m.goal;

    return Scaffold(
      backgroundColor: context.pageBg,
      appBar: AppBar(
        backgroundColor: context.pageBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Text('Calorie Tracker',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: context.textPrimary)),
        actions: [
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, AppRoutes.foodSearch)
                .then((_) => _load()),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.green.withOpacity(context.isDark ? 0.18 : 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, size: 16, color: AppColors.green),
                  const SizedBox(width: 4),
                  Text('Search',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.green)),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: _showAddDialog,
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppColors.orange.withOpacity(context.isDark ? 0.18 : 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.add_rounded, color: AppColors.orange, size: 20),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _calorieRingCard(m, remaining, overGoal),
              const SizedBox(height: 16),
              _macroCard(m),
              const SizedBox(height: 20),
              if (_recentFoods.isNotEmpty) ...[
                _sectionHeader('Quick Add', Icons.history_rounded, AppColors.orange),
                const SizedBox(height: 10),
                _recentFoodsRow(),
                const SizedBox(height: 20),
              ],
              _sectionHeader("Today's Meals", Icons.restaurant_menu_rounded, AppColors.green),
              const SizedBox(height: 10),
              _mealFilterChips(),
              const SizedBox(height: 12),
              _entriesList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _calorieRingCard(CalorieModel m, double remaining, bool overGoal) {
    final ringColor = overGoal
        ? Colors.redAccent
        : m.progress > 0.85
            ? AppColors.orange
            : AppColors.green;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF1A1A2E).withOpacity(0.35),
              blurRadius: 20, offset: const Offset(0, 8))
        ],
      ),
      child: Row(
        children: [
          ProgressRing(
            value: m.progress.clamp(0.0, 1.0),
            size: 120,
            progressColor: ringColor,
            strokeWidth: 12,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  m.totalCalories.toStringAsFixed(0),
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
                ),
                const Text('kcal',
                    style: TextStyle(fontSize: 10, color: Colors.white54)),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ringStatRow(Icons.flag_rounded, 'Goal',
                    '${m.goal.toStringAsFixed(0)} kcal', AppColors.orange),
                const SizedBox(height: 10),
                _ringStatRow(Icons.local_fire_department_rounded, 'Eaten',
                    '${m.totalCalories.toStringAsFixed(0)} kcal', ringColor),
                const SizedBox(height: 10),
                _ringStatRow(
                  overGoal ? Icons.warning_rounded : Icons.battery_charging_full_rounded,
                  overGoal ? 'Over by' : 'Left',
                  '${remaining.abs().toStringAsFixed(0)} kcal',
                  overGoal ? Colors.redAccent : AppColors.blue,
                ),
                const SizedBox(height: 12),
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(3)),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: m.progress.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                          color: ringColor,
                          borderRadius: BorderRadius.circular(3)),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  overGoal
                      ? 'Goal exceeded'
                      : '${(m.progress * 100).toInt()}% of daily goal',
                  style: const TextStyle(fontSize: 10, color: Colors.white38),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ringStatRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 10, color: Colors.white38)),
            Text(value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
          ],
        ),
      ],
    );
  }

  Widget _macroCard(CalorieModel m) {
    final total = m.totalProtein + m.totalCarbs + m.totalFat;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: context.cardDecoration(radius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Macronutrients',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: context.textPrimary)),
              if (total > 0)
                Text('${total.toStringAsFixed(0)}g total',
                    style: TextStyle(fontSize: 11, color: context.textHint)),
            ],
          ),
          if (total == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: context.textHint),
                  const SizedBox(width: 8),
                  Text('Log food to see macro breakdown',
                      style: TextStyle(fontSize: 12, color: context.textMuted)),
                ],
              ),
            )
          else ...[
            const SizedBox(height: 14),
            _macroBar('Protein', m.totalProtein, total, const Color(0xFF4D96FF)),
            const SizedBox(height: 10),
            _macroBar('Carbohydrates', m.totalCarbs, total, const Color(0xFFFFBF00)),
            const SizedBox(height: 10),
            _macroBar('Fat', m.totalFat, total, const Color(0xFFFF9F1C)),
            const SizedBox(height: 14),
            SizedBox(
              height: 90,
              child: MacroChart(
                protein: m.totalProtein,
                carbs: m.totalCarbs,
                fat: m.totalFat,
              ),
            ),
            if (m.totalFiber > 0 || m.totalSugar > 0 || m.totalSodium > 0) ...[
              const SizedBox(height: 14),
              Divider(color: context.divider, height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text('Micronutrients',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: context.textSecondary)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (m.totalFiber > 0)
                    _microStat('Fiber', '${m.totalFiber.toStringAsFixed(1)}g',
                        const Color(0xFF34C98A)),
                  if (m.totalFiber > 0 && m.totalSugar > 0)
                    const SizedBox(width: 12),
                  if (m.totalSugar > 0)
                    _microStat('Sugar', '${m.totalSugar.toStringAsFixed(1)}g',
                        const Color(0xFFFF6B9D)),
                  if (m.totalSugar > 0 && m.totalSodium > 0)
                    const SizedBox(width: 12),
                  if (m.totalSodium > 0)
                    _microStat('Sodium', '${m.totalSodium.toStringAsFixed(0)}mg',
                        const Color(0xFFAA88FF)),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _macroBar(String label, double val, double total, Color color) {
    final frac = total > 0 ? (val / total).clamp(0.0, 1.0) : 0.0;
    final pct = (frac * 100).toInt();
    return Column(
      children: [
        Row(
          children: [
            Container(
                width: 10, height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary)),
            const Spacer(),
            Text('${val.toStringAsFixed(1)}g',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary)),
            const SizedBox(width: 4),
            SizedBox(
              width: 32,
              child: Text('$pct%',
                  style: TextStyle(fontSize: 10, color: context.textHint),
                  textAlign: TextAlign.right),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: frac,
            minHeight: 6,
            backgroundColor: color.withOpacity(0.12),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _recentFoodsRow() {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _recentFoods.length,
        itemBuilder: (_, i) {
          final food = _recentFoods[i];
          return GestureDetector(
            onTap: () async {
              await _service.addEntry(CalorieEntry(
                name: food.name,
                calories: food.calories,
                protein: food.protein,
                carbs: food.carbs,
                fat: food.fat,
                fiber: food.fiber,
                sugar: food.sugar,
                sodium: food.sodium,
                iron: food.iron,
                calcium: food.calcium,
                vitaminB12: food.vitaminB12,
                vitaminD: food.vitaminD,
                vitaminC: food.vitaminC,
                magnesium: food.magnesium,
                glycemicIndex: food.glycemicIndex,
                time: DateTime.now(),
              ));
              _load();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                      '${food.name} added — ${food.calories.toStringAsFixed(0)} kcal'),
                  backgroundColor: AppColors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ));
              }
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: context.isDark
                        ? context.cardBorder
                        : AppColors.green.withOpacity(0.3)),
                boxShadow: context.isDark
                    ? null
                    : [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 4, offset: const Offset(0, 2))
                      ],
              ),
              child: Row(
                children: [
                  Icon(Icons.restaurant_rounded, size: 13, color: AppColors.green),
                  const SizedBox(width: 6),
                  Text(food.name,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: context.textPrimary)),
                  const SizedBox(width: 6),
                  Text('${food.calories.toStringAsFixed(0)} kcal',
                      style: TextStyle(fontSize: 10, color: context.textHint)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _mealFilterChips() {
    return SizedBox(
      height: 34,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _meals.length,
        itemBuilder: (_, i) {
          final meal = _meals[i];
          final selected = _selectedMeal == meal;
          final color = _mealColor(meal);
          return GestureDetector(
            onTap: () => setState(() => _selectedMeal = meal),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: EdgeInsets.only(right: i == _meals.length - 1 ? 0 : 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? color : context.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: selected
                        ? color
                        : context.isDark
                            ? context.mutedBorder
                            : Colors.black.withOpacity(0.08),
                    width: 1.5),
                boxShadow: selected
                    ? [
                        BoxShadow(
                            color: color.withOpacity(0.25),
                            blurRadius: 8, offset: const Offset(0, 3))
                      ]
                    : [],
              ),
              child: Row(
                children: [
                  if (meal != 'All') ...[
                    Icon(_mealIcon(meal),
                        size: 12,
                        color: selected ? Colors.white : context.textMuted),
                    const SizedBox(width: 5),
                  ],
                  Text(meal,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: selected ? Colors.white : context.textSecondary)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _entriesList() {
    final entries = _filteredEntries;

    if (entries.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: AppColors.green.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.restaurant_menu_rounded,
                  size: 36, color: AppColors.green.withOpacity(0.4)),
            ),
            const SizedBox(height: 16),
            Text(
              _selectedMeal == 'All'
                  ? 'No meals logged yet'
                  : 'No $_selectedMeal entries',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: context.textMuted),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap Search or + to log your first meal',
              style: TextStyle(fontSize: 12, color: context.textHint),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _emptyActionBtn(
                  label: 'Search Indian Food',
                  icon: Icons.search_rounded,
                  color: AppColors.green,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.foodSearch)
                      .then((_) => _load()),
                ),
                const SizedBox(width: 10),
                _emptyActionBtn(
                  label: 'Manual Entry',
                  icon: Icons.add_rounded,
                  color: AppColors.orange,
                  onTap: _showAddDialog,
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (_selectedMeal == 'All') {
      final groups = <String, List<(int, CalorieEntry)>>{};
      for (final order in ['Breakfast', 'Lunch', 'Dinner', 'Snacks']) {
        groups[order] = [];
      }
      for (int i = 0; i < _model!.entries.length; i++) {
        final meal = _mealFromTime(_model!.entries[i].time);
        groups[meal]?.add((i, _model!.entries[i]));
      }
      final widgets = <Widget>[];
      for (final meal in ['Breakfast', 'Lunch', 'Dinner', 'Snacks']) {
        final items = groups[meal]!;
        if (items.isEmpty) continue;
        final mealTotal = items.fold(0.0, (s, e) => s + e.$2.calories);
        widgets.add(_mealGroupHeader(meal, mealTotal));
        for (final item in items) {
          widgets.add(_entryCard(item.$1, item.$2));
        }
        widgets.add(const SizedBox(height: 8));
      }
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgets);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: entries.asMap().entries.map((e) {
        final globalIdx = _model!.entries.indexWhere(
            (entry) => entry.time == e.value.time && entry.name == e.value.name);
        return _entryCard(globalIdx, e.value);
      }).toList(),
    );
  }

  Widget _mealGroupHeader(String meal, double total) {
    final color = _mealColor(meal);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(_mealIcon(meal), size: 15, color: color),
          ),
          const SizedBox(width: 10),
          Text(meal,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: context.textPrimary)),
          const Spacer(),
          Text('${total.toStringAsFixed(0)} kcal',
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _entryCard(int index, CalorieEntry entry) {
    final meal = _mealFromTime(entry.time);
    final color = _mealColor(meal);
    final timeStr =
        '${entry.time.hour.toString().padLeft(2, '0')}:${entry.time.minute.toString().padLeft(2, '0')}';

    return Dismissible(
      key: Key('entry_${entry.time.millisecondsSinceEpoch}_${entry.name}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.redAccent, size: 22),
      ),
      confirmDismiss: (_) async => true,
      onDismissed: (_) async {
        await _service.removeEntry(index);
        _load();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: context.cardDecoration(radius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(context.isDark ? 0.18 : 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_mealIcon(meal), size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.name,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: context.textPrimary)),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      _macroPill('P', entry.protein, const Color(0xFF4D96FF)),
                      const SizedBox(width: 4),
                      _macroPill('C', entry.carbs, const Color(0xFFFFBF00)),
                      const SizedBox(width: 4),
                      _macroPill('F', entry.fat, const Color(0xFFFF9F1C)),
                    ],
                  ),
                  if (entry.fiber > 0 || entry.sugar > 0 || entry.sodium > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (entry.fiber > 0) ...[
                          _macroPill('Fi', entry.fiber, const Color(0xFF34C98A)),
                          const SizedBox(width: 4),
                        ],
                        if (entry.sugar > 0) ...[
                          _macroPill('Su', entry.sugar, const Color(0xFFFF6B9D)),
                          const SizedBox(width: 4),
                        ],
                        if (entry.sodium > 0)
                          _sodiumPill(entry.sodium),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  entry.calories.toStringAsFixed(0),
                  style: TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 16, color: color),
                ),
                Text('kcal',
                    style: TextStyle(fontSize: 9, color: context.textHint)),
                const SizedBox(height: 4),
                Text(timeStr,
                    style: TextStyle(fontSize: 10, color: context.textHint)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _macroPill(String label, double val, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(context.isDark ? 0.15 : 0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label ${val.toStringAsFixed(1)}g',
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }

  Widget _sodiumPill(double mg) {
    const color = Color(0xFFAA88FF);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(context.isDark ? 0.15 : 0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'Na ${mg.toStringAsFixed(0)}mg',
        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }

  Widget _microStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(context.isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(fontSize: 10, color: context.textHint)),
        ],
      ),
    );
  }

  Widget _emptyActionBtn({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(context.isDark ? 0.14 : 0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String label, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
              color: color.withOpacity(context.isDark ? 0.18 : 0.12),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 15, color: color),
        ),
        const SizedBox(width: 10),
        Text(label,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: context.textPrimary)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _AddFoodSheet — smart autocomplete bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _AddFoodSheet extends StatefulWidget {
  final VoidCallback onSaved;
  final CalorieService service;

  const _AddFoodSheet({required this.onSaved, required this.service});

  @override
  State<_AddFoodSheet> createState() => _AddFoodSheetState();
}

class _AddFoodSheetState extends State<_AddFoodSheet> {
  final _nameCtrl    = TextEditingController();
  final _calCtrl     = TextEditingController();
  final _protCtrl    = TextEditingController();
  final _carbCtrl    = TextEditingController();
  final _fatCtrl     = TextEditingController();
  final _fiberCtrl   = TextEditingController();
  final _sugarCtrl   = TextEditingController();
  final _sodiumCtrl  = TextEditingController();
  final _servingCtrl = TextEditingController();

  List<IndianFood> _suggestions = [];
  IndianFood? _selectedFood;
  bool _autoFilled = false;
  bool _saving = false;
  bool _showMicros = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _calCtrl.dispose();
    _protCtrl.dispose();
    _carbCtrl.dispose();
    _fatCtrl.dispose();
    _fiberCtrl.dispose();
    _sugarCtrl.dispose();
    _sodiumCtrl.dispose();
    _servingCtrl.dispose();
    super.dispose();
  }

  void _onNameChanged(String q) {
    if (q.isEmpty) {
      setState(() {
        _suggestions = [];
        _selectedFood = null;
        _autoFilled = false;
      });
      _clearNutrition();
      return;
    }
    // Merge Indian + world results, capped at 6 total
    final indian = IndianFoodDatabase.search(q);
    final world  = WorldFoodDatabase.search(q);
    // Interleave: up to 4 Indian + 2 World (or fill from whichever has more)
    final merged = <IndianFood>[];
    final iMax = indian.length;
    final wMax = world.length;
    for (int i = 0; i < 6; i++) {
      if (i < iMax && merged.length < 4) merged.add(indian[i]);
      else if (wMax > 0 && merged.length < 6) {
        final wIdx = i - (merged.length < iMax ? 0 : iMax);
        if (wIdx >= 0 && wIdx < wMax) merged.add(world[wIdx]);
      }
    }
    // If Indian filled fewer than 4, top up with world
    if (merged.length < 6) {
      for (final w in world) {
        if (!merged.contains(w) && merged.length < 6) merged.add(w);
      }
    }
    setState(() => _suggestions = merged.take(6).toList());
  }

  void _clearNutrition() {
    _calCtrl.clear();
    _protCtrl.clear();
    _carbCtrl.clear();
    _fatCtrl.clear();
    _fiberCtrl.clear();
    _sugarCtrl.clear();
    _sodiumCtrl.clear();
    _servingCtrl.clear();
  }

  void _selectFood(IndianFood food) {
    final scaled = food.scaled(food.servingGrams);
    setState(() {
      _selectedFood = food;
      _autoFilled = true;
      _suggestions = [];
      _showMicros = food.fiber > 0 || food.sugar > 0 || food.sodium > 0;
    });
    _nameCtrl.text = food.name;
    _servingCtrl.text = food.servingGrams.toStringAsFixed(0);
    _fillFromScaled(scaled);
  }

  void _fillFromScaled(IndianFood s) {
    _calCtrl.text   = s.calories.toStringAsFixed(1);
    _protCtrl.text  = s.protein.toStringAsFixed(1);
    _carbCtrl.text  = s.carbs.toStringAsFixed(1);
    _fatCtrl.text   = s.fat.toStringAsFixed(1);
    _fiberCtrl.text = s.fiber.toStringAsFixed(1);
    _sugarCtrl.text = s.sugar.toStringAsFixed(1);
    _sodiumCtrl.text = s.sodium.toStringAsFixed(0);
  }

  void _onServingChanged(String val) {
    if (_selectedFood == null) return;
    final grams = double.tryParse(val);
    if (grams == null || grams <= 0) return;
    _fillFromScaled(_selectedFood!.scaled(grams));
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final cal  = double.tryParse(_calCtrl.text) ?? 0;
    if (name.isEmpty || cal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Enter food name and calories'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.service.addEntry(CalorieEntry(
        name: name,
        calories: cal,
        protein: double.tryParse(_protCtrl.text) ?? 0,
        carbs:   double.tryParse(_carbCtrl.text) ?? 0,
        fat:     double.tryParse(_fatCtrl.text) ?? 0,
        fiber:   double.tryParse(_fiberCtrl.text) ?? 0,
        sugar:   double.tryParse(_sugarCtrl.text) ?? 0,
        sodium:  double.tryParse(_sodiumCtrl.text) ?? 0,
        time:    DateTime.now(),
      ));
      widget.onSaved();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  Widget _fieldWidget(BuildContext ctx, TextEditingController ctrl, String hint,
      IconData icon, {bool isNum = false, ValueChanged<String>? onChanged}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNum
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      style: TextStyle(fontSize: 14, color: ctx.textPrimary),
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 12, color: ctx.textHint),
        prefixIcon: Icon(icon, size: 17, color: AppColors.green),
        filled: true,
        fillColor: ctx.inputFill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: ctx.isDark
                ? BorderSide(color: ctx.mutedBorder, width: 1)
                : BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: ctx.isDark
                ? BorderSide(color: ctx.mutedBorder, width: 1)
                : BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: BorderSide(color: AppColors.green, width: 1.5)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: context.surfaceElevated,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 36, height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: context.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title row
              Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.orange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.add_rounded, color: AppColors.orange, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text('Log Food',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: context.textPrimary)),
                ],
              ),
              const SizedBox(height: 20),

              // ── Food name + live suggestions ──────────────────────────────
              _fieldWidget(context, _nameCtrl, 'Food name (e.g. Idli, Roti…)',
                  Icons.restaurant_outlined,
                  onChanged: _onNameChanged),

              // Auto-fill status badge
              if (_autoFilled) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.green.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.green.withOpacity(0.3), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome_rounded,
                          size: 13, color: AppColors.green),
                      const SizedBox(width: 6),
                      Text('Auto-filled from Indian food database',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.green)),
                    ],
                  ),
                ),
              ],

              // Suggestion tiles
              if (_suggestions.isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    color: context.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: context.cardBorder),
                    boxShadow: context.isDark
                        ? null
                        : [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 8,
                                offset: const Offset(0, 3))
                          ],
                  ),
                  child: Column(
                    children: _suggestions.asMap().entries.map((e) {
                      final idx  = e.key;
                      final food = e.value;
                      final isLast = idx == _suggestions.length - 1;
                      return InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => _selectFood(food),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 11),
                          decoration: BoxDecoration(
                            border: isLast
                                ? null
                                : Border(
                                    bottom: BorderSide(
                                        color: context.divider, width: 0.8)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 34, height: 34,
                                decoration: BoxDecoration(
                                  color: AppColors.green.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: Icon(Icons.restaurant_rounded,
                                    size: 16, color: AppColors.green),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(food.name,
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: context.textPrimary)),
                                    Text(
                                      '${food.calories.toStringAsFixed(0)} kcal · ${food.serving}',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: context.textHint),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    WorldFoodDatabase.foods.contains(food)
                                        ? '🌍'
                                        : '🇮🇳',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: context.inputFill,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(food.category,
                                        style: TextStyle(
                                            fontSize: 9,
                                            color: context.textMuted)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // ── Serving size (shown when DB food selected) ───────────────
              if (_selectedFood != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: _fieldWidget(
                          context, _servingCtrl, 'Serving (g)',
                          Icons.scale_outlined,
                          isNum: true,
                          onChanged: _onServingChanged),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: context.inputFill,
                        borderRadius: BorderRadius.circular(13),
                        border: context.isDark
                            ? Border.all(
                                color: context.mutedBorder, width: 1)
                            : null,
                      ),
                      child: Text(
                        _selectedFood!.serving,
                        style: TextStyle(
                            fontSize: 12,
                            color: context.textMuted,
                            fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // ── Macro fields row ─────────────────────────────────────────
              Text('Macronutrients',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: context.textSecondary)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _fieldWidget(context, _calCtrl, 'Calories (kcal)',
                        Icons.local_fire_department_outlined,
                        isNum: true),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _fieldWidget(context, _protCtrl, 'Protein (g)',
                        Icons.fitness_center_outlined,
                        isNum: true),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _fieldWidget(context, _carbCtrl, 'Carbs (g)',
                        Icons.grain_outlined,
                        isNum: true),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _fieldWidget(context, _fatCtrl, 'Fat (g)',
                        Icons.water_drop_outlined,
                        isNum: true),
                  ),
                ],
              ),

              // ── Micronutrients toggle ────────────────────────────────────
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () => setState(() => _showMicros = !_showMicros),
                child: Row(
                  children: [
                    Text('Micronutrients',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: context.textSecondary)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: context.inputFill,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('optional',
                          style: TextStyle(
                              fontSize: 9, color: context.textHint)),
                    ),
                    const Spacer(),
                    AnimatedRotation(
                      turns: _showMicros ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(Icons.keyboard_arrow_down_rounded,
                          size: 20, color: context.textMuted),
                    ),
                  ],
                ),
              ),

              if (_showMicros) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _fieldWidget(context, _fiberCtrl, 'Fiber (g)',
                          Icons.grass_outlined,
                          isNum: true),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _fieldWidget(context, _sugarCtrl, 'Sugar (g)',
                          Icons.cake_outlined,
                          isNum: true),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _fieldWidget(context, _sodiumCtrl, 'Sodium (mg)',
                    Icons.water_outlined,
                    isNum: true),
              ],

              const SizedBox(height: 24),

              // ── Save button ──────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.black87))
                      : const Text('Add to Log',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
