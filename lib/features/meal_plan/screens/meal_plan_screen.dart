import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/n_theme.dart';
import '../../../core/data/indian_food_database.dart';
import '../models/meal_plan_model.dart';
import '../services/meal_plan_service.dart';

// ── Constants ─────────────────────────────────────────────────────────────────

const _mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snacks'];

Color _mealColor(String meal) {
  switch (meal) {
    case 'Breakfast':
      return AppColors.orange;
    case 'Lunch':
      return AppColors.green;
    case 'Dinner':
      return const Color(0xFF9C6FDE);
    case 'Snacks':
      return AppColors.blue;
    default:
      return AppColors.primary;
  }
}

IconData _mealIcon(String meal) {
  switch (meal) {
    case 'Breakfast':
      return Icons.wb_sunny_rounded;
    case 'Lunch':
      return Icons.lunch_dining_rounded;
    case 'Dinner':
      return Icons.nightlight_round;
    case 'Snacks':
      return Icons.cookie_rounded;
    default:
      return Icons.restaurant_rounded;
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class MealPlanScreen extends StatefulWidget {
  const MealPlanScreen({super.key});

  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  final _service = MealPlanService();

  late DateTime _selectedDate;
  late List<DateTime> _weekDays;
  MealPlanDay? _day;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _weekDays = _buildWeek(_selectedDate);
    _loadDay();
  }

  List<DateTime> _buildWeek(DateTime ref) {
    // Monday-anchored week containing ref
    final monday = ref.subtract(Duration(days: ref.weekday - 1));
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  Future<void> _loadDay() async {
    setState(() => _loading = true);
    final day = await _service.loadDay(_selectedDate);
    if (mounted) setState(() { _day = day; _loading = false; });
  }

  void _selectDate(DateTime date) {
    setState(() => _selectedDate = date);
    _loadDay();
  }

  Future<void> _removeFood(String mealType, int index) async {
    await _service.removeFood(_selectedDate, index, mealType);
    await _loadDay();
  }

  // ── Bottom sheet: food picker ─────────────────────────────────────────────

  Future<void> _openFoodPicker(String mealType) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => _FoodPickerSheet(
        mealType: mealType,
        onAdd: (food) async {
          await _service.addFood(_selectedDate, food);
          await _loadDay();
        },
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.pageBg,
      appBar: AppBar(
        backgroundColor: context.pageBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: context.textSecondary),
        title: Text(
          'Meal Planner',
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: context.textPrimary),
        ),
      ),
      body: Column(
        children: [
          _WeekStrip(
            weekDays: _weekDays,
            selectedDate: _selectedDate,
            onSelect: _selectDate,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _day == null
                    ? const SizedBox()
                    : _DayContent(
                        day: _day!,
                        onAddFood: _openFoodPicker,
                        onRemoveFood: _removeFood,
                      ),
          ),
        ],
      ),
    );
  }
}

// ── Week date strip ───────────────────────────────────────────────────────────

class _WeekStrip extends StatelessWidget {
  final List<DateTime> weekDays;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelect;

  const _WeekStrip({
    required this.weekDays,
    required this.selectedDate,
    required this.onSelect,
  });

  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: weekDays.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final date = weekDays[i];
          final selected = _isSameDay(date, selectedDate);
          final isToday = _isSameDay(date, DateTime.now());

          return GestureDetector(
            onTap: () => onSelect(date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 52,
              decoration: BoxDecoration(
                color: selected ? AppColors.green : context.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isToday && !selected
                      ? AppColors.green.withOpacity(0.5)
                      : selected
                          ? Colors.transparent
                          : context.cardBorder,
                  width: isToday && !selected ? 1.5 : 1,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: AppColors.green.withOpacity(0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ]
                    : context.isDark
                        ? null
                        : [
                            BoxShadow(
                              color: context.shadowColor,
                              blurRadius: 4,
                            )
                          ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _dayLabels[i],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : context.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: selected ? Colors.white : context.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Day content (banner + meal sections) ─────────────────────────────────────

class _DayContent extends StatelessWidget {
  final MealPlanDay day;
  final ValueChanged<String> onAddFood;
  final Future<void> Function(String mealType, int index) onRemoveFood;

  const _DayContent({
    required this.day,
    required this.onAddFood,
    required this.onRemoveFood,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        _DayBanner(day: day),
        const SizedBox(height: 16),
        for (final meal in _mealTypes) ...[
          _MealSection(
            day: day,
            mealType: meal,
            onAddFood: onAddFood,
            onRemoveFood: onRemoveFood,
          ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}

// ── Day total banner ──────────────────────────────────────────────────────────

class _DayBanner extends StatelessWidget {
  final MealPlanDay day;

  const _DayBanner({required this.day});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A1A2E).withOpacity(0.4),
            blurRadius: 14,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department_rounded,
                  color: AppColors.orange, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Daily Total',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white60),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Planned',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white54),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                day.totalCalories.toStringAsFixed(0),
                style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1),
              ),
              const SizedBox(width: 6),
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Text(
                  'kcal',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white60),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _MacroCell(
                  label: 'Protein',
                  value: '${day.totalProtein.toStringAsFixed(1)}g',
                  color: AppColors.blue),
              _MacroCell(
                  label: 'Carbs',
                  value: '${day.totalCarbs.toStringAsFixed(1)}g',
                  color: AppColors.green),
              _MacroCell(
                  label: 'Fat',
                  value: '${day.totalFat.toStringAsFixed(1)}g',
                  color: AppColors.orange),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroCell extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MacroCell(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 3,
            height: 28,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: color)),
              Text(label,
                  style: const TextStyle(fontSize: 10, color: Colors.white54)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Meal section ──────────────────────────────────────────────────────────────

class _MealSection extends StatelessWidget {
  final MealPlanDay day;
  final String mealType;
  final ValueChanged<String> onAddFood;
  final Future<void> Function(String mealType, int index) onRemoveFood;

  const _MealSection({
    required this.day,
    required this.mealType,
    required this.onAddFood,
    required this.onRemoveFood,
  });

  @override
  Widget build(BuildContext context) {
    final color = _mealColor(mealType);
    final icon = _mealIcon(mealType);
    final foods = day.foodsForMeal(mealType);
    final mealCalories = day.caloriesForMeal(mealType);

    return Container(
      decoration: context.cardDecoration(radius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mealType,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: context.textPrimary),
                      ),
                      Text(
                        '${mealCalories.toStringAsFixed(0)} kcal',
                        style: TextStyle(fontSize: 11, color: color),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => onAddFood(mealType),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: color.withOpacity(0.3), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, size: 14, color: color),
                        const SizedBox(width: 4),
                        Text(
                          'Add',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: color),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Divider(height: 1, color: context.divider),

          // Food items or empty state
          if (foods.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.add_circle_outline_rounded,
                      size: 16, color: context.textHint),
                  const SizedBox(width: 8),
                  Text(
                    'Nothing planned yet',
                    style: TextStyle(fontSize: 13, color: context.textHint),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: foods.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: context.divider),
              itemBuilder: (_, i) => _FoodRow(
                food: foods[i],
                color: color,
                onDelete: () => onRemoveFood(mealType, i),
              ),
            ),

          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ── Food row inside a meal section ────────────────────────────────────────────

class _FoodRow extends StatelessWidget {
  final PlannedFood food;
  final Color color;
  final VoidCallback onDelete;

  const _FoodRow(
      {required this.food, required this.color, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: UniqueKey(),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red.withOpacity(0.12),
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.redAccent, size: 22),
      ),
      onDismissed: (_) => onDelete(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    food.name,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${food.grams.toStringAsFixed(0)}g  ·  '
                    'P:${food.protein.toStringAsFixed(1)}  '
                    'C:${food.carbs.toStringAsFixed(1)}  '
                    'F:${food.fat.toStringAsFixed(1)}',
                    style:
                        TextStyle(fontSize: 10, color: context.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${food.calories.toStringAsFixed(0)} kcal',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onDelete,
              child: Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Icon(Icons.close_rounded,
                    size: 16, color: context.textHint),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Food picker bottom sheet ──────────────────────────────────────────────────

class _FoodPickerSheet extends StatefulWidget {
  final String mealType;
  final Future<void> Function(PlannedFood food) onAdd;

  const _FoodPickerSheet({required this.mealType, required this.onAdd});

  @override
  State<_FoodPickerSheet> createState() => _FoodPickerSheetState();
}

class _FoodPickerSheetState extends State<_FoodPickerSheet> {
  final _ctrl = TextEditingController();
  String _selectedCategory = 'All';
  List<IndianFood> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onSearch);
    _ctrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _ctrl.text.trim();
    setState(() {
      _isSearching = q.isNotEmpty;
      _searchResults = q.isEmpty ? [] : IndianFoodDatabase.search(q);
    });
  }

  List<IndianFood> get _displayList {
    if (_isSearching) return _searchResults;
    if (_selectedCategory == 'All') return IndianFoodDatabase.popular;
    return IndianFoodDatabase.byCategory(_selectedCategory);
  }

  Future<void> _openServingSheet(IndianFood food) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _ServingSheet(
        food: food,
        mealType: widget.mealType,
        onConfirm: (planned) async {
          Navigator.pop(ctx); // close serving sheet
          Navigator.pop(context); // close food picker
          await widget.onAdd(planned);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _displayList;
    final color = _mealColor(widget.mealType);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: context.surfaceElevated,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.mutedBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_mealIcon(widget.mealType), size: 18, color: color),
                ),
                const SizedBox(width: 10),
                Text(
                  'Add to ${widget.mealType}',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: context.textPrimary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _ctrl,
              textInputAction: TextInputAction.search,
              style: TextStyle(color: context.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search food...',
                hintStyle: TextStyle(fontSize: 13, color: context.textHint),
                prefixIcon:
                    const Icon(Icons.search_rounded, color: AppColors.green),
                suffixIcon: _ctrl.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _ctrl.clear();
                          setState(() {
                            _isSearching = false;
                            _searchResults = [];
                          });
                        },
                        child: Icon(Icons.close_rounded,
                            color: context.textMuted, size: 18),
                      )
                    : null,
                filled: true,
                fillColor: context.inputFill,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                      color: context.isDark
                          ? context.mutedBorder
                          : Colors.transparent),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: AppColors.green, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Category chips
          if (!_isSearching)
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: IndianFoodDatabase.categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final cat = IndianFoodDatabase.categories[i];
                  final selected = cat == _selectedCategory;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: selected ? color : context.inputFill,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: selected
                              ? Colors.transparent
                              : context.mutedBorder,
                        ),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? Colors.white
                              : context.textSecondary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 8),

          // Food list
          Expanded(
            child: list.isEmpty && _isSearching
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded,
                            size: 48, color: context.textHint),
                        const SizedBox(height: 10),
                        Text(
                          'No results for "${_ctrl.text}"',
                          style: TextStyle(color: context.textMuted),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding:
                        const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: list.length,
                    itemBuilder: (_, i) => _PickerFoodTile(
                      food: list[i],
                      mealColor: color,
                      onTap: () => _openServingSheet(list[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Picker food tile ──────────────────────────────────────────────────────────

class _PickerFoodTile extends StatelessWidget {
  final IndianFood food;
  final Color mealColor;
  final VoidCallback onTap;

  const _PickerFoodTile(
      {required this.food, required this.mealColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: context.cardDecoration(radius: BorderRadius.circular(14)),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: mealColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(Icons.restaurant_rounded,
                      size: 20, color: mealColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        food.name,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: context.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${food.category}  ·  Serving: ${food.serving}',
                        style: TextStyle(
                            fontSize: 10, color: context.textHint),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${food.calories.toStringAsFixed(0)}',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: mealColor),
                    ),
                    Text('kcal/100g',
                        style: TextStyle(
                            fontSize: 9, color: context.textHint)),
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

// ── Serving size sheet ────────────────────────────────────────────────────────

class _ServingSheet extends StatefulWidget {
  final IndianFood food;
  final String mealType;
  final void Function(PlannedFood planned) onConfirm;

  const _ServingSheet({
    required this.food,
    required this.mealType,
    required this.onConfirm,
  });

  @override
  State<_ServingSheet> createState() => _ServingSheetState();
}

class _ServingSheetState extends State<_ServingSheet> {
  late double _grams;
  late TextEditingController _customCtrl;

  @override
  void initState() {
    super.initState();
    _grams = widget.food.servingGrams;
    _customCtrl =
        TextEditingController(text: _grams.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  void _setGrams(double g) {
    setState(() {
      _grams = g;
      _customCtrl.text = g.toStringAsFixed(0);
    });
  }

  Widget _servingChip(BuildContext ctx, String label, double g) {
    final selected = (_grams - g).abs() < 0.5;
    final color = _mealColor(widget.mealType);
    return GestureDetector(
      onTap: () => _setGrams(g),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : ctx.inputFill,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color : ctx.mutedBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : ctx.textSecondary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scaled = widget.food.scaled(_grams);
    final color = _mealColor(widget.mealType);

    return Container(
      decoration: BoxDecoration(
        color: context.surfaceElevated,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Food header
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_mealIcon(widget.mealType),
                      size: 24, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.food.name,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: context.textPrimary),
                        maxLines: 2,
                      ),
                      Text(
                        widget.food.category,
                        style: TextStyle(
                            fontSize: 12, color: context.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Macro preview
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.inputFill,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _MacroPreview('${scaled.calories.toStringAsFixed(0)}',
                      'kcal', AppColors.orange, context),
                  _MacroPreview('${scaled.protein.toStringAsFixed(1)}g',
                      'Protein', AppColors.blue, context),
                  _MacroPreview('${scaled.carbs.toStringAsFixed(1)}g',
                      'Carbs', AppColors.green, context),
                  _MacroPreview('${scaled.fat.toStringAsFixed(1)}g',
                      'Fat', const Color(0xFF9C6FDE), context),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Serving presets
            Text(
              'Serving Size',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: context.textSecondary),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _servingChip(
                  context,
                  '${widget.food.serving}\n(${widget.food.servingGrams.toStringAsFixed(0)}g)',
                  widget.food.servingGrams,
                ),
                _servingChip(context, '100g', 100),
                _servingChip(context, '150g', 150),
                _servingChip(context, '200g', 200),
              ],
            ),
            const SizedBox(height: 14),

            // Custom grams field
            TextField(
              controller: _customCtrl,
              keyboardType: TextInputType.number,
              style: TextStyle(color: context.textPrimary),
              onChanged: (v) {
                final g = double.tryParse(v);
                if (g != null && g > 0) setState(() => _grams = g);
              },
              decoration: InputDecoration(
                hintText: 'Custom amount (g)',
                hintStyle:
                    TextStyle(fontSize: 13, color: context.textHint),
                prefixIcon: const Icon(Icons.edit_outlined,
                    size: 18, color: AppColors.green),
                suffixText: 'g',
                filled: true,
                fillColor: context.inputFill,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: context.isDark
                          ? context.mutedBorder
                          : Colors.transparent),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.green, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Confirm button
            GestureDetector(
              onTap: () {
                final planned = PlannedFood(
                  name: widget.food.name,
                  calories: scaled.calories,
                  protein: scaled.protein,
                  carbs: scaled.carbs,
                  fat: scaled.fat,
                  grams: _grams,
                  mealType: widget.mealType,
                );
                widget.onConfirm(planned);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'Add to ${widget.mealType}  ·  ${scaled.calories.toStringAsFixed(0)} kcal',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Macro preview chip (used inside serving sheet) ────────────────────────────

Widget _MacroPreview(
    String value, String label, Color color, BuildContext ctx) {
  return Column(
    children: [
      Text(value,
          style: TextStyle(
              fontWeight: FontWeight.w800, fontSize: 15, color: color)),
      Text(label,
          style: TextStyle(fontSize: 10, color: ctx.textMuted)),
    ],
  );
}
