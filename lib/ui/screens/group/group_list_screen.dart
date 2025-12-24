import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/group_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/chat_provider.dart';
import '../../../core/models/chat.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/group/add_members_sheet.dart';

class GroupListScreen extends StatefulWidget {
  const GroupListScreen({super.key});

  @override
  State<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen> {
  @override
  void initState() {
    super.initState();
    // Load groups when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<GroupProvider>(context, listen: false).loadMyGroups();
    });
  }

  @override
  Widget build(BuildContext context) {
    final groupProvider = Provider.of<GroupProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Groups'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => groupProvider.loadMyGroups(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header with info
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surface,
            child: Row(
              children: [
                Icon(
                  Icons.group,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Group Discussions',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Join group chats to discuss with multiple people',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: groupProvider.isLoading && groupProvider.myGroups.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : groupProvider.myGroups.isEmpty
                    ? _buildEmptyState(context, user)
                    : _buildGroupsList(context, groupProvider, user),
          ),
        ],
      ),
      floatingActionButton: user?.role.name == 'pic'
          ? FloatingActionButton(
              onPressed: () => context.go('/create-group'),
              child: const Icon(Icons.add),
              tooltip: 'Create new group',
            )
          : null,
    );
  }

  Widget _buildEmptyState(BuildContext context, user) {
    final isPIC = user?.role.name == 'pic';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.groups_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No groups yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              isPIC
                  ? 'Create your first group to start discussions with candidates in your area.'
                  : 'You haven\'t joined any groups yet. Groups are created by PICs for area discussions.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          if (isPIC)
            CustomButton(
              text: 'Create Group',
              icon: Icons.add,
              onPressed: () => context.go('/create-group'),
            ),
        ],
      ),
    );
  }

  Widget _buildGroupsList(BuildContext context, GroupProvider groupProvider, user) {
    final myCreatedGroups = groupProvider.getMyCreatedGroups(user?.id ?? '');
    final myJoinedGroups = groupProvider.getMyJoinedGroups(user?.id ?? '');

    return RefreshIndicator(
      onRefresh: () async {
        await groupProvider.loadMyGroups();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // My Created Groups (for PICs)
          if (myCreatedGroups.isNotEmpty) ...[
            _buildSectionHeader(context, 'Groups I Created', Icons.admin_panel_settings),
            ...myCreatedGroups.map((group) => _buildGroupCard(context, group, true)),
            const SizedBox(height: 24),
          ],

          // Groups I Joined (for all users)
          if (myJoinedGroups.isNotEmpty) ...[
            _buildSectionHeader(context, 'Groups I Joined', Icons.group_add),
            ...myJoinedGroups.map((group) => _buildGroupCard(context, group, false)),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(BuildContext context, group, bool isCreator) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final memberCount = group.members?.length ?? 0;

    // Get last message from chat conversations
    Conversation? conversation;
    try {
      conversation = chatProvider.conversations.firstWhere(
        (conv) => conv.groupId == group.id,
      );
    } catch (e) {
      conversation = null;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.go('/chat/group/${group.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Group Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: group.avatar != null && group.avatar!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          group.avatar!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.group,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.group,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
              ),

              const SizedBox(width: 16),

              // Group Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            group.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isCreator)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Owner',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Member count and last message
                    Row(
                      children: [
                        Icon(
                          Icons.people,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$memberCount ${memberCount == 1 ? 'member' : 'members'}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),

                    if (conversation != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        conversation.lastMessage.content,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Unread count and menu
              Column(
                children: [
                  if (conversation != null)
                    Text(
                      _formatLastActivity(conversation.lastActivity),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),

                  // Menu button for group creators
                  if (isCreator)
                    IconButton(
                      icon: const Icon(Icons.more_vert, size: 20),
                      onPressed: () => _showGroupMenu(context, group),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),

                  // Unread count
                  if (chatProvider.unreadCounts[group.id] != null &&
                      chatProvider.unreadCounts[group.id]! > 0)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        chatProvider.unreadCounts[group.id]! > 99
                            ? '99+'
                            : chatProvider.unreadCounts[group.id].toString(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatLastActivity(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }

  void _showGroupMenu(BuildContext context, group) {
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
              'Group Options',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              group.name,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 24),

            // Add Members
            _buildMenuOption(
              context,
              'Add Members',
              'Invite more candidates to this group',
              Icons.person_add,
              () {
                Navigator.of(context).pop();
                _showAddMembersSheet(context, group);
              },
            ),

            const SizedBox(height: 16),

            // View Members
            _buildMenuOption(
              context,
              'View Members',
              'See all group members',
              Icons.people,
              () {
                Navigator.of(context).pop();
                // TODO: Navigate to group members screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Group members view coming soon')),
                );
              },
            ),

            const SizedBox(height: 16),

            // Group Settings
            _buildMenuOption(
              context,
              'Group Settings',
              'Edit group name and settings',
              Icons.settings,
              () {
                Navigator.of(context).pop();
                // TODO: Navigate to group settings
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Group settings coming soon')),
                );
              },
            ),

            const SizedBox(height: 24),

            // Danger zone
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.error.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Danger Zone',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildMenuOption(
                    context,
                    'Delete Group',
                    'Permanently delete this group',
                    Icons.delete_forever,
                    () {
                      Navigator.of(context).pop();
                      _showDeleteConfirmation(context, group);
                    },
                    color: Theme.of(context).colorScheme.error,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOption(BuildContext context, String title, String subtitle, IconData icon, VoidCallback onTap, {Color? color}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              icon,
              color: color ?? Theme.of(context).colorScheme.primary,
              size: 24,
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
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
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
    );
  }

  void _showAddMembersSheet(BuildContext context, group) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => AddMembersSheet(
        groupId: group.id,
        groupName: group.name,
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group'),
        content: Text(
          'Are you sure you want to delete "${group.name}"? This action cannot be undone and all messages will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement group deletion
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Group deletion coming soon')),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
