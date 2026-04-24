import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/firestore_service.dart';
import '../models/meal_plan_model.dart';

/// Path: users/{uid}/meal_plans/{YYYY-MM-DD}
/// Document: { dateKey, foods: [ PlannedFood ] }
class MealPlanService {
  CollectionReference<Map<String, dynamic>> get _col =>
      FirestoreService.collection('meal_plans');

  // ── Key helper — accepts String or DateTime ────────────────────────────────

  String _key(dynamic date) {
    if (date is DateTime) return FirestoreService.dateKey(date);
    return date as String;
  }

  // ── Load a specific day ────────────────────────────────────────────────────

  Future<MealPlanDay> loadDay(dynamic date) async {
    final key = _key(date);
    try {
      final doc = await _col.doc(key).get();
      if (!doc.exists || doc.data() == null) {
        return MealPlanDay(dateKey: key, foods: []);
      }
      final raw = (doc.data()!['foods'] as List<dynamic>? ?? []);
      return MealPlanDay(
        dateKey: key,
        foods: raw
            .map((e) =>
                PlannedFood.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
    } catch (_) {
      return MealPlanDay(dateKey: key, foods: []);
    }
  }

  // ── Load today ─────────────────────────────────────────────────────────────

  Future<MealPlanDay> loadToday() => loadDay(FirestoreService.todayKey);

  // ── Save a day ─────────────────────────────────────────────────────────────

  Future<void> saveDay(MealPlanDay day) async {
    await _col.doc(day.dateKey).set({
      'dateKey':   day.dateKey,
      'foods':     day.foods.map((f) => f.toMap()).toList(),
      'updatedAt': FirestoreService.serverTimestamp,
    });
  }

  // ── Add food to a day ──────────────────────────────────────────────────────

  Future<void> addFood(dynamic date, PlannedFood food) async {
    final day = await loadDay(date);
    day.foods.add(food);
    await saveDay(day);
  }

  // ── Remove food from a day (accepts optional mealType filter) ─────────────

  Future<void> removeFood(dynamic date, int index,
      [String? mealType]) async {
    final day = await loadDay(date);
    // If mealType given, find the index within that meal group
    if (mealType != null) {
      final mealFoods = day.foods
          .asMap()
          .entries
          .where((e) => e.value.mealType == mealType)
          .toList();
      if (index >= 0 && index < mealFoods.length) {
        day.foods.removeAt(mealFoods[index].key);
      }
    } else {
      if (index >= 0 && index < day.foods.length) {
        day.foods.removeAt(index);
      }
    }
    await saveDay(day);
  }

  // ── Load a range of days ───────────────────────────────────────────────────

  Future<List<MealPlanDay>> loadRange(int days) async {
    final futures = List.generate(days, (i) {
      final date = DateTime.now().add(Duration(days: i));
      return loadDay(date);
    });
    return Future.wait(futures);
  }

  // ── Real-time stream for today ────────────────────────────────────────────

  Stream<MealPlanDay> todayStream() {
    return _col.doc(FirestoreService.todayKey).snapshots().map((snap) {
      final key = FirestoreService.todayKey;
      if (!snap.exists || snap.data() == null) {
        return MealPlanDay(dateKey: key, foods: []);
      }
      final raw = (snap.data()!['foods'] as List<dynamic>? ?? []);
      return MealPlanDay(
        dateKey: key,
        foods: raw
            .map((e) =>
                PlannedFood.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
    });
  }
}
