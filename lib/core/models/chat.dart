import 'user.dart';
import 'group.dart';

enum MessageType { text, image, file }

class ChatMessage {
  final String id;
  final String senderId;
  final String? receiverId;
  final String? groupId;
  final String content;
  final MessageType type;
  final bool isRead;
  final DateTime createdAt;
  final DateTime updatedAt;
  final User? sender;
  final User? receiver;
  final Group? group;

  ChatMessage({
    required this.id,
    required this.senderId,
    this.receiverId,
    this.groupId,
    required this.content,
    this.type = MessageType.text,
    this.isRead = false,
    required this.createdAt,
    required this.updatedAt,
    this.sender,
    this.receiver,
    this.group,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      senderId: json['sender_id'],
      receiverId: json['receiver_id'],
      groupId: json['group_id'],
      content: json['content'],
      type: MessageType.values.firstWhere(
        (type) => type.name == json['type'],
        orElse: () => MessageType.text,
      ),
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      sender: json['sender'] != null ? User.fromJson(json['sender']) : null,
      receiver: json['receiver'] != null ? User.fromJson(json['receiver']) : null,
      group: json['group'] != null ? Group.fromJson(json['group']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'group_id': groupId,
      'content': content,
      'type': type.name,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'sender': sender?.toJson(),
      'receiver': receiver?.toJson(),
      'group': group?.toJson(),
    };
  }

  bool get isFromMe => senderId == 'current_user_id'; // Will be set by provider
}

class Conversation {
  final String id;
  final String? otherUserId;
  final String? groupId;
  final ChatMessage? lastMessage;
  final int unreadCount;
  final DateTime lastActivity;
  final User? otherUser;
  final Group? group;

  Conversation({
    required this.id,
    this.otherUserId,
    this.groupId,
    this.lastMessage,
    this.unreadCount = 0,
    required this.lastActivity,
    this.otherUser,
    this.group,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] ?? '',
      otherUserId: json['other_user_id'] ?? json['otherUserId'],
      groupId: json['group_id'] ?? json['groupId'],
      lastMessage: json['last_message'] != null ? ChatMessage.fromJson(json['last_message']) : null,
      unreadCount: json['unread_count'] ?? 0,
      lastActivity: json['last_activity'] != null ? DateTime.parse(json['last_activity']) : DateTime.now(),
      otherUser: json['other_user'] != null ? User.fromJson(json['other_user']) : null,
      group: json['group'] != null ? Group.fromJson(json['group']) : null,
    );
  }

  String get displayName {
    if (otherUser != null) return otherUser!.name;
    if (group != null) return group!.name;
    return 'Unknown';
  }

  String get displayAvatar {
    if (otherUser != null) return otherUser!.profilePicture ?? '';
    if (group != null) return group!.avatar ?? '';
    return '';
  }

  String get lastMessageContent {
    if (lastMessage != null) return lastMessage!.content;
    return 'No messages';
  }
}

class ChatHistory {
  final List<ChatMessage> messages;
  final int currentPage;
  final int totalPages;
  final int totalMessages;

  ChatHistory({
    required this.messages,
    required this.currentPage,
    required this.totalPages,
    required this.totalMessages,
  });

  factory ChatHistory.fromJson(Map<String, dynamic> json) {
    return ChatHistory(
      messages: (json['messages'] as List)
          .map((message) => ChatMessage.fromJson(message))
          .toList(),
      currentPage: json['current_page'] ?? 1,
      totalPages: json['total_pages'] ?? 1,
      totalMessages: json['total_messages'] ?? 0,
    );
  }
}
