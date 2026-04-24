import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/n_theme.dart';
import '../models/custom_food_model.dart';
import '../services/custom_food_service.dart';

class CustomFoodScreen extends StatefulWidget {
  const CustomFoodScreen({super.key});

  @override
  State<CustomFoodScreen> createState() => _CustomFoodScreenState();
}

class _CustomFoodScreenState extends State<CustomFoodScreen> {
  final CustomFoodService _service = CustomFoodService();
  final TextEditingController _searchCtrl = TextEditingController();

  List<CustomFoodModel> _allFoods = [];
  List<CustomFoodModel> _filteredFoods = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final foods = await _service.loadAll();
    if (mounted) {
      setState(() {
        _allFoods = foods;
        _filteredFoods = _applyFilter(foods, _searchCtrl.text);
        _loading = false;
      });
    }
  }

  void _onSearchChanged() {
    setState(() {
      _filteredFoods = _applyFilter(_allFoods, _searchCtrl.text);
    });
  }

  List<CustomFoodModel> _applyFilter(List<CustomFoodModel> foods, String query) {
    if (query.trim().isEmpty) return foods;
    final q = query.trim().toLowerCase();
    return foods.where((f) => f.name.toLowerCase().contains(q)).toList();
  }

  // ── Bottom sheet ──────────────────────────────────────────────────────────

  void _openSheet({CustomFoodModel? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddEditSheet(
        existing: existing,
        onSave: (food) async {
          await _service.save(food);
          await _load();
        },
      ),
    );
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  Future<bool> _confirmDelete(CustomFoodModel food) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Food',
          style: TextStyle(
              fontWeight: FontWeight.w800, color: ctx.textPrimary, fontSize: 16),
        ),
        content: Text(
          'Remove "${food.name}" from your custom foods?',
          style: TextStyle(fontSize: 13, color: ctx.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: TextStyle(color: ctx.textMuted, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _delete(CustomFoodModel food) async {
    final ok = await _confirmDelete(food);
    if (!ok) return;
    await _service.delete(food.id);
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('"${food.name}" deleted'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.pageBg,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredFoods.isEmpty
                    ? _buildEmptyState()
                    : _buildList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openSheet(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black87,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: context.pageBg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(10),
            border: context.isDark
                ? Border.all(color: context.cardBorder, width: 1)
                : null,
            boxShadow: context.isDark
                ? null
                : [
                    BoxShadow(
                        color: context.shadowColor,
                        blurRadius: 6,
                        offset: const Offset(0, 2))
                  ],
          ),
          child: Icon(Icons.arrow_back_rounded,
              size: 18, color: context.textPrimary),
        ),
      ),
      title: Text(
        'My Foods',
        style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: context.textPrimary),
      ),
      centerTitle: false,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(context.isDark ? 0.18 : 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.restaurant_menu_rounded,
                    size: 14, color: AppColors.primary),
                const SizedBox(width: 5),
                Text(
                  '${_allFoods.length} saved',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: TextField(
        controller: _searchCtrl,
        style: TextStyle(fontSize: 14, color: context.textPrimary),
        decoration: InputDecoration(
          hintText: 'Search my foods…',
          hintStyle: TextStyle(fontSize: 13, color: context.textHint),
          prefixIcon:
              Icon(Icons.search_rounded, size: 20, color: context.textMuted),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchCtrl.clear();
                    FocusScope.of(context).unfocus();
                  },
                  child:
                      Icon(Icons.close_rounded, size: 18, color: context.textMuted),
                )
              : null,
          filled: true,
          fillColor: context.inputFill,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: context.isDark
                ? BorderSide(color: context.mutedBorder, width: 1)
                : BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: context.isDark
                ? BorderSide(color: context.mutedBorder, width: 1)
                : BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        itemCount: _filteredFoods.length,
        itemBuilder: (_, i) => _FoodTile(
          food: _filteredFoods[i],
          onTap: () => _openSheet(existing: _filteredFoods[i]),
          onEdit: () => _openSheet(existing: _filteredFoods[i]),
          onDelete: () => _delete(_filteredFoods[i]),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasQuery = _searchCtrl.text.trim().isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                hasQuery
                    ? Icons.search_off_rounded
                    : Icons.restaurant_menu_rounded,
                size: 38,
                color: AppColors.primary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              hasQuery ? 'No results for "${_searchCtrl.text}"' : 'No custom foods yet',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: context.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              hasQuery
                  ? 'Try a different search term.'
                  : 'Tap + to add your first food.',
              style: TextStyle(fontSize: 13, color: context.textMuted),
              textAlign: TextAlign.center,
            ),
            if (!hasQuery) ...[
              const SizedBox(height: 28),
              GestureDetector(
                onTap: () => _openSheet(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.primary.withOpacity(0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.add_rounded, size: 20, color: Colors.black87),
                      SizedBox(width: 8),
                      Text(
                        'Add Custom Food',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Food Tile ────────────────────────────────────────────────────────────────

class _FoodTile extends StatelessWidget {
  final CustomFoodModel food;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FoodTile({
    required this.food,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('food_${food.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.10),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.redAccent, size: 22),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false; // we handle delete ourselves (with confirmation)
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: context.cardDecoration(radius: BorderRadius.circular(18)),
          child: Row(
            children: [
              // Icon badge
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: (food.isRecipe ? AppColors.orange : AppColors.primary)
                      .withOpacity(context.isDark ? 0.18 : 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  food.isRecipe
                      ? Icons.menu_book_rounded
                      : Icons.fastfood_rounded,
                  size: 22,
                  color:
                      food.isRecipe ? AppColors.orange : AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              // Name + macros
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            food.name,
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: context.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (food.isRecipe)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.orange
                                  .withOpacity(context.isDark ? 0.18 : 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Recipe',
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.orange),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${food.servingLabel}  ·  ${food.servingGrams.toStringAsFixed(0)}g',
                      style:
                          TextStyle(fontSize: 11, color: context.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _MacroPill(
                            label: 'P',
                            value: food.protein,
                            color: AppColors.blue),
                        const SizedBox(width: 4),
                        _MacroPill(
                            label: 'C',
                            value: food.carbs,
                            color: const Color(0xFFFFBF00)),
                        const SizedBox(width: 4),
                        _MacroPill(
                            label: 'F',
                            value: food.fat,
                            color: AppColors.orange),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Calories + actions
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    food.calories.toStringAsFixed(0),
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                        color: food.isRecipe ? AppColors.orange : AppColors.green),
                  ),
                  Text(
                    'kcal/100g',
                    style: TextStyle(fontSize: 9, color: context.textHint),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _ActionIcon(
                        icon: Icons.edit_rounded,
                        color: AppColors.blue,
                        onTap: onEdit,
                      ),
                      const SizedBox(width: 6),
                      _ActionIcon(
                        icon: Icons.delete_outline_rounded,
                        color: Colors.redAccent,
                        onTap: onDelete,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MacroPill extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _MacroPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(context.isDark ? 0.15 : 0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label ${value.toStringAsFixed(1)}g',
        style: TextStyle(
            fontSize: 9, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionIcon({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color.withOpacity(context.isDark ? 0.15 : 0.09),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 15, color: color),
      ),
    );
  }
}

// ── Add / Edit Bottom Sheet ──────────────────────────────────────────────────

class _AddEditSheet extends StatefulWidget {
  final CustomFoodModel? existing;
  final Future<void> Function(CustomFoodModel food) onSave;

  const _AddEditSheet({
    required this.existing,
    required this.onSave,
  });

  @override
  State<_AddEditSheet> createState() => _AddEditSheetState();
}

class _AddEditSheetState extends State<_AddEditSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _calCtrl;
  late final TextEditingController _proCtrl;
  late final TextEditingController _carbCtrl;
  late final TextEditingController _fatCtrl;
  late final TextEditingController _servingGramsCtrl;
  late final TextEditingController _servingLabelCtrl;

  late bool _isRecipe;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _calCtrl =
        TextEditingController(text: e != null ? e.calories.toString() : '');
    _proCtrl =
        TextEditingController(text: e != null ? e.protein.toString() : '');
    _carbCtrl =
        TextEditingController(text: e != null ? e.carbs.toString() : '');
    _fatCtrl = TextEditingController(text: e != null ? e.fat.toString() : '');
    _servingGramsCtrl = TextEditingController(
        text: e != null ? e.servingGrams.toString() : '100');
    _servingLabelCtrl =
        TextEditingController(text: e?.servingLabel ?? '100g');
    _isRecipe = e?.isRecipe ?? false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _calCtrl.dispose();
    _proCtrl.dispose();
    _carbCtrl.dispose();
    _fatCtrl.dispose();
    _servingGramsCtrl.dispose();
    _servingLabelCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final food = CustomFoodModel(
      id: widget.existing?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameCtrl.text.trim(),
      calories: double.tryParse(_calCtrl.text) ?? 0,
      protein: double.tryParse(_proCtrl.text) ?? 0,
      carbs: double.tryParse(_carbCtrl.text) ?? 0,
      fat: double.tryParse(_fatCtrl.text) ?? 0,
      servingGrams: double.tryParse(_servingGramsCtrl.text) ?? 100,
      servingLabel: _servingLabelCtrl.text.trim().isEmpty
          ? '100g'
          : _servingLabelCtrl.text.trim(),
      isRecipe: _isRecipe,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );

    await widget.onSave(food);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        decoration: BoxDecoration(
          color: context.surfaceElevated,
          borderRadius: BorderRadius.circular(28),
          border: context.isDark
              ? Border.all(color: context.cardBorder, width: 1)
              : null,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: context.textHint.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 18),

                // Header
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.primary
                            .withOpacity(context.isDark ? 0.18 : 0.12),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(
                        isEdit
                            ? Icons.edit_rounded
                            : Icons.add_circle_outline_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isEdit ? 'Edit Food' : 'Add Custom Food',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: context.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Food / Recipe toggle
                _buildToggle(context),
                const SizedBox(height: 18),

                // Name
                _field(
                  context,
                  controller: _nameCtrl,
                  hint: 'Food name',
                  icon: Icons.fastfood_rounded,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                ),
                const SizedBox(height: 12),

                // Calories
                _field(
                  context,
                  controller: _calCtrl,
                  hint: 'Calories per 100g (kcal)',
                  icon: Icons.local_fire_department_rounded,
                  isNum: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (double.tryParse(v) == null) return 'Invalid number';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Protein / Carbs / Fat row
                _sectionLabel(context, 'MACROS PER 100G'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _field(
                        context,
                        controller: _proCtrl,
                        hint: 'Protein g',
                        icon: Icons.egg_alt_rounded,
                        isNum: true,
                        iconColor: AppColors.blue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _field(
                        context,
                        controller: _carbCtrl,
                        hint: 'Carbs g',
                        icon: Icons.grain_rounded,
                        isNum: true,
                        iconColor: const Color(0xFFFFBF00),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _field(
                        context,
                        controller: _fatCtrl,
                        hint: 'Fat g',
                        icon: Icons.opacity_rounded,
                        isNum: true,
                        iconColor: AppColors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Serving size
                _sectionLabel(context, 'DEFAULT SERVING'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _field(
                        context,
                        controller: _servingGramsCtrl,
                        hint: 'Size (g)',
                        icon: Icons.monitor_weight_outlined,
                        isNum: true,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          final d = double.tryParse(v);
                          if (d == null || d <= 0) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 3,
                      child: _field(
                        context,
                        controller: _servingLabelCtrl,
                        hint: 'Label (e.g. 1 bowl)',
                        icon: Icons.label_outline_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // Save button
                GestureDetector(
                  onTap: _saving ? null : _save,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      color: AppColors.primary
                          .withOpacity(_saving ? 0.6 : 1.0),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: AppColors.primary.withOpacity(0.30),
                            blurRadius: 12,
                            offset: const Offset(0, 4))
                      ],
                    ),
                    child: Center(
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.black54),
                            )
                          : Text(
                              isEdit ? 'Save Changes' : 'Save Food',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: Colors.black87),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggle(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.inputFill,
        borderRadius: BorderRadius.circular(14),
        border: context.isDark
            ? Border.all(color: context.mutedBorder, width: 1)
            : null,
      ),
      child: Row(
        children: [
          _ToggleOption(
            label: 'Food',
            icon: Icons.fastfood_rounded,
            selected: !_isRecipe,
            activeColor: AppColors.primary,
            onTap: () => setState(() => _isRecipe = false),
          ),
          _ToggleOption(
            label: 'Recipe',
            icon: Icons.menu_book_rounded,
            selected: _isRecipe,
            activeColor: AppColors.orange,
            onTap: () => setState(() => _isRecipe = true),
          ),
        ],
      ),
    );
  }

  Widget _field(
    BuildContext context, {
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isNum = false,
    Color? iconColor,
    String? Function(String?)? validator,
  }) {
    final ic = iconColor ?? AppColors.green;
    return TextFormField(
      controller: controller,
      keyboardType: isNum
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      style: TextStyle(fontSize: 13, color: context.textPrimary),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 12, color: context.textHint),
        prefixIcon: Icon(icon, size: 16, color: ic),
        filled: true,
        fillColor: context.inputFill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: context.isDark
                ? BorderSide(color: context.mutedBorder, width: 1)
                : BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: context.isDark
                ? BorderSide(color: context.mutedBorder, width: 1)
                : BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: BorderSide(color: AppColors.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide:
                const BorderSide(color: Colors.redAccent, width: 1.2)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide:
                const BorderSide(color: Colors.redAccent, width: 1.5)),
        errorStyle: const TextStyle(fontSize: 10),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String label) {
    return Text(
      label,
      style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: context.textHint,
          letterSpacing: 1.1),
    );
  }
}

// ── Toggle Option ────────────────────────────────────────────────────────────

class _ToggleOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color activeColor;
  final VoidCallback onTap;

  const _ToggleOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: selected
                ? [
                    BoxShadow(
                        color: activeColor.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3))
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: selected ? Colors.black87 : context.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.black87 : context.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
