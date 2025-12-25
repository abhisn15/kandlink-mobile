import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/chat_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/assignment_provider.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../ui/router/app_router.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/responsive_scaffold.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Load conversations when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChat();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh conversations when app comes back to foreground
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      chatProvider.loadConversations();
      chatProvider.loadUnreadCounts();
    }
  }

  Future<void> _initializeChat() async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.user != null) {
      // Initialize socket connection
      await chatProvider.initializeSocket(
        authProvider.user!.id,
        'user_jwt_token_here', // This should come from secure storage
      );

      // Load conversations and unread counts
      await chatProvider.loadConversations();
      await chatProvider.loadUnreadCounts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);

    return ResponsiveScaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          // Connection status indicator
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: chatProvider.isConnected ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  chatProvider.isConnected ? 'Online' : 'Offline',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: chatProvider.isConnected ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: chatProvider.isLoading && chatProvider.conversations.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : chatProvider.conversations.isEmpty
              ? _buildEmptyState(context)
              : _buildConversationsList(context, chatProvider),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewChatOptions(context),
        child: const Icon(Icons.add),
        tooltip: 'Start new chat',
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No conversations yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation with a PIC or join a group chat.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Find PIC',
            onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false),
            icon: Icons.search,
          ),
        ],
      ),
    );
  }

  Widget _buildConversationsList(BuildContext context, ChatProvider chatProvider) {
    return RefreshIndicator(
      onRefresh: () async {
        await chatProvider.loadConversations();
        await chatProvider.loadUnreadCounts();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: chatProvider.conversations.length,
        itemBuilder: (context, index) {
          final conversation = chatProvider.conversations[index];
          return _buildConversationTile(context, conversation);
        },
      ),
    );
  }

  Widget _buildConversationTile(BuildContext context, conversation) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final unreadCount = chatProvider.unreadCounts[conversation.id] ?? 0;
    final isGroup = conversation.groupId != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          // Navigate to chat screen
          final route = isGroup
              ? '/chat/group/${conversation.groupId}'
              : '/chat/${conversation.otherUserId}';

          // Set current chat for message reading
          chatProvider.setCurrentChat(conversation.id);
          Navigator.of(context).pushNamed(route);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    backgroundImage: conversation.displayAvatar.isNotEmpty
                        ? NetworkImage(conversation.displayAvatar)
                        : null,
                    child: conversation.displayAvatar.isEmpty
                        ? Text(
                            conversation.displayName.substring(0, 1).toUpperCase(),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  if (!isGroup && conversation.otherUser?.isOnline == true)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.surface,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(width: 16),

              // Conversation Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.displayName,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isGroup)
                          Icon(
                            Icons.group,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      conversation.lastMessageContent,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatLastActivity(conversation.lastActivity),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),

              // Unread count
              if (unreadCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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

  void _showNewChatOptions(BuildContext context) {
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
              'Start New Conversation',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),

            // Chat with PIC option (for Candidates)
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                if (authProvider.user?.role.name == 'user') {
                  return _buildOptionButton(
                    context,
                    'Chat with PIC',
                    'Continue conversation with your assigned PIC',
                    Icons.person,
                    () {
                      Navigator.of(context).pop();
                      final assignmentProvider = Provider.of<AssignmentProvider>(context, listen: false);
                      if (assignmentProvider.currentAssignment != null &&
                          assignmentProvider.currentAssignment!.picId != null) {
                        Navigator.of(context).pushNamed(AppRoutes.chat(assignmentProvider.currentAssignment!.picId!));
                      } else {
                        Navigator.of(context).pushNamed(AppRoutes.picInfo);
                      }
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            // PIC Dashboard (for Candidates)
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                if (authProvider.user?.role.name == 'user') {
                  return Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: _buildOptionButton(
                      context,
                      'My PIC Info',
                      'View information about your assigned PIC',
                      Icons.person_pin_circle,
                      () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pushNamed(AppRoutes.picInfo);
                      },
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            // Join group option (for all users)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _buildOptionButton(
                context,
                'Join Group Chat',
                'Participate in group discussions',
                Icons.group,
                () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushNamed(AppRoutes.groups);
                },
              ),
            ),

            // Find new PIC option (for Candidates)
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                if (authProvider.user?.role.name == 'user') {
                  return Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: _buildOptionButton(
                      context,
                      'Find New PIC',
                      'Get assigned to a different PIC',
                      Icons.search,
                      () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pushNamed(AppRoutes.areaSelection);
                      },
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            // Create group option (for PICs)
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                if (authProvider.user?.role.name == 'pic') {
                  return Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: _buildOptionButton(
                      context,
                      'Create Group',
                      'Start a new group chat',
                      Icons.group_add,
                      () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pushNamed(AppRoutes.createGroup);
                      },
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
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
}
