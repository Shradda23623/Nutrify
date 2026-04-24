class BmiCalculator {
  static double calculateBmi(double height, double weight) {
    if (height <= 0 || weight <= 0) return 0.0;
    // height in meters, weight in kg
    return weight / (height * height);
  }

  static String getBmiCategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }
}
