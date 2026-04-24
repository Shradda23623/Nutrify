class TdeeModel {
  final double weightKg;
  final double heightCm;
  final int age;
  final String gender; // 'Male' | 'Female'
  final String activityLevel;
  final String goal; // 'lose' | 'maintain' | 'gain'

  TdeeModel({
    required this.weightKg,
    required this.heightCm,
    required this.age,
    required this.gender,
    required this.activityLevel,
    required this.goal,
  });

  /// Basal Metabolic Rate (Mifflin-St Jeor)
  double get bmr {
    if (gender == 'Female') {
      return (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161;
    }
    return (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5;
  }

  /// Activity multiplier
  double get _multiplier {
    switch (activityLevel) {
      case 'Sedentary':
        return 1.2;
      case 'Lightly Active':
        return 1.375;
      case 'Moderately Active':
        return 1.55;
      case 'Very Active':
        return 1.725;
      case 'Extra Active':
        return 1.9;
      default:
        return 1.2;
    }
  }

  /// Total Daily Energy Expenditure
  double get tdee => bmr * _multiplier;

  /// Recommended daily calories based on goal
  double get recommendedCalories {
    switch (goal) {
      case 'lose':
        return tdee - 500; // ~0.5kg/week loss
      case 'gain':
        return tdee + 500; // ~0.5kg/week gain
      default:
        return tdee; // maintain
    }
  }

  double get proteinGoal => weightKg * 1.8; // 1.8g per kg
  double get carbGoal => (recommendedCalories * 0.45) / 4;
  double get fatGoal => (recommendedCalories * 0.25) / 9;

  String get deficitSurplusLabel {
    switch (goal) {
      case 'lose':
        return '−500 kcal deficit → ~0.5 kg/week loss';
      case 'gain':
        return '+500 kcal surplus → ~0.5 kg/week gain';
      default:
        return 'Maintenance calories';
    }
  }

  static const List<String> activityLevels = [
    'Sedentary',
    'Lightly Active',
    'Moderately Active',
    'Very Active',
    'Extra Active',
  ];

  static const Map<String, String> activityDescriptions = {
    'Sedentary': 'Little or no exercise',
    'Lightly Active': '1–3 days/week',
    'Moderately Active': '3–5 days/week',
    'Very Active': '6–7 days/week',
    'Extra Active': 'Very hard exercise / physical job',
  };
}
