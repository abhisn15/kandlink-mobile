import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/chat_provider.dart';
import '../../../ui/router/app_router.dart';

class KandLinkBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const KandLinkBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context);
    final user = authProvider.user;
    final isPIC = user?.role.name == 'pic';
    final totalUnread = chatProvider.totalUnread;

    // Define navigation items based on user role
    final List<BottomNavigationBarItem> items = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home),
        label: 'Home',
        tooltip: 'Dashboard',
      ),
      BottomNavigationBarItem(
        icon: totalUnread > 0
            ? Badge(
                label: Text(totalUnread > 99 ? '99+' : totalUnread.toString()),
                child: const Icon(Icons.forum_outlined),
              )
            : const Icon(Icons.forum_outlined),
        activeIcon: totalUnread > 0
            ? Badge(
                label: Text(totalUnread > 99 ? '99+' : totalUnread.toString()),
                child: const Icon(Icons.forum),
              )
            : const Icon(Icons.forum),
        label: 'Messages',
        tooltip: isPIC ? 'Conversations' : 'Chat with PIC',
      ),
      if (user?.role.name == 'user') // Only for candidates
        const BottomNavigationBarItem(
          icon: Icon(Icons.person_pin_circle_outlined),
          activeIcon: Icon(Icons.person_pin_circle),
          label: 'My PIC',
          tooltip: 'PIC Information',
        ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        activeIcon: Icon(Icons.person),
        label: 'Profile',
        tooltip: 'My Profile',
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.surface.withOpacity(0.95),
            Theme.of(context).colorScheme.surface,
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, -4),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          items: items,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          selectedLabelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 10,
            letterSpacing: 0.6,
            height: 1.2,
          ),
          unselectedLabelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 10,
            letterSpacing: 0.4,
            height: 1.2,
          ),
          elevation: 0,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          enableFeedback: true,
          selectedIconTheme: IconThemeData(
            size: 26,
            color: Theme.of(context).colorScheme.primary,
          ),
          unselectedIconTheme: IconThemeData(
            size: 24,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          ),
        ),
      ),
    );
  }
}

// Navigation helper class
class NavigationHelper {
  static const int homeIndex = 0;
  static const int messagesIndex = 1;
  static const int picIndex = 2; // Only for candidates
  static const int profileIndex = 3;

  // Get navigation path based on index and user role
  static String getPathForIndex(int index, String? userRole) {
    if (userRole == 'user') {
      // Candidates: Home, Messages, My PIC, Profile
      switch (index) {
        case homeIndex:
          return AppRoutes.home;
        case messagesIndex:
          return AppRoutes.conversations;
        case picIndex:
          return AppRoutes.picInfo;
        case profileIndex:
          return AppRoutes.profile;
        default:
          return AppRoutes.home;
      }
    } else {
      // PICs: Home, Messages, Profile (no My PIC tab)
      switch (index) {
        case homeIndex:
          return AppRoutes.home;
        case messagesIndex:
          return AppRoutes.conversations;
        case 2: // Profile index for PICs (adjusted for missing PIC tab)
          return AppRoutes.profile;
        default:
          return AppRoutes.home;
      }
    }
  }

  // Get index based on current path and user role
  static int getIndexForPath(String path, String? userRole) {
    if (userRole == 'user') {
      // Candidates mapping
      switch (path) {
        case AppRoutes.home:
          return homeIndex;
        case AppRoutes.conversations:
          return messagesIndex;
        case AppRoutes.picInfo:
          return picIndex;
        case AppRoutes.profile:
          return profileIndex;
        default:
          // For other paths, try to find closest match
          if (path.startsWith('/chat')) {
            return messagesIndex; // Chat screens belong to messages tab
          }
          return homeIndex;
      }
    } else {
      // PICs mapping (no PIC tab)
      switch (path) {
        case AppRoutes.home:
          return homeIndex;
        case AppRoutes.conversations:
          return messagesIndex;
        case AppRoutes.profile:
          return 2; // Profile index for PICs (adjusted for missing PIC tab)
        default:
          if (path.startsWith('/chat')) {
            return messagesIndex;
          }
          return homeIndex;
      }
    }
  }

  // Get total number of tabs based on user role
  static int getTabCount(String? userRole) {
    return userRole == 'user' ? 4 : 3; // Candidates have 4 tabs, PICs have 3
  }
}
