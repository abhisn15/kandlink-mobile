import 'package:flutter/foundation.dart';

class Config {
  // API Configuration
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5000/api',
  );

  static const String socketUrl = String.fromEnvironment(
    'SOCKET_URL',
    defaultValue: 'http://localhost:5000',
  );

  // Environment
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  // App Configuration
  static const String appName = 'KandLink';
  static const String appVersion = '1.0.0';

  // Logging
  static const String logLevel = String.fromEnvironment(
    'LOG_LEVEL',
    defaultValue: 'debug',
  );

  // File Upload
  static const int maxFileSize = 10485760; // 10MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
  static const List<String> allowedFileTypes = ['pdf', 'doc', 'docx', 'txt'];

  // Debug mode
  static bool get isDebug => kDebugMode;
  static bool get isRelease => kReleaseMode;
  static bool get isDevelopment => environment == 'development';
  static bool get isStaging => environment == 'staging';
  static bool get isProduction => environment == 'production';

  // Feature flags
  static const bool enableOfflineMode = true;
  static const bool enablePushNotifications = true;
  static const bool enableFileSharing = true;
  static const bool enableGroupChat = true;

  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration socketReconnectDelay = Duration(seconds: 5);
  static const int socketMaxReconnectAttempts = 5;

  // Cache configuration
  static const Duration cacheExpiration = Duration(hours: 24);
  static const int maxCacheSize = 100 * 1024 * 1024; // 100MB

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
}
