import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/assignment_provider.dart';
import '../../../core/providers/offline_provider.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../ui/router/app_router.dart';
import '../auth/area_selection_screen.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/responsive_scaffold.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();

    // Load current assignment for candidates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final assignmentProvider = Provider.of<AssignmentProvider>(context, listen: false);
      final offlineProvider = Provider.of<OfflineProvider>(context, listen: false);

      // CRITICAL: Check if user has area selected, redirect if not
      if (authProvider.isAuthenticated &&
          authProvider.isEmailVerified &&
          authProvider.isWhatsappVerified &&
          authProvider.user?.areaId == null &&
          authProvider.user?.role.name == 'user') {
        debugPrint('🏠 HomeScreen: User authenticated but no area selected, redirecting to area selection');
        Navigator.of(context).pushNamed(AppRoutes.areaSelection);
        return;
      }

      // Always load current PIC assignment for candidates
      if (authProvider.user?.role.name == 'user') {
        debugPrint('🏠 HomeScreen: Loading current PIC assignment...');
        assignmentProvider.loadCurrentPIC().then((success) {
          debugPrint('🏠 HomeScreen: PIC assignment loaded successfully: $success');
          debugPrint('🏠 HomeScreen: Current assignment: ${assignmentProvider.currentAssignment}');
          debugPrint('🏠 HomeScreen: PIC ID: ${assignmentProvider.currentAssignment?.picId}');
          if (!success && assignmentProvider.error != null) {
            debugPrint('🏠 HomeScreen: Error loading PIC assignment: ${assignmentProvider.error}');
          }
        }).catchError((error) {
          debugPrint('🏠 HomeScreen: Exception loading PIC assignment: $error');
        });
      } else if (authProvider.user?.role.name == 'pic') {
        assignmentProvider.loadCandidatesForPIC();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final assignmentProvider = Provider.of<AssignmentProvider>(context);
    final offlineProvider = Provider.of<OfflineProvider>(context);
    final user = authProvider.user;

    // DOUBLE CHECK: Ensure user has area selected before showing home content
    if (authProvider.isAuthenticated &&
        authProvider.isEmailVerified &&
        authProvider.isWhatsappVerified &&
        user?.areaId == null &&
        user?.role.name == 'user') {
      debugPrint('🏠 HomeScreen build: User missing area, REDIRECTING TO AREA SELECTION');
      debugPrint('   isAuthenticated: ${authProvider.isAuthenticated}');
      debugPrint('   emailVerified: ${authProvider.isEmailVerified}');
      debugPrint('   whatsappVerified: ${authProvider.isWhatsappVerified}');
      debugPrint('   user?.areaId: ${user?.areaId}');
      // Trigger redirect and show loading
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushNamed(AppRoutes.areaSelection);
        }
      });
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Ensure user is not null before showing content
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return ResponsiveScaffold(
      appBar: AppBar(
        title: const Text('KandLink'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout from KandLink?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                await authProvider.logout();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
                }
              }
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: ResponsiveContainer(
        padding: EdgeInsets.zero,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100), // Space for bottom navigation
          child: Column(
            children: [
              // Offline status banner
              Consumer<OfflineProvider>(
                builder: (context, offlineProvider, child) {
                  if (!offlineProvider.isInitialized) return const SizedBox.shrink();

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: offlineProvider.isOnline ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                    child: Row(
                      children: [
                        Icon(
                          offlineProvider.isOnline ? Icons.wifi : Icons.wifi_off,
                          color: offlineProvider.isOnline ? Colors.green : Colors.orange,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            offlineProvider.isOnline
                                ? 'Online - All features available'
                                : 'Offline - Limited functionality',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: offlineProvider.isOnline ? Colors.green[700] : Colors.orange[700],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh, size: 16),
                          onPressed: () async {
                            await offlineProvider.checkConnectivity();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    offlineProvider.isOnline
                                        ? 'Connected to internet'
                                        : 'No internet connection',
                                  ),
                                  backgroundColor: offlineProvider.isOnline ? Colors.green : Colors.orange,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          tooltip: 'Check connection',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        if (offlineProvider.offlineQueueLength > 0)
                          Text(
                            '${offlineProvider.offlineQueueLength} pending',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.orange[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),

              // Main content
              Padding(
                padding: context.responsivePadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Section
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome, ${user.name}!',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Role: ${user?.role.name.toUpperCase() ?? 'Unknown'}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            if (user.city != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Location: ${user.city}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // PIC Information Section (for Candidates)
                    if (user?.role.name == 'user') ...[
                      _buildPICStatusSection(context, assignmentProvider),
                      const SizedBox(height: 24),
                    ],

                    // Quick Actions
                    Text(
                      'Quick Actions',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),

                    // Primary Chat Action (Highlighted for Candidates)
                    if (user?.role.name == 'user') ...[
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 24),
                        child: Card(
                          elevation: 4,
                          color: Theme.of(context).colorScheme.primaryContainer,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: InkWell(
                            onTap: () {
                              if (assignmentProvider.currentAssignment != null &&
                                  assignmentProvider.currentAssignment!.picId.isNotEmpty) {
                                final picId = assignmentProvider.currentAssignment!.picId!;
                                debugPrint('🏠 HomeScreen: Primary Chat - Navigating to chat with PIC ID: $picId');
                                Navigator.of(context).pushNamed(AppRoutes.chat(picId));
                              } else {
                                // No PIC assigned, go to conversations
                                Navigator.of(context).pushNamed(AppRoutes.conversations);
                              }
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.chat_bubble,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          assignmentProvider.currentAssignment != null &&
                                                  assignmentProvider.currentAssignment!.picId.isNotEmpty
                                              ? 'Chat dengan PIC Anda'
                                              : 'Lihat Pesan',
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          assignmentProvider.currentAssignment != null &&
                                                  assignmentProvider.currentAssignment!.picId.isNotEmpty
                                              ? 'Kirim pesan langsung ke PIC yang bertugas'
                                              : 'Akses semua percakapan Anda',
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7),
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.5),
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPICStatusSection(BuildContext context, AssignmentProvider assignmentProvider) {
    if (assignmentProvider.isLoading) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Text(
                'Loading PIC information...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    if (assignmentProvider.currentAssignment == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'No PIC Assigned',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Select an area above to get connected with a PIC in your location.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final assignment = assignmentProvider.currentAssignment!;
    if (assignment.picId == null) {
      return const SizedBox.shrink(); // Don't show PIC status if assignment is invalid
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  backgroundImage: assignment.pic?.profilePicture != null
                      ? NetworkImage(assignment.pic!.profilePicture!)
                      : null,
                  child: assignment.pic?.profilePicture == null
                      ? Text(
                          assignment.pic?.name.substring(0, 1).toUpperCase() ?? 'P',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your PIC',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                      Text(
                        assignment.pic?.name ?? 'PIC Name',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: () => Navigator.of(context).pushNamed(AppRoutes.picInfo),
                  tooltip: 'View PIC Details',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.location_city,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Area: ${assignment.area?.name ?? 'Unknown'}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Chat with PIC',
              icon: Icons.chat,
              height: 40,
              onPressed: assignment.picId != null && assignment.picId!.isNotEmpty
                  ? () {
                      debugPrint('🏠 PIC Status: Navigating to chat with PIC ID: ${assignment.picId}');
                      try {
                        Navigator.of(context).pushNamed(AppRoutes.chat(assignment.picId!));
                      } catch (e) {
                        debugPrint('🏠 PIC Status: Navigation error: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to open chat: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }

}
