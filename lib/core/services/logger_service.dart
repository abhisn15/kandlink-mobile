import 'package:logger/logger.dart';
import '../config/config.dart';

class LoggerService {
  static final LoggerService _instance = LoggerService._internal();
  factory LoggerService() => _instance;

  late Logger _logger;

  LoggerService._internal() {
    _initializeLogger();
  }

  void _initializeLogger() {
    final level = _getLogLevel();

    _logger = Logger(
      level: level,
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      ),
      output: Config.isProduction ? ProductionLogOutput() : null,
    );
  }

  Level _getLogLevel() {
    switch (Config.logLevel.toLowerCase()) {
      case 'verbose':
      case 'trace':
        return Level.trace;
      case 'debug':
        return Level.debug;
      case 'info':
        return Level.info;
      case 'warning':
        return Level.warning;
      case 'error':
        return Level.error;
      case 'wtf':
      case 'fatal':
        return Level.fatal;
      case 'nothing':
      case 'off':
        return Level.off;
      default:
        return Config.isProduction ? Level.warning : Level.debug;
    }
  }

  // Trace logging (formerly verbose)
  void t(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.t(message, error: error, stackTrace: stackTrace);
  }

  // Verbose logging (deprecated, use t() instead)
  void v(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.t(message, error: error, stackTrace: stackTrace);
  }

  // Debug logging
  void d(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  // Info logging
  void i(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  // Warning logging
  void w(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  // Error logging
  void e(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  // Fatal logging (formerly WTF)
  void f(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }

  // WTF logging (deprecated, use f() instead)
  void wtf(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }

  // API logging
  void logApiRequest(String method, String url, [Map<String, dynamic>? headers, dynamic body]) {
    d('API Request: $method $url');
    if (headers != null && !Config.isProduction) {
      d('Headers: $headers');
    }
    if (body != null && !Config.isProduction) {
      d('Body: $body');
    }
  }

  void logApiResponse(String method, String url, int statusCode, [dynamic response]) {
    if (statusCode >= 200 && statusCode < 300) {
      i('API Response: $method $url - $statusCode');
    } else if (statusCode >= 400) {
      e('API Error: $method $url - $statusCode');
      if (response != null && !Config.isProduction) {
        e('Error Response: $response');
      }
    } else {
      w('API Response: $method $url - $statusCode');
    }
  }

  // Socket logging
  void logSocketEvent(String event, [dynamic data]) {
    i('Socket Event: $event');
    if (data != null && !Config.isProduction) {
      d('Socket Data: $data');
    }
  }

  void logSocketError(String event, dynamic error) {
    e('Socket Error: $event - $error');
  }

  // Auth logging
  void logAuthEvent(String event, [String? userId]) {
    i('Auth Event: $event${userId != null ? ' (User: $userId)' : ''}');
  }

  // Chat logging
  void logChatEvent(String event, String chatId, [String? userId]) {
    i('Chat Event: $event (Chat: $chatId${userId != null ? ', User: $userId' : ''})');
  }

  // Offline logging
  void logOfflineEvent(String event, [dynamic data]) {
    w('Offline Event: $event${data != null ? ' - $data' : ''}');
  }

  // Performance logging
  void logPerformance(String operation, Duration duration, [String? details]) {
    i('Performance: $operation took ${duration.inMilliseconds}ms${details != null ? ' - $details' : ''}');
  }
}

class ProductionLogOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    // In production, you might want to send logs to a service like Firebase Crashlytics
    // or a logging service instead of printing to console

    // For now, only log errors and above in production
    if (event.level.index >= Level.error.index) {
      // Send to crash reporting service
      // Note: In production, consider using a proper logging service
      print('[${event.level.name.toUpperCase()}] ${event.lines.join('\n')}');
    }
  }
}

// Global logger instance
final logger = LoggerService();
