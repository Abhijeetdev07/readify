import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../models/message_model.dart';
import '../../services/media_service.dart';
import '../../core/utils/date_formatter.dart';

class VoiceMessagePlayer extends StatefulWidget {
  final MessageModel message;
  final bool isMe;

  const VoiceMessagePlayer({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  State<VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends State<VoiceMessagePlayer> {
  late final AudioPlayer _audioPlayer;
  final _mediaService = MediaStorageService.instance;

  bool _isPlaying = false;
  bool _isLoading = false;
  bool _isDownloaded = false;
  String? _localPath;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isSourceSet = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();

    if (widget.message.duration > 0) {
      _duration = Duration(seconds: widget.message.duration);
    }

    _checkLocalDiskExistence();

    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
          if (state.processingState == ProcessingState.completed) {
            _isPlaying = false;
            _position = Duration.zero;
            _audioPlayer.seek(Duration.zero);
            _audioPlayer.pause();
          }
        });
      }
    });

    _audioPlayer.positionStream.listen((pos) {
      if (mounted) {
        setState(() => _position = pos);
      }
    });

    _audioPlayer.durationStream.listen((dur) {
      if (dur != null && mounted) {
        setState(() => _duration = dur);
      }
    });
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
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _downloadAudio() async {
    setState(() => _isLoading = true);
    try {
      final downloadedPath = await _mediaService.downloadAndSyncMedia(
        messageId: widget.message.id,
        remoteUrl: widget.message.content,
        mediaType: 'audio',
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
          SnackBar(content: Text('Failed to download audio: $e')),
        );
      }
    }
  }

  Future<void> _togglePlay() async {
    if (!_isDownloaded) {
      await _downloadAudio();
      if (!_isDownloaded) return;
    }

    if (_isPlaying) {
      await _audioPlayer.pause();
      return;
    }

    if (_isSourceSet) {
      await _audioPlayer.play();
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_localPath != null && File(_localPath!).existsSync()) {
        await _audioPlayer.setFilePath(_localPath!);
      } else if (widget.message.content.startsWith('http')) {
        await _audioPlayer.setUrl(widget.message.content);
      }

      _isSourceSet = true;
      await _audioPlayer.play();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to play audio: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = const Color(0xFF128C7E);

    return Container(
      width: 230,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Action Button: Download Icon vs Play/Pause Icon
          GestureDetector(
            onTap: _isLoading
                ? null
                : (_isDownloaded ? _togglePlay : _downloadAudio),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: activeColor,
              child: _isLoading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Icon(
                      !_isDownloaded
                          ? Icons.download_rounded
                          : (_isPlaying ? Icons.pause : Icons.play_arrow),
                      color: Colors.white,
                      size: 24,
                    ),
            ),
          ),
          const SizedBox(width: 8),

          // Slider & Duration
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                    activeTrackColor: activeColor,
                    inactiveTrackColor: Colors.grey.shade300,
                    thumbColor: activeColor,
                  ),
                  child: Slider(
                    value: _position.inMilliseconds
                        .clamp(0, _duration.inMilliseconds > 0 ? _duration.inMilliseconds : 1)
                        .toDouble(),
                    max: (_duration.inMilliseconds > 0 ? _duration.inMilliseconds : 1).toDouble(),
                    onChanged: (val) {
                      if (_isSourceSet) {
                        _audioPlayer.seek(Duration(milliseconds: val.toInt()));
                      }
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormatter.formatDuration(_position.inSeconds),
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                      ),
                      Text(
                        !_isDownloaded && widget.message.fileSize > 0
                            ? '${(widget.message.fileSize / 1024).toStringAsFixed(0)} KB'
                            : DateFormatter.formatDuration(_duration.inSeconds),
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
