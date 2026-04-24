class PlannedFood {
  String name;
  double calories;
  double protein;
  double carbs;
  double fat;
  double grams;
  String mealType; // 'Breakfast', 'Lunch', 'Dinner', 'Snacks'

  PlannedFood({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.grams,
    required this.mealType,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'grams': grams,
        'mealType': mealType,
      };

  factory PlannedFood.fromMap(Map<String, dynamic> map) => PlannedFood(
        name: map['name'] ?? '',
        calories: (map['calories'] ?? 0).toDouble(),
        protein: (map['protein'] ?? 0).toDouble(),
        carbs: (map['carbs'] ?? 0).toDouble(),
        fat: (map['fat'] ?? 0).toDouble(),
        grams: (map['grams'] ?? 0).toDouble(),
        mealType: map['mealType'] ?? 'Breakfast',
      );
}

class MealPlanDay {
  String dateKey; // "YYYY-MM-DD"
  List<PlannedFood> foods;

  MealPlanDay({
    required this.dateKey,
    required this.foods,
  });

  // ── Computed totals ───────────────────────────────────────────────────────

  double get totalCalories => foods.fold(0, (sum, f) => sum + f.calories);
  double get totalProtein => foods.fold(0, (sum, f) => sum + f.protein);
  double get totalCarbs => foods.fold(0, (sum, f) => sum + f.carbs);
  double get totalFat => foods.fold(0, (sum, f) => sum + f.fat);

  List<PlannedFood> foodsForMeal(String mealType) =>
      foods.where((f) => f.mealType == mealType).toList();

  double caloriesForMeal(String mealType) =>
      foodsForMeal(mealType).fold(0, (sum, f) => sum + f.calories);

  // ── Serialisation ─────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
        'dateKey': dateKey,
        'foods': foods.map((f) => f.toMap()).toList(),
      };

  factory MealPlanDay.fromMap(Map<String, dynamic> map) => MealPlanDay(
        dateKey: map['dateKey'] ?? '',
        foods: (map['foods'] as List<dynamic>? ?? [])
            .map((f) => PlannedFood.fromMap(Map<String, dynamic>.from(f)))
            .toList(),
      );

  factory MealPlanDay.empty(String dateKey) =>
      MealPlanDay(dateKey: dateKey, foods: []);
}
