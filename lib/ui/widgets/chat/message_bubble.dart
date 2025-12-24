import 'package:flutter/material.dart';
import '../../../core/models/chat.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isFromMe;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isFromMe,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isFromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          left: isFromMe ? 64 : 8,
          right: isFromMe ? 8 : 64,
          bottom: 4,
        ),
        child: Column(
          crossAxisAlignment: isFromMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Sender name for group messages
            if (message.groupId != null && !isFromMe && message.sender != null) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  message.sender!.name,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],

            // Message bubble
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isFromMe
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isFromMe ? const Radius.circular(16) : const Radius.circular(4),
                  bottomRight: isFromMe ? const Radius.circular(4) : const Radius.circular(16),
                ),
                border: !isFromMe
                    ? Border.all(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                      )
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Message content
                  Text(
                    message.content,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isFromMe
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),

                  // Message type indicator (for images, files, etc.)
                  if (message.type != MessageType.text) ...[
                    const SizedBox(height: 8),
                    _buildMessageTypeIndicator(context, message),
                  ],
                ],
              ),
            ),

            // Message status and timestamp
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(message.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      fontSize: 10,
                    ),
                  ),
                  if (isFromMe) ...[
                    const SizedBox(width: 4),
                    Icon(
                      message.isRead ? Icons.done_all : Icons.done,
                      size: 12,
                      color: message.isRead
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageTypeIndicator(BuildContext context, ChatMessage message) {
    IconData icon;
    String label;

    switch (message.type) {
      case MessageType.image:
        icon = Icons.image;
        label = 'Image';
        break;
      case MessageType.file:
        icon = Icons.attach_file;
        label = 'File';
        break;
      default:
        icon = Icons.textsms;
        label = 'Message';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (isFromMe
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.surface)
            .withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: isFromMe
                ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.8)
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isFromMe
                  ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.8)
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
