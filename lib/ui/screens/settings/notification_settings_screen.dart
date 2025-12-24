import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/notification_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/assignment_provider.dart';
import '../../widgets/common/custom_button.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _messageNotifications = true;
  bool _groupNotifications = true;
  bool _assignmentNotifications = true;
  bool _generalNotifications = true;

  @override
  void initState() {
    super.initState();
    // Load current notification preferences
    _loadNotificationSettings();
  }

  void _loadNotificationSettings() {
    // TODO: Load notification settings from local storage or backend
    // For now, use default values
  }

  @override
  Widget build(BuildContext context) {
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final assignmentProvider = Provider.of<AssignmentProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.notifications,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Push Notifications',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Control which notifications you receive',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // FCM Status
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: notificationProvider.isInitialized
                    ? Colors.green.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: notificationProvider.isInitialized
                      ? Colors.green.withOpacity(0.3)
                      : Colors.orange.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    notificationProvider.isInitialized ? Icons.check_circle : Icons.warning,
                    color: notificationProvider.isInitialized ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notificationProvider.isInitialized
                              ? 'Notifications Enabled'
                              : 'Notifications Setup Required',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          notificationProvider.isInitialized
                              ? 'You will receive push notifications for messages and updates'
                              : 'Please enable notifications to receive updates',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (!notificationProvider.isInitialized)
                    TextButton(
                      onPressed: () => _enableNotifications(notificationProvider),
                      child: const Text('Enable'),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Notification Preferences
            Text(
              'Notification Preferences',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 16),

            // Message Notifications
            _buildNotificationOption(
              context,
              'Message Notifications',
              'Receive notifications for new messages',
              Icons.message,
              _messageNotifications,
              (value) => setState(() => _messageNotifications = value),
            ),

            // Group Notifications
            _buildNotificationOption(
              context,
              'Group Notifications',
              'Receive notifications for group messages',
              Icons.group,
              _groupNotifications,
              (value) => setState(() => _groupNotifications = value),
            ),

            // Assignment Notifications
            _buildNotificationOption(
              context,
              'Assignment Notifications',
              'Receive notifications about PIC assignments',
              Icons.assignment,
              _assignmentNotifications,
              (value) => setState(() => _assignmentNotifications = value),
            ),

            // General Notifications
            _buildNotificationOption(
              context,
              'General Notifications',
              'Receive app updates and announcements',
              Icons.notifications,
              _generalNotifications,
              (value) => setState(() => _generalNotifications = value),
            ),

            const SizedBox(height: 24),

            // Area Subscriptions
            Text(
              'Area Subscriptions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),
            Text(
              'Receive notifications for your subscribed areas',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),

            const SizedBox(height: 16),

            // Current Area
            if (authProvider.user?.areaId != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Area',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                          Text(
                            assignmentProvider.currentAssignment?.area?.name ?? 'Unknown Area',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Error message
            if (notificationProvider.error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  notificationProvider.error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 14,
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Save Button
            CustomButton(
              text: 'Save Preferences',
              onPressed: () => _saveNotificationSettings(),
              isLoading: notificationProvider.isLoading,
            ),

            const SizedBox(height: 16),

            // Test Notification Button
            CustomButton(
              text: 'Test Notification',
              onPressed: () => _testNotification(),
              outlined: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationOption(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Future<void> _enableNotifications(NotificationProvider notificationProvider) async {
    final success = await notificationProvider.initializeNotifications();
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notifications enabled successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _saveNotificationSettings() async {
    // TODO: Save notification preferences to local storage and backend
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification preferences saved!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _testNotification() async {
    // TODO: Send test notification
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Test notification sent! Check your device.'),
      ),
    );
  }
}
