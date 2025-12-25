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

    // DOUBLE CHECK: Ensure user has area selected before showing home content
    if (authProvider.isAuthenticated &&
        authProvider.isEmailVerified == true &&
        authProvider.isWhatsappVerified == true &&
        user?.areaId == null) {
      debugPrint('🏠 HomeScreen build: User missing area, REDIRECTING TO AREA SELECTION');
      // Trigger redirect and show loading
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/area-selection');
        }
      });
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
      body: _buildBody(context, user, assignmentProvider),
    );
  }

  Widget _buildBody(BuildContext context, user, AssignmentProvider assignmentProvider) {
    return ResponsiveContainer(
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
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Simple action buttons
                  Column(
                    children: [
                      // Messages button (for all users)
                      _buildActionCard(
                        context,
                        'Messages',
                        Icons.forum,
                        () => context.go('/conversations'),
                      ),
                      const SizedBox(height: 12),

                      // Chat with PIC (for candidates with assignment)
                      if (user?.role.name == 'user' && assignmentProvider.currentAssignment != null)
                        _buildActionCard(
                          context,
                          'Chat with PIC',
                          Icons.chat,
                          () => context.go('/chat/${assignmentProvider.currentAssignment!.picId}'),
                        ),

                      // PIC Info (for candidates)
                      if (user?.role.name == 'user')
                        _buildActionCard(
                          context,
                          'My PIC',
                          Icons.person_pin_circle,
                          () => context.go('/pic-info'),
                        ),

                      // Profile (for all users)
                      _buildActionCard(
                        context,
                        'Profile',
                        Icons.person,
                        () => context.go('/profile'),
                      ),

                      // Groups (for PICs)
                      if (user?.role.name == 'pic')
                        _buildActionCard(
                          context,
                          'Groups',
                          Icons.group,
                          () => context.go('/groups'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getActionDescription(title),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getActionDescription(String title) {
    switch (title) {
      case 'Messages':
        return 'View all your conversations';
      case 'Chat with PIC':
        return 'Start a chat with your assigned PIC';
      case 'My PIC':
        return 'View your PIC information';
      case 'Profile':
        return 'Manage your profile and settings';
      case 'Groups':
        return 'Manage your groups';
      default:
        return 'Tap to access';
    }
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
                'You haven\'t selected an area yet. Please select an area to get assigned to a PIC.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: 'Select Area',
                onPressed: () => context.go('/area-selection'),
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
                  radius: 24,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  backgroundImage: assignment.pic?.profilePicture != null
                      ? NetworkImage(assignment.pic!.profilePicture!)
                      : null,
                  child: assignment.pic?.profilePicture == null
                      ? Text(
                          assignment.pic?.name.substring(0, 1).toUpperCase() ?? 'P',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Chat with PIC',
              icon: Icons.chat,
              height: 40,
              onPressed: assignment.picId != null
                  ? () => context.go('/chat/${assignment.picId}')
                  : null,
            ),
            const SizedBox(height: 12),
            CustomButton(
              text: 'View PIC Details',
              icon: Icons.person,
              height: 40,
              outlined: true,
              onPressed: () => context.go('/pic-info'),
            ),
          ],
        ),
      ),
    );
  }
}
