class CalorieEntry {
  final String name;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;        // g
  final double sugar;        // g
  final double sodium;       // mg
  // ── Micronutrients ───────────────────────────────────────────────
  final double iron;         // mg
  final double calcium;      // mg
  final double vitaminB12;   // mcg
  final double vitaminD;     // IU
  final double vitaminC;     // mg
  final double magnesium;    // mg
  // ── Glycemic ─────────────────────────────────────────────────────
  final double glycemicIndex;  // 0–100
  final DateTime time;

  CalorieEntry({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber = 0.0,
    this.sugar = 0.0,
    this.sodium = 0.0,
    this.iron = 0.0,
    this.calcium = 0.0,
    this.vitaminB12 = 0.0,
    this.vitaminD = 0.0,
    this.vitaminC = 0.0,
    this.magnesium = 0.0,
    this.glycemicIndex = 0.0,
    required this.time,
  });

  /// Glycemic Load = (GI × net carbs) / 100
  double get glycemicLoad => (glycemicIndex * (carbs - fiber).clamp(0, double.infinity)) / 100;

  Map<String, dynamic> toMap() => {
        'name': name,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'fiber': fiber,
        'sugar': sugar,
        'sodium': sodium,
        'iron': iron,
        'calcium': calcium,
        'vitaminB12': vitaminB12,
        'vitaminD': vitaminD,
        'vitaminC': vitaminC,
        'magnesium': magnesium,
        'glycemicIndex': glycemicIndex,
        'time': time.toIso8601String(),
      };

  factory CalorieEntry.fromMap(Map<String, dynamic> map) => CalorieEntry(
        name: map['name'] ?? '',
        calories: (map['calories'] ?? 0).toDouble(),
        protein: (map['protein'] ?? 0).toDouble(),
        carbs: (map['carbs'] ?? 0).toDouble(),
        fat: (map['fat'] ?? 0).toDouble(),
        fiber: (map['fiber'] ?? 0).toDouble(),
        sugar: (map['sugar'] ?? 0).toDouble(),
        sodium: (map['sodium'] ?? 0).toDouble(),
        iron: (map['iron'] ?? 0).toDouble(),
        calcium: (map['calcium'] ?? 0).toDouble(),
        vitaminB12: (map['vitaminB12'] ?? 0).toDouble(),
        vitaminD: (map['vitaminD'] ?? 0).toDouble(),
        vitaminC: (map['vitaminC'] ?? 0).toDouble(),
        magnesium: (map['magnesium'] ?? 0).toDouble(),
        glycemicIndex: (map['glycemicIndex'] ?? 0).toDouble(),
        time: DateTime.parse(map['time']),
      );
}

class CalorieModel {
  List<CalorieEntry> entries;
  double goal;

  CalorieModel({
    required this.entries,
    required this.goal,
  });

  double get totalCalories    => entries.fold(0, (s, e) => s + e.calories);
  double get totalProtein     => entries.fold(0, (s, e) => s + e.protein);
  double get totalCarbs       => entries.fold(0, (s, e) => s + e.carbs);
  double get totalFat         => entries.fold(0, (s, e) => s + e.fat);
  double get totalFiber       => entries.fold(0, (s, e) => s + e.fiber);
  double get totalSugar       => entries.fold(0, (s, e) => s + e.sugar);
  double get totalSodium      => entries.fold(0, (s, e) => s + e.sodium);
  double get totalIron        => entries.fold(0, (s, e) => s + e.iron);
  double get totalCalcium     => entries.fold(0, (s, e) => s + e.calcium);
  double get totalVitaminB12  => entries.fold(0, (s, e) => s + e.vitaminB12);
  double get totalVitaminD    => entries.fold(0, (s, e) => s + e.vitaminD);
  double get totalVitaminC    => entries.fold(0, (s, e) => s + e.vitaminC);
  double get totalMagnesium   => entries.fold(0, (s, e) => s + e.magnesium);
  double get totalGlycemicLoad => entries.fold(0, (s, e) => s + e.glycemicLoad);

  double get progress  => (totalCalories / goal).clamp(0.0, 1.0);
  double get remaining => (goal - totalCalories).clamp(0, goal);
}
