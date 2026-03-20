import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

// ──────────────────────────────────────────────────────────────
// WORKER USER
// Lightweight user model — holds the data we get from Firebase
// Auth REST API after a successful sign-in or sign-up.
// ──────────────────────────────────────────────────────────────
class WorkerUser {
  final String uid;
  final String email;
  final String? displayName;
  final String idToken;

  const WorkerUser({
    required this.uid,
    required this.email,
    this.displayName,
    required this.idToken,
  });
}

// ──────────────────────────────────────────────────────────────
// AUTH SERVICE (Worker App)
// Uses Firebase Auth REST API instead of the native Android SDK.
// This bypasses the "app-not-authorized" error that occurs when
// the Android package name (com.doer.doer_worker) doesn't match
// the registered appId in Firebase Console.
//
// Singleton — call AuthService().init() once in main() so that
// currentUser is available synchronously throughout the app.
//
// Methods:
//   init          : restore saved session from SharedPreferences
//   signUp        : create account with email + password
//   signIn        : login with email + password
//   signOut       : clear session
//   resetPassword : send password reset email
//   currentUser   : currently logged-in WorkerUser (null if not)
// ──────────────────────────────────────────────────────────────
class AuthService {
  // ── Singleton ──
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const _apiKey = 'AIzaSyDlYooo-DvtaSPSQVuPJ74YUj1HwcTG-nM';
  static const _base = 'https://identitytoolkit.googleapis.com/v1/accounts';

  final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));

  WorkerUser? _currentUser;

  WorkerUser? get currentUser => _currentUser;

  // ── Restore session from SharedPreferences on app start ──
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('w_uid');
    final email = prefs.getString('w_email');
    final token = prefs.getString('w_token');
    if (uid != null && email != null && token != null) {
      _currentUser = WorkerUser(
        uid: uid,
        email: email,
        displayName: prefs.getString('w_name'),
        idToken: token,
      );
    }
  }

  // ── Sign Up ──
  Future<WorkerUser?> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final resp = await _dio.post(
        '$_base:signUp?key=$_apiKey',
        data: {
          'email': email,
          'password': password,
          'returnSecureToken': true,
        },
      );

      final uid = resp.data['localId'] as String;
      final idToken = resp.data['idToken'] as String;
      final refreshToken = resp.data['refreshToken'] as String;

      // Set display name
      await _dio.post(
        '$_base:update?key=$_apiKey',
        data: {
          'idToken': idToken,
          'displayName': name,
          'returnSecureToken': true,
        },
      );

      _currentUser = WorkerUser(
          uid: uid, email: email, displayName: name, idToken: idToken);
      await _saveSession(uid, email, name, idToken, refreshToken);

      // Register with backend
      try {
        await ApiService().register(
          firebaseToken: idToken,
          firebaseUid: uid,
          email: email,
          name: name,
        );
      } catch (_) {
        // Backend registration can fail if user already exists — that's OK
      }

      return _currentUser;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  // ── Sign In ──
  Future<WorkerUser?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final resp = await _dio.post(
        '$_base:signInWithPassword?key=$_apiKey',
        data: {
          'email': email,
          'password': password,
          'returnSecureToken': true,
        },
      );

      final uid = resp.data['localId'] as String;
      final idToken = resp.data['idToken'] as String;
      final refreshToken = resp.data['refreshToken'] as String;
      final displayName = resp.data['displayName'] as String?;

      _currentUser = WorkerUser(
          uid: uid, email: email, displayName: displayName, idToken: idToken);
      await _saveSession(uid, email, displayName, idToken, refreshToken);

      // Login with backend to get JWT. If not registered, register first.
      try {
        try {
          await ApiService().login(firebaseToken: idToken, firebaseUid: uid);
        } catch (_) {
          await ApiService().register(
            firebaseToken: idToken,
            firebaseUid: uid,
            email: email,
            name: displayName ?? email.split('@').first,
          );
        }
      } catch (e) {
        print('Backend auth failed: $e');
      }

      return _currentUser;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  // ── Sign Out ──
  Future<void> signOut() async {
    _currentUser = null;
    await ApiService().logout();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('w_uid');
    await prefs.remove('w_email');
    await prefs.remove('w_name');
    await prefs.remove('w_token');
    await prefs.remove('w_refresh');
  }

  // ── Reset Password ──
  Future<void> resetPassword({required String email}) async {
    try {
      await _dio.post(
        '$_base:sendOobCode?key=$_apiKey',
        data: {
          'requestType': 'PASSWORD_RESET',
          'email': email,
        },
      );
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  // ── Persist session to SharedPreferences ──
  Future<void> _saveSession(
    String uid,
    String email,
    String? name,
    String token,
    String refresh,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('w_uid', uid);
    await prefs.setString('w_email', email);
    if (name != null) await prefs.setString('w_name', name);
    await prefs.setString('w_token', token);
    await prefs.setString('w_refresh', refresh);
  }

  // ── Map Firebase REST error codes to user-friendly messages ──
  String _mapError(DioException e) {
    final msg =
        ((e.response?.data?['error']?['message'] as String?) ?? '').toUpperCase();

    if (msg.contains('EMAIL_EXISTS')) {
      return 'This email is already registered. Try signing in.';
    }
    if (msg.contains('INVALID_EMAIL')) {
      return 'Please enter a valid email address.';
    }
    if (msg.contains('WEAK_PASSWORD')) {
      return 'Password is too weak. Use at least 6 characters.';
    }
    if (msg.contains('EMAIL_NOT_FOUND') ||
        msg.contains('INVALID_LOGIN_CREDENTIALS') ||
        msg.contains('INVALID_PASSWORD')) {
      return 'Incorrect email or password.';
    }
    if (msg.contains('USER_DISABLED')) {
      return 'This account has been disabled.';
    }
    if (msg.contains('TOO_MANY_ATTEMPTS')) {
      return 'Too many attempts. Please try again later.';
    }
    if (msg.contains('OPERATION_NOT_ALLOWED')) {
      return 'Email sign-in is not enabled. Contact support.';
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Connection timed out. Check your internet connection.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'No internet connection. Please try again.';
    }
    return 'Something went wrong. Please try again.';
  }
}
