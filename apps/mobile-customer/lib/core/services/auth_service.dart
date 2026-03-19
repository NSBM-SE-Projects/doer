import 'package:firebase_auth/firebase_auth.dart';

// ──────────────────────────────────────────────────────────────
// AUTH SERVICE
// Wraps Firebase Auth into simple methods our screens can call.
// Methods:
//   - signUp: create account with email + password
//   - signIn: login with email + password
//   - signOut: logout
//   - resetPassword: send reset email
//   - currentUser: get logged in user (null if not logged in)
//   - authStateChanges: stream that fires when login state changes
// ──────────────────────────────────────────────────────────────
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current logged in user (null if not logged in)
  User? get currentUser => _auth.currentUser;

  // Stream that emits whenever auth state changes (login/logout)
  // Used in splash screen to decide: go to home or go to login
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Sign Up with email & password ──
  // Returns the User on success, throws error message on failure
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

      // Set the display name after creating the account
      await credential.user?.updateDisplayName(name);
      await credential.user?.reload();

      return _auth.currentUser;
    } on FirebaseAuthException catch (e) {
      throw _getErrorMessage(e.code);
    }
  }

  // ── Sign In with email & password ──
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
      throw _getErrorMessage(e.code);
    }
  }

  // ── Sign Out ──
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ── Reset Password ──
  // Sends a password reset email to the given address
  Future<void> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _getErrorMessage(e.code);
    }
  }

  // ── Convert Firebase error codes to user-friendly messages ──
  String _getErrorMessage(String code) {
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
