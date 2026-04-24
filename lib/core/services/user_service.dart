import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'firestore_service.dart';
import '../../features/profile/models/user_model.dart';

/// Manages the user profile document in Firestore.
/// Path: users/{uid}  (top-level fields on the user document)
class UserService {
  // ── Load profile ───────────────────────────────────────────────────────────

  Future<UserModel> load() async {
    try {
      final doc = await FirestoreService.userDoc.get();
      if (!doc.exists || doc.data() == null) return UserModel();
      return UserModel.fromMap(doc.data()!);
    } catch (_) {
      return UserModel();
    }
  }

  // ── Save profile ───────────────────────────────────────────────────────────

  Future<void> save(UserModel user) async {
    await FirestoreService.userDoc.set(
      user.toMap()..['updatedAt'] = FirestoreService.serverTimestamp,
      SetOptions(merge: true),
    );
  }

  // ── Update individual fields ───────────────────────────────────────────────

  Future<void> updateField(String field, dynamic value) async {
    await FirestoreService.userDoc.set(
      {field: value, 'updatedAt': FirestoreService.serverTimestamp},
      SetOptions(merge: true),
    );
  }

  // ── Upload profile photo to Firebase Storage ───────────────────────────────

  /// Uploads [imageFile] and returns the download URL.
  /// Also updates the 'avatarUrl' field in the user document.
  Future<String> uploadAvatar(File imageFile) async {
    final uid  = FirestoreService.uid;
    final ref  = FirebaseStorage.instance
        .ref()
        .child('avatars')
        .child('$uid.jpg');

    final task = await ref.putFile(
      imageFile,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    final url = await task.ref.getDownloadURL();

    // Persist the URL so other devices can load it
    await FirestoreService.userDoc.update({'avatarUrl': url});
    return url;
  }

  // ── Stream (real-time updates) ─────────────────────────────────────────────

  Stream<UserModel> stream() {
    return FirestoreService.userDoc.snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return UserModel();
      return UserModel.fromMap(snap.data()!);
    });
  }

  // ── Calorie goal shortcut ──────────────────────────────────────────────────

  Future<void> saveCalorieGoal(double goal) =>
      updateField('dailyCalorieGoal', goal);

  Future<double> loadCalorieGoal() async {
    final user = await load();
    return user.dailyCalorieGoal;
  }
}
