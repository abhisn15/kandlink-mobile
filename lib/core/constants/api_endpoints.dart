import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiEndpoints {
  // Base URL
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:5000/api';

  // Authentication
  static String get register => dotenv.env['API_AUTH_REGISTER'] ?? '/auth/register';
  static String get login => dotenv.env['API_AUTH_LOGIN'] ?? '/auth/login';
  static String get refreshToken => dotenv.env['API_AUTH_REFRESH_TOKEN'] ?? '/auth/refresh-token';
  static String get logout => dotenv.env['API_AUTH_LOGOUT'] ?? '/auth/logout';
  static String get verifyEmail => dotenv.env['API_AUTH_VERIFY_EMAIL'] ?? '/auth/verify-email';
  static String get verifyWhatsapp => dotenv.env['API_AUTH_VERIFY_WHATSAPP'] ?? '/auth/verify-whatsapp';
  static String get resendVerification => dotenv.env['API_AUTH_RESEND_VERIFICATION'] ?? '/auth/resend-verification';

  // User
  static String get getProfile => dotenv.env['API_USER_PROFILE'] ?? '/users/me';
  static String get updateProfile => dotenv.env['API_USER_UPDATE_PROFILE'] ?? '/users/me';
  static String get updateFcmToken => dotenv.env['API_USER_UPDATE_FCM_TOKEN'] ?? '/users/fcm-token';

  // Areas
  static String get getAreas => dotenv.env['API_AREAS_GET'] ?? '/areas';

  // Assignment
  static String get assignPIC => dotenv.env['API_ASSIGN_PIC'] ?? '/assign';
  static String get getCurrentPIC => dotenv.env['API_ASSIGN_CURRENT'] ?? '/assign/current';
  static String get getCandidatesForPIC => dotenv.env['API_ASSIGN_PIC_CANDIDATES'] ?? '/assign/pic/candidates';
  static String get redirectCandidate => dotenv.env['API_ASSIGN_REDIRECT_CANDIDATE'] ?? '/assign/pic/redirect';
  static String get getAssignmentHistory => dotenv.env['API_ASSIGN_HISTORY'] ?? '/assign/history';

  // Chat
  static String get sendMessage => dotenv.env['API_CHAT_SEND_MESSAGE'] ?? '/chat/send';
  static String get sendGroupMessage => dotenv.env['API_CHAT_SEND_GROUP_MESSAGE'] ?? '/chat/group/send';
  static String get getChatHistory => dotenv.env['API_CHAT_HISTORY'] ?? '/chat/history';
  static String get getConversations => dotenv.env['API_CHAT_CONVERSATIONS'] ?? '/chat/conversations';
  static String get getUnreadMessages => dotenv.env['API_CHAT_UNREAD'] ?? '/chat/unread';
  static String get markAsRead => dotenv.env['API_CHAT_MARK_READ'] ?? '/chat/mark-read';

  // Groups
  static String get createGroup => dotenv.env['API_GROUPS_CREATE'] ?? '/groups/create';
  static String get addMembers => dotenv.env['API_GROUPS_ADD_MEMBERS'] ?? '/groups/add-members';
  static String get getMyGroups => dotenv.env['API_GROUPS_MY'] ?? '/groups/my';
  static String getGroupMembers(String groupId) => '/groups/$groupId/members';

  // Socket events
  static String get socketUrl => dotenv.env['SOCKET_URL'] ?? 'http://localhost:5000';
}
