class BmiModel {
  final double heightCm;
  final double weightKg;

  BmiModel({required this.heightCm, required this.weightKg});

  double get bmi {
    if (heightCm <= 0) return 0;
    final heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }

  String get category {
    final b = bmi;
    if (b == 0) return '—';
    if (b < 18.5) return 'Underweight';
    if (b < 25.0) return 'Normal weight';
    if (b < 30.0) return 'Overweight';
    return 'Obese';
  }

  String get emoji {
    final b = bmi;
    if (b == 0) return '❓';
    if (b < 18.5) return '🥗';
    if (b < 25.0) return '💪';
    if (b < 30.0) return '⚠️';
    return '🚨';
  }

  String get advice {
    final b = bmi;
    if (b == 0) return 'Enter your height and weight to calculate BMI.';
    if (b < 18.5) {
      return 'Your BMI is below normal. Consider increasing your calorie intake '
          'with nutrient-rich foods and adding strength training to build muscle.';
    }
    if (b < 25.0) {
      return 'Great job! Your BMI is in the healthy range. Keep maintaining a '
          'balanced diet and regular exercise to stay fit.';
    }
    if (b < 30.0) {
      return 'Your BMI is slightly above normal. A moderate calorie deficit, '
          'more cardio, and reducing processed foods can help reach a healthy weight.';
    }
    return 'Your BMI indicates obesity. Please consult a healthcare professional '
        'and consider a structured diet and exercise plan for safe weight loss.';
  }

  // Returns 0.0–1.0 position on gauge (BMI range 10–40)
  double get gaugePosition => ((bmi - 10) / 30).clamp(0.0, 1.0);
}
