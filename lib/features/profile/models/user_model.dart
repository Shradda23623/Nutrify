class UserModel {
  String name;
  int age;
  double heightCm;
  double weightKg;
  String gender; // 'Male' | 'Female' | 'Other'
  double dailyCalorieGoal;
  double dailyWaterGoalLitres;
  int dailyStepGoal;
  String goal; // 'lose' | 'maintain' | 'gain'
  String avatarPath; // local file path to user's chosen photo

  UserModel({
    this.name = '',
    this.age = 0,
    this.heightCm = 0,
    this.weightKg = 0,
    this.gender = 'Female',
    this.dailyCalorieGoal = 2000,
    this.dailyWaterGoalLitres = 8,
    this.dailyStepGoal = 10000,
    this.goal = 'maintain',
    this.avatarPath = '',
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'age': age,
        'heightCm': heightCm,
        'weightKg': weightKg,
        'gender': gender,
        'dailyCalorieGoal': dailyCalorieGoal,
        'dailyWaterGoalLitres': dailyWaterGoalLitres,
        'dailyStepGoal': dailyStepGoal,
        'goal': goal,
        'avatarPath': avatarPath,
      };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        name: map['name'] ?? '',
        age: (map['age'] ?? 0) as int,
        heightCm: (map['heightCm'] ?? 0).toDouble(),
        weightKg: (map['weightKg'] ?? 0).toDouble(),
        gender: map['gender'] ?? 'Female',
        dailyCalorieGoal: (map['dailyCalorieGoal'] ?? 2000).toDouble(),
        dailyWaterGoalLitres:
            (map['dailyWaterGoalLitres'] ?? 8).toDouble(),
        dailyStepGoal: (map['dailyStepGoal'] ?? 10000) as int,
        goal: map['goal'] ?? 'maintain',
        avatarPath: map['avatarPath'] ?? '',
      );

  double get bmi {
    if (heightCm <= 0) return 0;
    final h = heightCm / 100;
    return weightKg / (h * h);
  }

  String get bmiCategory {
    final b = bmi;
    if (b == 0) return '—';
    if (b < 18.5) return 'Underweight';
    if (b < 25.0) return 'Normal';
    if (b < 30.0) return 'Overweight';
    return 'Obese';
  }
}
