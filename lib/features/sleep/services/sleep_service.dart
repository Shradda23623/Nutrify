import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/firestore_service.dart';
import '../models/sleep_model.dart';

/// Path: users/{uid}/sleep/{auto-id}
class SleepService {
  CollectionReference<Map<String, dynamic>> get _col =>
      FirestoreService.collection('sleep');

  // ── Get all entries (newest first) ────────────────────────────────────────

  Future<List<SleepEntry>> getEntries() async {
    try {
      final snap = await _col.orderBy('bedtime', descending: true).get();
      return snap.docs
          .map((d) => SleepEntry.fromMap(d.data()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── Add entry ──────────────────────────────────────────────────────────────

  Future<void> addEntry(SleepEntry entry) async {
    await _col.add({
      ...entry.toMap(),
      'createdAt': FirestoreService.serverTimestamp,
    });
  }

  // ── Delete entry by index ──────────────────────────────────────────────────

  Future<void> deleteEntry(int index) async {
    try {
      final snap =
          await _col.orderBy('bedtime', descending: true).get();
      if (index < 0 || index >= snap.docs.length) return;
      await snap.docs[index].reference.delete();
    } catch (_) {}
  }

  // ── 7-day averages ────────────────────────────────────────────────────────

  Future<Map<String, double>> getWeeklyAverage() async {
    try {
      final cutoff = DateTime.now().subtract(const Duration(days: 7));
      final snap = await _col
          .where('bedtime',
              isGreaterThanOrEqualTo: cutoff.toIso8601String())
          .get();
      if (snap.docs.isEmpty) return {'hours': 0, 'quality': 0};
      final entries =
          snap.docs.map((d) => SleepEntry.fromMap(d.data())).toList();
      final avgHours = entries.map((e) => e.durationHours).reduce((a, b) => a + b) /
          entries.length;
      final avgQuality =
          entries.map((e) => e.quality.toDouble()).reduce((a, b) => a + b) /
              entries.length;
      return {'hours': avgHours, 'quality': avgQuality};
    } catch (_) {
      return {'hours': 0, 'quality': 0};
    }
  }

  // ── Real-time stream ──────────────────────────────────────────────────────

  Stream<List<SleepEntry>> stream() {
    return _col.orderBy('bedtime', descending: true).snapshots().map(
        (snap) => snap.docs
            .map((d) => SleepEntry.fromMap(d.data()))
            .toList());
  }
}
