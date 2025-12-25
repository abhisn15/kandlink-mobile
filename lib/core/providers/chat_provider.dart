import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/chat.dart' as chat_models;
import '../models/user.dart';
import '../models/chat.dart';
import '../services/chat_service.dart';
import '../services/socket_service.dart';
import '../services/local_storage_service.dart';
import '../services/offline_service.dart';
import '../database/database.dart';
import '../services/logger_service.dart';

class ChatProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();
  final SocketService _socketService = SocketService();
  final LocalStorageService _localStorage = LocalStorageService();
  final OfflineService _offlineService = OfflineService();
  final AppDatabase _database = AppDatabase();

  List<chat_models.Conversation> _conversations = [];
  List<ChatMessage> _messages = [];
  Map<String, int> _unreadCounts = {};
  bool _isLoading = false;
  bool _isConnected = false;
  String? _error;
  String? _currentChatId; // userId or groupId

  // Getters
  List<chat_models.Conversation> get conversations => _conversations;
  List<ChatMessage> get messages => _messages;
  Map<String, int> get unreadCounts => _unreadCounts;
  bool get isLoading => _isLoading;
  bool get isConnected => _isConnected;
  String? get error => _error;
  String? get currentChatId => _currentChatId;
  int get totalUnread => _unreadCounts.values.fold(0, (sum, count) => sum + count);

  // Initialize socket connection
  Future<void> initializeSocket(String userId, String token) async {
    try {
      await _socketService.connect(userId, token);

      // Set up event listeners
      _socketService.setMessageListener((data) {
        try {
          // Parse the message data and handle it
          final messageData = data as Map<String, dynamic>;
          if (messageData.containsKey('message')) {
            final message = ChatMessage.fromJson(messageData['message']);
            _handleIncomingMessage(message);
          }
        } catch (e) {
          debugPrint('Error parsing message: $e');
        }
      });

      _socketService.setGroupMessageListener((data) {
        try {
          final messageData = data as Map<String, dynamic>;
          if (messageData.containsKey('message')) {
            final message = ChatMessage.fromJson(messageData['message']);
            _handleIncomingMessage(message);
          }
        } catch (e) {
          debugPrint('Error parsing group message: $e');
        }
      });

      // Check connection status periodically
      _checkConnectionStatus();
    } catch (e) {
      debugPrint('Socket initialization error: $e');
      _error = e.toString();
      notifyListeners();
    }
  }

  void _checkConnectionStatus() {
    // Check connection status and update UI
    final wasConnected = _isConnected;
    _isConnected = _socketService.isConnected;

    if (wasConnected != _isConnected) {
      notifyListeners();
    }

    // Check again after 1 second
    Future.delayed(const Duration(seconds: 1), _checkConnectionStatus);
  }

  void _handleIncomingMessage(ChatMessage message) {
    // Schedule notification to next frame to avoid calling during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Add to messages if it's the current chat
      if (_currentChatId != null &&
          ((message.receiverId == _currentChatId) ||
           (message.groupId == _currentChatId) ||
           (message.senderId == _currentChatId))) {
        _messages.add(message);
      }

      // Update conversations
      _updateConversationsWithMessage(message);

      // Update unread counts if not in current chat
      if (_currentChatId == null ||
          (_currentChatId != message.senderId && _currentChatId != message.groupId)) {
        final key = message.groupId ?? message.senderId!;
        _unreadCounts[key] = (_unreadCounts[key] ?? 0) + 1;
      }

      // Notify listeners once after all updates
      notifyListeners();
    });
  }

  void _updateConversationsWithMessage(ChatMessage message) {
    // Find or create conversation
    chat_models.Conversation? conversation = _conversations.firstWhere(
      (conv) => conv.id == (message.groupId ?? message.senderId),
      orElse: () => chat_models.Conversation(
        id: message.groupId ?? message.senderId!,
        otherUserId: message.groupId == null ? message.senderId : null,
        groupId: message.groupId,
        lastMessage: message,
        lastActivity: message.createdAt,
        otherUser: message.sender,
        group: message.group,
      ),
    );

    // Update conversation
    if (_conversations.contains(conversation)) {
      final index = _conversations.indexOf(conversation);
      _conversations[index] = chat_models.Conversation(
        id: conversation.id,
        otherUserId: conversation.otherUserId,
        groupId: conversation.groupId,
        lastMessage: message,
        unreadCount: conversation.unreadCount,
        lastActivity: message.createdAt,
        otherUser: conversation.otherUser,
        group: conversation.group,
      );
    } else {
      _conversations.insert(0, chat_models.Conversation(
        id: message.groupId ?? message.senderId!,
        otherUserId: message.groupId == null ? message.senderId : null,
        groupId: message.groupId,
        lastMessage: message,
        lastActivity: message.createdAt,
        otherUser: message.sender,
        group: message.group,
      ));
    }

    // Sort conversations by last activity
    _conversations.sort((a, b) => b.lastActivity.compareTo(a.lastActivity));
    notifyListeners();
  }

  void _markMessagesAsRead(List<String> messageIds) {
    for (var message in _messages) {
      if (messageIds.contains(message.id)) {
        // Note: Since ChatMessage is immutable, we might need to create a new list
        // For simplicity, we'll just mark as read in the current session
      }
    }
    notifyListeners();
  }

  // Load conversations
  Future<bool> loadConversations() async {
    _setLoading(true);
    _setError(null);

    try {
      if (_offlineService.isOnline) {
        // Online: Fetch from API
        final conversations = await _chatService.getConversations();
        _conversations = conversations;

        // Cache conversations locally
        await _localStorage.cacheConversations(conversations);
      } else {
        // Offline: Load from cache
        _conversations = _localStorage.getCachedConversations();
        debugPrint('Loaded ${_conversations.length} conversations from cache');
      }

      _setLoading(false);
      return true;
    } catch (e) {
      // If API fails, try to load from cache
      if (_offlineService.isOnline) {
        _conversations = _localStorage.getCachedConversations();
        debugPrint('API failed, loaded ${_conversations.length} conversations from cache');
      }

      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Load messages for a specific chat
  Future<bool> loadMessages({
    String? otherUserId,
    String? groupId,
    int page = 1,
    int limit = 50,
  }) async {
    _setLoading(true);
    _setError(null);

    final chatId = otherUserId ?? groupId;

    try {
      if (_offlineService.isOnline) {
        // Online: Fetch from API
        final chatHistory = await _chatService.getChatHistory(
          otherUserId: otherUserId,
          groupId: groupId,
          page: page,
          limit: limit,
        );

        if (page == 1) {
          _messages = chatHistory.messages;
        } else {
          _messages.addAll(chatHistory.messages);
        }

        // Cache messages locally
        if (chatId != null) {
          await _localStorage.cacheMessages(chatId, _messages);
        }
      } else {
        // Offline: Load from cache
        if (chatId != null) {
          _messages = _localStorage.getCachedMessages(chatId);
          debugPrint('Loaded ${_messages.length} messages from cache for $chatId');
        }
      }

      _currentChatId = chatId;
      _setLoading(false);
      return true;
    } catch (e) {
      // If API fails, try to load from cache
      if (_offlineService.isOnline && chatId != null) {
        _messages = _localStorage.getCachedMessages(chatId);
        debugPrint('API failed, loaded ${_messages.length} messages from cache for $chatId');
      }

      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Send message
  Future<bool> sendMessage(String receiverId, String content, {String type = 'text'}) async {
    // Create message object for immediate UI feedback
    final tempMessage = ChatMessage(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      senderId: 'current_user', // Will be set properly
      receiverId: receiverId,
      content: content,
      type: type == 'text' ? MessageType.text : MessageType.text, // Default to text
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Add to local messages immediately for instant UI feedback
    _messages.add(tempMessage);
    _updateConversationsWithMessage(tempMessage);
    notifyListeners();

    if (_offlineService.isOnline) {
      // Online: Send immediately
      try {
        final message = await _chatService.sendMessage(receiverId, content, type: type);

        // Replace temp message with real message
        _messages.remove(tempMessage);
        _messages.add(message);
        _updateConversationsWithMessage(message);

        // Cache messages locally
        await _localStorage.cacheMessages(receiverId, _messages);

        // Emit via socket for real-time delivery
        if (_socketService.isConnected) {
          _socketService.sendMessage(receiverId, content, type: type);
        }

        notifyListeners();
        return true;
      } catch (e) {
        // Remove temp message on failure
        _messages.remove(tempMessage);
        _setError(e.toString());
        notifyListeners();
        return false;
      }
    } else {
      // Offline: Queue for later
      await _offlineService.queueOfflineRequest(
        method: 'POST',
        url: '/chat/send',
        body: {
          'receiverId': receiverId,
          'message': content,
          'type': type,
        },
        requestId: 'send_message_${DateTime.now().millisecondsSinceEpoch}',
      );

      // Cache messages locally
      await _localStorage.cacheMessages(receiverId, _messages);

      notifyListeners();
      return true; // Return true for offline queued messages
    }
  }

  // Send group message
  Future<bool> sendGroupMessage(String groupId, String content, {String type = 'text'}) async {
    try {
      final message = await _chatService.sendGroupMessage(groupId, content, type: type);

      // Add to local messages immediately for instant UI feedback
      _messages.add(message);
      _updateConversationsWithMessage(message);

      // Emit via socket for real-time delivery
      if (_socketService.isConnected) {
        _socketService.sendGroupMessage(groupId, content, type: type);
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Mark messages as read
  Future<bool> markMessagesAsRead(List<String> messageIds) async {
    try {
      await _chatService.markAsRead(messageIds);

      // Update local unread counts
      if (_currentChatId != null) {
        _unreadCounts.remove(_currentChatId);
      }

      // Emit via socket
      if (_socketService.isConnected) {
        _socketService.markMessagesAsRead(messageIds);
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Load unread counts
  Future<bool> loadUnreadCounts() async {
    try {
      final unread = await _chatService.getUnreadMessages();
      _unreadCounts = unread;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Set current chat (for marking messages as read when viewing)
  void setCurrentChat(String chatId) {
    _currentChatId = chatId;

    // Mark messages as read for this chat
    if (_unreadCounts.containsKey(chatId)) {
      final unreadCount = _unreadCounts[chatId]!;
      if (unreadCount > 0) {
        // Get the last N message IDs to mark as read
        final messageIds = _messages
            .where((msg) => !msg.isRead)
            .take(unreadCount)
            .map((msg) => msg.id)
            .toList();

        if (messageIds.isNotEmpty) {
          markMessagesAsRead(messageIds);
        }
      }
    }
  }

  // Clear current chat
  void clearCurrentChat() {
    _currentChatId = null;
  }

  // Add typing indicator methods
  void startTyping(String chatId) {
    if (_socketService.socket != null && _socketService.socket!.connected) {
      _socketService.socket!.emit('typing_start', {'chatId': chatId});
    }
  }

  void stopTyping(String chatId) {
    if (_socketService.socket != null && _socketService.socket!.connected) {
      _socketService.socket!.emit('typing_stop', {'chatId': chatId});
    }
  }

  // Utility methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    // Schedule notification to next frame to avoid calling during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Cleanup
  void disconnect() {
    _socketService.disconnect();
    _isConnected = false;
    _conversations.clear();
    _messages.clear();
    _unreadCounts.clear();
    _currentChatId = null;
    notifyListeners();
  }

  // Add message to conversation (for optimistic updates)
  void addMessage(ChatMessage message) {
    _messages.add(message);
    _updateConversationsWithMessage(message);
    notifyListeners();
  }

  // Remove message (for error handling)
  void removeMessage(String messageId) {
    _messages.removeWhere((msg) => msg.id == messageId);
    notifyListeners();
  }
}
