import '../models/chat.dart';
import 'api_service.dart';
import '../constants/api_endpoints.dart';

class ChatService {
  final ApiService _apiService = ApiService();

  // Send personal message
  Future<ChatMessage> sendMessage(String receiverId, String message, {String type = 'text'}) async {
    final body = {
      'receiverId': receiverId,
      'message': message,
      'type': type,
    };

    final response = await _apiService.post(ApiEndpoints.sendMessage, body: body);
    return ChatMessage.fromJson(response['data']);
  }

  // Send group message
  Future<ChatMessage> sendGroupMessage(String groupId, String message, {String type = 'text'}) async {
    final body = {
      'groupId': groupId,
      'message': message,
      'type': type,
    };

    final response = await _apiService.post(ApiEndpoints.sendGroupMessage, body: body);
    return ChatMessage.fromJson(response['data']);
  }

  // Get chat history
  Future<ChatHistory> getChatHistory({
    String? otherUserId,
    String? groupId,
    int page = 1,
    int limit = 50,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (otherUserId != null) queryParams['otherUserId'] = otherUserId;
    if (groupId != null) queryParams['groupId'] = groupId;

    final response = await _apiService.get(ApiEndpoints.getChatHistory, queryParams: queryParams);
    return ChatHistory.fromJson(response['data']);
  }

  // Get conversations list
  Future<List<Conversation>> getConversations() async {
    final response = await _apiService.get(ApiEndpoints.getConversations);
    final conversationsData = response['data'] as List;
    return conversationsData.map((conv) => Conversation.fromJson(conv)).toList();
  }

  // Get unread messages
  Future<Map<String, int>> getUnreadMessages() async {
    final response = await _apiService.get(ApiEndpoints.getUnreadMessages);
    return Map<String, int>.from(response['data']);
  }

  // Mark messages as read
  Future<void> markAsRead(List<String> messageIds) async {
    final body = {'messageIds': messageIds};
    await _apiService.post(ApiEndpoints.markAsRead, body: body);
  }
}
