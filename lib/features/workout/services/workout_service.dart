import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/firestore_service.dart';
import '../models/workout_model.dart';

/// Path: users/{uid}/workouts/{sessionId}
class WorkoutService {
  CollectionReference<Map<String, dynamic>> get _col =>
      FirestoreService.collection('workouts');

  // ── Get all sessions (newest first) ───────────────────────────────────────

  Future<List<WorkoutSession>> getSessions() async {
    try {
      final snap = await _col.orderBy('date', descending: true).get();
      return snap.docs
          .map((d) => WorkoutSession.fromMap({...d.data(), 'id': d.id}))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── Add session ────────────────────────────────────────────────────────────

  Future<void> addSession(WorkoutSession session) async {
    await _col.doc(session.id).set({
      ...session.toMap(),
      'createdAt': FirestoreService.serverTimestamp,
    });
  }

  // ── Delete session ─────────────────────────────────────────────────────────

  Future<void> deleteSession(String id) async {
    await _col.doc(id).delete();
  }

  // ── Today's sessions ──────────────────────────────────────────────────────

  Future<List<WorkoutSession>> getTodaySessions() async {
    final all = await getSessions();
    final today = DateTime.now();
    return all.where((s) =>
        s.date.year == today.year &&
        s.date.month == today.month &&
        s.date.day == today.day).toList();
  }

  // ── Weekly stats ───────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getWeeklyStats() async {
    try {
      final cutoff = DateTime.now().subtract(const Duration(days: 7));
      final snap = await _col
          .where('date',
              isGreaterThanOrEqualTo: cutoff.toIso8601String())
          .get();
      if (snap.docs.isEmpty) {
        return {
          'sessions': 0,
          'totalMinutes': 0,
          'totalCalories': 0,
          'avgDuration': 0,
        };
      }
      final sessions = snap.docs
          .map((d) => WorkoutSession.fromMap({...d.data(), 'id': d.id}))
          .toList();
      final totalMin =
          sessions.fold<int>(0, (s, e) => s + e.totalDurationMinutes);
      final totalCal =
          sessions.fold<int>(0, (s, e) => s + e.totalCaloriesBurned);
      return {
        'sessions': sessions.length,
        'totalMinutes': totalMin,
        'totalCalories': totalCal,
        'avgDuration': sessions.isEmpty
            ? 0
            : (totalMin / sessions.length).round(),
      };
    } catch (_) {
      return {
        'sessions': 0,
        'totalMinutes': 0,
        'totalCalories': 0,
        'avgDuration': 0,
      };
    }
  }

  // ── Real-time stream ──────────────────────────────────────────────────────

  Stream<List<WorkoutSession>> stream() {
    return _col.orderBy('date', descending: true).snapshots().map(
        (snap) => snap.docs
            .map((d) =>
                WorkoutSession.fromMap({...d.data(), 'id': d.id}))
            .toList());
  }
}
