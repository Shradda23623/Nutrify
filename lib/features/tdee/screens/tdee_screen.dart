import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/n_theme.dart';
import '../models/tdee_model.dart';

class TdeeScreen extends StatefulWidget {
  const TdeeScreen({super.key});

  @override
  State<TdeeScreen> createState() => _TdeeScreenState();
}

class _TdeeScreenState extends State<TdeeScreen> {
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();

  String _gender = 'Male';
  String _activity = 'Moderately Active';
  String _goal = 'maintain';
  TdeeModel? _result;

  void _calculate() {
    final w = double.tryParse(_weightCtrl.text);
    final h = double.tryParse(_heightCtrl.text);
    final a = int.tryParse(_ageCtrl.text);

    if (w == null || h == null || a == null || w <= 0 || h <= 0 || a <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields correctly.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _result = TdeeModel(
        weightKg: w,
        heightCm: h,
        age: a,
        gender: _gender,
        activityLevel: _activity,
        goal: _goal,
      );
    });
    FocusScope.of(context).unfocus();
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.pageBg,
      appBar: AppBar(
        title: Text('TDEE Calculator',
            style: TextStyle(color: context.textPrimary)),
        backgroundColor: context.pageBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: context.textSecondary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // What is TDEE banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(context.isDark ? 0.2 : 0.25),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.flash_on_rounded,
                      size: 22, color: Colors.deepOrange),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'TDEE is the total calories your body burns per day. '
                      'Eat below it to lose weight, above to gain.',
                      style: TextStyle(
                          fontSize: 12, height: 1.5, color: context.textSecondary),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Input card
            _card(
              context: context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your Details',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary)),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                          child: _field(context, _weightCtrl, 'Weight (kg)',
                              Icons.monitor_weight_outlined)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _field(context, _heightCtrl, 'Height (cm)',
                              Icons.height_rounded)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                          child: _field(
                              context, _ageCtrl, 'Age', Icons.cake_rounded)),
                      const SizedBox(width: 10),
                      Expanded(child: _genderPicker(context)),
                    ],
                  ),

                  const SizedBox(height: 16),
                  Text('Activity Level',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: context.textSecondary)),
                  const SizedBox(height: 8),
                  _activityDropdown(context),

                  const SizedBox(height: 16),
                  Text('Your Goal',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: context.textSecondary)),
                  const SizedBox(height: 8),
                  _goalSelector(context),
                ],
              ),
            ),

            const SizedBox(height: 16),

            GestureDetector(
              onTap: _calculate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.primary.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: const Center(
                  child: Text('Calculate TDEE',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ),

            // Results
            if (_result != null) ...[
              const SizedBox(height: 24),

              // Main result
              _card(
                context: context,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _bigStat(context, Icons.local_fire_department_rounded,
                            'BMR',
                            '${_result!.bmr.toStringAsFixed(0)} kcal',
                            AppColors.orange),
                        Container(
                            width: 1,
                            height: 50,
                            color: context.divider),
                        _bigStat(context, Icons.flash_on_rounded, 'TDEE',
                            '${_result!.tdee.toStringAsFixed(0)} kcal',
                            AppColors.green),
                        Container(
                            width: 1,
                            height: 50,
                            color: context.divider),
                        _bigStat(context, Icons.track_changes_rounded,
                            'Target',
                            '${_result!.recommendedCalories.toStringAsFixed(0)} kcal',
                            AppColors.blue),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: context.inputFill,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              size: 18, color: context.textSecondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _result!.deficitSurplusLabel,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: context.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Macro breakdown
              _card(
                context: context,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Recommended Daily Macros',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: context.textPrimary)),
                    const SizedBox(height: 14),
                    _macroRow(context, 'Protein',
                        '${_result!.proteinGoal.toStringAsFixed(0)} g',
                        '(1.8g per kg body weight)',
                        const Color(0xFF4D96FF)),
                    const SizedBox(height: 10),
                    _macroRow(context, 'Carbs',
                        '${_result!.carbGoal.toStringAsFixed(0)} g',
                        '(45% of target calories)',
                        const Color(0xFFFFE66D)),
                    const SizedBox(height: 10),
                    _macroRow(context, 'Fat',
                        '${_result!.fatGoal.toStringAsFixed(0)} g',
                        '(25% of target calories)',
                        const Color(0xFFFF9F1C)),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Activity descriptions
              _card(
                context: context,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Activity Level Guide',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: context.textPrimary)),
                    const SizedBox(height: 12),
                    ...TdeeModel.activityLevels.map((lvl) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: lvl == _activity
                                      ? AppColors.green
                                      : context.mutedBorder,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(lvl,
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: context.textPrimary,
                                      fontWeight: lvl == _activity
                                          ? FontWeight.w700
                                          : FontWeight.w400)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                    TdeeModel.activityDescriptions[lvl] ?? '',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: context.textHint)),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _card({required BuildContext context, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: context.cardDecoration(radius: BorderRadius.circular(20)),
      child: child,
    );
  }

  Widget _field(BuildContext context, TextEditingController ctrl,
      String hint, IconData icon) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: TextStyle(color: context.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 12, color: context.textHint),
        prefixIcon: Icon(icon, size: 18, color: AppColors.green),
        filled: true,
        fillColor: context.inputFill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: context.isDark ? context.mutedBorder : Colors.transparent),
        ),
      ),
    );
  }

  Widget _genderPicker(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: context.inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: context.isDark ? context.mutedBorder : Colors.transparent),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _gender,
          isExpanded: true,
          dropdownColor: context.surfaceElevated,
          style: TextStyle(color: context.textPrimary, fontSize: 14),
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              color: context.textSecondary),
          items: ['Male', 'Female']
              .map((g) => DropdownMenuItem(value: g, child: Text(g)))
              .toList(),
          onChanged: (v) => setState(() => _gender = v ?? 'Male'),
        ),
      ),
    );
  }

  Widget _activityDropdown(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: context.inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: context.isDark ? context.mutedBorder : Colors.transparent),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _activity,
          isExpanded: true,
          dropdownColor: context.surfaceElevated,
          style: TextStyle(color: context.textPrimary, fontSize: 14),
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              color: context.textSecondary),
          items: TdeeModel.activityLevels
              .map((a) => DropdownMenuItem(value: a, child: Text(a)))
              .toList(),
          onChanged: (v) => setState(() => _activity = v ?? _activity),
        ),
      ),
    );
  }

  Widget _goalSelector(BuildContext context) {
    return Row(
      children: [
        _goalChip(context, 'lose', 'Lose'),
        const SizedBox(width: 8),
        _goalChip(context, 'maintain', 'Maintain'),
        const SizedBox(width: 8),
        _goalChip(context, 'gain', 'Gain'),
      ],
    );
  }

  Widget _goalChip(BuildContext context, String value, String label) {
    final sel = _goal == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _goal = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: sel ? AppColors.primary : context.inputFill,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: sel ? AppColors.green : context.mutedBorder,
                width: 1.5),
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: sel ? Colors.black : context.textSecondary,
                    fontWeight:
                        sel ? FontWeight.w700 : FontWeight.w400)),
          ),
        ),
      ),
    );
  }

  Widget _bigStat(BuildContext context, IconData icon, String label,
      String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: context.textPrimary)),
        Text(label,
            style: TextStyle(fontSize: 11, color: context.textMuted)),
      ],
    );
  }

  Widget _macroRow(BuildContext context, String label, String value,
      String sub, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Text(label,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: context.textPrimary)),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: context.textPrimary)),
            Text(sub,
                style: TextStyle(fontSize: 10, color: context.textHint)),
          ],
        ),
      ],
    );
  }
}
