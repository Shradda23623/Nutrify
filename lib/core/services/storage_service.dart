import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'firestore_service.dart';

/// Firebase Storage helper for file uploads.
/// All files are stored under  gs://<bucket>/users/{uid}/...
class StorageService {
  static final _storage = FirebaseStorage.instance;

  // ── Upload a file and return its download URL ─────────────────────────────

  static Future<String> upload({
    required File file,
    required String storagePath,   // e.g. "users/{uid}/avatars/photo.jpg"
    String? contentType,           // e.g. "image/jpeg"
    void Function(double progress)? onProgress,
  }) async {
    final ref = _storage.ref().child(storagePath);
    final meta = contentType != null
        ? SettableMetadata(contentType: contentType)
        : null;

    final task = ref.putFile(file, meta);

    if (onProgress != null) {
      task.snapshotEvents.listen((snap) {
        if (snap.totalBytes > 0) {
          onProgress(snap.bytesTransferred / snap.totalBytes);
        }
      });
    }

    final snapshot = await task;
    return snapshot.ref.getDownloadURL();
  }

  // ── Upload profile avatar ─────────────────────────────────────────────────

  static Future<String> uploadAvatar(File imageFile,
      {void Function(double)? onProgress}) async {
    final uid  = FirestoreService.uid;
    final path = 'users/$uid/avatars/profile.jpg';
    return upload(
      file:        imageFile,
      storagePath: path,
      contentType: 'image/jpeg',
      onProgress:  onProgress,
    );
  }

  // ── Upload food scan / barcode image ─────────────────────────────────────

  static Future<String> uploadFoodImage(File imageFile) async {
    final uid  = FirestoreService.uid;
    final ts   = DateTime.now().millisecondsSinceEpoch;
    final path = 'users/$uid/food_images/$ts.jpg';
    return upload(
      file:        imageFile,
      storagePath: path,
      contentType: 'image/jpeg',
    );
  }

  // ── Delete a file ─────────────────────────────────────────────────────────

  static Future<void> delete(String storagePath) async {
    try {
      await _storage.ref().child(storagePath).delete();
    } catch (_) {}
  }

  // ── Get download URL for an existing file ────────────────────────────────

  static Future<String?> getDownloadUrl(String storagePath) async {
    try {
      return await _storage.ref().child(storagePath).getDownloadURL();
    } catch (_) {
      return null;
    }
  }
}
