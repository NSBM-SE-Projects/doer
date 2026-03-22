import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized API client for all backend calls.
/// Automatically attaches JWT token to every request.
class ApiService {
  // ── Singleton ──
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (_jwt != null) {
          options.headers['Authorization'] = 'Bearer $_jwt';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // Only clear JWT on 401 for non-auth endpoints (auth endpoints
        // return 401 for invalid Firebase tokens, not expired JWTs)
        if (error.response?.statusCode == 401) {
          final path = error.requestOptions.path;
          if (!path.contains('/auth/')) {
            await _clearJwt();
          }
        }
        handler.next(error);
      },
    ));
  }

  static const _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000/api',
  );
  late final Dio _dio;
  String? _jwt;

  /// Call after login/register to store the JWT
  void setToken(String token) => _jwt = token;

  /// Call on logout
  void clearToken() => _jwt = null;

  /// Restore JWT from SharedPreferences
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _jwt = prefs.getString('w_backend_jwt');
  }

  /// Persist JWT to SharedPreferences
  Future<void> _saveJwt(String jwt) async {
    _jwt = jwt;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('w_backend_jwt', jwt);
  }

  /// Clear stored JWT
  Future<void> _clearJwt() async {
    _jwt = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('w_backend_jwt');
  }

  // ════════════════════════════════════════════════════════════
  // AUTH
  // ════════════════════════════════════════════════════════════

  /// Register with backend
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    final resp = await _dio.post('/auth/register', data: {
      'email': email,
      'password': password,
      'name': name,
      if (phone != null) 'phone': phone,
      'role': 'WORKER',
    });
    final jwt = resp.data['token'] as String;
    await _saveJwt(jwt);
    return resp.data;
  }

  /// Login with backend
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final resp = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    final jwt = resp.data['token'] as String;
    await _saveJwt(jwt);
    return resp.data;
  }

  /// Get current user profile
  Future<Map<String, dynamic>> getMe() async {
    final resp = await _dio.get('/users/me');
    return resp.data;
  }

  Future<Map<String, dynamic>> googleAuth({
    required String email,
    required String name,
    required String googleId,
  }) async {
    final resp = await _dio.post('/auth/google', data: {
      'email': email,
      'name': name,
      'googleId': googleId,
      'role': 'WORKER',
    });
    final jwt = resp.data['token'] as String;
    await _saveJwt(jwt);
    return resp.data;
  }

  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final resp = await _dio.put('/auth/change-password', data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
    return resp.data;
  }

  Future<Map<String, dynamic>> resetPassword(String email) async {
    final resp = await _dio.post('/auth/reset-password', data: {'email': email});
    return resp.data;
  }

  Future<void> deleteAccount() async {
    await _dio.delete('/auth/account');
    await _clearJwt();
  }

  /// Logout — clear JWT
  Future<void> logout() async {
    await _clearJwt();
  }

  // ════════════════════════════════════════════════════════════
  // PROFILE
  // ════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? phone,
    String? avatarUrl,
  }) async {
    final resp = await _dio.put('/users/me', data: {
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
    });
    return resp.data;
  }

  Future<Map<String, dynamic>> updateWorkerProfile({
    String? bio,
    bool? isAvailable,
    double? latitude,
    double? longitude,
    String? nicNumber,
    List<String>? categoryIds,
  }) async {
    final resp = await _dio.put('/users/me/worker', data: {
      if (bio != null) 'bio': bio,
      if (isAvailable != null) 'isAvailable': isAvailable,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (nicNumber != null) 'nicNumber': nicNumber,
      if (categoryIds != null) 'categoryIds': categoryIds,
    });
    return resp.data;
  }

  // ════════════════════════════════════════════════════════════
  // CATEGORIES
  // ════════════════════════════════════════════════════════════

  Future<List<dynamic>> getCategories() async {
    final resp = await _dio.get('/categories');
    return resp.data['categories'] as List;
  }

  // ════════════════════════════════════════════════════════════
  // JOBS
  // ════════════════════════════════════════════════════════════

  Future<List<dynamic>> getAvailableJobs({String? categoryId}) async {
    final resp = await _dio.get('/jobs/available', queryParameters: {
      if (categoryId != null) 'categoryId': categoryId,
    });
    return resp.data['jobs'] as List;
  }

  Future<Map<String, dynamic>> getMyJobs({String? status}) async {
    final resp = await _dio.get('/jobs/my', queryParameters: {
      if (status != null) 'status': status,
    });
    return resp.data;
  }

  Future<Map<String, dynamic>> getJob(String jobId) async {
    final resp = await _dio.get('/jobs/$jobId');
    return resp.data['job'];
  }

  Future<Map<String, dynamic>> assignJob(String jobId) async {
    final resp = await _dio.patch('/jobs/$jobId/assign');
    return resp.data;
  }

  Future<Map<String, dynamic>> startJob(String jobId) async {
    final resp = await _dio.patch('/jobs/$jobId/start');
    return resp.data;
  }

  Future<Map<String, dynamic>> completeJob(String jobId) async {
    final resp = await _dio.patch('/jobs/$jobId/complete');
    return resp.data;
  }

  Future<Map<String, dynamic>> cancelJob(String jobId) async {
    final resp = await _dio.patch('/jobs/$jobId/cancel');
    return resp.data;
  }

  // ════════════════════════════════════════════════════════════
  // MESSAGES
  // ════════════════════════════════════════════════════════════

  Future<List<dynamic>> getConversations() async {
    final resp = await _dio.get('/messages');
    return resp.data['conversations'] as List;
  }

  Future<List<dynamic>> getMessages(String jobId) async {
    final resp = await _dio.get('/messages/$jobId');
    return resp.data['messages'] as List;
  }

  Future<Map<String, dynamic>> sendMessage(String jobId, String content) async {
    final resp = await _dio.post('/messages/$jobId', data: {
      'content': content,
    });
    return resp.data['message'];
  }

  // ════════════════════════════════════════════════════════════
  // NOTIFICATIONS
  // ════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> getNotifications() async {
    final resp = await _dio.get('/notifications');
    return resp.data;
  }

  Future<void> markNotificationRead(String id) async {
    await _dio.patch('/notifications/$id/read');
  }

  Future<void> markAllNotificationsRead() async {
    await _dio.patch('/notifications/read-all');
  }

  Future<void> registerFcmToken(String token) async {
    await _dio.post('/notifications/register-token', data: {'fcmToken': token});
  }

  // ════════════════════════════════════════════════════════════
  // PAYMENTS
  // ════════════════════════════════════════════════════════════

  Future<List<dynamic>> getMyPayments() async {
    final resp = await _dio.get('/payments');
    return resp.data['payments'] as List;
  }

  // ════════════════════════════════════════════════════════════
  // APPLICATIONS
  // ════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> applyToJob(String jobId, {String? message, double? price}) async {
    final resp = await _dio.post('/applications/$jobId', data: {
      if (message != null) 'message': message,
      if (price != null) 'price': price,
    });
    return resp.data;
  }

  Future<List<dynamic>> getMyApplications() async {
    final resp = await _dio.get('/applications/my');
    return resp.data['applications'] as List;
  }

  Future<Map<String, dynamic>> withdrawApplication(String id) async {
    final resp = await _dio.delete('/applications/$id/withdraw');
    return resp.data;
  }

  // ════════════════════════════════════════════════════════════
  // MAPS
  // ════════════════════════════════════════════════════════════

  Future<List<dynamic>> placesAutocomplete(String input) async {
    final resp = await _dio.get('/maps/autocomplete', queryParameters: {'input': input});
    return resp.data['predictions'] as List;
  }

  Future<Map<String, dynamic>> getPlaceDetails(String placeId) async {
    final resp = await _dio.get('/maps/place-details', queryParameters: {'placeId': placeId});
    return resp.data;
  }

  Future<Map<String, dynamic>> getDistance(double oLat, double oLng, double dLat, double dLng) async {
    final resp = await _dio.get('/maps/distance', queryParameters: {
      'originLat': oLat, 'originLng': oLng, 'destLat': dLat, 'destLng': dLng,
    });
    return resp.data;
  }

  Future<Map<String, dynamic>> reverseGeocode(double lat, double lng) async {
    final resp = await _dio.get('/maps/reverse-geocode', queryParameters: {'lat': lat, 'lng': lng});
    return resp.data;
  }

  // ════════════════════════════════════════════════════════════
  // AGORA
  // ════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> getAgoraToken(String channelName) async {
    final resp = await _dio.get('/agora/token', queryParameters: {'channelName': channelName});
    return resp.data;
  }

  // ════════════════════════════════════════════════════════════
  // HELPERS
  // ════════════════════════════════════════════════════════════

  /// Extract user-friendly error message from DioException
  static String errorMessage(dynamic error) {
    if (error is DioException) {
      if (error.response?.data is Map) {
        final msg = error.response?.data['error'];
        if (msg is String) return msg;
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return 'Connection timed out. Check your internet.';
      }
      if (error.type == DioExceptionType.connectionError) {
        return 'No internet connection.';
      }
    }
    return error.toString();
  }
}
