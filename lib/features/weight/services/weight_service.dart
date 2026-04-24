import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/firestore_service.dart';
import '../models/weight_model.dart';

/// Path: users/{uid}/weight/{auto-id}
/// Each document = one WeightEntry
class WeightService {
  CollectionReference<Map<String, dynamic>> get _col =>
      FirestoreService.collection('weight');

  // ── Load all entries (sorted oldest → newest) ─────────────────────────────

  Future<List<WeightEntry>> loadAll() async {
    try {
      final snap = await _col.orderBy('date').get();
      return snap.docs
          .map((d) => WeightEntry.fromMap({...d.data(), 'id': d.id}))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── Add entry ──────────────────────────────────────────────────────────────

  Future<void> addEntry(WeightEntry entry) async {
    await _col.add({
      ...entry.toMap(),
      'createdAt': FirestoreService.serverTimestamp,
    });
  }

  // ── Delete by list index (used by weight_screen) ──────────────────────────

  Future<void> deleteEntry(int index) async {
    try {
      final snap = await _col.orderBy('date').get();
      if (index < 0 || index >= snap.docs.length) return;
      await snap.docs[index].reference.delete();
    } catch (_) {}
  }

  // ── Delete by Firestore document ID ───────────────────────────────────────

  Future<void> deleteById(String docId) async {
    await _col.doc(docId).delete();
  }

  // ── Convenience getters ────────────────────────────────────────────────────

  WeightEntry? latestEntry(List<WeightEntry> entries) =>
      entries.isEmpty ? null : entries.last;

  double? weightChange(List<WeightEntry> entries) {
    if (entries.length < 2) return null;
    return entries.last.kg - entries.first.kg;
  }

  // ── Real-time stream ──────────────────────────────────────────────────────

  Stream<List<WeightEntry>> stream() {
    return _col.orderBy('date').snapshots().map((snap) => snap.docs
        .map((d) => WeightEntry.fromMap({...d.data(), 'id': d.id}))
        .toList());
  }
}
