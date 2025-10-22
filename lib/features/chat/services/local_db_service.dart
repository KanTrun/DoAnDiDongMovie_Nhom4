import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/conversation.dart';
import '../models/message.dart';

class LocalDbService {
  static Database? _database;
  static const String _dbName = 'chat_local.db';
  static const int _dbVersion = 1;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Conversations table
    await db.execute('''
      CREATE TABLE conversations (
        id INTEGER PRIMARY KEY,
        is_group INTEGER NOT NULL,
        title TEXT,
        created_by INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        last_message_at TEXT,
        unread_count INTEGER DEFAULT 0
      )
    ''');

    // Messages table
    await db.execute('''
      CREATE TABLE messages (
        id INTEGER PRIMARY KEY,
        conversation_id INTEGER NOT NULL,
        sender_id INTEGER NOT NULL,
        content TEXT,
        media_url TEXT,
        media_type TEXT,
        type TEXT NOT NULL DEFAULT 'text',
        created_at TEXT NOT NULL,
        edited_at TEXT,
        is_deleted INTEGER DEFAULT 0,
        is_read INTEGER DEFAULT 0,
        sender_name TEXT,
        sender_avatar TEXT,
        FOREIGN KEY (conversation_id) REFERENCES conversations (id)
      )
    ''');

    // Message reactions table
    await db.execute('''
      CREATE TABLE message_reactions (
        message_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        reaction TEXT NOT NULL,
        created_at TEXT NOT NULL,
        PRIMARY KEY (message_id, user_id),
        FOREIGN KEY (message_id) REFERENCES messages (id)
      )
    ''');

    // Create indexes
    await db.execute('CREATE INDEX idx_messages_conversation_id ON messages(conversation_id)');
    await db.execute('CREATE INDEX idx_messages_created_at ON messages(created_at)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here
  }

  // Conversation operations
  Future<void> saveConversation(Conversation conversation) async {
    final db = await database;
    await db.insert(
      'conversations',
      {
        'id': conversation.id,
        'is_group': conversation.isGroup ? 1 : 0,
        'title': conversation.title,
        'created_by': conversation.createdBy,
        'created_at': conversation.createdAt.toIso8601String(),
        'last_message_at': conversation.lastMessageAt?.toIso8601String(),
        'unread_count': conversation.unreadCount,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Conversation>> getConversations() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'conversations',
      orderBy: 'last_message_at DESC, created_at DESC',
    );

    return maps.map((map) => Conversation.fromJson({
      'id': map['id'],
      'isGroup': map['is_group'] == 1,
      'title': map['title'],
      'createdBy': map['created_by'],
      'createdAt': map['created_at'],
      'lastMessageAt': map['last_message_at'],
      'participants': [],
      'unreadCount': map['unread_count'] ?? 0,
    })).toList();
  }

  Future<Conversation?> getConversation(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'conversations',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;

    final map = maps.first;
    return Conversation.fromJson({
      'id': map['id'],
      'isGroup': map['is_group'] == 1,
      'title': map['title'],
      'createdBy': map['created_by'],
      'createdAt': map['created_at'],
      'lastMessageAt': map['last_message_at'],
      'participants': [],
      'unreadCount': map['unread_count'] ?? 0,
    });
  }

  Future<void> updateConversationLastMessage(int conversationId, DateTime lastMessageAt) async {
    final db = await database;
    await db.update(
      'conversations',
      {'last_message_at': lastMessageAt.toIso8601String()},
      where: 'id = ?',
      whereArgs: [conversationId],
    );
  }

  Future<void> updateConversationUnreadCount(int conversationId, int unreadCount) async {
    final db = await database;
    await db.update(
      'conversations',
      {'unread_count': unreadCount},
      where: 'id = ?',
      whereArgs: [conversationId],
    );
  }

  // Message operations
  Future<void> saveMessage(Message message) async {
    final db = await database;
    await db.insert(
      'messages',
      {
        'id': message.id,
        'conversation_id': message.conversationId,
        'sender_id': message.senderId,
        'content': message.content,
        'media_url': message.mediaUrl,
        'media_type': message.mediaType,
        'type': message.type,
        'created_at': message.createdAt.toIso8601String(),
        'edited_at': message.editedAt?.toIso8601String(),
        'is_deleted': message.isDeleted ? 1 : 0,
        'is_read': message.isRead ? 1 : 0,
        'sender_name': message.senderName,
        'sender_avatar': message.senderAvatar,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Update conversation last message time
    await updateConversationLastMessage(message.conversationId, message.createdAt);
  }

  Future<List<Message>> getMessages(int conversationId, {int limit = 50, int offset = 0}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'conversation_id = ? AND is_deleted = 0',
      whereArgs: [conversationId],
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );

    return maps.map((map) => Message.fromJson({
      'id': map['id'],
      'conversationId': map['conversation_id'],
      'senderId': map['sender_id'],
      'content': map['content'],
      'mediaUrl': map['media_url'],
      'mediaType': map['media_type'],
      'type': map['type'],
      'createdAt': map['created_at'],
      'editedAt': map['edited_at'],
      'isDeleted': map['is_deleted'] == 1,
      'isRead': map['is_read'] == 1,
      'senderName': map['sender_name'],
      'senderAvatar': map['sender_avatar'],
      'reactions': [],
    })).toList();
  }

  Future<void> markMessageAsRead(int messageId) async {
    final db = await database;
    await db.update(
      'messages',
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  Future<void> markConversationAsRead(int conversationId) async {
    final db = await database;
    await db.update(
      'messages',
      {'is_read': 1},
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
    );
  }

  Future<void> deleteMessage(int messageId) async {
    final db = await database;
    await db.update(
      'messages',
      {'is_deleted': 1},
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  Future<void> updateMessage(int messageId, String content) async {
    final db = await database;
    await db.update(
      'messages',
      {
        'content': content,
        'edited_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  // Reaction operations
  Future<void> saveMessageReaction(int messageId, int userId, String reaction) async {
    final db = await database;
    await db.insert(
      'message_reactions',
      {
        'message_id': messageId,
        'user_id': userId,
        'reaction': reaction,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removeMessageReaction(int messageId, int userId) async {
    final db = await database;
    await db.delete(
      'message_reactions',
      where: 'message_id = ? AND user_id = ?',
      whereArgs: [messageId, userId],
    );
  }

  Future<List<MessageReaction>> getMessageReactions(int messageId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'message_reactions',
      where: 'message_id = ?',
      whereArgs: [messageId],
    );

    return maps.map((map) => MessageReaction.fromJson({
      'reaction': map['reaction'],
      'userId': map['user_id'],
      'createdAt': map['created_at'],
    })).toList();
  }

  // Cleanup operations
  Future<void> clearOldMessages(int daysOld) async {
    final db = await database;
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
    await db.delete(
      'messages',
      where: 'created_at < ?',
      whereArgs: [cutoffDate.toIso8601String()],
    );
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('message_reactions');
    await db.delete('messages');
    await db.delete('conversations');
  }
}
