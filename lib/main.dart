import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/assignment_provider.dart';
import 'core/providers/chat_provider.dart';
import 'core/providers/group_provider.dart';
import 'core/providers/notification_provider.dart';
import 'core/providers/offline_provider.dart';
import 'core/theme/app_theme.dart';
import 'ui/router/app_router.dart';
import 'ui/screens/splash/splash_screen.dart';
import 'ui/screens/auth/login_screen.dart';
import 'ui/screens/auth/register_screen.dart';
import 'ui/screens/auth/email_verification_screen.dart';
import 'ui/screens/auth/whatsapp_verification_screen.dart';
import 'ui/screens/auth/area_selection_screen.dart';
import 'ui/screens/home/home_screen.dart';
import 'ui/screens/chat/conversations_screen.dart';
import 'ui/screens/profile/profile_screen.dart';
import 'ui/screens/assignment/pic_info_screen.dart';
import 'ui/screens/settings/notification_settings_screen.dart';
import 'ui/screens/chat/chat_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Firebase (with error handling for development)
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyDummyKeyForDevelopmentPurposesOnly",
        appId: "1:123456789012:android:abcdef1234567890abcdef",
        messagingSenderId: "123456789012",
        projectId: "kandlink-dev",
        storageBucket: "kandlink-dev.appspot.com",
      ),
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Firebase initialization failed (expected in development): $e');
    // Continue without Firebase for development
  }

  // Initialize offline support
  final offlineProvider = OfflineProvider();
  await offlineProvider.initialize();
  print('Offline service initialized. Online: ${offlineProvider.isOnline}');

  runApp(const KandLinkApp());
}

class KandLinkApp extends StatelessWidget {
  const KandLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AssignmentProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => GroupProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => OfflineProvider()),
        // Add other providers here as needed
      ],
      child: MaterialApp(
        title: 'KandLink',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRoutes.generateRoute,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}