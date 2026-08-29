import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'sqlite_service.dart';

class MediaStorageService {
  static final MediaStorageService instance = MediaStorageService._init();
  final Dio _dio = Dio();

  MediaStorageService._init();

  // Sub-folder constants
  static const String folderImages = 'app_storage/chat_images';
  static const String folderAudio = 'app_storage/chat_audio';
  static const String folderVideos = 'app_storage/chat_videos';

  // 1. Get or create dedicated sandbox folder
  Future<String> getDirectoryForType(String mediaType) async {
    final appDocDir = await getApplicationDocumentsDirectory();
    String subFolder;

    switch (mediaType.toLowerCase()) {
      case 'image':
        subFolder = folderImages;
        break;
      case 'audio':
        subFolder = folderAudio;
        break;
      case 'video':
        subFolder = folderVideos;
        break;
      default:
        subFolder = 'app_storage/chat_misc';
    }

    final directory = Directory('${appDocDir.path}/$subFolder');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory.path;
  }

  // 2. Download remote file from Firebase Storage & update local_path column in SQLite
  Future<String?> downloadAndSyncMedia({
    required String messageId,
    required String remoteUrl,
    required String mediaType,
    String? customFileName,
    void Function(int received, int total)? onProgress,
  }) async {
    try {
      final folderPath = await getDirectoryForType(mediaType);
      
      // Determine file name and extension
      final extension = _getExtensionForType(mediaType, remoteUrl);
      final fileName = customFileName ?? 'media_${messageId}_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final localFilePath = '$folderPath/$fileName';

      final file = File(localFilePath);
      if (await file.exists()) {
        // If file already exists locally, ensure SQLite is linked and return path
        await SqliteService.instance.updateMessageLocalPath(messageId, localFilePath);
        return localFilePath;
      }

      // Download file using Dio
      final response = await _dio.download(
        remoteUrl,
        localFilePath,
        onReceiveProgress: onProgress,
      );

      if (response.statusCode == 200) {
        // Update local_path column in SQLite
        await SqliteService.instance.updateMessageLocalPath(messageId, localFilePath);
        return localFilePath;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // 3. Save outgoing locally recorded/captured file into sandbox
  Future<String> saveOutgoingMedia({
    required File sourceFile,
    required String mediaType,
    required String messageId,
  }) async {
    final folderPath = await getDirectoryForType(mediaType);
    final extension = sourceFile.path.split('.').last;
    final targetPath = '$folderPath/media_${messageId}_${DateTime.now().millisecondsSinceEpoch}.$extension';

    final savedFile = await sourceFile.copy(targetPath);
    
    // Update local_path column in SQLite
    await SqliteService.instance.updateMessageLocalPath(messageId, savedFile.path);
    return savedFile.path;
  }

  // 4. Verify if file exists on disk
  bool isMediaAvailableLocally(String? localPath) {
    if (localPath == null || localPath.isEmpty) return false;
    return File(localPath).existsSync();
  }

  // 5. Retrieve File instance if present
  File? getLocalFile(String? localPath) {
    if (isMediaAvailableLocally(localPath)) {
      return File(localPath!);
    }
    return null;
  }

  String _getExtensionForType(String mediaType, String url) {
    if (url.contains('.')) {
      final cleanUrl = url.split('?').first;
      final ext = cleanUrl.split('.').last;
      if (ext.length <= 4) return ext;
    }

    switch (mediaType.toLowerCase()) {
      case 'image':
        return 'jpg';
      case 'audio':
        return 'm4a';
      case 'video':
        return 'mp4';
      default:
        return 'bin';
    }
  }
}

// Alias for backwards compatibility
typedef MediaService = MediaStorageService;
