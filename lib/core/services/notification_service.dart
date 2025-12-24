import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final AuthService _authService = AuthService();

  String? _fcmToken;
  bool _isInitialized = false;

  String? get fcmToken => _fcmToken;
  bool get isInitialized => _isInitialized;

  // Initialize notifications
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Request permission for iOS
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('User granted permission: ${settings.authorizationStatus}');

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Get FCM token
      await _getFCMToken();

      // Configure message handlers
      _configureMessageHandlers();

      _isInitialized = true;
      debugPrint('Notification service initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize notification service: $e');
    }
  }

  // Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  // Get FCM token
  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      debugPrint('FCM Token: $_fcmToken');

      if (_fcmToken != null) {
        // Send token to backend
        await _updateFCMTokenOnBackend(_fcmToken!);
      }
    } catch (e) {
      debugPrint('Failed to get FCM token: $e');
    }
  }

  // Update FCM token on backend
  Future<void> _updateFCMTokenOnBackend(String token) async {
    try {
      await _authService.updateFcmToken(token);
      debugPrint('FCM token updated on backend');
    } catch (e) {
      debugPrint('Failed to update FCM token on backend: $e');
    }
  }

  // Configure message handlers
  void _configureMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

    // Handle messages when app is opened from terminated state
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Handle token refresh
    _firebaseMessaging.onTokenRefresh.listen(_handleTokenRefresh);
  }

  // Handle foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Received foreground message: ${message.notification?.title}');

    // Show local notification
    await _showLocalNotification(message);
  }

  // Handle background messages (static function)
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    debugPrint('Received background message: ${message.notification?.title}');
    // Background message handling is done by the system
  }

  // Handle message opened app
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('Message opened app: ${message.notification?.title}');
    _navigateToMessageScreen(message);
  }

  // Handle token refresh
  void _handleTokenRefresh(String token) {
    debugPrint('FCM token refreshed: $token');
    _fcmToken = token;
    _updateFCMTokenOnBackend(token);
  }

  // Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'kandlink_channel',
      'KandLink Notifications',
      channelDescription: 'Notifications for KandLink app',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'KandLink',
      message.notification?.body ?? 'You have a new message',
      details,
      payload: _getNotificationPayload(message),
    );
  }

  // Handle notification tapped
  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      _navigateFromPayload(payload);
    }
  }

  // Navigate to message screen based on notification
  void _navigateToMessageScreen(RemoteMessage message) {
    final data = message.data;
    final type = data['type'];
    final chatId = data['chatId'];
    final groupId = data['groupId'];

    if (type == 'message' && chatId != null) {
      // Navigate to personal chat
      // This will be handled by the navigation service
      debugPrint('Navigate to chat: $chatId');
    } else if (type == 'group_message' && groupId != null) {
      // Navigate to group chat
      debugPrint('Navigate to group chat: $groupId');
    }
  }

  // Get notification payload
  String _getNotificationPayload(RemoteMessage message) {
    final data = message.data;
    return '${data['type']}:${data['chatId'] ?? data['groupId']}';
  }

  // Navigate from payload
  void _navigateFromPayload(String payload) {
    final parts = payload.split(':');
    if (parts.length == 2) {
      final type = parts[0];
      final id = parts[1];

      if (type == 'message') {
        debugPrint('Navigate to chat: $id');
      } else if (type == 'group_message') {
        debugPrint('Navigate to group chat: $id');
      }
    }
  }

  // Subscribe to topic (for area-specific notifications)
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Failed to subscribe to topic: $e');
    }
  }

  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Failed to unsubscribe from topic: $e');
    }
  }

  // Get initial message (when app is opened from terminated state)
  Future<RemoteMessage?> getInitialMessage() async {
    return await _firebaseMessaging.getInitialMessage();
  }

  // Refresh FCM token
  Future<void> refreshToken() async {
    await _getFCMToken();
  }

  // Cleanup
  void dispose() {
    // No specific cleanup needed for FCM
    _isInitialized = false;
  }
}
