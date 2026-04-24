import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/firestore_service.dart';
import '../models/water_model.dart';

/// Path: users/{uid}/water/{YYYY-MM-DD}
/// { intake: int, goal: int, updatedAt: Timestamp }
class WaterService {
  CollectionReference<Map<String, dynamic>> get _col =>
      FirestoreService.collection('water');

  // ── Load today ─────────────────────────────────────────────────────────────

  Future<WaterModel> load() async {
    try {
      final doc = await _col.doc(FirestoreService.todayKey).get();
      if (!doc.exists || doc.data() == null) {
        return WaterModel(intake: 0, goal: 8);
      }
      final d = doc.data()!;
      return WaterModel(
        intake: (d['intake'] as num?)?.toInt() ?? 0,
        goal:   (d['goal']   as num?)?.toInt() ?? 8,
      );
    } catch (_) {
      return WaterModel(intake: 0, goal: 8);
    }
  }

  // ── Save today ─────────────────────────────────────────────────────────────

  Future<void> save(WaterModel model) async {
    await _col.doc(FirestoreService.todayKey).set({
      'intake':    model.intake,
      'goal':      model.goal,
      'updatedAt': FirestoreService.serverTimestamp,
    });
  }

  // ── Weekly history ─────────────────────────────────────────────────────────

  Future<List<int>> getWeeklyHistory(int days) async {
    final futures = List.generate(days, (i) {
      final date = DateTime.now().subtract(Duration(days: days - 1 - i));
      return _col.doc(FirestoreService.dateKey(date)).get();
    });
    final snapshots = await Future.wait(futures);
    return snapshots.map((snap) {
      if (!snap.exists || snap.data() == null) return 0;
      return (snap.data()!['intake'] as num?)?.toInt() ?? 0;
    }).toList();
  }

  // ── Real-time stream ──────────────────────────────────────────────────────

  Stream<WaterModel> stream() {
    return _col.doc(FirestoreService.todayKey).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) {
        return WaterModel(intake: 0, goal: 8);
      }
      final d = snap.data()!;
      return WaterModel(
        intake: (d['intake'] as num?)?.toInt() ?? 0,
        goal:   (d['goal']   as num?)?.toInt() ?? 8,
      );
    });
  }
}
