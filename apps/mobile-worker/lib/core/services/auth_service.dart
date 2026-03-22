import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'api_service.dart';
import 'socket_service.dart';
import 'notification_service.dart';

class WorkerUser {
  final String email;
  final String? displayName;

  const WorkerUser({required this.email, this.displayName});
}

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  WorkerUser? _currentUser;
  WorkerUser? get currentUser => _currentUser;

  final _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('w_email');
    if (email != null) {
      _currentUser = WorkerUser(
        email: email,
        displayName: prefs.getString('w_name'),
      );
    }
  }

  Future<WorkerUser?> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      await ApiService().register(
        email: email,
        password: password,
        name: name,
      );
      _currentUser = WorkerUser(email: email, displayName: name);
      await _saveSession(email, name);
      await _connectServices();
      return _currentUser;
    } catch (e) {
      throw ApiService.errorMessage(e);
    }
  }

  Future<WorkerUser?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final resp = await ApiService().login(
        email: email,
        password: password,
      );
      final user = resp['user'];
      final name = user?['name'] ?? email.split('@').first;
      _currentUser = WorkerUser(email: email, displayName: name);
      await _saveSession(email, name);
      await _connectServices();
      return _currentUser;
    } catch (e) {
      throw ApiService.errorMessage(e);
    }
  }

  Future<WorkerUser?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw 'Google sign-in cancelled';

      final email = googleUser.email;
      final name = googleUser.displayName ?? email.split('@').first;

      await ApiService().googleAuth(
        email: email,
        name: name,
        googleId: googleUser.id,
      );

      _currentUser = WorkerUser(email: email, displayName: name);
      await _saveSession(email, name);
      await _connectServices();
      return _currentUser;
    } catch (e) {
      if (e is String) throw e;
      throw ApiService.errorMessage(e);
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await ApiService().changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
    } catch (e) {
      throw ApiService.errorMessage(e);
    }
  }

  Future<void> signOut() async {
    _currentUser = null;
    await ApiService().logout();
    SocketService().disconnect();
    try { await _googleSignIn.signOut(); } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('w_email');
    await prefs.remove('w_name');
  }

  Future<void> resetPassword({required String email}) async {
    try {
      await ApiService().resetPassword(email);
    } catch (e) {
      throw ApiService.errorMessage(e);
    }
  }

  Future<void> _connectServices() async {
    await SocketService().connect();
    await NotificationService().init();
  }

  Future<void> _saveSession(String email, String? name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('w_email', email);
    if (name != null) await prefs.setString('w_name', name);
  }
}
