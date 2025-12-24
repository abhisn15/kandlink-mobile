import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/email_verification_screen.dart';
import '../screens/auth/whatsapp_verification_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/area/area_selection_screen.dart';
import '../screens/assignment/pic_info_screen.dart';
import '../screens/assignment/assignment_history_screen.dart';
import '../screens/assignment/pic_dashboard_screen.dart';
import '../screens/chat/chat_list_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/group/group_list_screen.dart';
import '../screens/group/create_group_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/settings/notification_settings_screen.dart';
import '../screens/splash/splash_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      // Splash Screen
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),

      // Authentication Routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/email-verification',
        builder: (context, state) => const EmailVerificationScreen(),
      ),
      GoRoute(
        path: '/whatsapp-verification',
        builder: (context, state) => const WhatsappVerificationScreen(),
      ),

      // Main App Routes (Protected)
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/area-selection',
        builder: (context, state) => const AreaSelectionScreen(),
      ),
      GoRoute(
        path: '/pic-info',
        builder: (context, state) => const PICInfoScreen(),
      ),
      GoRoute(
        path: '/assignment-history',
        builder: (context, state) => const AssignmentHistoryScreen(),
      ),
      GoRoute(
        path: '/pic-dashboard',
        builder: (context, state) => const PICDashboardScreen(),
      ),

      // Chat Routes
      GoRoute(
        path: '/chats',
        builder: (context, state) => const ChatListScreen(),
      ),
      GoRoute(
        path: '/chat/:userId',
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return ChatScreen(userId: userId);
        },
      ),
      GoRoute(
        path: '/chat/group/:groupId',
        builder: (context, state) {
          final groupId = state.pathParameters['groupId']!;
          return ChatScreen(groupId: groupId);
        },
      ),

      // Group Routes
      GoRoute(
        path: '/groups',
        builder: (context, state) => const GroupListScreen(),
      ),
      GoRoute(
        path: '/create-group',
        builder: (context, state) => const CreateGroupScreen(),
      ),

      // Profile Route
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/notification-settings',
        builder: (context, state) => const NotificationSettingsScreen(),
      ),
    ],
    redirect: (context, state) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isAuthenticated = authProvider.isAuthenticated;
      final isOnAuthPage = state.matchedLocation.startsWith('/login') ||
                          state.matchedLocation.startsWith('/register') ||
                          state.matchedLocation.startsWith('/email-verification') ||
                          state.matchedLocation.startsWith('/whatsapp-verification');
      final isOnSplash = state.matchedLocation == '/';

      // If user is not authenticated and not on auth pages or splash
      if (!isAuthenticated && !isOnAuthPage && !isOnSplash) {
        return '/login';
      }

      // If user is authenticated and on auth pages
      if (isAuthenticated && isOnAuthPage) {
        return '/home';
      }

      // If user is authenticated but email not verified
      if (isAuthenticated && !authProvider.isEmailVerified &&
          !state.matchedLocation.startsWith('/email-verification')) {
        return '/email-verification';
      }

      // If user is authenticated and email verified but WhatsApp not verified
      if (isAuthenticated && authProvider.isEmailVerified &&
          !authProvider.isWhatsappVerified &&
          !state.matchedLocation.startsWith('/whatsapp-verification')) {
        return '/whatsapp-verification';
      }

      return null;
    },
  );
}
