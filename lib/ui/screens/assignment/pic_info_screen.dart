import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/assignment_provider.dart';
import '../../../core/models/assignment.dart';
import '../../../ui/router/app_router.dart';
import '../../widgets/common/custom_button.dart';

class PICInfoScreen extends StatefulWidget {
  const PICInfoScreen({super.key});

  @override
  State<PICInfoScreen> createState() => _PICInfoScreenState();
}

class _PICInfoScreenState extends State<PICInfoScreen> {
  @override
  void initState() {
    super.initState();
    // Load current assignment when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AssignmentProvider>(context, listen: false).loadCurrentPIC();
    });
  }

  @override
  Widget build(BuildContext context) {
    final assignmentProvider = Provider.of<AssignmentProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your PIC'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => assignmentProvider.refreshCurrentAssignment(),
          ),
        ],
      ),
      body: assignmentProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : assignmentProvider.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading PIC information',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        assignmentProvider.error!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      CustomButton(
                        text: 'Retry',
                        onPressed: () => assignmentProvider.loadCurrentPIC(),
                      ),
                    ],
                  ),
                )
              : assignmentProvider.currentAssignment == null
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
                            'No PIC Assigned',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You haven\'t selected an area yet. Please select an area to get assigned to a PIC.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          CustomButton(
                            text: 'Select Area',
                            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.areaSelection),
                          ),
                        ],
                      ),
                    )
                  : _buildPICInfo(context, assignmentProvider.currentAssignment!),
    );
  }

  Widget _buildPICInfo(BuildContext context, Assignment assignment) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Success Message
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'You are successfully connected with your PIC!',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // PIC Information Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        backgroundImage: assignment.pic?.profilePicture != null
                            ? NetworkImage(assignment.pic!.profilePicture!)
                            : null,
                        child: assignment.pic?.profilePicture == null
                            ? Text(
                                assignment.pic?.name.substring(0, 1).toUpperCase() ?? 'P',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              assignment.pic?.name ?? 'PIC Name',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'PIC (Personal Information Counselor)',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // PIC Details
                  _buildInfoRow(
                    context,
                    'Email',
                    assignment.pic?.email ?? 'Not available',
                    Icons.email,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    context,
                    'Phone',
                    assignment.pic?.phone ?? 'Not available',
                    Icons.phone,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    context,
                    'Location',
                    assignment.pic?.city ?? 'Not available',
                    Icons.location_on,
                  ),

                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Assignment Info
                  Text(
                    'Assignment Details',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    context,
                    'Area',
                    assignment.area?.name ?? 'Unknown Area',
                    Icons.location_city,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    context,
                    'Assigned On',
                    _formatDateTime(assignment.assignedAt),
                    Icons.calendar_today,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Action Buttons
          CustomButton(
            text: 'Start Chat with PIC',
            icon: Icons.chat,
            onPressed: assignment.picId != null
                ? () => Navigator.of(context).pushNamed(AppRoutes.chat(assignment.picId!))
                : null,
          ),

          const SizedBox(height: 16),

          CustomButton(
            text: 'Wrong Area? Request Redirect',
            icon: Icons.location_off,
            outlined: true,
            onPressed: () => _showRedirectDialog(context),
          ),

          const SizedBox(height: 16),

          CustomButton(
            text: 'View Assignment History',
            icon: Icons.history,
            outlined: true,
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.assignmentHistory),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
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
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _showRedirectDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Area Redirect'),
        content: const Text(
          'If you selected the wrong area or need to be reassigned to a different location, '
          'please contact your current PIC first. They can help redirect you to the correct area.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement redirect request functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please contact your PIC directly for area redirect requests.'),
                ),
              );
            },
            child: const Text('Contact PIC'),
          ),
        ],
      ),
    );
  }
}
