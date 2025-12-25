import 'dart:async';
import 'package:flutter/foundation.dart';
import 'local_storage_service.dart';
import 'offline_service.dart';
import 'api_service.dart';
import '../models/chat.dart';
import '../models/user.dart';
import '../models/assignment.dart';
import '../models/group.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final LocalStorageService _localStorage = LocalStorageService();
  final OfflineService _offlineService = OfflineService();
  final ApiService _apiService = ApiService();

  Timer? _syncTimer;
  bool _isSyncing = false;

  // Getters
  bool get isSyncing => _isSyncing;

  // Initialize sync service
  Future<void> initialize() async {
    await _localStorage.initialize();

    // Start periodic sync when online
    _offlineService.connectionStream.listen((isOnline) {
      if (isOnline) {
        _startPeriodicSync();
        _performFullSync();
      } else {
        _stopPeriodicSync();
      }
    });
  }

  // Start periodic sync
  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (_offlineService.isOnline) {
        _performIncrementalSync();
      }
    });
  }

  // Stop periodic sync
  void _stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  // Perform full sync (when coming back online)
  Future<void> _performFullSync() async {
    if (_isSyncing) return;

    _isSyncing = true;
    debugPrint('Starting full sync...');

    try {
      // Sync conversations and messages
      await _syncConversations();

      // Sync assignments
      await _syncAssignments();

      // Update sync timestamp
      await _localStorage.setLastSyncTimestamp(DateTime.now());

      debugPrint('Full sync completed');
    } catch (e) {
      debugPrint('Full sync failed: $e');
    } finally {
      _isSyncing = false;
    }
  }

  // Perform incremental sync
  Future<void> _performIncrementalSync() async {
    if (_isSyncing) return;

    _isSyncing = true;
    debugPrint('Starting incremental sync...');

    try {
      final lastSync = _localStorage.getLastSyncTimestamp();
      if (lastSync != null) {
        // Only sync data changed since last sync
        await _syncRecentMessages(lastSync);
      }

      await _localStorage.setLastSyncTimestamp(DateTime.now());
      debugPrint('Incremental sync completed');
    } catch (e) {
      debugPrint('Incremental sync failed: $e');
    } finally {
      _isSyncing = false;
    }
  }

  // Sync conversations
  Future<void> _syncConversations() async {
    try {
      // Get conversations from API
      final apiResponse = await _apiService.get('/chat/conversations');
      if (apiResponse.data['success'] == true) {
        final conversationsData = apiResponse.data['data'] as List;
        final apiConversations = conversationsData.map((conv) {
          final convMap = conv as Map<String, dynamic>;
          return Conversation(
            id: convMap['id'],
            otherUserId: convMap['other_user_id'],
            groupId: convMap['group_id'],
            lastMessage: ChatMessage.fromJson(convMap['last_message']),
            unreadCount: convMap['unread_count'] ?? 0,
            lastActivity: DateTime.parse(convMap['last_activity']),
            otherUser: convMap['other_user'] != null
                ? User.fromJson(convMap['other_user'])
                : null,
            group: convMap['group'] != null
                ? Group.fromJson(convMap['group'])
                : null,
          );
        }).toList();

        // Cache conversations locally
        await _localStorage.cacheConversations(apiConversations);
      }
    } catch (e) {
      debugPrint('Failed to sync conversations: $e');
    }
  }

  // Sync assignments
  Future<void> _syncAssignments() async {
    try {
      // Get current assignment from API
      final apiResponse = await _apiService.get('/assign/current');
      if (apiResponse.data['success'] == true && apiResponse.data['data'] != null) {
        final assignment = Assignment.fromJson(apiResponse.data['data']);

        // Cache assignment locally
        await _localStorage.cacheAssignments([assignment]);
      }
    } catch (e) {
      debugPrint('Failed to sync assignments: $e');
    }
  }

  // Sync recent messages
  Future<void> _syncRecentMessages(DateTime since) async {
    try {
      // Get conversations from cache
      final conversations = _localStorage.getCachedConversations();

      for (final conversation in conversations) {
        try {
          // Get recent messages for this conversation
          final queryParams = {
            'since': since.toIso8601String(),
            'limit': '50',
          };

          dynamic apiResponse;
          if (conversation.groupId != null) {
            apiResponse = await _apiService.get('/chat/history?groupId=${conversation.groupId}', queryParameters: queryParams);
          } else {
            apiResponse = await _apiService.get('/chat/history?otherUserId=${conversation.otherUserId}', queryParameters: queryParams);
          }

          if (apiResponse.data['success'] == true) {
            final messagesData = apiResponse.data['data']['messages'] as List;
            final newMessages = messagesData.map((msg) => ChatMessage.fromJson(msg)).toList();

            if (newMessages.isNotEmpty) {
              // Get existing cached messages
              final existingMessages = _localStorage.getCachedMessages(conversation.id);

              // Merge messages (avoiding duplicates)
              final allMessages = [...existingMessages];
              for (final newMsg in newMessages) {
                if (!allMessages.any((existing) => existing.id == newMsg.id)) {
                  allMessages.add(newMsg);
                }
              }

              // Sort by timestamp
              allMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

              // Cache merged messages
              await _localStorage.cacheMessages(conversation.id, allMessages);
            }
          }
        } catch (e) {
          debugPrint('Failed to sync messages for conversation ${conversation.id}: $e');
        }
      }
    } catch (e) {
      debugPrint('Failed to sync recent messages: $e');
    }
  }

  // Force sync all data
  Future<void> forceFullSync() async {
    if (!_offlineService.isOnline) {
      throw Exception('Cannot sync while offline');
    }

    await _performFullSync();
  }

  // Get cached data for offline use
  List<Conversation> getCachedConversations() {
    return _localStorage.getCachedConversations();
  }

  List<ChatMessage> getCachedMessages(String chatId) {
    return _localStorage.getCachedMessages(chatId);
  }

  Assignment? getCachedCurrentAssignment() {
    final assignments = _localStorage.getCachedAssignments();
    return assignments.isNotEmpty ? assignments.first : null;
  }

  // Clear all cached data
  Future<void> clearCache() async {
    await _localStorage.clearAllCache();
  }

  // Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    final conversations = _localStorage.getCachedConversations();
    final cacheSize = await _localStorage.getCacheSize();
    final lastSync = _localStorage.getLastSyncTimestamp();

    return {
      'conversationsCount': conversations.length,
      'cacheSize': cacheSize,
      'lastSync': lastSync?.toIso8601String(),
      'isOnline': _offlineService.isOnline,
      'offlineQueueLength': _offlineService.queueLength,
    };
  }

  // Dispose
  void dispose() {
    _stopPeriodicSync();
  }
}
