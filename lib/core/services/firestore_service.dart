import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Base helper — every data service extends this.
/// Provides a typed reference to the current user's subcollection.
///
/// Firestore structure:
/// users/
///   {uid}/
///     profile fields (name, age, heightCm, …)
///     calories/{YYYY-MM-DD}   → { goal, entries: [] }
///     water/{YYYY-MM-DD}      → { intake, goal }
///     weight/{entryId}        → WeightEntry
///     measurements/{entryId}  → MeasurementEntry
///     sleep/{entryId}         → SleepEntry
///     workouts/{sessionId}    → WorkoutSession
///     fasting/{sessionId}     → FastingSession
///     meal_plans/{YYYY-MM-DD} → MealPlan
///     custom_foods/{foodId}   → CustomFood
///     micronutrients/{YYYY-MM-DD} → { entries: [] }
///     streaks/data            → { count, lastDate }

class FirestoreService {
  static final _db = FirebaseFirestore.instance;

  /// Current user's UID. Throws if not logged in.
  static String get uid {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) throw Exception('User not logged in');
    return u.uid;
  }

  /// Root document for the current user.
  static DocumentReference<Map<String, dynamic>> get userDoc =>
      _db.collection('users').doc(uid);

  /// A named subcollection under the current user.
  static CollectionReference<Map<String, dynamic>> collection(String name) =>
      userDoc.collection(name);

  /// Helper: "YYYY-MM-DD" string for a given date.
  static String dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static String get todayKey => dateKey(DateTime.now());

  /// Batch write helper — returns a Firestore WriteBatch.
  static WriteBatch get batch => _db.batch();

  /// Server timestamp field value.
  static FieldValue get serverTimestamp => FieldValue.serverTimestamp();
}
