import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/chat_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/assignment_provider.dart';
import '../../../core/models/chat.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../ui/router/app_router.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/chat/message_bubble.dart';
import '../../widgets/chat/message_input.dart';

class ChatScreen extends StatefulWidget {
  final String? userId;
  final String? groupId;

  const ChatScreen({super.key, this.userId, this.groupId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _loadChat();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadChat() async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final chatId = widget.userId ?? widget.groupId;

    if (chatId != null) {
      // Set current chat
      chatProvider.setCurrentChat(chatId);

      // Load messages
      await chatProvider.loadMessages(
        otherUserId: widget.userId,
        groupId: widget.groupId,
      );

      // Scroll to bottom after loading messages
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    // Clear input
    _messageController.clear();

    // Stop typing indicator
    if (_isTyping) {
      _stopTyping();
    }

    // Send message
    bool success = false;
    if (widget.groupId != null) {
      success = await chatProvider.sendGroupMessage(widget.groupId!, message);
    } else if (widget.userId != null) {
      success = await chatProvider.sendMessage(widget.userId!, message);
    }

    if (success) {
      _scrollToBottom();
    }
  }

  void _startTyping() {
    if (!_isTyping) {
      setState(() => _isTyping = true);
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      final chatId = widget.userId ?? widget.groupId;
      if (chatId != null) {
        chatProvider.startTyping(chatId);
      }
    }
  }

  void _stopTyping() {
    if (_isTyping) {
      setState(() => _isTyping = false);
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      final chatId = widget.userId ?? widget.groupId;
      if (chatId != null) {
        chatProvider.stopTyping(chatId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final assignmentProvider = Provider.of<AssignmentProvider>(context);
    final isGroup = widget.groupId != null;

    // Get chat title and info
    String chatTitle = 'Chat';
    String? chatAvatarUrl;
    bool isOnline = false;

    if (isGroup) {
      // Find group name from conversations
      Conversation? conversation;
      try {
        conversation = chatProvider.conversations.firstWhere(
          (conv) => conv.groupId == widget.groupId,
        );
      } catch (e) {
        conversation = null;
      }
      chatTitle = conversation?.displayName ?? 'Group Chat';
      chatAvatarUrl = conversation?.displayAvatar;
    } else {
      // For personal chats - prioritize PIC info from assignment
      final currentAssignment = assignmentProvider.currentAssignment;
      if (currentAssignment != null && currentAssignment.picId == widget.userId) {
        // This is chat with assigned PIC
        chatTitle = currentAssignment.pic?.name ?? 'PIC';
        chatAvatarUrl = currentAssignment.pic?.profilePicture;
        isOnline = currentAssignment.pic?.isOnline ?? false;
      } else {
        // Fallback to conversation data
        Conversation? conversation;
        try {
          conversation = chatProvider.conversations.firstWhere(
            (conv) => conv.otherUserId == widget.userId,
          );
        } catch (e) {
          conversation = null;
        }
        chatTitle = conversation?.displayName ?? 'Chat';
        chatAvatarUrl = conversation?.displayAvatar;
        isOnline = conversation?.otherUser?.isOnline ?? false;
      }
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: chatAvatarUrl != null ? NetworkImage(chatAvatarUrl!) : null,
              backgroundColor: chatAvatarUrl == null ? Theme.of(context).colorScheme.primary : null,
              child: chatAvatarUrl == null ? Text(
                chatTitle.isNotEmpty ? chatTitle.substring(0, 1).toUpperCase() : '?',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chatTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!isGroup)
                    Text(
                      isOnline ? 'Online' : 'Offline',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isOnline ? Colors.green : Colors.grey,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showChatInfo(context),
            tooltip: 'Chat info',
          ),
        ],
      ),
      body: Column(
        children: [
          // Connection status banner
          if (!chatProvider.isConnected)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.orange.withOpacity(0.1),
              child: Row(
                children: [
                  Icon(Icons.wifi_off, color: Colors.orange, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Connecting...',
                    style: TextStyle(color: Colors.orange, fontSize: 12),
                  ),
                ],
              ),
            ),

          // Messages list
          Expanded(
            child: chatProvider.isLoading && chatProvider.messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : chatProvider.messages.isEmpty
                    ? _buildEmptyChat(context)
                    : _buildMessagesList(context, chatProvider, authProvider),
          ),

          // Message input
          MessageInput(
            controller: _messageController,
            onSend: _sendMessage,
            onTypingStart: _startTyping,
            onTypingStop: _stopTyping,
            enabled: chatProvider.isConnected,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChat(BuildContext context) {
    final isGroup = widget.groupId != null;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isGroup ? Icons.group : Icons.chat_bubble_outline,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            isGroup ? 'No messages in this group yet' : 'Start a conversation',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            isGroup
                ? 'Be the first to send a message in this group!'
                : 'Send a message to start the conversation.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(BuildContext context, ChatProvider chatProvider, AuthProvider authProvider) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: chatProvider.messages.length,
      itemBuilder: (context, index) {
        final message = chatProvider.messages[index];
        final isFromMe = message.senderId == authProvider.user?.id;

        // Show date separator if needed
        final showDateSeparator = index == 0 ||
            !_isSameDay(message.createdAt, chatProvider.messages[index - 1].createdAt);

        return Column(
          children: [
            if (showDateSeparator) ...[
              _buildDateSeparator(message.createdAt),
              const SizedBox(height: 16),
            ],
            MessageBubble(
              message: message,
              isFromMe: isFromMe,
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);

    String dateText;
    if (messageDate == today) {
      dateText = 'Today';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      dateText = 'Yesterday';
    } else {
      dateText = '${date.day}/${date.month}/${date.year}';
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        ),
        child: Text(
          dateText,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).textTheme.bodySmall?.color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  void _showChatInfo(BuildContext context) {
    final isGroup = widget.groupId != null;

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
              isGroup ? 'Group Information' : 'Chat Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),

            if (isGroup) ...[
              _buildInfoItem(
                context,
                'Group Chat',
                'This is a group conversation with multiple participants',
                Icons.group,
              ),
              const SizedBox(height: 16),
              _buildActionButton(
                context,
                'View Group Members',
                Icons.people,
                () {
                  Navigator.of(context).pop();
                  // TODO: Navigate to group members screen
                },
              ),
            ] else ...[
              _buildInfoItem(
                context,
                'Personal Chat',
                'Private conversation with your PIC',
                Icons.person,
              ),
              const SizedBox(height: 16),
              _buildActionButton(
                context,
                'View PIC Profile',
                Icons.person_outline,
                () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushNamed(AppRoutes.picInfo);
                },
              ),
            ],

            const SizedBox(height: 16),
            _buildActionButton(
              context,
              'Search Messages',
              Icons.search,
              () {
                Navigator.of(context).pop();
                // TODO: Implement message search
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, String title, String subtitle, IconData icon) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
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
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
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
