import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized API client for all backend calls.
/// Automatically attaches JWT token to every request.
class ApiService {
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

  void setToken(String token) => _jwt = token;
  void clearToken() => _jwt = null;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _jwt = prefs.getString('c_backend_jwt');
  }

  Future<void> _saveJwt(String jwt) async {
    _jwt = jwt;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('c_backend_jwt', jwt);
  }

  Future<void> _clearJwt() async {
    _jwt = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('c_backend_jwt');
  }

  // ══ AUTH ══

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
      'phone': ?phone,
      'role': 'CUSTOMER',
    });
    await _saveJwt(resp.data['token']);
    return resp.data;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final resp = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    await _saveJwt(resp.data['token']);
    return resp.data;
  }

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
      'role': 'CUSTOMER',
    });
    await _saveJwt(resp.data['token']);
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

  Future<void> logout() async => await _clearJwt();

  // ══ PROFILE ══

  Future<Map<String, dynamic>> updateProfile({
    String? name, String? phone, String? avatarUrl,
  }) async {
    final resp = await _dio.put('/users/me', data: {
      'name': ?name,
      'phone': ?phone,
      'avatarUrl': ?avatarUrl,
    });
    return resp.data;
  }

  Future<Map<String, dynamic>> updateCustomerProfile({
    String? address, double? latitude, double? longitude,
  }) async {
    final resp = await _dio.put('/users/me/customer', data: {
      'address': ?address,
      'latitude': ?latitude,
      'longitude': ?longitude,
    });
    return resp.data;
  }

  // ══ CATEGORIES ══

  Future<List<dynamic>> getCategories() async {
    final resp = await _dio.get('/categories');
    return resp.data['categories'] as List;
  }

  Future<Map<String, dynamic>> getCategory(String id) async {
    final resp = await _dio.get('/categories/$id');
    return resp.data['category'];
  }

  // ══ WORKERS ══

  Future<List<dynamic>> getWorkers({String? categoryId, bool? available}) async {
    final resp = await _dio.get('/users/workers', queryParameters: {
      'categoryId': ?categoryId,
      if (available != null) 'available': available.toString(),
    });
    return resp.data['workers'] as List;
  }

  Future<Map<String, dynamic>> getWorker(String id) async {
    final resp = await _dio.get('/users/workers/$id');
    return resp.data['worker'];
  }

  // ══ UPLOAD ══

  Future<List<String>> uploadImages(List<String> base64Images, {String folder = 'doer/jobs'}) async {
    final resp = await _dio.post('/upload/multiple', data: {
      'images': base64Images,
      'folder': folder,
    });
    return List<String>.from(resp.data['urls']);
  }

  // ══ JOBS ══

  Future<Map<String, dynamic>> createJob({
    required String title,
    required String description,
    required String categoryId,
    double? price,
    double? budgetMin,
    double? budgetMax,
    String? urgency,
    double? latitude,
    double? longitude,
    String? address,
    String? scheduledAt,
    List<String>? imageUrls,
  }) async {
    final resp = await _dio.post('/jobs', data: {
      'title': title,
      'description': description,
      'categoryId': categoryId,
      if (price != null) 'price': price,
      if (budgetMin != null) 'budgetMin': budgetMin,
      if (budgetMax != null) 'budgetMax': budgetMax,
      if (urgency != null) 'urgency': urgency,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (address != null) 'address': address,
      if (imageUrls != null && imageUrls.isNotEmpty) 'imageUrls': imageUrls,
      if (scheduledAt != null) 'scheduledAt': scheduledAt,

    });
    return resp.data;
  }

  Future<Map<String, dynamic>> closeJob(String id) async {
    final resp = await _dio.patch('/jobs/$id/close');
    return resp.data;
  }

  Future<Map<String, dynamic>> getMyJobs({String? status}) async {
    final resp = await _dio.get('/jobs/my', queryParameters: {
      'status': ?status,
    });
    return resp.data;
  }

  Future<Map<String, dynamic>> getJob(String id) async {
    final resp = await _dio.get('/jobs/$id');
    return resp.data['job'];
  }

  Future<Map<String, dynamic>> cancelJob(String id) async {
    final resp = await _dio.patch('/jobs/$id/cancel');
    return resp.data;
  }

  Future<Map<String, dynamic>> reviewJob(String jobId, {
    required int rating, String? comment, List<String>? photoUrls,
  }) async {
    final resp = await _dio.post('/jobs/$jobId/review', data: {
      'rating': rating,
      if (comment != null) 'comment': comment,
      if (photoUrls != null && photoUrls.isNotEmpty) 'photoUrls': photoUrls,
    });
    return resp.data;
  }

  // ══ MESSAGES ══

  Future<List<dynamic>> getConversations() async {
    final resp = await _dio.get('/messages');
    return resp.data['conversations'] as List;
  }

  Future<List<dynamic>> getMessages(String jobId) async {
    final resp = await _dio.get('/messages/$jobId');
    return resp.data['messages'] as List;
  }

  Future<Map<String, dynamic>> sendMessage(String jobId, String content) async {
    final resp = await _dio.post('/messages/$jobId', data: {'content': content});
    return resp.data['message'];
  }

  // ══ NOTIFICATIONS ══

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

  // ══ PAYMENTS ══

  Future<Map<String, dynamic>> createPayment(String jobId) async {
    final resp = await _dio.post('/payments/$jobId');
    return resp.data;
  }

  Future<Map<String, dynamic>> releasePayment(String jobId) async {
    final resp = await _dio.post('/payments/$jobId/release');
    return resp.data;
  }

  Future<Map<String, dynamic>> raiseDispute(String jobId, {
    required String reason,
    required String description,
    List<String>? evidence,
  }) async {
    final resp = await _dio.post('/payments/$jobId/dispute', data: {
      'reason': reason,
      'description': description,
      if (evidence != null) 'evidence': evidence,
    });
    return resp.data;
  }

  Future<List<dynamic>> getMyPayments() async {
    final resp = await _dio.get('/payments');
    return resp.data['payments'] as List;
  }

  // ══ APPLICATIONS ══

  Future<List<dynamic>> getJobApplications(String jobId) async {
    final resp = await _dio.get('/applications/job/$jobId');
    return resp.data['applications'] as List;
  }

  Future<Map<String, dynamic>> acceptApplication(String applicationId) async {
    final resp = await _dio.patch('/applications/$applicationId/accept');
    return resp.data;
  }

  Future<Map<String, dynamic>> rejectApplication(String applicationId) async {
    final resp = await _dio.patch('/applications/$applicationId/reject');
    return resp.data;
  }

  // ══ MAPS ══

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

  // ══ AGORA ══

  Future<Map<String, dynamic>> getAgoraToken(String channelName) async {
    final resp = await _dio.get('/agora/token', queryParameters: {'channelName': channelName});
    return resp.data;
  }

  // ══ HELPERS ══

  static String errorMessage(dynamic error) {
    if (error is DioException) {
      if (error.response?.data is Map) {
        final msg = error.response?.data['error'];
        if (msg is String) return msg;
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return 'Connection timed out.';
      }
      if (error.type == DioExceptionType.connectionError) {
        return 'No internet connection.';
      }
    }
    return error.toString();
  }
}
