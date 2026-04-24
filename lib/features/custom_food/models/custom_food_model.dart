class CustomFoodModel {
  final String id;
  final String name;
  final double calories; // per 100g
  final double protein;  // per 100g
  final double carbs;    // per 100g
  final double fat;      // per 100g
  final double servingGrams;
  final String servingLabel;
  final bool isRecipe;
  final DateTime createdAt;

  const CustomFoodModel({
    required this.id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.servingGrams,
    required this.servingLabel,
    required this.isRecipe,
    required this.createdAt,
  });

  /// Returns a copy of this model with nutrition scaled to [grams].
  CustomFoodModel scaled(double grams) {
    final factor = grams / 100.0;
    return CustomFoodModel(
      id: id,
      name: name,
      calories: calories * factor,
      protein: protein * factor,
      carbs: carbs * factor,
      fat: fat * factor,
      servingGrams: grams,
      servingLabel: servingLabel,
      isRecipe: isRecipe,
      createdAt: createdAt,
    );
  }

  CustomFoodModel copyWith({
    String? id,
    String? name,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? servingGrams,
    String? servingLabel,
    bool? isRecipe,
    DateTime? createdAt,
  }) {
    return CustomFoodModel(
      id: id ?? this.id,
      name: name ?? this.name,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      servingGrams: servingGrams ?? this.servingGrams,
      servingLabel: servingLabel ?? this.servingLabel,
      isRecipe: isRecipe ?? this.isRecipe,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'servingGrams': servingGrams,
        'servingLabel': servingLabel,
        'isRecipe': isRecipe,
        'createdAt': createdAt.toIso8601String(),
      };

  factory CustomFoodModel.fromMap(Map<String, dynamic> map) => CustomFoodModel(
        id: map['id'] as String,
        name: map['name'] as String,
        calories: (map['calories'] ?? 0).toDouble(),
        protein: (map['protein'] ?? 0).toDouble(),
        carbs: (map['carbs'] ?? 0).toDouble(),
        fat: (map['fat'] ?? 0).toDouble(),
        servingGrams: (map['servingGrams'] ?? 100).toDouble(),
        servingLabel: map['servingLabel'] as String? ?? '100g',
        isRecipe: map['isRecipe'] as bool? ?? false,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );

  @override
  String toString() =>
      'CustomFoodModel(id: $id, name: $name, calories: $calories/100g)';
}
