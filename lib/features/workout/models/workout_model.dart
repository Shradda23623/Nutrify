import 'dart:convert';

class WorkoutExercise {
  final String name;
  final String category;
  final int sets;
  final int reps;
  final int durationMinutes;
  final double weightKg;
  final int caloriesBurned;
  final String notes;

  const WorkoutExercise({
    required this.name,
    required this.category,
    this.sets = 3,
    this.reps = 10,
    this.durationMinutes = 0,
    this.weightKg = 0,
    this.caloriesBurned = 0,
    this.notes = '',
  });

  WorkoutExercise copyWith({
    String? name,
    String? category,
    int? sets,
    int? reps,
    int? durationMinutes,
    double? weightKg,
    int? caloriesBurned,
    String? notes,
  }) {
    return WorkoutExercise(
      name: name ?? this.name,
      category: category ?? this.category,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      weightKg: weightKg ?? this.weightKg,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'category': category,
        'sets': sets,
        'reps': reps,
        'durationMinutes': durationMinutes,
        'weightKg': weightKg,
        'caloriesBurned': caloriesBurned,
        'notes': notes,
      };

  factory WorkoutExercise.fromMap(Map<String, dynamic> map) => WorkoutExercise(
        name: map['name'] ?? '',
        category: map['category'] ?? '',
        sets: map['sets'] ?? 3,
        reps: map['reps'] ?? 10,
        durationMinutes: map['durationMinutes'] ?? 0,
        weightKg: (map['weightKg'] ?? 0).toDouble(),
        caloriesBurned: map['caloriesBurned'] ?? 0,
        notes: map['notes'] ?? '',
      );
}

class WorkoutSession {
  final String id;
  final DateTime date;
  final String name;
  final List<WorkoutExercise> exercises;
  final int totalDurationMinutes;
  final int totalCaloriesBurned;
  final int mood; // 1-5

  const WorkoutSession({
    required this.id,
    required this.date,
    required this.name,
    required this.exercises,
    this.totalDurationMinutes = 0,
    this.totalCaloriesBurned = 0,
    this.mood = 3,
  });

  WorkoutSession copyWith({
    String? id,
    DateTime? date,
    String? name,
    List<WorkoutExercise>? exercises,
    int? totalDurationMinutes,
    int? totalCaloriesBurned,
    int? mood,
  }) {
    return WorkoutSession(
      id: id ?? this.id,
      date: date ?? this.date,
      name: name ?? this.name,
      exercises: exercises ?? this.exercises,
      totalDurationMinutes: totalDurationMinutes ?? this.totalDurationMinutes,
      totalCaloriesBurned: totalCaloriesBurned ?? this.totalCaloriesBurned,
      mood: mood ?? this.mood,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date.toIso8601String(),
        'name': name,
        'exercises': exercises.map((e) => e.toMap()).toList(),
        'totalDurationMinutes': totalDurationMinutes,
        'totalCaloriesBurned': totalCaloriesBurned,
        'mood': mood,
      };

  factory WorkoutSession.fromMap(Map<String, dynamic> map) => WorkoutSession(
        id: map['id'] ?? '',
        date: DateTime.parse(map['date']),
        name: map['name'] ?? '',
        exercises: (map['exercises'] as List<dynamic>? ?? [])
            .map((e) => WorkoutExercise.fromMap(e as Map<String, dynamic>))
            .toList(),
        totalDurationMinutes: map['totalDurationMinutes'] ?? 0,
        totalCaloriesBurned: map['totalCaloriesBurned'] ?? 0,
        mood: map['mood'] ?? 3,
      );

  String toJson() => jsonEncode(toMap());
  factory WorkoutSession.fromJson(String source) =>
      WorkoutSession.fromMap(jsonDecode(source));
}

class ExerciseTemplate {
  final String name;
  final String category;
  final int defaultSets;
  final int defaultReps;
  final int defaultDuration; // minutes, for cardio/flexibility
  final double caloriesPerMinute;
  final String muscleGroup;
  final String instructions;

  const ExerciseTemplate({
    required this.name,
    required this.category,
    this.defaultSets = 3,
    this.defaultReps = 10,
    this.defaultDuration = 0,
    required this.caloriesPerMinute,
    required this.muscleGroup,
    required this.instructions,
  });
}

class ExerciseLibrary {
  static const List<ExerciseTemplate> exercises = [
    // CHEST
    ExerciseTemplate(
      name: 'Bench Press',
      category: 'Chest',
      defaultSets: 4,
      defaultReps: 8,
      caloriesPerMinute: 8.0,
      muscleGroup: 'Pectorals, Triceps, Deltoids',
      instructions: 'Lie flat on bench, lower barbell to chest, then press up to full arm extension.',
    ),
    ExerciseTemplate(
      name: 'Push-Ups',
      category: 'Chest',
      defaultSets: 3,
      defaultReps: 15,
      caloriesPerMinute: 7.0,
      muscleGroup: 'Pectorals, Triceps, Core',
      instructions: 'Keep body straight, lower chest to ground and push back up with arms.',
    ),
    ExerciseTemplate(
      name: 'Incline Dumbbell Press',
      category: 'Chest',
      defaultSets: 3,
      defaultReps: 10,
      caloriesPerMinute: 7.5,
      muscleGroup: 'Upper Pectorals, Deltoids',
      instructions: 'On inclined bench at 30-45 degrees, press dumbbells from chest level upward.',
    ),
    ExerciseTemplate(
      name: 'Cable Flyes',
      category: 'Chest',
      defaultSets: 3,
      defaultReps: 12,
      caloriesPerMinute: 6.0,
      muscleGroup: 'Pectorals',
      instructions: 'Stand between cables, bring handles together in front of chest with slight arm bend.',
    ),
    ExerciseTemplate(
      name: 'Dips',
      category: 'Chest',
      defaultSets: 3,
      defaultReps: 10,
      caloriesPerMinute: 8.0,
      muscleGroup: 'Lower Pectorals, Triceps',
      instructions: 'Lean slightly forward on parallel bars and lower body until shoulders are below elbows.',
    ),
    // BACK
    ExerciseTemplate(
      name: 'Pull-Ups',
      category: 'Back',
      defaultSets: 3,
      defaultReps: 8,
      caloriesPerMinute: 8.0,
      muscleGroup: 'Latissimus Dorsi, Biceps',
      instructions: 'Hang from bar with overhand grip and pull body up until chin clears bar.',
    ),
    ExerciseTemplate(
      name: 'Barbell Row',
      category: 'Back',
      defaultSets: 4,
      defaultReps: 8,
      caloriesPerMinute: 7.5,
      muscleGroup: 'Middle Back, Rhomboids, Lats',
      instructions: 'Hinge at hips, keep back flat, and row the barbell up to lower chest.',
    ),
    ExerciseTemplate(
      name: 'Lat Pulldown',
      category: 'Back',
      defaultSets: 3,
      defaultReps: 12,
      caloriesPerMinute: 6.5,
      muscleGroup: 'Latissimus Dorsi, Biceps',
      instructions: 'Grip wide bar, pull it down to upper chest while keeping chest tall.',
    ),
    ExerciseTemplate(
      name: 'Deadlift',
      category: 'Back',
      defaultSets: 4,
      defaultReps: 5,
      caloriesPerMinute: 9.0,
      muscleGroup: 'Full Back, Glutes, Hamstrings',
      instructions: 'Feet hip-width, grip bar outside knees, stand up by driving hips forward.',
    ),
    ExerciseTemplate(
      name: 'Seated Cable Row',
      category: 'Back',
      defaultSets: 3,
      defaultReps: 12,
      caloriesPerMinute: 6.0,
      muscleGroup: 'Middle Back, Rhomboids',
      instructions: 'Sit upright, pull handle to lower chest squeezing shoulder blades together.',
    ),
    // LEGS
    ExerciseTemplate(
      name: 'Barbell Squat',
      category: 'Legs',
      defaultSets: 4,
      defaultReps: 8,
      caloriesPerMinute: 9.0,
      muscleGroup: 'Quadriceps, Glutes, Hamstrings',
      instructions: 'Bar across upper back, descend until thighs are parallel to floor, drive up through heels.',
    ),
    ExerciseTemplate(
      name: 'Leg Press',
      category: 'Legs',
      defaultSets: 3,
      defaultReps: 12,
      caloriesPerMinute: 7.0,
      muscleGroup: 'Quadriceps, Glutes',
      instructions: 'Push platform away with feet at shoulder width, do not lock knees at top.',
    ),
    ExerciseTemplate(
      name: 'Romanian Deadlift',
      category: 'Legs',
      defaultSets: 3,
      defaultReps: 10,
      caloriesPerMinute: 7.5,
      muscleGroup: 'Hamstrings, Glutes',
      instructions: 'Keep legs nearly straight, hinge forward lowering bar along legs until hamstrings stretch.',
    ),
    ExerciseTemplate(
      name: 'Lunges',
      category: 'Legs',
      defaultSets: 3,
      defaultReps: 12,
      caloriesPerMinute: 7.0,
      muscleGroup: 'Quadriceps, Glutes, Hamstrings',
      instructions: 'Step forward, lower back knee toward floor, push back to start with front heel.',
    ),
    ExerciseTemplate(
      name: 'Calf Raises',
      category: 'Legs',
      defaultSets: 4,
      defaultReps: 15,
      caloriesPerMinute: 5.0,
      muscleGroup: 'Gastrocnemius, Soleus',
      instructions: 'Stand on edge of step, rise onto toes fully, then lower below step level.',
    ),
    // SHOULDERS
    ExerciseTemplate(
      name: 'Overhead Press',
      category: 'Shoulders',
      defaultSets: 4,
      defaultReps: 8,
      caloriesPerMinute: 7.5,
      muscleGroup: 'Deltoids, Triceps, Traps',
      instructions: 'Press barbell from shoulder level to full overhead extension, avoid arching lower back.',
    ),
    ExerciseTemplate(
      name: 'Lateral Raises',
      category: 'Shoulders',
      defaultSets: 3,
      defaultReps: 15,
      caloriesPerMinute: 5.5,
      muscleGroup: 'Lateral Deltoids',
      instructions: 'Raise dumbbells out to sides until arms are parallel to floor, control the descent.',
    ),
    ExerciseTemplate(
      name: 'Front Raises',
      category: 'Shoulders',
      defaultSets: 3,
      defaultReps: 12,
      caloriesPerMinute: 5.5,
      muscleGroup: 'Anterior Deltoids',
      instructions: 'Raise dumbbells forward to shoulder height, keep slight bend in elbows.',
    ),
    ExerciseTemplate(
      name: 'Face Pulls',
      category: 'Shoulders',
      defaultSets: 3,
      defaultReps: 15,
      caloriesPerMinute: 5.0,
      muscleGroup: 'Posterior Deltoids, Rotator Cuff',
      instructions: 'Pull rope attachment to face level with elbows high and wide.',
    ),
    ExerciseTemplate(
      name: 'Arnold Press',
      category: 'Shoulders',
      defaultSets: 3,
      defaultReps: 10,
      caloriesPerMinute: 7.0,
      muscleGroup: 'All Deltoid Heads',
      instructions: 'Start with palms facing you, rotate and press overhead ending palms forward.',
    ),
    // ARMS
    ExerciseTemplate(
      name: 'Barbell Curl',
      category: 'Arms',
      defaultSets: 3,
      defaultReps: 10,
      caloriesPerMinute: 5.5,
      muscleGroup: 'Biceps',
      instructions: 'Curl barbell from hip to shoulder height keeping elbows at sides.',
    ),
    ExerciseTemplate(
      name: 'Tricep Pushdown',
      category: 'Arms',
      defaultSets: 3,
      defaultReps: 12,
      caloriesPerMinute: 5.0,
      muscleGroup: 'Triceps',
      instructions: 'Push cable bar down until arms are fully extended, keep elbows close to body.',
    ),
    ExerciseTemplate(
      name: 'Hammer Curls',
      category: 'Arms',
      defaultSets: 3,
      defaultReps: 12,
      caloriesPerMinute: 5.5,
      muscleGroup: 'Biceps, Brachialis',
      instructions: 'Curl dumbbells with neutral grip (thumbs up) to shoulder height.',
    ),
    ExerciseTemplate(
      name: 'Skull Crushers',
      category: 'Arms',
      defaultSets: 3,
      defaultReps: 10,
      caloriesPerMinute: 5.5,
      muscleGroup: 'Triceps',
      instructions: 'Lower barbell toward forehead by bending elbows, then extend back to start.',
    ),
    ExerciseTemplate(
      name: 'Preacher Curls',
      category: 'Arms',
      defaultSets: 3,
      defaultReps: 10,
      caloriesPerMinute: 5.0,
      muscleGroup: 'Biceps',
      instructions: 'Rest upper arms on preacher pad and curl weight up to full contraction.',
    ),
    // CORE
    ExerciseTemplate(
      name: 'Plank',
      category: 'Core',
      defaultSets: 3,
      defaultReps: 1,
      defaultDuration: 1,
      caloriesPerMinute: 5.0,
      muscleGroup: 'Transverse Abdominis, Stabilizers',
      instructions: 'Hold body in straight line from head to heels on forearms and toes.',
    ),
    ExerciseTemplate(
      name: 'Crunches',
      category: 'Core',
      defaultSets: 3,
      defaultReps: 20,
      caloriesPerMinute: 5.5,
      muscleGroup: 'Rectus Abdominis',
      instructions: 'Curl shoulders toward knees, pause at top, slowly lower back down.',
    ),
    ExerciseTemplate(
      name: 'Russian Twists',
      category: 'Core',
      defaultSets: 3,
      defaultReps: 20,
      caloriesPerMinute: 6.0,
      muscleGroup: 'Obliques',
      instructions: 'Sit with feet off floor, rotate torso side to side touching hands to floor.',
    ),
    ExerciseTemplate(
      name: 'Leg Raises',
      category: 'Core',
      defaultSets: 3,
      defaultReps: 15,
      caloriesPerMinute: 5.5,
      muscleGroup: 'Lower Abs, Hip Flexors',
      instructions: 'Lie flat, raise straight legs to 90 degrees, slowly lower without touching floor.',
    ),
    ExerciseTemplate(
      name: 'Mountain Climbers',
      category: 'Core',
      defaultSets: 3,
      defaultReps: 20,
      defaultDuration: 1,
      caloriesPerMinute: 8.0,
      muscleGroup: 'Core, Hip Flexors, Shoulders',
      instructions: 'In push-up position, drive knees alternately toward chest at pace.',
    ),
    // CARDIO
    ExerciseTemplate(
      name: 'Running',
      category: 'Cardio',
      defaultSets: 1,
      defaultReps: 1,
      defaultDuration: 30,
      caloriesPerMinute: 11.0,
      muscleGroup: 'Full Body, Cardiovascular',
      instructions: 'Maintain steady pace with relaxed shoulders and natural arm swing.',
    ),
    ExerciseTemplate(
      name: 'Cycling',
      category: 'Cardio',
      defaultSets: 1,
      defaultReps: 1,
      defaultDuration: 30,
      caloriesPerMinute: 9.0,
      muscleGroup: 'Legs, Cardiovascular',
      instructions: 'Keep cadence around 80-100 RPM with slight forward lean.',
    ),
    ExerciseTemplate(
      name: 'Jump Rope',
      category: 'Cardio',
      defaultSets: 3,
      defaultReps: 1,
      defaultDuration: 5,
      caloriesPerMinute: 12.0,
      muscleGroup: 'Full Body, Cardiovascular',
      instructions: 'Jump with both feet, keep elbows close to body and wrists doing the rotation.',
    ),
    ExerciseTemplate(
      name: 'Burpees',
      category: 'Cardio',
      defaultSets: 3,
      defaultReps: 10,
      caloriesPerMinute: 10.0,
      muscleGroup: 'Full Body',
      instructions: 'Drop to push-up, complete push-up, jump feet to hands, jump up with arms overhead.',
    ),
    ExerciseTemplate(
      name: 'Rowing',
      category: 'Cardio',
      defaultSets: 1,
      defaultReps: 1,
      defaultDuration: 20,
      caloriesPerMinute: 10.0,
      muscleGroup: 'Back, Arms, Legs, Cardiovascular',
      instructions: 'Drive with legs first, then lean back slightly, then pull handle to lower chest.',
    ),
    ExerciseTemplate(
      name: 'HIIT Sprints',
      category: 'Cardio',
      defaultSets: 8,
      defaultReps: 1,
      defaultDuration: 1,
      caloriesPerMinute: 14.0,
      muscleGroup: 'Full Body, Cardiovascular',
      instructions: 'Sprint at maximum effort for 20-30 seconds, rest for equal time, repeat.',
    ),
    // FLEXIBILITY
    ExerciseTemplate(
      name: 'Yoga Flow',
      category: 'Flexibility',
      defaultSets: 1,
      defaultReps: 1,
      defaultDuration: 20,
      caloriesPerMinute: 3.5,
      muscleGroup: 'Full Body',
      instructions: 'Move through poses with breath, holding each for 3-5 breaths.',
    ),
    ExerciseTemplate(
      name: 'Hip Flexor Stretch',
      category: 'Flexibility',
      defaultSets: 2,
      defaultReps: 1,
      defaultDuration: 2,
      caloriesPerMinute: 2.0,
      muscleGroup: 'Hip Flexors, Quads',
      instructions: 'In lunge position, push hips forward and hold to stretch front of hip.',
    ),
    ExerciseTemplate(
      name: 'Hamstring Stretch',
      category: 'Flexibility',
      defaultSets: 2,
      defaultReps: 1,
      defaultDuration: 2,
      caloriesPerMinute: 2.0,
      muscleGroup: 'Hamstrings, Calves',
      instructions: 'Sit with legs extended, reach toward toes keeping back as flat as possible.',
    ),
    ExerciseTemplate(
      name: 'Shoulder Mobility',
      category: 'Flexibility',
      defaultSets: 2,
      defaultReps: 10,
      defaultDuration: 5,
      caloriesPerMinute: 2.5,
      muscleGroup: 'Shoulders, Upper Back',
      instructions: 'Perform arm circles and cross-body stretches to open shoulder joint.',
    ),
    ExerciseTemplate(
      name: 'Foam Rolling',
      category: 'Flexibility',
      defaultSets: 1,
      defaultReps: 1,
      defaultDuration: 10,
      caloriesPerMinute: 2.0,
      muscleGroup: 'Full Body Myofascial',
      instructions: 'Roll slowly over muscle groups, pausing on tender spots for 20-30 seconds.',
    ),
    ExerciseTemplate(
      name: 'Cat-Cow Stretch',
      category: 'Flexibility',
      defaultSets: 2,
      defaultReps: 10,
      caloriesPerMinute: 2.0,
      muscleGroup: 'Spine, Core',
      instructions: 'On hands and knees, alternate arching and rounding spine with each breath.',
    ),
  ];

  static List<String> get categories =>
      ['Chest', 'Back', 'Legs', 'Shoulders', 'Arms', 'Core', 'Cardio', 'Flexibility'];

  static List<ExerciseTemplate> byCategory(String category) =>
      exercises.where((e) => e.category == category).toList();

  static List<ExerciseTemplate> search(String query) {
    final q = query.toLowerCase();
    return exercises
        .where((e) =>
            e.name.toLowerCase().contains(q) ||
            e.category.toLowerCase().contains(q) ||
            e.muscleGroup.toLowerCase().contains(q))
        .toList();
  }
}
