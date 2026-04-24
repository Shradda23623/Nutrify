import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/user_service.dart';
import '../../../features/profile/models/user_model.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final PageController _pageCtrl = PageController();
  int _step = 0; // 0=basic info, 1=goals, 2=BMI advice

  // Basic info
  String _name = '';
  final _ageCtrl = TextEditingController();
  String _gender = 'Female';

  // Height — separate controllers for each unit
  String _heightUnit = 'cm'; // 'cm' or 'ft'
  final _heightCmCtrl = TextEditingController();
  final _feetCtrl = TextEditingController();
  final _inchesCtrl = TextEditingController();

  // Weight — separate controllers for each unit
  String _weightUnit = 'kg'; // 'kg' or 'lbs'
  final _weightKgCtrl = TextEditingController();
  final _weightLbsCtrl = TextEditingController();

  // Goal
  String _goal = 'maintain'; // lose / maintain / gain

  // Computed BMI
  double _bmi = 0;
  String _bmiCategory = '';
  Color _bmiColor = AppColors.green;
  String _advice = '';
  List<String> _tips = [];

  bool _saving = false;

  // ── Unit conversion helpers ────────────────────────────────────────────────

  /// Always returns cm regardless of which unit is selected.
  double get _heightInCm {
    if (_heightUnit == 'cm') {
      return double.tryParse(_heightCmCtrl.text) ?? 0;
    }
    final ft = double.tryParse(_feetCtrl.text) ?? 0;
    final inch = double.tryParse(_inchesCtrl.text) ?? 0;
    return ft * 30.48 + inch * 2.54;
  }

  /// Always returns kg regardless of which unit is selected.
  double get _weightInKg {
    if (_weightUnit == 'kg') {
      return double.tryParse(_weightKgCtrl.text) ?? 0;
    }
    final lbs = double.tryParse(_weightLbsCtrl.text) ?? 0;
    return lbs * 0.453592;
  }

  void _switchHeightUnit(String newUnit) {
    if (_heightUnit == newUnit) return;
    final currentCm = _heightInCm;
    setState(() {
      _heightUnit = newUnit;
      if (newUnit == 'cm') {
        _heightCmCtrl.text =
            currentCm > 0 ? currentCm.toStringAsFixed(0) : '';
      } else {
        if (currentCm > 0) {
          final totalInches = currentCm / 2.54;
          final ft = totalInches ~/ 12;
          final inch = (totalInches % 12).round();
          _feetCtrl.text = '$ft';
          _inchesCtrl.text = '$inch';
        }
      }
    });
  }

  void _switchWeightUnit(String newUnit) {
    if (_weightUnit == newUnit) return;
    final currentKg = _weightInKg;
    setState(() {
      _weightUnit = newUnit;
      if (newUnit == 'kg') {
        _weightKgCtrl.text =
            currentKg > 0 ? currentKg.toStringAsFixed(1) : '';
      } else {
        if (currentKg > 0) {
          _weightLbsCtrl.text = (currentKg * 2.20462).toStringAsFixed(1);
        }
      }
    });
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final name = ModalRoute.of(context)?.settings.arguments as String?;
      if (name != null && name.isNotEmpty) {
        setState(() => _name = name);
      }
    });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _ageCtrl.dispose();
    _heightCmCtrl.dispose();
    _feetCtrl.dispose();
    _inchesCtrl.dispose();
    _weightKgCtrl.dispose();
    _weightLbsCtrl.dispose();
    super.dispose();
  }

  // ── Validation ─────────────────────────────────────────────────────────────

  bool _validateBasicInfo() {
    if (_name.isEmpty) {
      _snack('Please enter your name.');
      return false;
    }
    final h = _heightInCm;
    final w = _weightInKg;
    final a = int.tryParse(_ageCtrl.text);

    if (h < 50 || h > 250) {
      _snack(_heightUnit == 'cm'
          ? 'Please enter a valid height (50–250 cm).'
          : 'Please enter a valid height (1\'8\" – 8\'2\").');
      return false;
    }
    if (w < 20 || w > 300) {
      _snack(_weightUnit == 'kg'
          ? 'Please enter a valid weight (20–300 kg).'
          : 'Please enter a valid weight (44–661 lbs).');
      return false;
    }
    if (a == null || a < 5 || a > 120) {
      _snack('Please enter a valid age (5–120 years).');
      return false;
    }
    return true;
  }

  // ── BMI calculation + personalised advice ──────────────────────────────────

  void _computeBmi() {
    final hM = _heightInCm / 100;
    final w = _weightInKg;
    if (hM == 0) return;
    _bmi = w / (hM * hM);

    if (_bmi < 18.5) {
      _bmiCategory = 'Underweight';
      _bmiColor = const Color(0xFF4D96FF);
    } else if (_bmi < 25) {
      _bmiCategory = 'Normal Weight';
      _bmiColor = AppColors.green;
    } else if (_bmi < 30) {
      _bmiCategory = 'Overweight';
      _bmiColor = const Color(0xFFFFBF00);
    } else {
      _bmiCategory = 'Obese';
      _bmiColor = Colors.redAccent;
    }

    _buildAdvice();
  }

  void _buildAdvice() {
    if (_goal == 'lose') {
      if (_bmi < 18.5) {
        _advice =
            'Your BMI shows you\'re already underweight. Losing more weight could be harmful. We recommend focusing on maintaining a balanced diet and building strength instead.';
        _tips = [
          'Eat nutrient-dense meals (eggs, nuts, whole grains)',
          'Add light strength training to build muscle',
          'Aim for at least 2,000 kcal/day with quality foods',
          'Consult a doctor before any weight-loss plan',
        ];
      } else if (_bmi < 25) {
        _advice =
            'You\'re in a healthy weight range. A slight calorie deficit of 200–300 kcal/day combined with exercise will help you tone up without losing too much.';
        _tips = [
          'Target a mild deficit: ~200–300 kcal below TDEE',
          'Prioritise protein (1.6g per kg) to preserve muscle',
          'Add 30 min cardio 4–5 days/week',
          'Track your meals daily using the Calorie Tracker',
        ];
      } else if (_bmi < 30) {
        _advice =
            'A moderate approach will work well. A 500 kcal daily deficit plus regular exercise can help you lose ~0.5 kg/week safely.';
        _tips = [
          'Cut 400–500 kcal from your daily intake',
          'Walk 8,000–10,000 steps every day',
          'Replace sugary drinks with water (8 glasses/day)',
          'Log every meal to stay accountable',
        ];
      } else {
        _advice =
            'A structured plan will make a big difference. Start with moderate changes and build habits gradually. You can lose weight safely with consistency.';
        _tips = [
          'Aim for a 500–700 kcal daily deficit',
          'Start with 20–30 min walks daily, increase gradually',
          'Eliminate processed foods and sugary beverages',
          'Set weekly weigh-ins to track progress',
          'Consider consulting a nutritionist for guidance',
        ];
      }
    } else if (_goal == 'gain') {
      if (_bmi < 18.5) {
        _advice =
            'Building mass is a great goal for you. A calorie surplus with strength training will help you gain healthy weight and muscle.';
        _tips = [
          'Eat 300–500 kcal above your TDEE daily',
          'Prioritise protein: 1.8–2.2g per kg body weight',
          'Strength train 3–4 times per week',
          'Track your weight weekly — aim for +0.3 kg/week',
        ];
      } else if (_bmi < 25) {
        _advice =
            'You\'re in a great starting position for lean muscle gain. A controlled calorie surplus with resistance training will build quality mass.';
        _tips = [
          'Eat 200–300 kcal above your TDEE',
          'Focus on progressive overload in the gym',
          'Protein target: 1.8g/kg body weight',
          'Sleep 7–9 hours for optimal muscle recovery',
        ];
      } else {
        _advice =
            'With a higher BMI, focus on body recomposition — building muscle while managing fat. This takes longer but is healthier than a large bulk.';
        _tips = [
          'Eat at maintenance or a very slight surplus (~100 kcal)',
          'Strength train 4 times/week targeting all muscle groups',
          'High protein intake (2g/kg) to support muscle growth',
          'Monitor body composition, not just weight on scale',
        ];
      }
    } else {
      // maintain
      if (_bmi < 18.5) {
        _advice =
            'While maintaining weight, try to gradually improve your nutrition quality to reach a healthier body composition.';
        _tips = [
          'Eat at your TDEE with nutrient-dense foods',
          'Focus on whole foods: lean protein, vegetables, grains',
          'Light resistance training helps build healthy mass',
          'Track meals to ensure you\'re meeting your calorie target',
        ];
      } else if (_bmi < 25) {
        _advice =
            'You\'re already at a healthy weight — great work! Focus on consistency to keep it up long-term.';
        _tips = [
          'Eat balanced meals — protein, carbs, and healthy fats',
          'Stay active with 150 min of exercise per week',
          'Drink 8 glasses of water daily',
          'Monitor your weight weekly to stay on track',
        ];
      } else {
        _advice =
            'Maintaining your current weight is a solid first step. Gradually improving diet quality and activity will help you feel better over time.';
        _tips = [
          'Eat at your TDEE — avoid large calorie swings',
          'Reduce processed and high-sugar foods',
          'Walk 7,000–10,000 steps per day',
          'Use the Progress screen to track trends over time',
        ];
      }
    }
  }

  // ── Save profile ───────────────────────────────────────────────────────────

  Future<void> _saveAndFinish() async {
    setState(() => _saving = true);

    final height = _heightInCm;
    final weight = _weightInKg;
    final age = int.tryParse(_ageCtrl.text) ?? 0;
    final hM = height / 100;
    final bmi = hM > 0 ? weight / (hM * hM) : 0;

    double calorieGoal = 2000;
    if (age > 0 && height > 0 && weight > 0) {
      double bmr = _gender == 'Female'
          ? 10 * weight + 6.25 * height - 5 * age - 161
          : 10 * weight + 6.25 * height - 5 * age + 5;
      double tdee = bmr * 1.55;
      if (_goal == 'lose') {
        calorieGoal = tdee - 500;
      } else if (_goal == 'gain') {
        calorieGoal = tdee + 300;
      } else {
        calorieGoal = tdee;
      }
      calorieGoal = calorieGoal.clamp(1200, 4000);
    }

    final profile = {
      'name': _name,
      'age': age,
      'gender': _gender,
      'heightCm': height,
      'weightKg': weight,
      'bmi': double.parse(bmi.toStringAsFixed(1)),
      'goal': _goal,
      'dailyCalorieGoal': calorieGoal.roundToDouble(),
      'dailyWaterGoalLitres': 8.0,
      'dailyStepGoal': 10000,
    };

    await UserService().save(UserModel.fromMap(profile));

    setState(() => _saving = false);

    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
          context, AppRoutes.home, (_) => false);
    }
  }

  // ── Step navigation ────────────────────────────────────────────────────────

  void _nextStep() {
    if (_step == 0) {
      if (!_validateBasicInfo()) return;
      _computeBmi();
      setState(() => _step = 1);
      _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut);
    } else if (_step == 1) {
      _computeBmi();
      setState(() => _step = 2);
      _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut);
    }
  }

  void _prevStep() {
    if (_step > 0) {
      setState(() => _step--);
      _pageCtrl.previousPage(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.redAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Progress bar ────────────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (_step > 0)
                        GestureDetector(
                          onTap: _prevStep,
                          child: const Icon(Icons.arrow_back_ios_rounded,
                              size: 20),
                        )
                      else
                        const SizedBox(width: 20),
                      const Spacer(),
                      Text(
                        'Step ${_step + 1} of 3',
                        style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black45,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (_step + 1) / 3,
                      minHeight: 5,
                      backgroundColor: Colors.black.withOpacity(0.08),
                      valueColor:
                          AlwaysStoppedAnimation(AppColors.green),
                    ),
                  ),
                ],
              ),
            ),

            // ── Page view ───────────────────────────────────────────
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep0BasicInfo(),
                  _buildStep1Goals(),
                  _buildStep2Advice(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 0: Basic Info ─────────────────────────────────────────────────────

  Widget _buildStep0BasicInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tell us about yourself',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text(
              'We use this to personalise your nutrition and fitness plan.',
              style: TextStyle(fontSize: 13, color: Colors.black45)),
          const SizedBox(height: 28),

          // Name
          _label('Your Name'),
          _NameField(
            initialValue: _name,
            onChanged: (v) => setState(() => _name = v),
          ),
          const SizedBox(height: 16),

          // Age & Gender
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Age'),
                    _textField(
                      controller: _ageCtrl,
                      hint: 'e.g. 22',
                      icon: Icons.cake_rounded,
                      isNumber: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Gender'),
                    _dropdownField(
                      value: _gender,
                      items: const ['Female', 'Male', 'Other'],
                      icon: Icons.wc_rounded,
                      onChanged: (v) =>
                          setState(() => _gender = v ?? 'Female'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Height with unit toggle
          _heightInputSection(),
          const SizedBox(height: 16),

          // Weight with unit toggle
          _weightInputSection(),

          const SizedBox(height: 36),
          _nextButton('Continue', _nextStep),
        ],
      ),
    );
  }

  // ── Height input with cm / ft toggle ──────────────────────────────────────

  Widget _heightInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Height',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54)),
            const Spacer(),
            _unitToggle(
              options: const ['cm', 'ft'],
              selected: _heightUnit,
              onSelect: _switchHeightUnit,
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (_heightUnit == 'cm')
          _textField(
            controller: _heightCmCtrl,
            hint: 'e.g. 165',
            icon: Icons.height_rounded,
            isNumber: true,
            suffix: 'cm',
          )
        else
          Row(
            children: [
              Expanded(
                child: _textField(
                  controller: _feetCtrl,
                  hint: '5',
                  icon: Icons.height_rounded,
                  isNumber: true,
                  suffix: 'ft',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _textField(
                  controller: _inchesCtrl,
                  hint: '6',
                  icon: Icons.straighten_rounded,
                  isNumber: true,
                  suffix: 'in',
                ),
              ),
            ],
          ),
      ],
    );
  }

  // ── Weight input with kg / lbs toggle ─────────────────────────────────────

  Widget _weightInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Weight',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54)),
            const Spacer(),
            _unitToggle(
              options: const ['kg', 'lbs'],
              selected: _weightUnit,
              onSelect: _switchWeightUnit,
            ),
          ],
        ),
        const SizedBox(height: 6),
        _textField(
          controller: _weightUnit == 'kg' ? _weightKgCtrl : _weightLbsCtrl,
          hint: _weightUnit == 'kg' ? 'e.g. 60' : 'e.g. 132',
          icon: Icons.monitor_weight_outlined,
          isNumber: true,
          suffix: _weightUnit,
        ),
      ],
    );
  }

  // ── Segmented unit toggle chip ─────────────────────────────────────────────

  Widget _unitToggle({
    required List<String> options,
    required String selected,
    required ValueChanged<String> onSelect,
  }) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((opt) {
          final isSelected = opt == selected;
          return GestureDetector(
            onTap: () => onSelect(opt),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.green : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.green.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : [],
              ),
              child: Text(
                opt,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : Colors.black45,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Step 1: Goal Selection ─────────────────────────────────────────────────

  Widget _buildStep1Goals() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('What is your goal?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text(
              'We will build a personalised plan based on your target.',
              style: TextStyle(fontSize: 13, color: Colors.black45)),
          const SizedBox(height: 32),

          _goalCard(
            value: 'lose',
            icon: Icons.trending_down_rounded,
            title: 'Lose Weight',
            subtitle:
                'Reduce body fat with a calorie deficit and cardio',
            color: const Color(0xFF4D96FF),
          ),
          const SizedBox(height: 14),
          _goalCard(
            value: 'maintain',
            icon: Icons.balance_rounded,
            title: 'Stay Fit & Maintain',
            subtitle:
                'Keep your current weight while improving fitness',
            color: AppColors.green,
          ),
          const SizedBox(height: 14),
          _goalCard(
            value: 'gain',
            icon: Icons.trending_up_rounded,
            title: 'Build Muscle & Gain',
            subtitle:
                'Increase strength and mass with a calorie surplus',
            color: const Color(0xFFFF9F1C),
          ),

          const SizedBox(height: 36),
          _nextButton('See My Plan', _nextStep),
        ],
      ),
    );
  }

  // ── Step 2: BMI Advice ─────────────────────────────────────────────────────

  Widget _buildStep2Advice() {
    // Format height for display in whichever unit the user chose
    String heightDisplay;
    if (_heightUnit == 'cm') {
      heightDisplay = '${_heightInCm.toStringAsFixed(0)} cm';
    } else {
      final ft = _feetCtrl.text;
      final inch = _inchesCtrl.text;
      heightDisplay = '${ft}ft ${inch}in (${_heightInCm.toStringAsFixed(0)} cm)';
    }

    // Format weight for display
    String weightDisplay;
    if (_weightUnit == 'kg') {
      weightDisplay = '${_weightInKg.toStringAsFixed(1)} kg';
    } else {
      final lbs = _weightLbsCtrl.text;
      weightDisplay = '${lbs} lbs (${_weightInKg.toStringAsFixed(1)} kg)';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your Personalised Plan',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
            'Based on your BMI and goal — here\'s what we recommend for you, ${_name.split(' ').first}.',
            style: const TextStyle(fontSize: 13, color: Colors.black45),
          ),
          const SizedBox(height: 24),

          // BMI result card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _bmiColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: _bmiColor.withOpacity(0.4), width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: _bmiColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _bmi.toStringAsFixed(1),
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: _bmiColor),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BMI: $_bmiCategory',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: _bmiColor),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Goal: ${_goalLabel(_goal)}',
                        style: const TextStyle(
                            fontSize: 13, color: Colors.black54),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'H: $heightDisplay',
                        style: const TextStyle(
                            fontSize: 11, color: Colors.black38),
                      ),
                      Text(
                        'W: $weightDisplay',
                        style: const TextStyle(
                            fontSize: 11, color: Colors.black38),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Advice
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.auto_awesome_rounded,
                    color: AppColors.green, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _advice,
                    style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                        height: 1.6),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          const Text('Your Action Plan',
              style:
                  TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ..._tips.asMap().entries.map((e) => _tipTile(e.key + 1, e.value)),

          const SizedBox(height: 20),
          _bmiScaleWidget(),
          const SizedBox(height: 32),

          // Start button
          _saving
              ? const Center(child: CircularProgressIndicator())
              : GestureDetector(
                  onTap: _saveAndFinish,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 17),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.45),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        "Let's Start My Journey!",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  // ── BMI scale ──────────────────────────────────────────────────────────────

  Widget _bmiScaleWidget() {
    final zones = [
      _BmiZone('Under', '< 18.5', const Color(0xFF4D96FF)),
      _BmiZone('Normal', '18.5–25', AppColors.green),
      _BmiZone('Over', '25–30', const Color(0xFFFFBF00)),
      _BmiZone('Obese', '> 30', Colors.redAccent),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('BMI Reference',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black45)),
          const SizedBox(height: 10),
          Row(
            children: zones.map((z) {
              final isActive =
                  (_bmiCategory == 'Underweight' && z.label == 'Under') ||
                  (_bmiCategory == 'Normal Weight' && z.label == 'Normal') ||
                  (_bmiCategory == 'Overweight' && z.label == 'Over') ||
                  (_bmiCategory == 'Obese' && z.label == 'Obese');
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive ? z.color : z.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(z.label,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isActive ? Colors.white : z.color)),
                      Text(z.range,
                          style: TextStyle(
                              fontSize: 8,
                              color: isActive
                                  ? Colors.white70
                                  : Colors.black38)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Goal card ──────────────────────────────────────────────────────────────

  Widget _goalCard({
    required String value,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    final selected = _goal == value;
    return GestureDetector(
      onTap: () => setState(() => _goal = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? color : Colors.black.withOpacity(0.08),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: color.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ]
              : [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: selected ? color : Colors.black87)),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.black45)),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, color: color, size: 22),
          ],
        ),
      ),
    );
  }

  // ── UI Helpers ─────────────────────────────────────────────────────────────

  String _goalLabel(String goal) {
    switch (goal) {
      case 'lose':
        return 'Lose Weight';
      case 'gain':
        return 'Gain Muscle';
      case 'maintain':
      default:
        return 'Maintain Health';
    }
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isNumber = false,
    String? suffix,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.green, size: 20),
        suffixText: suffix,
        suffixStyle:
            const TextStyle(fontWeight: FontWeight.w700, color: Colors.black38),
      ),
    );
  }

  Widget _dropdownField({
    required String value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F1F3),
        borderRadius: BorderRadius.circular(13),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          isExpanded: true,
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _tipTile(int index, String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: AppColors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$index',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.green),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _nextButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 17),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}

class _BmiZone {
  final String label;
  final String range;
  final Color color;
  _BmiZone(this.label, this.range, this.color);
}

class _NameField extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;

  const _NameField({required this.initialValue, required this.onChanged});

  @override
  State<_NameField> createState() => _NameFieldState();
}

class _NameFieldState extends State<_NameField> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(_NameField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != _ctrl.text && _ctrl.text.isEmpty) {
      _ctrl.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      onChanged: widget.onChanged,
      decoration: const InputDecoration(
        hintText: 'e.g. Jane Doe',
        prefixIcon: Icon(Icons.person_outline_rounded,
            color: AppColors.green, size: 20),
      ),
    );
  }
}
