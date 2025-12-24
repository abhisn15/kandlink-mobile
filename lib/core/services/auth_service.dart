import '../models/user.dart';
import '../models/area.dart';
import 'api_service.dart';
import '../constants/api_endpoints.dart';

class AuthService {
  final ApiService _apiService = ApiService();

  // Register new user
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
    required String city,
    required String role,
  }) async {
    final body = {
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'password_confirmation': passwordConfirmation,
      'city': city,
      'role': role,
    };

    final response = await _apiService.post(ApiEndpoints.register, body: body);
    return response;
  }

  // Login user
  Future<Map<String, dynamic>> login(String email, String password) async {
    final body = {
      'email': email,
      'password': password,
    };

    final response = await _apiService.post(ApiEndpoints.login, body: body);

    // Store tokens if login successful
    if (response['success'] == true && response['data'] != null) {
      final tokens = response['data']['tokens'];
      if (tokens != null) {
        await _apiService.setTokens(tokens['accessToken'], tokens['refreshToken']);
      }
    }

    return response;
  }

  // Refresh token
  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    final body = {'refreshToken': refreshToken};
    final response = await _apiService.post(ApiEndpoints.refreshToken, body: body);

    // Update stored tokens if refresh successful
    if (response['success'] == true && response['data'] != null) {
      final tokens = response['data']['tokens'];
      if (tokens != null) {
        await _apiService.setTokens(tokens['accessToken'], tokens['refreshToken']);
      }
    }

    return response;
  }

  // Logout user
  Future<Map<String, dynamic>> logout() async {
    try {
      final response = await _apiService.post(ApiEndpoints.logout);
      await _apiService.clearTokens(); // Clear stored tokens regardless of API response
      return response;
    } catch (e) {
      // Even if API call fails, clear local tokens
      await _apiService.clearTokens();
      rethrow;
    }
  }

  // Verify email
  Future<Map<String, dynamic>> verifyEmail(String token) async {
    final body = {'token': token};
    return await _apiService.post(ApiEndpoints.verifyEmail, body: body);
  }

  // Verify WhatsApp
  Future<Map<String, dynamic>> verifyWhatsapp(String code) async {
    final body = {'code': code};
    return await _apiService.post(ApiEndpoints.verifyWhatsapp, body: body);
  }

  // Resend verification
  Future<Map<String, dynamic>> resendVerification(String type) async {
    final body = {'type': type};
    return await _apiService.post(ApiEndpoints.resendVerification, body: body);
  }

  // Get user profile
  Future<User> getProfile() async {
    final response = await _apiService.get(ApiEndpoints.getProfile);
    return User.fromJson(response['data']);
  }

  // Update user profile
  Future<User> updateProfile({
    String? name,
    String? phone,
    String? city,
    String? profilePicture,
  }) async {
    final body = {};
    if (name != null) body['name'] = name;
    if (phone != null) body['phone'] = phone;
    if (city != null) body['city'] = city;
    if (profilePicture != null) body['profile_picture'] = profilePicture;

    final response = await _apiService.put(ApiEndpoints.updateProfile, body: body);
    return User.fromJson(response['data']);
  }

  // Update FCM token
  Future<void> updateFcmToken(String fcmToken) async {
    final body = {'fcmToken': fcmToken};
    await _apiService.post(ApiEndpoints.updateFcmToken, body: body);
  }

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    return await _apiService.isAuthenticated();
  }

  // Get all areas
  Future<List<Area>> getAreas() async {
    final response = await _apiService.get(ApiEndpoints.getAreas);
    return (response['data'] as List).map((area) => Area.fromJson(area)).toList();
  }
}
