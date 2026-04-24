import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_service.dart';

/// Path: users/{uid}/streaks/{YYYY-MM-DD}
/// Document: { goalsHit: int, date: String }
///
/// Also maintains users/{uid}/streaks/_summary for quick reads:
/// { currentStreak: int, bestStreak: int, lastDate: String }
class StreakService {
  CollectionReference<Map<String, dynamic>> get _col =>
      FirestoreService.collection('streaks');

  DocumentReference<Map<String, dynamic>> get _summaryDoc =>
      _col.doc('_summary');

  // ── Record a day (call when user logs goals) ──────────────────────────────

  Future<void> recordDay({required int goalsHit}) async {
    final key = FirestoreService.todayKey;
    await _col.doc(key).set({
      'goalsHit': goalsHit,
      'date':     key,
      'savedAt':  FirestoreService.serverTimestamp,
    });
    // Recompute and cache summary
    await _updateSummary();
  }

  // ── Get current streak ────────────────────────────────────────────────────

  Future<int> getCurrentStreak() async {
    try {
      final doc = await _summaryDoc.get();
      if (doc.exists && doc.data() != null) {
        return (doc.data()!['currentStreak'] as num?)?.toInt() ?? 0;
      }
      return await _computeCurrentStreak();
    } catch (_) {
      return 0;
    }
  }

  // ── Get best streak ───────────────────────────────────────────────────────

  Future<int> getBestStreak() async {
    try {
      final doc = await _summaryDoc.get();
      if (doc.exists && doc.data() != null) {
        return (doc.data()!['bestStreak'] as num?)?.toInt() ?? 0;
      }
      return await _computeBestStreak();
    } catch (_) {
      return 0;
    }
  }

  // ── Internals ─────────────────────────────────────────────────────────────

  Future<void> _updateSummary() async {
    final current = await _computeCurrentStreak();
    final best    = await _computeBestStreak();
    await _summaryDoc.set({
      'currentStreak': current,
      'bestStreak':    best,
      'updatedAt':     FirestoreService.serverTimestamp,
    });
  }

  Future<int> _computeCurrentStreak() async {
    int streak = 0;
    for (int i = 0; i < 365; i++) {
      final date = DateTime.now().subtract(Duration(days: i));
      final key  = FirestoreService.dateKey(date);
      try {
        final doc = await _col.doc(key).get();
        if (doc.exists &&
            (doc.data()!['goalsHit'] as num? ?? 0) >= 2) {
          streak++;
        } else {
          break;
        }
      } catch (_) {
        break;
      }
    }
    return streak;
  }

  Future<int> _computeBestStreak() async {
    try {
      final snap = await _col
          .orderBy('date')
          .where('goalsHit', isGreaterThanOrEqualTo: 2)
          .get();
      if (snap.docs.isEmpty) return 0;

      int best = 0, current = 1;
      DateTime? prev;
      for (final doc in snap.docs) {
        if (doc.id == '_summary') continue;
        final dateStr = doc.data()['date'] as String? ?? doc.id;
        try {
          final date = DateTime.parse(dateStr);
          if (prev != null &&
              date.difference(prev).inDays == 1) {
            current++;
          } else {
            current = 1;
          }
          if (current > best) best = current;
          prev = date;
        } catch (_) {}
      }
      return best;
    } catch (_) {
      return 0;
    }
  }
}
