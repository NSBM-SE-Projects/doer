import 'package:firebase_auth/firebase_auth.dart';

// ──────────────────────────────────────────────────────────────
// AUTH SERVICE (Worker App)
// Wraps Firebase Auth into simple methods for worker screens.
// Methods:
//   - signUp    : create worker account with email + password
//   - signIn    : login with email + password
//   - signOut   : logout
//   - resetPassword : send reset email
//   - currentUser   : currently logged-in Firebase user (null if not)
//   - authStateChanges : stream that fires on login/logout changes
// ──────────────────────────────────────────────────────────────
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Currently logged-in user — null if not signed in
  User? get currentUser => _auth.currentUser;

  // Stream used in splash screen to route → home or → onboarding
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Sign Up ──
  // Creates a Firebase account, sets the display name, returns the User.
  Future<User?> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await credential.user?.updateDisplayName(name);
      await credential.user?.reload();
      return _auth.currentUser;
    } on FirebaseAuthException catch (e) {
      throw _friendlyError(e.code);
    }
  }

  // ── Sign In ──
  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw _friendlyError(e.code);
    }
  }

  // ── Sign Out ──
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ── Reset Password ──
  Future<void> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _friendlyError(e.code);
    }
  }

  // ── Map Firebase error codes → readable messages ──
  String _friendlyError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered. Try signing in.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
