import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/n_theme.dart';
import '../../../core/data/indian_food_database.dart';
import '../../../core/data/world_food_database.dart';
import '../models/calorie_model.dart';
import '../services/calorie_service.dart';
import '../../custom_food/models/custom_food_model.dart';
import '../../custom_food/services/custom_food_service.dart';

class FoodSearchScreen extends StatefulWidget {
  const FoodSearchScreen({super.key});

  @override
  State<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends State<FoodSearchScreen> {
  final _ctrl = TextEditingController();
  final _calorieService = CalorieService();
  final _customFoodService = CustomFoodService();

  List<IndianFood> _results = [];
  List<CustomFoodModel> _customFoods = [];
  String _selectedCategory = 'All';
  bool _isSearching = false;
  // 'Indian' | 'World' | 'All'
  String _origin = 'Indian';

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_onTextChanged);
    _loadCustomFoods();
  }

  Future<void> _loadCustomFoods() async {
    final foods = await _customFoodService.loadAll();
    if (mounted) setState(() => _customFoods = foods);
  }

  void _onTextChanged() {
    final q = _ctrl.text.trim();
    List<IndianFood> results = [];
    if (q.isNotEmpty) {
      if (_origin == 'Indian') {
        results = IndianFoodDatabase.search(q);
      } else if (_origin == 'World') {
        results = WorldFoodDatabase.search(q);
      } else {
        // 'All' — merge both, Indian first
        results = [
          ...IndianFoodDatabase.search(q),
          ...WorldFoodDatabase.search(q),
        ];
      }
    }
    setState(() {
      _isSearching = q.isNotEmpty;
      _results = results;
      // reset category when origin changes mid-search
    });
  }

  void _setOrigin(String origin) {
    setState(() {
      _origin = origin;
      _selectedCategory = 'All';
    });
    _onTextChanged();
  }

  List<String> get _activeCategories {
    if (_origin == 'World') return WorldFoodDatabase.categories;
    if (_origin == 'Indian') return IndianFoodDatabase.categories;
    // 'All' — Indian categories (most specific)
    return IndianFoodDatabase.categories;
  }

  List<IndianFood> get _displayList {
    if (_isSearching) return _results;
    if (_origin == 'World') {
      return _selectedCategory == 'All'
          ? WorldFoodDatabase.popular
          : WorldFoodDatabase.byCategory(_selectedCategory);
    }
    if (_origin == 'All') {
      if (_selectedCategory == 'All') {
        return [...IndianFoodDatabase.popular, ...WorldFoodDatabase.popular];
      }
      return IndianFoodDatabase.byCategory(_selectedCategory);
    }
    // Indian
    if (_selectedCategory == 'All') return IndianFoodDatabase.popular;
    return IndianFoodDatabase.byCategory(_selectedCategory);
  }

  // ── Add food with serving size dialog ────────────────────────────────────

  Future<void> _showAddDialog(IndianFood food) async {
    double selectedGrams = food.servingGrams;
    final customCtrl = TextEditingController(
        text: food.servingGrams.toStringAsFixed(0));

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setModal) {
          final scaled = food.scaled(selectedGrams);

          return Container(
            decoration: BoxDecoration(
              color: ctx.surfaceElevated,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.restaurant_rounded,
                            size: 22, color: Color(0xFF6BCB77)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              food.name,
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: ctx.textPrimary),
                              maxLines: 2,
                            ),
                            Text(
                              food.category,
                              style: TextStyle(
                                  fontSize: 12, color: ctx.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Nutrition preview
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: ctx.inputFill,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _macroChip(ctx, '${scaled.calories.toStringAsFixed(0)}',
                            'kcal', AppColors.orange),
                        _macroChip(ctx, '${scaled.protein.toStringAsFixed(1)}g',
                            'Protein', AppColors.blue),
                        _macroChip(ctx, '${scaled.carbs.toStringAsFixed(1)}g',
                            'Carbs', AppColors.green),
                        _macroChip(ctx, '${scaled.fat.toStringAsFixed(1)}g',
                            'Fat', Colors.purple),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Serving presets
                  Text('Serving Size',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: ctx.textSecondary)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _servingChip(
                          ctx,
                          '${food.serving}\n(${food.servingGrams.toStringAsFixed(0)}g)',
                          food.servingGrams,
                          selectedGrams, (g) {
                        setModal(() {
                          selectedGrams = g;
                          customCtrl.text = g.toStringAsFixed(0);
                        });
                      }),
                      _servingChip(ctx, '100g', 100, selectedGrams, (g) {
                        setModal(() {
                          selectedGrams = g;
                          customCtrl.text = g.toStringAsFixed(0);
                        });
                      }),
                      _servingChip(ctx, '150g', 150, selectedGrams, (g) {
                        setModal(() {
                          selectedGrams = g;
                          customCtrl.text = g.toStringAsFixed(0);
                        });
                      }),
                      _servingChip(ctx, '200g', 200, selectedGrams, (g) {
                        setModal(() {
                          selectedGrams = g;
                          customCtrl.text = g.toStringAsFixed(0);
                        });
                      }),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Custom grams field
                  TextField(
                    controller: customCtrl,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: ctx.textPrimary),
                    onChanged: (v) {
                      final g = double.tryParse(v);
                      if (g != null && g > 0) {
                        setModal(() => selectedGrams = g);
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'Custom amount (g)',
                      hintStyle: TextStyle(
                          fontSize: 13, color: ctx.textHint),
                      prefixIcon: const Icon(Icons.edit_outlined,
                          size: 18, color: Color(0xFF6BCB77)),
                      suffixText: 'g',
                      filled: true,
                      fillColor: ctx.inputFill,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: ctx.isDark
                                ? ctx.mutedBorder
                                : Colors.transparent),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: AppColors.green, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Add button
                  GestureDetector(
                    onTap: () async {
                      Navigator.pop(ctx);
                      await _addFood(food.scaled(selectedGrams));
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Add ${scaled.calories.toStringAsFixed(0)} kcal to Log',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
    customCtrl.dispose();
  }

  Widget _originChip(String emoji, String label, String value, Color color) {
    final selected = _origin == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => _setOrigin(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              '$emoji $label',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected
                    ? Colors.white
                    : context.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _macroChip(BuildContext ctx, String value, String label, Color color) {
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

  Widget _servingChip(BuildContext ctx, String label, double grams,
      double selected, ValueChanged<double> onTap) {
    final isSelected = (grams - selected).abs() < 0.1;
    return GestureDetector(
      onTap: () => onTap(grams),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.green : ctx.inputFill,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.green : ctx.mutedBorder,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : ctx.textSecondary,
          ),
        ),
      ),
    );
  }

  Future<void> _addFood(IndianFood food) async {
    final entry = CalorieEntry(
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
    );
    await _calorieService.addEntry(entry);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${food.name} (${food.servingGrams.toStringAsFixed(0)}g) added to log'),
          backgroundColor: AppColors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onTextChanged);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final list = _displayList;

    return Scaffold(
      backgroundColor: context.pageBg,
      appBar: AppBar(
        backgroundColor: context.pageBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: context.textSecondary),
        title: Text(
          'Search Foods',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: context.textPrimary),
        ),
      ),
      body: Column(
        children: [
          // ── Origin toggle: Indian / World / All ───────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.cardBorder),
              ),
              child: Row(
                children: [
                  _originChip('🇮🇳', 'Indian', 'Indian',
                      const Color(0xFFFF9933)),
                  const SizedBox(width: 4),
                  _originChip('🌍', 'World', 'World',
                      const Color(0xFF4D96FF)),
                  const SizedBox(width: 4),
                  _originChip('✨', 'All', 'All',
                      AppColors.green),
                ],
              ),
            ),
          ),

          // ── Search bar ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    textInputAction: TextInputAction.search,
                    style: TextStyle(color: context.textPrimary),
                    decoration: InputDecoration(
                      hintText: _origin == 'Indian'
                          ? 'Search — idli, dal, biryani…'
                          : _origin == 'World'
                              ? 'Search — pasta, sushi, burger…'
                              : 'Search any food…',
                      hintStyle: TextStyle(
                          fontSize: 13, color: context.textHint),
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: Color(0xFF6BCB77)),
                      suffixIcon: _ctrl.text.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _ctrl.clear();
                                setState(() {
                                  _isSearching = false;
                                  _results = [];
                                });
                              },
                              child: Icon(Icons.close_rounded,
                                  color: context.textMuted, size: 18),
                            )
                          : null,
                      filled: true,
                      fillColor: context.surface,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                            color: context.isDark
                                ? context.cardBorder
                                : Colors.transparent),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                            color: Color(0xFF6BCB77), width: 1.5),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Category chips (only when not searching) ──────────────
          if (!_isSearching)
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _activeCategories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final cat = _activeCategories[i];
                  final selected = cat == _selectedCategory;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.green
                            : context.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: selected
                                ? Colors.transparent
                                : context.cardBorder),
                        boxShadow: selected
                            ? []
                            : [
                                BoxShadow(
                                  color: context.shadowColor,
                                  blurRadius: 4,
                                )
                              ],
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

          const SizedBox(height: 12),

          // ── Section heading ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  _isSearching
                      ? '${_results.length} result${_results.length == 1 ? '' : 's'}'
                      : _selectedCategory == 'All'
                          ? (_origin == 'World'
                              ? 'Popular World Foods'
                              : _origin == 'All'
                                  ? 'Popular Foods'
                                  : 'Popular Indian Foods')
                          : _selectedCategory,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: context.textMuted),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(
                        context.isDark ? 0.2 : 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.local_dining_rounded,
                          size: 11, color: context.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        _origin == 'Indian'
                            ? '${IndianFoodDatabase.foods.length} Indian foods'
                            : _origin == 'World'
                                ? '${WorldFoodDatabase.foods.length} world foods'
                                : '${IndianFoodDatabase.foods.length + WorldFoodDatabase.foods.length} total',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: context.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ── My Foods banner (shown when not searching) ────────────
          if (!_isSearching && _customFoods.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: GestureDetector(
                onTap: () => Navigator.pushNamed(context, AppRoutes.customFoods)
                    .then((_) => _loadCustomFoods()),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withOpacity(
                        context.isDark ? 0.15 : 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.add_box_rounded,
                          color: AppColors.orange, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        'My Foods · ${_customFoods.length} saved',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.orange),
                      ),
                      const Spacer(),
                      Icon(Icons.chevron_right_rounded,
                          color: AppColors.orange, size: 18),
                    ],
                  ),
                ),
              ),
            ),

          // ── Food list ─────────────────────────────────────────────
          Expanded(
            child: list.isEmpty && _isSearching
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off_rounded,
                              size: 52, color: context.textHint),
                          const SizedBox(height: 12),
                          Text(
                            'No ${_origin == 'All' ? '' : _origin + ' '}food found for "${_ctrl.text}"',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: context.textMuted, height: 1.5),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try a different spelling or switch origin above.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 12, color: context.textHint),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                    itemCount: list.length,
                    itemBuilder: (ctx, i) =>
                        _FoodTile(food: list[i], onAdd: _showAddDialog),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Food tile widget ──────────────────────────────────────────────────────────

class _FoodTile extends StatelessWidget {
  final IndianFood food;
  final Function(IndianFood) onAdd;

  const _FoodTile({required this.food, required this.onAdd});

  Color get _categoryColor {
    switch (food.category) {
      // Indian
      case 'Breakfast':      return const Color(0xFFFF9F1C);
      case 'Rice':           return const Color(0xFF6BCB77);
      case 'Dal':            return const Color(0xFFFFBF00);
      case 'Curry':          return Colors.redAccent;
      case 'Roti & Bread':   return const Color(0xFF8B5CF6);
      case 'Snacks':         return const Color(0xFF4D96FF);
      case 'Street Food':    return Colors.deepOrange;
      case 'Sweets':         return Colors.pink;
      case 'Dairy':          return Colors.lightBlue;
      case 'Drinks':         return Colors.teal;
      case 'Fruits':         return const Color(0xFF6BCB77);
      // World
      case 'Italian':        return const Color(0xFF009246);
      case 'Chinese':        return const Color(0xFFDE2910);
      case 'American':       return const Color(0xFF3C3B6E);
      case 'Japanese':       return const Color(0xFFBC002D);
      case 'Mexican':        return const Color(0xFF006847);
      case 'Thai':           return const Color(0xFFFF6B35);
      case 'Mediterranean':  return const Color(0xFF1B6CA8);
      case 'Continental':    return const Color(0xFF7B5EA7);
      default:               return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => onAdd(food),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _categoryColor.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      food.name.isNotEmpty ? food.name[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: _categoryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        food.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        food.category,
                        style: TextStyle(fontSize: 11, color: _categoryColor),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'P ${food.protein.toStringAsFixed(1)}g',
                            style: TextStyle(
                                fontSize: 10, color: context.textMuted),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'C ${food.carbs.toStringAsFixed(1)}g',
                            style: TextStyle(
                                fontSize: 10, color: context.textMuted),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'F ${food.fat.toStringAsFixed(1)}g',
                            style: TextStyle(
                                fontSize: 10, color: context.textMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${food.calories.toStringAsFixed(0)}',
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: _categoryColor),
                    ),
                    Text('kcal/100g',
                        style: TextStyle(
                            fontSize: 9, color: context.textHint)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '+ Add',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ),
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
