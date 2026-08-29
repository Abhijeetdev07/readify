import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../models/message_model.dart';
import '../../services/media_service.dart';
import '../../core/utils/date_formatter.dart';

class VideoMessagePlayer extends StatefulWidget {
  final MessageModel message;
  final bool isMe;

  const VideoMessagePlayer({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  State<VideoMessagePlayer> createState() => _VideoMessagePlayerState();
}

class _VideoMessagePlayerState extends State<VideoMessagePlayer> {
  VideoPlayerController? _controller;
  final _mediaService = MediaStorageService.instance;
  bool _isDownloaded = false;
  String? _localPath;
  bool _isInitialized = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkLocalDiskExistence();
  }

  void _checkLocalDiskExistence() {
    final path = widget.message.localPath;
    if (path != null && path.isNotEmpty && File(path).existsSync()) {
      _isDownloaded = true;
      _localPath = path;
    } else if (!widget.message.content.startsWith('http') && File(widget.message.content).existsSync()) {
      _isDownloaded = true;
      _localPath = widget.message.content;
    } else {
      _isDownloaded = false;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _downloadVideo() async {
    setState(() => _isLoading = true);
    try {
      final downloadedPath = await _mediaService.downloadAndSyncMedia(
        messageId: widget.message.id,
        remoteUrl: widget.message.content,
        mediaType: 'video',
      );

      if (downloadedPath != null && File(downloadedPath).existsSync()) {
        setState(() {
          _isDownloaded = true;
          _localPath = downloadedPath;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download video: $e')),
        );
      }
    }
  }

  Future<void> _initializeAndPlay() async {
    if (!_isDownloaded) {
      await _downloadVideo();
      if (!_isDownloaded) return;
    }

    setState(() => _isLoading = true);
    try {
      if (_localPath != null && File(_localPath!).existsSync()) {
        _controller = VideoPlayerController.file(File(localPath!));
      } else if (widget.message.content.startsWith('http')) {
        _controller = VideoPlayerController.networkUrl(Uri.parse(widget.message.content));
      }

      if (_controller != null) {
        await _controller!.initialize();
        setState(() {
          _isInitialized = true;
          _isLoading = false;
        });
        _openFullScreenPlayer();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load video: $e')),
        );
      }
    }
  }

  String? get localPath => _localPath;

  void _openFullScreenPlayer() {
    if (_controller == null || !_isInitialized) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullScreenVideoPlayer(controller: _controller!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 180,
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background / Thumbnail Placeholder
          const Center(
            child: Icon(Icons.videocam, color: Colors.white30, size: 48),
          ),

          // Action Button: Download Icon vs Play Icon
          if (_isLoading)
            const CircularProgressIndicator(color: Color(0xFF128C7E))
          else
            GestureDetector(
              onTap: _isDownloaded
                  ? (_isInitialized ? _openFullScreenPlayer : _initializeAndPlay)
                  : _downloadVideo,
              child: CircleAvatar(
                radius: 26,
                backgroundColor: Colors.black.withValues(alpha: 0.65),
                child: Icon(
                  !_isDownloaded ? Icons.download_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),
            ),

          // Duration / File Size Badge Overlay (Bottom Left)
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                !_isDownloaded && widget.message.fileSize > 0
                    ? '${(widget.message.fileSize / (1024 * 1024)).toStringAsFixed(1)} MB'
                    : DateFormatter.formatDuration(widget.message.duration),
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Full Screen In-App Video Player with Controls ---
class _FullScreenVideoPlayer extends StatefulWidget {
  final VideoPlayerController controller;

  const _FullScreenVideoPlayer({required this.controller});

  @override
  State<_FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<_FullScreenVideoPlayer> {
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    widget.controller.play();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.7),
        foregroundColor: Colors.white,
        title: const Text('Video', style: TextStyle(fontSize: 16)),
        elevation: 0,
      ),
      body: GestureDetector(
        onTap: () => setState(() => _showControls = !_showControls),
        child: Center(
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio > 0 ? controller.value.aspectRatio : 16 / 9,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                VideoPlayer(controller),

                // Controls Overlay
                if (_showControls) ...[
                  Center(
                    child: IconButton(
                      iconSize: 56,
                      icon: Icon(
                        controller.value.isPlaying ? Icons.pause_circle : Icons.play_circle,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                      onPressed: () {
                        setState(() {
                          controller.value.isPlaying ? controller.pause() : controller.play();
                        });
                      },
                    ),
                  ),

                  // Bottom Progress Bar
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    color: Colors.black.withValues(alpha: 0.5),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        VideoProgressIndicator(
                          controller,
                          allowScrubbing: true,
                          colors: const VideoProgressColors(
                            playedColor: Color(0xFF128C7E),
                            bufferedColor: Colors.white24,
                            backgroundColor: Colors.white10,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormatter.formatDuration(controller.value.position.inSeconds),
                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                            Text(
                              DateFormatter.formatDuration(controller.value.duration.inSeconds),
                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
