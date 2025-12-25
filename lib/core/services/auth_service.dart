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
    final data = {
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'password_confirmation': passwordConfirmation,
      'city': city,
      'role': role,
    };

    final response = await _apiService.post(ApiEndpoints.register, data: data);
    return response.data;
  }

  // Login user
  Future<Map<String, dynamic>> login(String email, String password) async {
    final data = {
      'email': email,
      'password': password,
    };

    final response = await _apiService.post(ApiEndpoints.login, data: data);
    final responseData = response.data;

    // Store tokens if login successful
    if (responseData['success'] == true && responseData['data'] != null) {
      final tokens = responseData['data']['tokens'];
      if (tokens != null) {
        await _apiService.setTokens(tokens['accessToken'], tokens['refreshToken']);
      }
    }

    // Handle specific error cases
    if (responseData['success'] == false && responseData['message'] != null) {
      final message = responseData['message']?.toString().toLowerCase();
      if (message?.contains('email_not_verified') == true || message?.contains('email not verified') == true) {
        return {
          'success': false,
          'message': 'EMAIL_NOT_VERIFIED',
          'data': responseData['data'],
        };
      }
    }

    return responseData;
  }

  // Refresh token
  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    final data = {'refreshToken': refreshToken};
    final response = await _apiService.post(ApiEndpoints.refreshToken, data: data);
    final responseData = response.data;

    // Update stored tokens if refresh successful
    if (responseData['success'] == true && responseData['data'] != null) {
      final tokens = responseData['data']['tokens'];
      if (tokens != null) {
        await _apiService.setTokens(tokens['accessToken'], tokens['refreshToken']);
      }
    }

    return responseData;
  }

  // Logout user
  Future<Map<String, dynamic>> logout() async {
    try {
      final response = await _apiService.post(ApiEndpoints.logout);
      await _apiService.clearTokens(); // Clear stored tokens regardless of API response
      return response.data;
    } catch (e) {
      // Even if API call fails, clear local tokens
      await _apiService.clearTokens();
      rethrow;
    }
  }

  // Verify email
  Future<Map<String, dynamic>> verifyEmail(String token) async {
    final data = {'token': token};
    final response = await _apiService.post(ApiEndpoints.verifyEmail, data: data);
    return response.data;
  }

  // Verify WhatsApp
  Future<Map<String, dynamic>> verifyWhatsapp(String code) async {
    final data = {'code': code};
    final response = await _apiService.post(ApiEndpoints.verifyWhatsapp, data: data);
    return response.data;
  }

  // Resend verification
  Future<Map<String, dynamic>> resendVerification(String type) async {
    final data = {'type': type};
    final response = await _apiService.post(ApiEndpoints.resendVerification, data: data);
    return response.data;
  }

  // Get user profile
  Future<User> getProfile() async {
    final response = await _apiService.get(ApiEndpoints.getProfile);
    return User.fromJson(response.data['data']);
  }

  // Update user profile
  Future<User> updateProfile({
    String? name,
    String? phone,
    String? city,
    String? profilePicture,
    String? areaId,
  }) async {
    final data = {};
    if (name != null) data['name'] = name;
    if (phone != null) data['phone'] = phone;
    if (city != null) data['city'] = city;
    if (profilePicture != null) data['profile_picture'] = profilePicture;
    if (areaId != null) {
      data['area_id'] = areaId;
      // Add dummy field to ensure request is not considered empty
      data['_updated_at'] = DateTime.now().toIso8601String();
    }

    // Use assign endpoint for area-only updates
    final isAreaOnlyUpdate = areaId != null && name == null && phone == null && city == null && profilePicture == null;
    if (isAreaOnlyUpdate) {
      return await assignArea(areaId!);
    }

    // Try PATCH method for mixed updates that include area
    final response = await _apiService.put(ApiEndpoints.updateProfile, data: data);
    return User.fromJson(response.data['data']);
  }

  // Assign area using dedicated endpoint
  Future<User> assignArea(String areaId) async {
    final data = {'areaId': areaId};
    final response = await _apiService.post('/assign', data: data);

    // After successful assignment, get updated user profile
    // since assign endpoint doesn't return user object
    if (response.data['success'] == true) {
      return await getProfile();
    } else {
      throw Exception(response.data['message'] ?? 'Area assignment failed');
    }
  }

  // Update FCM token
  Future<void> updateFcmToken(String fcmToken) async {
    final data = {'fcmToken': fcmToken};
    await _apiService.post(ApiEndpoints.updateFcmToken, data: data);
  }

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    return await _apiService.isAuthenticated();
  }

  // Get all areas
  Future<List<Area>> getAreas() async {
    final response = await _apiService.get(ApiEndpoints.getAreas);

    // Debug: Log response structure
    print('🔍 AREAS API Response type: ${response.data.runtimeType}');
    print('🔍 AREAS API Response: ${response.data}');

    // Handle different response formats
    dynamic areasData;
    if (response.data is List) {
      // Direct array response: [{id: ..., name: ...}, ...]
      print('✅ AREAS: Direct List response detected');
      areasData = response.data;
    } else if (response.data is Map && response.data['data'] is List) {
      // Nested response: {data: [{id: ..., name: ...}, ...]}
      print('✅ AREAS: Nested Map response detected');
      areasData = response.data['data'];
    } else if (response.data is Map && response.data['data'] is Map && response.data['data']['data'] is List) {
      // Double nested: {data: {data: [...]}}
      print('✅ AREAS: Double nested response detected');
      areasData = response.data['data']['data'];
    } else {
      print('❌ AREAS: Unexpected response format: ${response.data.runtimeType}');
      throw Exception('Unexpected areas response format: ${response.data.runtimeType}');
    }

    if (areasData is! List) {
      print('❌ AREAS: areasData is not List: ${areasData.runtimeType}');
      throw Exception('Areas data is not a List');
    }

    print('✅ AREAS: Processing ${areasData.length} areas');
    try {
      final areas = (areasData as List).map((area) {
        print('🔍 Processing area: $area');
        return Area.fromJson(area as Map<String, dynamic>);
      }).toList();
      print('✅ AREAS: Successfully parsed ${areas.length} areas');
      return areas;
    } catch (e, stackTrace) {
      print('❌ AREAS: Error parsing areas: $e');
      print('❌ AREAS: Stack trace: $stackTrace');
      rethrow;
    }
  }
}
