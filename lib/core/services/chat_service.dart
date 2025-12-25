import '../models/chat.dart';
import 'api_service.dart';
import '../constants/api_endpoints.dart';

class ChatService {
  final ApiService _apiService = ApiService();

  // Send personal message
  Future<ChatMessage> sendMessage(String receiverId, String message, {String type = 'text'}) async {
    final data = {
      'receiverId': receiverId,
      'message': message,
      'type': type,
    };

    final response = await _apiService.post(ApiEndpoints.sendMessage, data: data);
    return ChatMessage.fromJson(response.data['data']);
  }

  // Send group message
  Future<ChatMessage> sendGroupMessage(String groupId, String message, {String type = 'text'}) async {
    final data = {
      'groupId': groupId,
      'message': message,
      'type': type,
    };

    final response = await _apiService.post(ApiEndpoints.sendGroupMessage, data: data);
    return ChatMessage.fromJson(response.data['data']);
  }

  // Get chat history
  Future<ChatHistory> getChatHistory({
    String? otherUserId,
    String? groupId,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final queryParameters = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

      if (otherUserId != null) queryParameters['otherUserId'] = otherUserId;
      if (groupId != null) queryParameters['groupId'] = groupId;

      final response = await _apiService.get(ApiEndpoints.getChatHistory, queryParameters: queryParameters);
      final responseData = response.data;

      // Debug response structure
      print('🔍 ChatService.getChatHistory - Response: $responseData');

      if (responseData['success'] == true) {
        // Handle both Map and List responses from backend
        final data = responseData['data'];
        if (data is Map) {
          return ChatHistory.fromJson(data as Map<String, dynamic>);
        } else if (data is List) {
          // If backend sends messages directly as array, wrap in ChatHistory
          return ChatHistory(
            messages: data.map((msg) => ChatMessage.fromJson(msg)).toList(),
            currentPage: responseData['pagination']?['page'] ?? 1,
            totalPages: responseData['pagination']?['totalPages'] ?? 1,
            totalMessages: responseData['pagination']?['total'] ?? data.length,
          );
        } else {
          throw Exception('Unexpected data format from chat history API');
        }
      } else {
        throw Exception(responseData['message'] ?? 'Failed to get chat history');
      }
    } catch (e) {
      print('❌ ChatService.getChatHistory error: $e');
      rethrow;
    }
  }

  // Get conversations list
  Future<List<Conversation>> getConversations() async {
    try {
    final response = await _apiService.get(ApiEndpoints.getConversations);
      final responseData = response.data;

      // Debug response structure
      print('🔍 ChatService.getConversations - Response: $responseData');

      if (responseData['success'] == true) {
        final conversationsData = responseData['data'];
        if (conversationsData is List) {
    return conversationsData.map((conv) => Conversation.fromJson(conv)).toList();
        } else {
          throw Exception('Conversations data is not a list: $conversationsData');
        }
      } else {
        throw Exception(responseData['message'] ?? 'Failed to get conversations');
      }
    } catch (e) {
      print('❌ ChatService.getConversations error: $e');
      rethrow;
    }
  }

  // Get unread messages
  Future<Map<String, int>> getUnreadMessages() async {
    final response = await _apiService.get(ApiEndpoints.getUnreadMessages);
    return Map<String, int>.from(response.data['data']);
  }

  // Mark messages as read
  Future<void> markAsRead(List<String> messageIds) async {
    final data = {'messageIds': messageIds};
    await _apiService.post(ApiEndpoints.markAsRead, data: data);
  }
}
