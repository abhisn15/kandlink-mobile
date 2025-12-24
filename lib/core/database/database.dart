import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

part 'database.g.dart';

// Database configuration
QueryExecutor _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'kandlink.sqlite'));
    return NativeDatabase(file);
  });
}

@DriftDatabase(tables: [Messages, ChatConversations, Users, Groups])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // Messages operations
  Future<List<Message>> getMessagesForChat(String chatId, {int? limit, int? offset}) {
    final query = select(messages)
      ..where((msg) => msg.chatId.equals(chatId))
      ..orderBy([(msg) => OrderingTerm.desc(msg.createdAt)]);

    if (limit != null) {
      query.limit(limit);
    }
    if (offset != null && offset > 0) {
      query.limit(limit ?? 50, offset: offset);
    }

    return query.get();
  }

  Future<int> saveMessage(MessagesCompanion message) {
    return into(messages).insert(message);
  }

  Future<bool> updateMessageReadStatus(String messageId, bool isRead) {
    return (update(messages)
          ..where((msg) => msg.id.equals(messageId)))
        .write(MessagesCompanion(isRead: Value(isRead)))
        .then((rowsAffected) => rowsAffected > 0);
  }

  Future<int> deleteMessage(String messageId) {
    return (delete(messages)..where((msg) => msg.id.equals(messageId))).go();
  }

  Future<void> deleteMessagesForChat(String chatId) {
    return (delete(messages)..where((msg) => msg.chatId.equals(chatId))).go();
  }

  // Conversations operations
  Future<List<ChatConversation>> getAllConversations() {
    final query = select(chatConversations)
      ..orderBy([(conv) => OrderingTerm.desc(conv.lastMessageAt)]);

    return query.get();
  }

  Future<ChatConversation?> getConversation(String id) {
    return (select(chatConversations)..where((conv) => conv.id.equals(id))).getSingleOrNull();
  }

  Future<int> saveConversation(ChatConversationsCompanion conversation) {
    return into(chatConversations).insert(conversation, onConflict: DoUpdate((_) => conversation));
  }

  Future<bool> updateConversationLastMessage(String conversationId, String lastMessageId, DateTime timestamp) {
    return (update(chatConversations)
          ..where((conv) => conv.id.equals(conversationId)))
        .write(ChatConversationsCompanion(
          lastMessageId: Value(lastMessageId),
          lastMessageAt: Value(timestamp),
        ))
        .then((rowsAffected) => rowsAffected > 0);
  }

  Future<int> deleteConversation(String conversationId) {
    return (delete(chatConversations)..where((conv) => conv.id.equals(conversationId))).go();
  }

  // Users operations
  Future<User?> getUser(String id) {
    return (select(users)..where((user) => user.id.equals(id))).getSingleOrNull();
  }

  Future<List<User>> getAllUsers() {
    return select(users).get();
  }

  Future<int> saveUser(UsersCompanion user) {
    return into(users).insert(user, onConflict: DoUpdate((_) => user));
  }

  Future<int> deleteUser(String userId) {
    return (delete(users)..where((user) => user.id.equals(userId))).go();
  }

  // Groups operations
  Future<Group?> getGroup(String id) {
    return (select(groups)..where((group) => group.id.equals(id))).getSingleOrNull();
  }

  Future<List<Group>> getAllGroups() {
    return select(groups).get();
  }

  Future<int> saveGroup(GroupsCompanion group) {
    return into(groups).insert(group, onConflict: DoUpdate((_) => group));
  }

  Future<int> deleteGroup(String groupId) {
    return (delete(groups)..where((group) => group.id.equals(groupId))).go();
  }

  // Utility methods
  Future<void> clearAllData() async {
    await delete(messages).go();
    await delete(chatConversations).go();
    await delete(users).go();
    await delete(groups).go();
  }

  Future<Map<String, int>> getDatabaseStats() async {
    final messageCount = await (selectOnly(messages)..addColumns([messages.id.count()])).map((row) => row.read(messages.id.count())).getSingle();
    final conversationCount = await (selectOnly(chatConversations)..addColumns([chatConversations.id.count()])).map((row) => row.read(chatConversations.id.count())).getSingle();
    final userCount = await (selectOnly(users)..addColumns([users.id.count()])).map((row) => row.read(users.id.count())).getSingle();
    final groupCount = await (selectOnly(groups)..addColumns([groups.id.count()])).map((row) => row.read(groups.id.count())).getSingle();

    return {
      'messages': messageCount ?? 0,
      'conversations': conversationCount ?? 0,
      'users': userCount ?? 0,
      'groups': groupCount ?? 0,
    };
  }
}

// Tables definitions
class Messages extends Table {
  TextColumn get id => text()();
  TextColumn get chatId => text()(); // conversation ID
  TextColumn get senderId => text()();
  TextColumn get content => text()();
  IntColumn get type => integer().withDefault(const Constant(0))(); // 0=text, 1=image, 2=file
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class ChatConversations extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()(); // 'personal' or 'group'
  TextColumn get name => text().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get avatar => text().nullable()();
  TextColumn get lastMessageId => text().nullable()();
  DateTimeColumn get lastMessageAt => dateTime().nullable()();
  IntColumn get unreadCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class Users extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get email => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get city => text().nullable()();
  TextColumn get role => text()(); // 'user' or 'pic'
  TextColumn get profilePicture => text().nullable()();
  TextColumn get areaId => text().nullable()();
  BoolColumn get isOnline => boolean().withDefault(const Constant(false))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class Groups extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get avatar => text().nullable()();
  TextColumn get createdBy => text()();
  TextColumn get areaId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
