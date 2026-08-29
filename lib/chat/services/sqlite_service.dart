import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/user_model.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../models/call_log_model.dart';

class SqliteService {
  static final SqliteService instance = SqliteService._init();
  static Database? _database;

  SqliteService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('readify_chat.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Contacts Table
    await db.execute('''
      CREATE TABLE contacts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        avatar_url TEXT,
        about TEXT,
        last_seen INTEGER
      )
    ''');

    // 2. Conversations Summary Table
    await db.execute('''
      CREATE TABLE conversations (
        chat_id TEXT PRIMARY KEY,
        peer_id TEXT NOT NULL,
        peer_name TEXT NOT NULL,
        peer_avatar TEXT,
        last_message TEXT,
        last_message_time INTEGER,
        last_message_type TEXT,
        unread_count INTEGER DEFAULT 0,
        FOREIGN KEY (peer_id) REFERENCES contacts (id)
      )
    ''');

    // 3. Messages Table
    await db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        chat_id TEXT NOT NULL,
        sender_id TEXT NOT NULL,
        receiver_id TEXT NOT NULL,
        message_type TEXT NOT NULL,
        content TEXT,
        local_path TEXT,
        status TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        duration INTEGER DEFAULT 0,
        file_size INTEGER DEFAULT 0,
        FOREIGN KEY (chat_id) REFERENCES conversations (chat_id)
      )
    ''');

    // 4. Call Logs Table
    await db.execute('''
      CREATE TABLE call_logs (
        id TEXT PRIMARY KEY,
        peer_id TEXT NOT NULL,
        peer_name TEXT NOT NULL,
        peer_avatar TEXT,
        call_type TEXT NOT NULL,
        direction TEXT NOT NULL,
        duration INTEGER DEFAULT 0,
        timestamp INTEGER NOT NULL
      )
    ''');
  }

  // --- Messages Operations ---
  Future<void> insertMessage(MessageModel message) async {
    final db = await instance.database;
    await db.insert(
      'messages',
      message.toSqlite(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<MessageModel>> getMessages(String chatId) async {
    final db = await instance.database;
    final result = await db.query(
      'messages',
      where: 'chat_id = ?',
      whereArgs: [chatId],
      orderBy: 'timestamp ASC',
    );
    return result.map((map) => MessageModel.fromSqlite(map)).toList();
  }

  Future<List<MessageModel>> getPendingMessages() async {
    final db = await instance.database;
    final result = await db.query(
      'messages',
      where: 'status = ?',
      whereArgs: ['pending'],
      orderBy: 'timestamp ASC',
    );
    return result.map((map) => MessageModel.fromSqlite(map)).toList();
  }

  Future<void> updateMessageStatus(String messageId, String status) async {
    final db = await instance.database;
    await db.update(
      'messages',
      {'status': status},
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  Future<void> updateMessageLocalPath(String messageId, String localPath) async {
    final db = await instance.database;
    await db.update(
      'messages',
      {'local_path': localPath},
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  // --- Conversations Operations ---
  Future<void> insertOrUpdateConversation(ChatModel chat) async {
    final db = await instance.database;
    await db.insert(
      'conversations',
      chat.toSqlite(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ChatModel>> getConversations() async {
    final db = await instance.database;
    final result = await db.query(
      'conversations',
      orderBy: 'last_message_time DESC',
    );
    return result.map((map) => ChatModel.fromSqlite(map)).toList();
  }

  // --- Contacts Operations ---
  Future<void> insertOrUpdateContact(UserModel user) async {
    final db = await instance.database;
    await db.insert(
      'contacts',
      user.toSqlite(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<UserModel?> getContact(String uid) async {
    final db = await instance.database;
    final result = await db.query(
      'contacts',
      where: 'id = ?',
      whereArgs: [uid],
    );
    if (result.isNotEmpty) {
      return UserModel.fromSqlite(result.first);
    }
    return null;
  }

  // --- Call Logs Operations ---
  Future<void> insertCallLog(CallLogModel callLog) async {
    final db = await instance.database;
    await db.insert(
      'call_logs',
      callLog.toSqlite(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<CallLogModel>> getCallLogs() async {
    final db = await instance.database;
    final result = await db.query(
      'call_logs',
      orderBy: 'timestamp DESC',
    );
    return result.map((map) => CallLogModel.fromSqlite(map)).toList();
  }

  // --- Batch & Advanced Operations ---
  Future<void> insertBatchMessages(List<MessageModel> messages) async {
    final db = await instance.database;
    final batch = db.batch();
    for (final msg in messages) {
      batch.insert(
        'messages',
        msg.toSqlite(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<MessageModel>> searchMessages(String query) async {
    final db = await instance.database;
    final result = await db.query(
      'messages',
      where: 'content LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'timestamp DESC',
    );
    return result.map((map) => MessageModel.fromSqlite(map)).toList();
  }

  Future<void> markMessagesAsRead(String chatId, String myUid) async {
    final db = await instance.database;
    await db.update(
      'messages',
      {'status': 'read'},
      where: 'chat_id = ? AND receiver_id = ? AND status != ?',
      whereArgs: [chatId, myUid, 'read'],
    );
  }

  Future<void> deleteMessage(String messageId) async {
    final db = await instance.database;
    await db.delete(
      'messages',
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  Future<void> deleteConversation(String chatId) async {
    final db = await instance.database;
    await db.delete(
      'conversations',
      where: 'chat_id = ?',
      whereArgs: [chatId],
    );
    await db.delete(
      'messages',
      where: 'chat_id = ?',
      whereArgs: [chatId],
    );
  }

  Future<void> clearAllData() async {
    final db = await instance.database;
    await db.delete('messages');
    await db.delete('conversations');
    await db.delete('contacts');
    await db.delete('call_logs');
  }

  Future<void> close() async {
    final db = await instance.database;
    await db.close();
  }
}
