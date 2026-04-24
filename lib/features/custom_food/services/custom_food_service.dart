import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/firestore_service.dart';
import '../models/custom_food_model.dart';

/// Path: users/{uid}/custom_foods/{foodId}
class CustomFoodService {
  CollectionReference<Map<String, dynamic>> get _col =>
      FirestoreService.collection('custom_foods');

  // ── Load all ───────────────────────────────────────────────────────────────

  Future<List<CustomFoodModel>> loadAll() async {
    try {
      final snap =
          await _col.orderBy('createdAt', descending: true).get();
      return snap.docs
          .map((d) => CustomFoodModel.fromMap({...d.data(), 'id': d.id}))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── Add food ───────────────────────────────────────────────────────────────

  Future<void> addFood(CustomFoodModel food) async {
    await _col.doc(food.id).set({
      ...food.toMap(),
      'createdAt': FirestoreService.serverTimestamp,
    });
  }

  // ── Delete food ────────────────────────────────────────────────────────────

  Future<void> deleteFood(String id) async {
    await _col.doc(id).delete();
  }

  // ── Update food ────────────────────────────────────────────────────────────

  Future<void> updateFood(CustomFoodModel food) async {
    await _col.doc(food.id).update({
      ...food.toMap(),
      'updatedAt': FirestoreService.serverTimestamp,
    });
  }

  // ── Search ─────────────────────────────────────────────────────────────────

  Future<List<CustomFoodModel>> search(String query) async {
    final all = await loadAll();
    final q   = query.toLowerCase();
    return all
        .where((f) => f.name.toLowerCase().contains(q))
        .toList();
  }

  // ── Aliases used by custom_food_screen ───────────────────────────────────

  Future<void> save(CustomFoodModel food)   => addFood(food);
  Future<void> delete(String id)            => deleteFood(id);

  // ── Real-time stream ──────────────────────────────────────────────────────

  Stream<List<CustomFoodModel>> stream() {
    return _col.orderBy('createdAt', descending: true).snapshots().map(
        (snap) => snap.docs
            .map((d) =>
                CustomFoodModel.fromMap({...d.data(), 'id': d.id}))
            .toList());
  }
}
