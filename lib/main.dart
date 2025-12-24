import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/assignment_provider.dart';
import 'core/providers/chat_provider.dart';
import 'core/providers/group_provider.dart';
import 'core/providers/notification_provider.dart';
import 'core/providers/offline_provider.dart';
import 'core/theme/app_theme.dart';
import 'ui/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (with error handling for development)
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyDummyKeyForDevelopment",
        appId: "1:dummy:android:dummy",
        messagingSenderId: "dummy",
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
      child: MaterialApp.router(
        title: 'KandLink',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: AppRouter.router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}