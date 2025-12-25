import 'package:flutter/material.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/email_verification_screen.dart';
import '../screens/auth/whatsapp_verification_screen.dart';
import '../screens/auth/area_selection_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/chat/conversations_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/assignment/pic_info_screen.dart';
import '../screens/settings/notification_settings_screen.dart';
import '../screens/chat/chat_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String emailVerification = '/email-verification';
  static const String whatsappVerification = '/whatsapp-verification';
  static const String areaSelection = '/area-selection';
  static const String home = '/home';
  static const String conversations = '/conversations';
  static const String profile = '/profile';
  static const String picInfo = '/pic-info';
  static const String notificationSettings = '/notification-settings';
  static const String groups = '/groups';
  static const String createGroup = '/create-group';
  static const String picDashboard = '/pic-dashboard';
  static const String assignmentHistory = '/assignment-history';

  // Chat routes with parameters
  static String chat(String userId) => '/chat/$userId';
  static String groupChat(String groupId) => '/chat/group/$groupId';

  // Route generator
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case emailVerification:
        return MaterialPageRoute(builder: (_) => const EmailVerificationScreen());
      case whatsappVerification:
        return MaterialPageRoute(builder: (_) => const WhatsappVerificationScreen());
      case areaSelection:
        return MaterialPageRoute(builder: (_) => const AreaSelectionScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case conversations:
        return MaterialPageRoute(builder: (_) => const ConversationsScreen());
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case picInfo:
        return MaterialPageRoute(builder: (_) => const PICInfoScreen());
      case notificationSettings:
        return MaterialPageRoute(builder: (_) => const NotificationSettingsScreen());
      default:
        // Handle chat routes with parameters
        if (settings.name?.startsWith('/chat/') == true) {
          final pathSegments = settings.name!.split('/');
          if (pathSegments.length >= 3) {
            if (pathSegments[2] == 'group' && pathSegments.length >= 4) {
              // Group chat: /chat/group/{groupId}
              final groupId = pathSegments[3];
              return MaterialPageRoute(
                builder: (_) => ChatScreen(groupId: groupId),
              );
            } else {
              // Personal chat: /chat/{userId}
              final userId = pathSegments[2];
              return MaterialPageRoute(
                builder: (_) => ChatScreen(userId: userId),
              );
            }
          }
        }
        // Default fallback
        return MaterialPageRoute(builder: (_) => const SplashScreen());
    }
}
}