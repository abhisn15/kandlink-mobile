import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../ui/router/app_router.dart';
import 'bottom_navigation_bar.dart';

class MainScaffold extends StatefulWidget {
  final Widget child;
  final bool showBottomNav;

  const MainScaffold({
    super.key,
    required this.child,
    this.showBottomNav = true,
  });

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;
  List<String> _navigationPaths = [];

  @override
  void initState() {
    super.initState();
    // Don't access inherited widgets here
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Now we can safely access inherited widgets
    _initializeNavigationPaths();

    // Update current index based on current route
    final currentPath = ModalRoute.of(context)?.settings.name;
    final userRole = _getCurrentUserRole();
    final newIndex = _getIndexForPath(currentPath, userRole);

    if (newIndex != _currentIndex) {
      setState(() {
        _currentIndex = newIndex;
      });
    }
  }

  void _initializeNavigationPaths() {
    final userRole = _getCurrentUserRole();
    final tabCount = _getTabCount(userRole);

    final newPaths =
        List.generate(tabCount, (index) => _getPathForIndex(index, userRole));

    if (_navigationPaths.length != newPaths.length ||
        !_navigationPaths.asMap().entries.every((entry) =>
            entry.key < newPaths.length &&
            entry.value == newPaths[entry.key])) {
      setState(() {
        _navigationPaths = newPaths;
        _currentIndex = 0; // Reset to first tab when navigation changes
      });
    }
  }

  String? _getCurrentUserRole() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return authProvider.user?.role.name;
  }

  void _onBottomNavTap(int index) {
    if (index >= 0 && index < _navigationPaths.length) {
      final path = _navigationPaths[index];
      final currentPath = ModalRoute.of(context)?.settings.name;
      if (path != currentPath) {
        Navigator.of(context).pushNamedAndRemoveUntil(path, (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userRole = authProvider.user?.role.name;
    final currentPath = ModalRoute.of(context)?.settings.name;

    // Check if current route should have bottom navigation
    final shouldShowBottomNav = widget.showBottomNav &&
        authProvider.isAuthenticated &&
        authProvider.isEmailVerified == true &&
        authProvider.isWhatsappVerified == true &&
        (userRole == 'user' ? authProvider.user?.areaId != null : true) &&
        _navigationPaths.contains(currentPath);

    // Debug: Print bottom nav visibility conditions
    debugPrint('🔍 Bottom Nav Debug:');
    debugPrint('   widget.showBottomNav: ${widget.showBottomNav}');
    debugPrint('   isAuthenticated: ${authProvider.isAuthenticated}');
    debugPrint('   isEmailVerified: ${authProvider.isEmailVerified}');
    debugPrint('   isWhatsappVerified: ${authProvider.isWhatsappVerified}');
    debugPrint('   userRole: $userRole');
    debugPrint('   areaId (for user): ${authProvider.user?.areaId}');
    debugPrint('   currentPath: $currentPath');
    debugPrint('   _navigationPaths: $_navigationPaths');
    debugPrint('   _navigationPaths.contains(currentPath): ${_navigationPaths.contains(currentPath)}');
    debugPrint('   SHOULD SHOW BOTTOM NAV: $shouldShowBottomNav');

    if (!shouldShowBottomNav) {
      // For non-main routes (like chat), wrap with WillPopScope to handle back navigation
      return WillPopScope(
        onWillPop: () async {
          // If not on main navigation paths, allow normal back navigation (pop)
          if (!_navigationPaths.contains(currentPath)) {
            debugPrint('Back navigation: Not on main tab, allowing normal pop');
            return true; // Allow normal back navigation
          }

          // If on home, allow app to exit
          if (currentPath == AppRoutes.home) {
            debugPrint('Back navigation: On home, allowing app exit');
            return true; // Allow the system to handle back (exit app)
          }

          // For other main tabs, go to home
          debugPrint('Back navigation: On main tab, going to home');
          Navigator.of(context)
              .pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
          return false; // Don't pop the route
        },
        child: widget
            .child, // Don't wrap with Scaffold, let child handle its own AppBar
      );
    }

    // For main navigation routes, wrap with WillPopScope
    return WillPopScope(
      onWillPop: () async {
        // If on home tab, allow exit
        if (_currentIndex == 0) {
          debugPrint('Back navigation: On home tab, allowing app exit');
          return true;
        }

        // Otherwise, go to home tab
        debugPrint('Back navigation: Going to home tab');
        _onBottomNavTap(0);
        return false;
      },
      child: Scaffold(
        body: GestureDetector(
          // Swipe left to go to next tab, right to go to previous tab
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity! < 0) {
              // Swipe left - next tab
              final nextIndex = (_currentIndex + 1) % _navigationPaths.length;
              _onBottomNavTap(nextIndex);
            } else if (details.primaryVelocity! > 0) {
              // Swipe right - previous tab
              final prevIndex = _currentIndex > 0
                  ? _currentIndex - 1
                  : _navigationPaths.length - 1;
              _onBottomNavTap(prevIndex);
            }
          },
          child: widget.child, // Show the actual child content
        ),
        bottomNavigationBar: KandLinkBottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onBottomNavTap,
        ),
      ),
    );
  }

  int _getIndexForPath(String? path, String? userRole) {
    if (path == null) return 0;

    final paths = _getNavigationPathsForRole(userRole);
    return paths.indexOf(path);
  }

  int _getTabCount(String? userRole) {
    return _getNavigationPathsForRole(userRole).length;
  }

  String _getPathForIndex(int index, String? userRole) {
    final paths = _getNavigationPathsForRole(userRole);
    if (index >= 0 && index < paths.length) {
      return paths[index];
    }
    return AppRoutes.home;
  }

  List<String> _getNavigationPathsForRole(String? userRole) {
    if (userRole == 'pic') {
      return [AppRoutes.home, AppRoutes.conversations, AppRoutes.profile];
    } else {
      // Default for user/candidate
      return [AppRoutes.home, AppRoutes.conversations, AppRoutes.profile];
    }
  }
}
