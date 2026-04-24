import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Wraps Firebase Auth + Google Sign-In.
/// All methods return [AuthResult] so the UI never imports Firebase directly.
class AuthService {
  static final _auth   = FirebaseAuth.instance;
  static final _google = GoogleSignIn();
  static final _db     = FirebaseFirestore.instance;

  // ── Current user ───────────────────────────────────────────────────────────

  static User? get currentUser  => _auth.currentUser;
  static String? get currentUid => _auth.currentUser?.uid;
  static String? get currentEmail => _auth.currentUser?.email;

  /// Stream that emits whenever auth state changes (login / logout).
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Check login state ──────────────────────────────────────────────────────

  static Future<bool> isLoggedIn() async => _auth.currentUser != null;

  static Future<bool> isFirstLaunch() async => _auth.currentUser == null;

  // ── Check if profile setup is complete ────────────────────────────────────

  static Future<bool> hasCompletedSetup() async {
    final uid = currentUid;
    if (uid == null) return false;
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) return false;
      final data = doc.data()!;
      final name   = (data['name'] as String? ?? '').trim();
      final height = (data['heightCm'] as num?)?.toDouble() ?? 0;
      return name.isNotEmpty && height > 0;
    } catch (_) {
      return false;
    }
  }

  // ── Email + Password Sign Up ───────────────────────────────────────────────

  static Future<AuthResult> signUp(String email, String password,
      {String name = ''}) async {
    email = email.trim().toLowerCase();
    if (email.isEmpty || !email.contains('@')) {
      return AuthResult.fail('Please enter a valid email address.');
    }
    if (password.length < 6) {
      return AuthResult.fail('Password must be at least 6 characters.');
    }
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (name.isNotEmpty) await cred.user?.updateDisplayName(name);

      // Bootstrap Firestore user document
      await _db.collection('users').doc(cred.user!.uid).set({
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return AuthResult.ok(user: cred.user);
    } on FirebaseAuthException catch (e) {
      return AuthResult.fail(_mapError(e.code));
    } catch (_) {
      return AuthResult.fail('Sign up failed. Please try again.');
    }
  }

  // ── Email + Password Log In ────────────────────────────────────────────────

  static Future<AuthResult> logIn(String email, String password) async {
    email = email.trim().toLowerCase();
    if (email.isEmpty || password.isEmpty) {
      return AuthResult.fail('Please enter your email and password.');
    }
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return AuthResult.ok(user: cred.user);
    } on FirebaseAuthException catch (e) {
      return AuthResult.fail(_mapError(e.code));
    } catch (_) {
      return AuthResult.fail('Login failed. Please try again.');
    }
  }

  // ── Google Sign-In ─────────────────────────────────────────────────────────

  static Future<AuthResult> signInWithGoogle() async {
    try {
      final googleUser = await _google.signIn();
      if (googleUser == null) {
        return AuthResult.fail('Google sign-in was cancelled.');
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final cred = await _auth.signInWithCredential(credential);

      // Create Firestore doc if first-time Google sign-in
      final doc = await _db.collection('users').doc(cred.user!.uid).get();
      if (!doc.exists) {
        await _db.collection('users').doc(cred.user!.uid).set({
          'name': cred.user!.displayName ?? '',
          'email': cred.user!.email ?? '',
          'avatarUrl': cred.user!.photoURL ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      return AuthResult.ok(user: cred.user);
    } on FirebaseAuthException catch (e) {
      return AuthResult.fail(_mapError(e.code));
    } catch (_) {
      return AuthResult.fail('Google sign-in failed. Please try again.');
    }
  }

  // ── Password Reset ─────────────────────────────────────────────────────────

  static Future<AuthResult> sendPasswordReset(String email) async {
    email = email.trim().toLowerCase();
    if (email.isEmpty) {
      return AuthResult.fail('Please enter your email address.');
    }
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return AuthResult.ok();
    } on FirebaseAuthException catch (e) {
      return AuthResult.fail(_mapError(e.code));
    } catch (_) {
      return AuthResult.fail('Failed to send reset email.');
    }
  }

  // ── Change Password ────────────────────────────────────────────────────────

  static Future<AuthResult> changePassword(
      String currentPassword, String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) return AuthResult.fail('Not logged in.');
    try {
      final cred = EmailAuthProvider.credential(
          email: user.email!, password: currentPassword);
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPassword);
      return AuthResult.ok();
    } on FirebaseAuthException catch (e) {
      return AuthResult.fail(_mapError(e.code));
    } catch (_) {
      return AuthResult.fail('Failed to change password.');
    }
  }

  // ── Log Out ────────────────────────────────────────────────────────────────

  static Future<void> logOut() async {
    await _google.signOut();
    await _auth.signOut();
  }

  static Future<void> signOut() => logOut();

  // ── Delete Account ─────────────────────────────────────────────────────────

  static Future<AuthResult> deleteAccount(String password) async {
    final user = _auth.currentUser;
    if (user == null) return AuthResult.fail('Not logged in.');
    try {
      final cred = EmailAuthProvider.credential(
          email: user.email!, password: password);
      await user.reauthenticateWithCredential(cred);
      await _purgeUserData(user.uid);
      await user.delete();
      return AuthResult.ok();
    } on FirebaseAuthException catch (e) {
      return AuthResult.fail(_mapError(e.code));
    } catch (_) {
      return AuthResult.fail('Failed to delete account.');
    }
  }

  static Future<void> _purgeUserData(String uid) async {
    final ref = _db.collection('users').doc(uid);
    for (final sub in [
      'calories', 'water', 'weight', 'measurements',
      'sleep', 'workouts', 'fasting', 'meal_plans',
      'custom_foods', 'micronutrients',
    ]) {
      final snap = await ref.collection(sub).get();
      for (final doc in snap.docs) {
        await doc.reference.delete();
      }
    }
    await ref.delete();
  }

  // ── Error mapping ──────────────────────────────────────────────────────────

  static String _mapError(String code) {
    const map = {
      'user-not-found':           'No account found with this email.',
      'wrong-password':           'Incorrect password. Please try again.',
      'email-already-in-use':     'An account with this email already exists.',
      'invalid-email':            'Please enter a valid email address.',
      'weak-password':            'Password must be at least 6 characters.',
      'user-disabled':            'This account has been disabled.',
      'too-many-requests':        'Too many attempts. Please try again later.',
      'network-request-failed':   'No internet. Please check your connection.',
      'invalid-credential':       'Invalid email or password.',
    };
    return map[code] ?? 'Authentication error ($code). Please try again.';
  }
}

// ── Result wrapper ─────────────────────────────────────────────────────────

class AuthResult {
  final bool success;
  final String? error;
  final User? user;

  const AuthResult._({required this.success, this.error, this.user});

  factory AuthResult.ok({User? user}) =>
      AuthResult._(success: true, user: user);

  factory AuthResult.fail(String msg) =>
      AuthResult._(success: false, error: msg);
}
