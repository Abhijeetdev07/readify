import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../core/constants/app_constants.dart';
import 'firestore_service.dart';
import 'sqlite_service.dart';
import 'storage_service.dart';

typedef OnMessageSyncedCallback = void Function(String messageId, String status);

class SyncService {
  static final SyncService instance = SyncService._init();
  final Connectivity _connectivity = Connectivity();
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isSyncing = false;
  OnMessageSyncedCallback? _onMessageSynced;

  SyncService._init();

  // 1. Listen to Connectivity changes
  void initializeSyncEngine({OnMessageSyncedCallback? onMessageSynced}) {
    if (onMessageSynced != null) {
      _onMessageSynced = onMessageSynced;
    }
    _subscription?.cancel();
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final isOnline = results.any((result) => result != ConnectivityResult.none);
      if (isOnline) {
        processPendingOfflineQueue();
      }
    });

    // Run immediate check upon startup
    checkAndSync();
  }

  Future<void> checkAndSync() async {
    final results = await _connectivity.checkConnectivity();
    final isOnline = results.any((result) => result != ConnectivityResult.none);
    if (isOnline) {
      await processPendingOfflineQueue();
    }
  }

  // 2. Query SQLite pending queue & dispatch to Cloud Firestore
  // Query: SELECT * FROM messages WHERE status = 'pending' ORDER BY timestamp ASC;
  Future<void> processPendingOfflineQueue() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final pendingMessages = await SqliteService.instance.getPendingMessages();

      for (final message in pendingMessages) {
        try {
          String finalContent = message.content;

          // If media file needs upload first
          if (message.messageType != AppConstants.typeText &&
              message.localPath != null &&
              message.localPath!.isNotEmpty &&
              !message.content.startsWith('http')) {
            final file = File(message.localPath!);
            if (await file.exists()) {
              final remoteUrl = await _storageService.uploadChatMedia(
                file: file,
                chatId: message.chatId,
                mediaType: message.messageType,
              );
              finalContent = remoteUrl;
            }
          }

          // Build online message and send to Firestore
          final onlineMessage = message.copyWith(
            content: finalContent,
            status: AppConstants.statusSent,
          );

          await _firestoreService.sendMessageToFirestore(onlineMessage);

          // Update SQLite record to 'sent'
          await SqliteService.instance.updateMessageStatus(message.id, AppConstants.statusSent);

          // Notify UI state
          _onMessageSynced?.call(message.id, AppConstants.statusSent);
        } catch (_) {
          // If a request fails due to sudden network loss, halt loop and wait for next connection event
          break;
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
