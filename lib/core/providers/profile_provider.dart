import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class ProfileProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  bool _isLoading = false;
  String? _error;

  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Load user profile
  Future<bool> loadProfile() async {
    _setLoading(true);
    _setError(null);

    try {
      _user = await _authService.getProfile();
      debugPrint('👤 PROFILE_LOADED: ${_user?.name}');
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to load profile: $e');
      _setLoading(false);
      return false;
    }
  }

  // Update profile
  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? city,
    String? profilePicture,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      _user = await _authService.updateProfile(
        name: name,
        phone: phone,
        city: city,
        profilePicture: profilePicture,
      );
      debugPrint('✅ PROFILE_UPDATED: ${_user?.name}');
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update profile: $e');
      _setLoading(false);
      return false;
    }
  }

  // Update FCM token
  Future<bool> updateFcmToken(String fcmToken) async {
    try {
      await _authService.updateFcmToken(fcmToken);
      debugPrint('🔔 FCM_TOKEN_UPDATED');
      return true;
    } catch (e) {
      _setError('Failed to update FCM token: $e');
      return false;
    }
  }

  // Logout
  Future<bool> logout() async {
    _setLoading(true);
    _setError(null);

    try {
      // TODO: Implement logout
      // await _authService.logout();
      debugPrint('🚪 LOGGING_OUT');

      // Clear local data
      _user = null;

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to logout: $e');
      _setLoading(false);
      return false;
    }
  }
}
