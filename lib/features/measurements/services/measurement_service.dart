import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/firestore_service.dart';
import '../models/measurement_model.dart';

/// Path: users/{uid}/measurements/{entryId}
class MeasurementService {
  CollectionReference<Map<String, dynamic>> get _col =>
      FirestoreService.collection('measurements');

  // ── Load all (newest first) ────────────────────────────────────────────────

  Future<List<MeasurementEntry>> loadAll() async {
    try {
      final snap = await _col.orderBy('date', descending: true).get();
      return snap.docs
          .map((d) => MeasurementEntry.fromMap({...d.data(), 'id': d.id}))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── Add entry ──────────────────────────────────────────────────────────────

  Future<void> addEntry(MeasurementEntry entry) async {
    await _col.doc(entry.id).set({
      ...entry.toMap(),
      'createdAt': FirestoreService.serverTimestamp,
    });
  }

  // ── Delete entry ───────────────────────────────────────────────────────────

  Future<void> deleteEntry(String id) async {
    await _col.doc(id).delete();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  MeasurementEntry? latest(List<MeasurementEntry> entries) =>
      entries.isEmpty ? null : entries.first;

  /// Returns the most recent non-null value for [field] across all entries.
  double? latestFieldValue(List<MeasurementEntry> entries, String field) {
    for (final e in entries) {
      final v = _value(e, field);
      if (v != null) return v;
    }
    return null;
  }

  double? change(List<MeasurementEntry> entries, String field) {
    final withField =
        entries.where((e) => _value(e, field) != null).toList();
    if (withField.length < 2) return null;
    return _value(withField[0], field)! - _value(withField[1], field)!;
  }

  double? _value(MeasurementEntry e, String field) {
    switch (field) {
      case 'waist':  return e.waist;
      case 'hips':   return e.hips;
      case 'chest':  return e.chest;
      case 'arms':   return e.arms;
      case 'thighs': return e.thighs;
      default:       return null;
    }
  }

  // ── Real-time stream ──────────────────────────────────────────────────────

  Stream<List<MeasurementEntry>> stream() {
    return _col.orderBy('date', descending: true).snapshots().map(
        (snap) => snap.docs
            .map((d) =>
                MeasurementEntry.fromMap({...d.data(), 'id': d.id}))
            .toList());
  }
}
