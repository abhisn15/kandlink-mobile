class ApiEndpoints {
  // Base URL
  static const String baseUrl = 'http://localhost:5000/api';

  // Authentication
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String refreshToken = '/auth/refresh-token';
  static const String logout = '/auth/logout';
  static const String verifyEmail = '/auth/verify-email';
  static const String verifyWhatsapp = '/auth/verify-whatsapp';
  static const String resendVerification = '/auth/resend-verification';

  // User
  static const String getProfile = '/users/me';
  static const String updateProfile = '/users/me';
  static const String updateFcmToken = '/users/fcm-token';

  // Areas
  static const String getAreas = '/areas';

  // Assignment
  static const String assignPIC = '/assign';
  static const String getCurrentPIC = '/assign/current';
  static const String getCandidatesForPIC = '/assign/pic/candidates';
  static const String redirectCandidate = '/assign/pic/redirect';
  static const String getAssignmentHistory = '/assign/history';

  // Chat
  static const String sendMessage = '/chat/send';
  static const String sendGroupMessage = '/chat/group/send';
  static const String getChatHistory = '/chat/history';
  static const String getConversations = '/chat/conversations';
  static const String getUnreadMessages = '/chat/unread';
  static const String markAsRead = '/chat/mark-read';

  // Groups
  static const String createGroup = '/groups/create';
  static const String addMembers = '/groups/add-members';
  static const String getMyGroups = '/groups/my';
  static String getGroupMembers(String groupId) => '/groups/$groupId/members';

  // Socket events
  static const String socketUrl = 'http://localhost:5000';
}
