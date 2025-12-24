import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/assignment_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/models/assignment.dart';

class PICDashboardScreen extends StatefulWidget {
  const PICDashboardScreen({super.key});

  @override
  State<PICDashboardScreen> createState() => _PICDashboardScreenState();
}

class _PICDashboardScreenState extends State<PICDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Load candidates for PIC when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AssignmentProvider>(context, listen: false).loadCandidatesForPIC();
    });
  }

  @override
  Widget build(BuildContext context) {
    final assignmentProvider = Provider.of<AssignmentProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Candidates'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => assignmentProvider.loadCandidatesForPIC(),
          ),
        ],
      ),
      body: assignmentProvider.isLoading && assignmentProvider.candidatesForPIC.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : assignmentProvider.candidatesForPIC.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Candidates Assigned',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You don\'t have any candidates assigned to you yet.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'New candidates will be automatically assigned to you when they select your area.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    await assignmentProvider.loadCandidatesForPIC();
                  },
                  child: Column(
                    children: [
                      // Summary Card
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${assignmentProvider.candidatesForPIC.length}',
                              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Total Candidates',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Candidates List
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: assignmentProvider.candidatesForPIC.length +
                              (assignmentProvider.isLoading ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == assignmentProvider.candidatesForPIC.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final assignment = assignmentProvider.candidatesForPIC[index];
                            return _buildCandidateCard(context, assignment);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildCandidateCard(BuildContext context, Assignment assignment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showCandidateOptions(context, assignment),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Candidate Avatar
              CircleAvatar(
                radius: 28,
                backgroundColor: Theme.of(context).colorScheme.primary,
                backgroundImage: assignment.candidate?.profilePicture != null
                    ? NetworkImage(assignment.candidate!.profilePicture!)
                    : null,
                child: assignment.candidate?.profilePicture == null
                    ? Text(
                        assignment.candidate?.name.substring(0, 1).toUpperCase() ?? 'C',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),

              const SizedBox(width: 16),

              // Candidate Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assignment.candidate?.name ?? 'Unknown Candidate',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Area: ${assignment.area?.name ?? 'Unknown'}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Assigned: ${_formatDateTime(assignment.assignedAt)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),

              // Status Indicator
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // More Options
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () => _showCandidateOptions(context, assignment),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCandidateOptions(BuildContext context, Assignment assignment) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              assignment.candidate?.name ?? 'Candidate',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Area: ${assignment.area?.name ?? 'Unknown'}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // Action Buttons
            _buildActionButton(
              context,
              'Start Chat',
              Icons.chat,
              () {
                Navigator.of(context).pop();
                // TODO: Navigate to chat with candidate
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Chat with ${assignment.candidate?.name} will be opened'),
                  ),
                );
              },
            ),

            const SizedBox(height: 8),

            _buildActionButton(
              context,
              'View Profile',
              Icons.person,
              () {
                Navigator.of(context).pop();
                // TODO: Navigate to candidate profile
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Profile view for ${assignment.candidate?.name} will be implemented'),
                  ),
                );
              },
            ),

            const SizedBox(height: 8),

            _buildActionButton(
              context,
              'Create Group',
              Icons.group_add,
              () {
                Navigator.of(context).pop();
                // TODO: Navigate to create group with this candidate
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Group creation with ${assignment.candidate?.name} will be implemented'),
                  ),
                );
              },
            ),

            const SizedBox(height: 8),

            _buildActionButton(
              context,
              'Redirect to Different Area',
              Icons.location_on,
              () {
                Navigator.of(context).pop();
                _showRedirectDialog(context, assignment);
              },
              color: Theme.of(context).colorScheme.secondary,
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String text,
    IconData icon,
    VoidCallback onPressed, {
    Color? color,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Icon(
              icon,
              color: color ?? Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 16),
            Text(
              text,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: color ?? Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRedirectDialog(BuildContext context, Assignment assignment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Redirect Candidate'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Redirect ${assignment.candidate?.name ?? 'this candidate'} to a different area?',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'This will reassign them to a new PIC in the selected area.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final assignmentProvider = Provider.of<AssignmentProvider>(context, listen: false);

              // TODO: Show area selection dialog
              // For now, show a placeholder
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Area selection dialog will be implemented. Redirect functionality ready.'),
                ),
              );
            },
            child: const Text('Select Area'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
