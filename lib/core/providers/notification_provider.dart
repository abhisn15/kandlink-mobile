import 'package:flutter/foundation.dart';
import '../services/notification_service.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();

  bool _isInitialized = false;
  bool _isLoading = false;
  String? _error;
  String? _fcmToken;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get fcmToken => _fcmToken;

  // Initialize notifications
  Future<bool> initializeNotifications() async {
    if (_isInitialized) return true;

    _setLoading(true);
    _setError(null);

    try {
      await _notificationService.initialize();
      _isInitialized = true;
      _fcmToken = _notificationService.fcmToken;
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Subscribe to area topic
  Future<bool> subscribeToArea(String areaId) async {
    try {
      await _notificationService.subscribeToTopic('area_$areaId');
      debugPrint('Subscribed to area notifications: $areaId');
      return true;
    } catch (e) {
      _setError(e.toString());
      notifyListeners();
      return false;
    }
  }

  // Unsubscribe from area topic
  Future<bool> unsubscribeFromArea(String areaId) async {
    try {
      await _notificationService.unsubscribeFromTopic('area_$areaId');
      debugPrint('Unsubscribed from area notifications: $areaId');
      return true;
    } catch (e) {
      _setError(e.toString());
      notifyListeners();
      return false;
    }
  }

  // Subscribe to user-specific notifications
  Future<bool> subscribeToUserNotifications(String userId) async {
    try {
      await _notificationService.subscribeToTopic('user_$userId');
      debugPrint('Subscribed to user notifications: $userId');
      return true;
    } catch (e) {
      _setError(e.toString());
      notifyListeners();
      return false;
    }
  }

  // Refresh FCM token
  Future<bool> refreshFCMToken() async {
    _setLoading(true);
    _setError(null);

    try {
      await _notificationService.refreshToken();
      _fcmToken = _notificationService.fcmToken;
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Handle app opened from notification
  Future<void> handleInitialMessage() async {
    final initialMessage = await _notificationService.getInitialMessage();
    if (initialMessage != null) {
      // Handle the initial message (navigate to appropriate screen)
      debugPrint('Handling initial message: ${initialMessage.notification?.title}');
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Utility methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }
}
