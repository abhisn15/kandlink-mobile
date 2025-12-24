import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/chat.dart';
import '../models/user.dart';
import '../models/area.dart';
import '../models/assignment.dart';
import '../models/group.dart';

class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  static const String _userKey = 'cached_user';
  static const String _areasKey = 'cached_areas';
  static const String _conversationsKey = 'cached_conversations';
  static const String _messagesKey = 'cached_messages_';
  static const String _assignmentsKey = 'cached_assignments';
  static const String _groupsKey = 'cached_groups';
  static const String _lastSyncKey = 'last_sync_timestamp';

  late SharedPreferences _prefs;

  // Initialize
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // User caching
  Future<void> cacheUser(User user) async {
    try {
      final userJson = json.encode(user.toJson());
      await _prefs.setString(_userKey, userJson);
    } catch (e) {
      debugPrint('Failed to cache user: $e');
    }
  }

  User? getCachedUser() {
    try {
      final userJson = _prefs.getString(_userKey);
      if (userJson != null) {
        final userMap = json.decode(userJson) as Map<String, dynamic>;
        return User.fromJson(userMap);
      }
    } catch (e) {
      debugPrint('Failed to get cached user: $e');
    }
    return null;
  }

  // Areas caching
  Future<void> cacheAreas(List<Area> areas) async {
    try {
      final areasJson = json.encode(areas.map((area) => area.toJson()).toList());
      await _prefs.setString(_areasKey, areasJson);
    } catch (e) {
      debugPrint('Failed to cache areas: $e');
    }
  }

  List<Area> getCachedAreas() {
    try {
      final areasJson = _prefs.getString(_areasKey);
      if (areasJson != null) {
        final areasList = json.decode(areasJson) as List;
        return areasList.map((area) => Area.fromJson(area)).toList();
      }
    } catch (e) {
      debugPrint('Failed to get cached areas: $e');
    }
    return [];
  }

  // Conversations caching
  Future<void> cacheConversations(List<Conversation> conversations) async {
    try {
      final conversationsJson = json.encode(
        conversations.map((conv) => {
          'id': conv.id,
          'otherUserId': conv.otherUserId,
          'groupId': conv.groupId,
          'lastMessage': conv.lastMessage.toJson(),
          'unreadCount': conv.unreadCount,
          'lastActivity': conv.lastActivity.toIso8601String(),
          'otherUser': conv.otherUser?.toJson(),
          'group': conv.group?.toJson(),
        }).toList()
      );
      await _prefs.setString(_conversationsKey, conversationsJson);
    } catch (e) {
      debugPrint('Failed to cache conversations: $e');
    }
  }

  List<Conversation> getCachedConversations() {
    try {
      final conversationsJson = _prefs.getString(_conversationsKey);
      if (conversationsJson != null) {
        final conversationsList = json.decode(conversationsJson) as List;
        return conversationsList.map((conv) {
          final convMap = conv as Map<String, dynamic>;
          return Conversation(
            id: convMap['id'],
            otherUserId: convMap['otherUserId'],
            groupId: convMap['groupId'],
            lastMessage: ChatMessage.fromJson(convMap['lastMessage']),
            unreadCount: convMap['unreadCount'] ?? 0,
            lastActivity: DateTime.parse(convMap['lastActivity']),
            otherUser: convMap['otherUser'] != null
                ? User.fromJson(convMap['otherUser'])
                : null,
            group: convMap['group'] != null
                ? Group.fromJson(convMap['group'])
                : null,
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('Failed to get cached conversations: $e');
    }
    return [];
  }

  // Messages caching (per chat)
  Future<void> cacheMessages(String chatId, List<ChatMessage> messages) async {
    try {
      final messagesJson = json.encode(
        messages.map((msg) => msg.toJson()).toList()
      );
      await _prefs.setString('$_messagesKey$chatId', messagesJson);
    } catch (e) {
      debugPrint('Failed to cache messages for $chatId: $e');
    }
  }

  List<ChatMessage> getCachedMessages(String chatId) {
    try {
      final messagesJson = _prefs.getString('$_messagesKey$chatId');
      if (messagesJson != null) {
        final messagesList = json.decode(messagesJson) as List;
        return messagesList.map((msg) => ChatMessage.fromJson(msg)).toList();
      }
    } catch (e) {
      debugPrint('Failed to get cached messages for $chatId: $e');
    }
    return [];
  }

  // Assignments caching
  Future<void> cacheAssignments(List<Assignment> assignments) async {
    try {
      final assignmentsJson = json.encode(
        assignments.map((assignment) => assignment.toJson()).toList()
      );
      await _prefs.setString(_assignmentsKey, assignmentsJson);
    } catch (e) {
      debugPrint('Failed to cache assignments: $e');
    }
  }

  List<Assignment> getCachedAssignments() {
    try {
      final assignmentsJson = _prefs.getString(_assignmentsKey);
      if (assignmentsJson != null) {
        final assignmentsList = json.decode(assignmentsJson) as List;
        return assignmentsList.map((assignment) => Assignment.fromJson(assignment)).toList();
      }
    } catch (e) {
      debugPrint('Failed to get cached assignments: $e');
    }
    return [];
  }

  // Groups caching
  Future<void> cacheGroups(List<Group> groups) async {
    try {
      final groupsJson = json.encode(
        groups.map((group) => group.toJson()).toList()
      );
      await _prefs.setString(_groupsKey, groupsJson);
    } catch (e) {
      debugPrint('Failed to cache groups: $e');
    }
  }

  List<Group> getCachedGroups() {
    try {
      final groupsJson = _prefs.getString(_groupsKey);
      if (groupsJson != null) {
        final groupsList = json.decode(groupsJson) as List;
        return groupsList.map((group) => Group.fromJson(group)).toList();
      }
    } catch (e) {
      debugPrint('Failed to get cached groups: $e');
    }
    return [];
  }

  // Sync timestamp
  Future<void> setLastSyncTimestamp(DateTime timestamp) async {
    await _prefs.setString(_lastSyncKey, timestamp.toIso8601String());
  }

  DateTime? getLastSyncTimestamp() {
    final timestampStr = _prefs.getString(_lastSyncKey);
    if (timestampStr != null) {
      try {
        return DateTime.parse(timestampStr);
      } catch (e) {
        debugPrint('Failed to parse sync timestamp: $e');
      }
    }
    return null;
  }

  // Clear all cached data
  Future<void> clearAllCache() async {
    await _prefs.remove(_userKey);
    await _prefs.remove(_areasKey);
    await _prefs.remove(_conversationsKey);
    await _prefs.remove(_assignmentsKey);
    await _prefs.remove(_groupsKey);

    // Clear all message caches
    final keys = _prefs.getKeys();
    final messageKeys = keys.where((key) => key.startsWith(_messagesKey)).toList();
    for (final key in messageKeys) {
      await _prefs.remove(key);
    }

    await _prefs.remove(_lastSyncKey);
    debugPrint('All cached data cleared');
  }

  // Clear specific chat messages
  Future<void> clearChatMessages(String chatId) async {
    await _prefs.remove('$_messagesKey$chatId');
  }

  // Get cache size (approximate)
  Future<int> getCacheSize() async {
    final keys = _prefs.getKeys();
    int totalSize = 0;

    for (final key in keys) {
      final value = _prefs.getString(key);
      if (value != null) {
        totalSize += value.length * 2; // Rough estimate: 2 bytes per character
      }
    }

    return totalSize;
  }
}
