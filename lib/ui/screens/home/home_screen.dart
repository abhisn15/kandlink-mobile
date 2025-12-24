import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/assignment_provider.dart';
import '../../../core/providers/offline_provider.dart';
import '../../../core/utils/responsive_utils.dart';
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

      if (authProvider.user?.role.name == 'user') {
        assignmentProvider.loadCurrentPIC();
      } else if (authProvider.user?.role.name == 'pic') {
        assignmentProvider.loadCandidatesForPIC();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final assignmentProvider = Provider.of<AssignmentProvider>(context);
    final user = authProvider.user;

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
                  content: const Text('Are you sure you want to logout?'),
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
                  context.go('/login');
                }
              }
            },
          ),
        ],
      ),
      body: ResponsiveContainer(
        child: const Center(
          child: Text('Home Screen'),
        ),
      ),
    );
  }

  // Temporarily commented out complex build method
  /*
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final assignmentProvider = Provider.of<AssignmentProvider>(context);
    final user = authProvider.user;

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
                  content: const Text('Are you sure you want to logout?'),
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
                  context.go('/login');
                }
              }
            },
          ),
        ],
      ),
      body: ResponsiveContainer(
        padding: EdgeInsets.zero,
        child: SingleChildScrollView(
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
                      'Welcome, ${user?.name ?? 'User'}!',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Role: ${user?.role.name.toUpperCase() ?? 'Unknown'}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (user?.city != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Location: ${user!.city}',
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

            // Action Buttons Grid
            SizedBox(
              height: context.isMobile ? 400 : context.isTablet ? 500 : 600,
              child: ResponsiveGridView(
                children: [
                  // Area Selection (for Candidates)
                  if (user?.role.name == 'user')
                    _buildActionCard(
                      context,
                      'Select Area',
                      Icons.location_on,
                      () => context.go('/area-selection'),
                    ),

                  // PIC Info (for Candidates)
                  if (user?.role.name == 'user')
                    _buildActionCard(
                      context,
                      'My PIC',
                      Icons.person_pin_circle,
                      () => context.go('/pic-info'),
                    ),

                  // Chat
                  _buildActionCard(
                    context,
                    'Messages',
                    Icons.chat,
                    () => context.go('/chats'),
                  ),

                  // Groups (PIC only)
                  if (user?.role.name == 'pic')
                    _buildActionCard(
                      context,
                      'Groups',
                      Icons.group,
                      () => context.go('/groups'),
                    ),

                  // Profile
                  _buildActionCard(
                    context,
                    'Profile',
                    Icons.person,
                    () => context.go('/profile'),
                  ),

                  // Notification Settings
                  _buildActionCard(
                    context,
                    'Notifications',
                    Icons.notifications,
                    () => context.go('/notification-settings'),
                  ),

                  // PIC Dashboard (PIC only)
                  if (user?.role.name == 'pic')
                    _buildActionCard(
                      context,
                      'My Candidates',
                      Icons.people,
                      () => context.go('/pic-dashboard'),
                    ),

                  // Create Group (PIC only)
                  if (user?.role.name == 'pic')
                    _buildActionCard(
                      context,
                      'Create Group',
                      Icons.group_add,
                      () => context.go('/create-group'),
                    ),
                ],
              ),
            ),
          ],
            ),
          ),
        ),
    );
  }
  */

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
                  onPressed: () => context.go('/pic-info'),
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
              onPressed: () => context.go('/chat/${assignment.picId}'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
