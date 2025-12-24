import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/assignment_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/models/assignment.dart';
import '../../widgets/common/custom_button.dart';

class AssignmentHistoryScreen extends StatefulWidget {
  const AssignmentHistoryScreen({super.key});

  @override
  State<AssignmentHistoryScreen> createState() => _AssignmentHistoryScreenState();
}

class _AssignmentHistoryScreenState extends State<AssignmentHistoryScreen> {
  @override
  void initState() {
    super.initState();
    // Load assignment history when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final assignmentProvider = Provider.of<AssignmentProvider>(context, listen: false);
      assignmentProvider.loadAssignmentHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final assignmentProvider = Provider.of<AssignmentProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignment History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => assignmentProvider.loadAssignmentHistory(),
          ),
        ],
      ),
      body: assignmentProvider.isLoading && assignmentProvider.assignmentHistory.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : assignmentProvider.assignmentHistory.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 64,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Assignment History',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        user?.role.name == 'user'
                            ? 'You haven\'t been assigned to any PIC yet.'
                            : 'No candidates have been assigned to you yet.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    await assignmentProvider.loadAssignmentHistory(page: 1);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: assignmentProvider.assignmentHistory.length +
                        (assignmentProvider.isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == assignmentProvider.assignmentHistory.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final assignment = assignmentProvider.assignmentHistory[index];
                      return _buildAssignmentCard(context, assignment, user);
                    },
                  ),
                ),
    );
  }

  Widget _buildAssignmentCard(BuildContext context, Assignment assignment, user) {
    final isPIC = user?.role.name == 'pic';
    final otherPerson = isPIC ? assignment.candidate : assignment.pic;
    final isCurrentAssignment = assignment.id == Provider.of<AssignmentProvider>(context).currentAssignment?.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status
            Row(
              children: [
                Expanded(
                  child: Text(
                    isPIC ? 'Candidate Assignment' : 'PIC Assignment',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (isCurrentAssignment)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Current',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Person Info
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  backgroundImage: otherPerson?.profilePicture != null
                      ? NetworkImage(otherPerson!.profilePicture!)
                      : null,
                  child: otherPerson?.profilePicture == null
                      ? Text(
                          otherPerson?.name.substring(0, 1).toUpperCase() ?? '?',
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
                        otherPerson?.name ?? 'Unknown',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isPIC ? 'Candidate' : 'PIC (Personal Information Counselor)',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
                // Contact info
                if (otherPerson?.phone != null)
                  IconButton(
                    icon: Icon(
                      Icons.phone,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: () {
                      // TODO: Implement phone call functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Call ${otherPerson!.phone}'),
                        ),
                      );
                    },
                    tooltip: 'Call ${otherPerson?.phone}',
                  ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),

            // Assignment Details
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

            const SizedBox(height: 4),

            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Assigned: ${_formatDateTime(assignment.assignedAt)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Action Buttons
            if (isCurrentAssignment && !isPIC)
              CustomButton(
                text: 'Chat with PIC',
                icon: Icons.chat,
                height: 40,
                onPressed: () => Navigator.of(context).pushNamed('/chat/${assignment.picId}'),
              )
            else if (isCurrentAssignment && isPIC)
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Chat',
                      icon: Icons.chat,
                      height: 40,
                      onPressed: () => Navigator.of(context).pushNamed('/chat/${assignment.candidateId}'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CustomButton(
                      text: 'Redirect',
                      icon: Icons.location_on,
                      height: 40,
                      outlined: true,
                      onPressed: () => _showRedirectDialog(context, assignment),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'Today at ${_formatTime(dateTime)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday at ${_formatTime(dateTime)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${_formatTime(dateTime)}';
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
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
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Show area selection dialog for redirect
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Area selection for redirect will be implemented next.'),
                ),
              );
            },
            child: const Text('Continue'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
