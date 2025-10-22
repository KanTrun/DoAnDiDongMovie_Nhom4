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
  Future<void> saveConversation(Conversation c) async {
    final db = await database;
    await db.insert('conversations', {
      'id': c.id,
      'is_group': c.isGroup ? 1 : 0,
      'title': c.title,
      'created_by': c.createdBy,
      'created_at': c.createdAt.toUtc().toIso8601String(),
      'last_message_at': c.lastMessageAt?.toUtc().toIso8601String(),
      'unread_count': c.unreadCount,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Conversation>> getConversations() async {
    final db = await database;
    final maps = await db.query('conversations',
        orderBy: 'COALESCE(last_message_at, created_at) DESC');
    return maps.map((m) => Conversation.fromJson({
      'id': m['id'],
      'isGroup': m['is_group'] == 1,
      'title': m['title'],
      'createdBy': m['created_by'],
      'createdAt': m['created_at'],
      'lastMessageAt': m['last_message_at'],
      'participants': [],
      'unreadCount': m['unread_count'] ?? 0,
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

  Future<void> updateConversationLastMessage(int conversationId, DateTime at) async {
    final db = await database;
    await db.update('conversations',
        {'last_message_at': at.toUtc().toIso8601String()},
        where: 'id = ?', whereArgs: [conversationId]);
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
  Future<void> saveMessage(Message m) async {
    final db = await database;
    await db.insert('messages', {
      'id': m.id,
      'conversation_id': m.conversationId,
      'sender_id': m.senderId,
      'content': m.content,
      'media_url': m.mediaUrl,
      'media_type': m.mediaType,
      'type': m.type,
      'created_at': m.createdAt.toUtc().toIso8601String(),
      'edited_at': m.editedAt?.toUtc().toIso8601String(),
      'is_deleted': m.isDeleted ? 1 : 0,
      'is_read': m.isRead ? 1 : 0,
      'sender_name': m.senderName,
      'sender_avatar': m.senderAvatar,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    await updateConversationLastMessage(m.conversationId, m.createdAt);
  }

  Future<List<Message>> getMessages(int conversationId, {int limit = 50, int offset = 0}) async {
    print('DEBUG DB: Getting messages from local DB for conversation $conversationId');
    final db = await database;
    final maps = await db.query('messages',
        where: 'conversation_id = ? AND is_deleted = 0',
        whereArgs: [conversationId],
        orderBy: 'created_at ASC',
        limit: limit, offset: offset);

    print('DEBUG DB: Found ${maps.length} local messages');
    return maps.map((m) => Message.fromJson({
      'id': m['id'],
      'conversationId': m['conversation_id'],
      'senderId': m['sender_id'],
      'content': m['content'],
      'mediaUrl': m['media_url'],
      'mediaType': m['media_type'],
      'type': m['type'],
      'createdAt': m['created_at'],
      'editedAt': m['edited_at'],
      'isDeleted': m['is_deleted'] == 1,
      'isRead': m['is_read'] == 1,
      'senderName': m['sender_name'],
      'senderAvatar': m['sender_avatar'],
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
