import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/firestore_service.dart';
import '../../calories/services/calorie_service.dart';
import '../../calories/models/calorie_model.dart';

/// Daily Reference Intakes (DRI) for adults.
class MicroGoals {
  static const double iron       = 18.0;   // mg  (women; 8 mg men)
  static const double calcium    = 1000.0; // mg
  static const double vitaminB12 = 2.4;    // mcg
  static const double vitaminD   = 600.0;  // IU
  static const double vitaminC   = 90.0;   // mg
  static const double magnesium  = 400.0;  // mg
}

enum DeficiencyLevel { ok, low, critical }

class MicronutrientStatus {
  final String name;
  final String unit;
  final double intake;
  final double goal;
  final double percent;
  final DeficiencyLevel level;
  final String emoji;
  final String tip;

  const MicronutrientStatus({
    required this.name,
    required this.unit,
    required this.intake,
    required this.goal,
    required this.percent,
    required this.level,
    required this.emoji,
    required this.tip,
  });
}

class WeeklyMicroSnapshot {
  final String dateLabel;
  final double ironPct;
  final double calciumPct;
  final double b12Pct;
  final double vitDPct;

  const WeeklyMicroSnapshot({
    required this.dateLabel,
    required this.ironPct,
    required this.calciumPct,
    required this.b12Pct,
    required this.vitDPct,
  });
}

/// Path: users/{uid}/micronutrients/{YYYY-MM-DD}
class MicronutrientService {
  final _calorieService = CalorieService();

  CollectionReference<Map<String, dynamic>> get _col =>
      FirestoreService.collection('micronutrients');

  // ── Today's status (derived from today's calorie entries) ─────────────────

  Future<List<MicronutrientStatus>> getTodayStatus() async {
    final model = await _calorieService.load();
    return _buildStatuses(model);
  }

  List<MicronutrientStatus> _buildStatuses(CalorieModel model) {
    return [
      _status('Iron',        'mg',  model.totalIron,       MicroGoals.iron,       '🩸',
          'Eat spinach, lentils, fortified cereals or tofu.'),
      _status('Calcium',     'mg',  model.totalCalcium,    MicroGoals.calcium,    '🦴',
          'Include dairy, ragi, sesame seeds or leafy greens.'),
      _status('Vitamin B12', 'mcg', model.totalVitaminB12, MicroGoals.vitaminB12, '⚡',
          'Eggs, dairy, paneer or B12-fortified plant milks.'),
      _status('Vitamin D',   'IU',  model.totalVitaminD,   MicroGoals.vitaminD,   '☀️',
          'Sunlight exposure, fatty fish, eggs or fortified milk.'),
      _status('Vitamin C',   'mg',  model.totalVitaminC,   MicroGoals.vitaminC,   '🍊',
          'Citrus, amla, capsicum, guava or broccoli.'),
      _status('Magnesium',   'mg',  model.totalMagnesium,  MicroGoals.magnesium,  '💚',
          'Nuts, seeds, dark chocolate, beans or whole grains.'),
    ];
  }

  MicronutrientStatus _status(String name, String unit, double intake,
      double goal, String emoji, String tip) {
    final pct = (intake / goal).clamp(0.0, 1.0);
    final level = pct >= 0.75
        ? DeficiencyLevel.ok
        : pct >= 0.40
            ? DeficiencyLevel.low
            : DeficiencyLevel.critical;
    return MicronutrientStatus(
      name: name, unit: unit, intake: intake, goal: goal,
      percent: pct, level: level, emoji: emoji, tip: tip,
    );
  }

  // ── Save today's snapshot to Firestore ────────────────────────────────────

  Future<void> saveTodaySnapshot() async {
    final model = await _calorieService.load();
    await _col.doc(FirestoreService.todayKey).set({
      'iron':      model.totalIron,
      'calcium':   model.totalCalcium,
      'vitaminB12':model.totalVitaminB12,
      'vitaminD':  model.totalVitaminD,
      'vitaminC':  model.totalVitaminC,
      'magnesium': model.totalMagnesium,
      'savedAt':   FirestoreService.serverTimestamp,
    });
  }

  // ── Weekly snapshots for chart ─────────────────────────────────────────────

  Future<List<WeeklyMicroSnapshot>> getWeeklySnapshots() async {
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final futures = List.generate(7, (i) {
      final date = DateTime.now().subtract(Duration(days: 6 - i));
      return _col.doc(FirestoreService.dateKey(date)).get();
    });
    final snapshots = await Future.wait(futures);
    return List.generate(7, (i) {
      final date = DateTime.now().subtract(Duration(days: 6 - i));
      final data = snapshots[i].data() ?? {};
      return WeeklyMicroSnapshot(
        dateLabel:  dayNames[date.weekday - 1],
        ironPct:    ((data['iron']       ?? 0) / MicroGoals.iron      ).clamp(0.0, 1.0),
        calciumPct: ((data['calcium']    ?? 0) / MicroGoals.calcium   ).clamp(0.0, 1.0),
        b12Pct:     ((data['vitaminB12'] ?? 0) / MicroGoals.vitaminB12).clamp(0.0, 1.0),
        vitDPct:    ((data['vitaminD']   ?? 0) / MicroGoals.vitaminD  ).clamp(0.0, 1.0),
      );
    });
  }
}
