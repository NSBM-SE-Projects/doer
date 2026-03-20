import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthUser {
  final String email;
  final String? displayName;

  const AuthUser({required this.email, this.displayName});
}

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  AuthUser? _currentUser;
  AuthUser? get currentUser => _currentUser;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('c_email');
    if (email != null) {
      _currentUser = AuthUser(
        email: email,
        displayName: prefs.getString('c_name'),
      );
    }
  }

  Future<AuthUser?> signUp({
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
      _currentUser = AuthUser(email: email, displayName: name);
      await _saveSession(email, name);
      return _currentUser;
    } catch (e) {
      throw ApiService.errorMessage(e);
    }
  }

  Future<AuthUser?> signIn({
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
      _currentUser = AuthUser(email: email, displayName: name);
      await _saveSession(email, name);
      return _currentUser;
    } catch (e) {
      throw ApiService.errorMessage(e);
    }
  }

  Future<void> signOut() async {
    _currentUser = null;
    await ApiService().logout();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('c_email');
    await prefs.remove('c_name');
  }

  Future<void> resetPassword({required String email}) async {
    // Password reset requires backend endpoint (not yet implemented)
    throw 'Password reset is not available yet. Please contact support.';
  }

  Future<void> _saveSession(String email, String? name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('c_email', email);
    if (name != null) await prefs.setString('c_name', name);
  }
}
