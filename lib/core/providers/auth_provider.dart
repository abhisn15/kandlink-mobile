import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/area.dart';
import '../services/auth_service.dart';
import 'notification_provider.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  bool _isLoading = false;
  String? _error;
  List<Area> _areas = [];

  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Area> get areas => _areas;
  bool get isAuthenticated => _user != null;
  bool get isEmailVerified => _user?.emailVerifiedAt != null;
  bool get isWhatsappVerified => _user?.whatsappVerifiedAt != null;

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

  // Register user
  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
    required String city,
    required String role,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _authService.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
        passwordConfirmation: passwordConfirmation,
        city: city,
        role: role,
      );

      if (response['success'] == true) {
        // Registration successful, user needs to verify email
        _setLoading(false);
        return true;
      } else {
        _setError(response['message'] ?? 'Registration failed');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Login user
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _authService.login(email, password);

      if (response['success'] == true) {
        final userData = response['data']['user'];
        _user = User.fromJson(userData);

        // Initialize notifications after successful login
        try {
          final notificationProvider = NotificationProvider();
          await notificationProvider.initializeNotifications();

          // Subscribe to user-specific notifications
          if (_user?.id != null) {
            await notificationProvider.subscribeToUserNotifications(_user!.id);
          }

          // Subscribe to area notifications if user has area
          if (_user?.areaId != null) {
            await notificationProvider.subscribeToArea(_user!.areaId!);
          }
        } catch (e) {
          debugPrint('Failed to initialize notifications: $e');
        }

        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError(response['message'] ?? 'Login failed');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Logout user
  Future<bool> logout() async {
    _setLoading(true);

    try {
      await _authService.logout();
      _user = null;
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      // Even if API call fails, clear local user data
      _user = null;
      _setLoading(false);
      notifyListeners();
      return true;
    }
  }

  // Verify email
  Future<bool> verifyEmail(String token) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _authService.verifyEmail(token);

      if (response['success'] == true) {
        final userData = response['data'];
        _user = User.fromJson(userData);
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError(response['message'] ?? 'Email verification failed');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Verify WhatsApp
  Future<bool> verifyWhatsapp(String code) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _authService.verifyWhatsapp(code);

      if (response['success'] == true) {
        final userData = response['data'];
        _user = User.fromJson(userData);
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError(response['message'] ?? 'WhatsApp verification failed');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Resend verification
  Future<bool> resendVerification(String type) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _authService.resendVerification(type);

      if (response['success'] == true) {
        _setLoading(false);
        return true;
      } else {
        _setError(response['message'] ?? 'Resend verification failed');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError(e.toString());
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
      final updatedUser = await _authService.updateProfile(
        name: name,
        phone: phone,
        city: city,
        profilePicture: profilePicture,
      );

      _user = updatedUser;
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Update FCM token
  Future<void> updateFcmToken(String fcmToken) async {
    try {
      await _authService.updateFcmToken(fcmToken);
    } catch (e) {
      // Silently fail for FCM token updates
      debugPrint('Failed to update FCM token: $e');
    }
  }

  // Load user profile (for app startup)
  Future<bool> loadProfile() async {
    _setLoading(true);
    _setError(null);

    try {
      final user = await _authService.getProfile();
      _user = user;
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Load areas
  Future<bool> loadAreas() async {
    _setLoading(true);
    _setError(null);

    try {
      final areas = await _authService.getAreas();
      _areas = areas;
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Check authentication status
  Future<bool> checkAuthStatus() async {
    final isAuth = await _authService.isAuthenticated();
    if (isAuth) {
      return await loadProfile();
    }
    return false;
  }
}
