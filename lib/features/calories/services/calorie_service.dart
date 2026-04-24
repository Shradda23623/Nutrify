import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/user_service.dart';
import '../models/calorie_model.dart';

/// Stores daily calorie entries in Firestore.
///
/// Path: users/{uid}/calories/{YYYY-MM-DD}
/// Document shape:
/// {
///   goal: double,
///   entries: [ { name, calories, protein, … , time } ]
/// }
class CalorieService {
  static const _defaultGoal = 2000.0;
  final _userService = UserService();

  CollectionReference<Map<String, dynamic>> get _col =>
      FirestoreService.collection('calories');

  // ── Load today ─────────────────────────────────────────────────────────────

  Future<CalorieModel> load() async {
    final goal = await _userService.loadCalorieGoal();
    try {
      final doc = await _col.doc(FirestoreService.todayKey).get();
      if (!doc.exists || doc.data() == null) {
        return CalorieModel(entries: [], goal: goal);
      }
      final data = doc.data()!;
      final rawList = (data['entries'] as List<dynamic>? ?? []);
      final entries = rawList
          .map((e) => CalorieEntry.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
      return CalorieModel(
        entries: entries,
        goal: (data['goal'] as num?)?.toDouble() ?? goal,
      );
    } catch (_) {
      return CalorieModel(entries: [], goal: goal);
    }
  }

  // ── Save all today's entries ───────────────────────────────────────────────

  Future<void> saveEntries(List<CalorieEntry> entries) async {
    final goal = await _userService.loadCalorieGoal();
    await _col.doc(FirestoreService.todayKey).set(
      {
        'goal': goal,
        'entries': entries.map((e) => e.toMap()).toList(),
        'updatedAt': FirestoreService.serverTimestamp,
      },
      SetOptions(merge: true),
    );
  }

  // ── Add single entry ───────────────────────────────────────────────────────

  Future<void> addEntry(CalorieEntry entry) async {
    final model = await load();
    model.entries.add(entry);
    await saveEntries(model.entries);
    await _addToRecent(entry);
  }

  // ── Remove entry by index ──────────────────────────────────────────────────

  Future<void> removeEntry(int index) async {
    final model = await load();
    if (index >= 0 && index < model.entries.length) {
      model.entries.removeAt(index);
      await saveEntries(model.entries);
    }
  }

  // ── Save calorie goal ──────────────────────────────────────────────────────

  Future<void> saveGoal(double goal) => _userService.saveCalorieGoal(goal);

  // ── Weekly history (last N days) ───────────────────────────────────────────

  Future<List<double>> getWeeklyHistory(int days) async {
    final futures = List.generate(days, (i) {
      final date = DateTime.now().subtract(Duration(days: days - 1 - i));
      return _col.doc(FirestoreService.dateKey(date)).get();
    });
    final snapshots = await Future.wait(futures);
    return snapshots.map((snap) {
      if (!snap.exists || snap.data() == null) return 0.0;
      final entries = (snap.data()!['entries'] as List<dynamic>? ?? []);
      return entries.fold<double>(0,
          (s, e) => s + ((e as Map)['calories'] as num? ?? 0).toDouble());
    }).toList();
  }

  // ── Recent foods (quick-add list) ─────────────────────────────────────────

  Future<List<CalorieEntry>> getRecentFoods() async {
    try {
      final doc = await FirestoreService.userDoc
          .collection('recent_foods')
          .doc('list')
          .get();
      if (!doc.exists || doc.data() == null) return [];
      final raw = (doc.data()!['items'] as List<dynamic>? ?? []);
      return raw
          .map((e) =>
              CalorieEntry.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _addToRecent(CalorieEntry entry) async {
    final recent = await getRecentFoods();
    recent.removeWhere(
        (e) => e.name.toLowerCase() == entry.name.toLowerCase());
    recent.insert(0, entry);
    await FirestoreService.userDoc
        .collection('recent_foods')
        .doc('list')
        .set({'items': recent.take(10).map((e) => e.toMap()).toList()});
  }

  // ── Real-time stream ──────────────────────────────────────────────────────

  Stream<CalorieModel> stream() {
    return _col.doc(FirestoreService.todayKey).snapshots().asyncMap(
      (snap) async {
        final goal = await _userService.loadCalorieGoal();
        if (!snap.exists || snap.data() == null) {
          return CalorieModel(entries: [], goal: goal);
        }
        final data = snap.data()!;
        final entries = (data['entries'] as List<dynamic>? ?? [])
            .map((e) =>
                CalorieEntry.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList();
        return CalorieModel(
          entries: entries,
          goal: (data['goal'] as num?)?.toDouble() ?? goal,
        );
      },
    );
  }
}
