import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/message_model.dart';
import '../services/firestore_service.dart';
import '../services/sqlite_service.dart';
import '../services/sync_service.dart';
import '../services/storage_service.dart';
import '../services/media_service.dart';
import '../core/constants/app_constants.dart';

class ChatProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final SqliteService _sqliteService = SqliteService.instance;
  final StorageService _storageService = StorageService();
  final MediaStorageService _mediaStorage = MediaStorageService.instance;

  List<MessageModel> _messages = [];
  List<MessageModel> get messages => _messages;

  ChatProvider() {
    // Initialize auto sync engine on startup with state-update callback
    SyncService.instance.initializeSyncEngine(
      onMessageSynced: (messageId, status) {
        updateLocalMessageStatus(messageId, status);
      },
    );
  }

  // Load offline messages directly from SQLite
  Future<void> loadLocalMessages(String chatId) async {
    _messages = await _sqliteService.getMessages(chatId);
    notifyListeners();
  }

  // Check live network state
  Future<bool> _checkIsOnline() async {
    try {
      final results = await Connectivity().checkConnectivity();
      return results.any((r) => r != ConnectivityResult.none);
    } catch (_) {
      return false;
    }
  }

  // 1. Send Text Message (Offline First)
  Future<void> sendTextMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    final messageId = const Uuid().v4();
    final message = MessageModel(
      id: messageId,
      chatId: chatId,
      senderId: senderId,
      receiverId: receiverId,
      messageType: AppConstants.typeText,
      content: text.trim(),
      status: AppConstants.statusPending,
      timestamp: DateTime.now(),
    );

    // 1. Immediately insert into SQLite (offline first) with 'pending' (🕒)
    await _sqliteService.insertMessage(message);
    _messages.add(message);
    notifyListeners();

    // 2. Check live connectivity before attempting cloud push
    final isOnline = await _checkIsOnline();
    if (!isOnline) {
      // Keep 'pending' (🕒) in SQLite; SyncService will push when online
      return;
    }

    // 3. Online: push to Cloud Firestore and mark 'sent' (✓)
    try {
      final sentMessage = message.copyWith(status: AppConstants.statusSent);
      await _firestoreService.sendMessageToFirestore(sentMessage);
      await _sqliteService.updateMessageStatus(messageId, AppConstants.statusSent);

      final index = _messages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        _messages[index] = sentMessage;
        notifyListeners();
      }
    } catch (_) {
      // Stays 'pending' in SQLite; SyncService will push on reconnect
    }
  }

  // 2. Send Media Message (Image, Audio voice note, Video)
  Future<void> sendMediaMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required File file,
    required String mediaType, // image, audio, video
    int duration = 0,
  }) async {
    final messageId = const Uuid().v4();
    final fileSize = await file.length();

    // Copy to sandbox storage & record local_path
    final localPath = await _mediaStorage.saveOutgoingMedia(
      sourceFile: file,
      mediaType: mediaType,
      messageId: messageId,
    );

    final message = MessageModel(
      id: messageId,
      chatId: chatId,
      senderId: senderId,
      receiverId: receiverId,
      messageType: mediaType,
      content: localPath,
      localPath: localPath,
      status: AppConstants.statusPending,
      timestamp: DateTime.now(),
      duration: duration,
      fileSize: fileSize,
    );

    // Insert locally first (instant UI update with 🕒)
    await _sqliteService.insertMessage(message);
    _messages.add(message);
    notifyListeners();

    final isOnline = await _checkIsOnline();
    if (!isOnline) {
      // Keep 'pending'; SyncService handles it once internet returns
      return;
    }

    // Try background upload and dispatch
    try {
      final remoteUrl = await _storageService.uploadChatMedia(
        file: File(localPath),
        chatId: chatId,
        mediaType: mediaType,
      );

      final sentMessage = message.copyWith(
        content: remoteUrl,
        status: AppConstants.statusSent,
      );

      await _firestoreService.sendMessageToFirestore(sentMessage);
      await _sqliteService.updateMessageStatus(messageId, AppConstants.statusSent);

      final index = _messages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        _messages[index] = sentMessage;
        notifyListeners();
      }
    } catch (_) {
      // Stays 'pending'; SyncService handles it once internet returns
    }
  }

  // 3. Update single message status in local UI memory
  void updateLocalMessageStatus(String messageId, String status) {
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      _messages[index] = _messages[index].copyWith(status: status);
      notifyListeners();
    }
  }

  // 4. Sync incoming message from Firestore Stream to local SQLite
  void syncIncomingMessage(MessageModel message) async {
    await _sqliteService.insertMessage(message);
    final index = _messages.indexWhere((m) => m.id == message.id);
    if (index != -1) {
      _messages[index] = message;
    } else {
      _messages.add(message);
    }
    notifyListeners();
  }

  // 5. Mark all messages as read in chat (local SQLite)
  Future<void> markChatAsRead(String chatId, String myUid) async {
    await _sqliteService.markMessagesAsRead(chatId, myUid);
  }

  // 6. Mark message as read in Cloud Firestore (turns ticks into blue ticks 🔵✓✓)
  Future<void> markMessageAsReadInCloud(String chatId, String messageId) async {
    try {
      await _firestoreService.markMessageAsRead(chatId, messageId);
      await _sqliteService.updateMessageStatus(messageId, AppConstants.statusRead);
    } catch (_) {}
  }
}
