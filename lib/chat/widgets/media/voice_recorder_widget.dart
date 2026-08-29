import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/utils/date_formatter.dart';

class VoiceRecorderWidget extends StatefulWidget {
  final Function(File audioFile, int durationSeconds) onRecordingComplete;

  const VoiceRecorderWidget({
    super.key,
    required this.onRecordingComplete,
  });

  @override
  State<VoiceRecorderWidget> createState() => _VoiceRecorderWidgetState();
}

class _VoiceRecorderWidgetState extends State<VoiceRecorderWidget> {
  late final AudioRecorder _audioRecorder;
  bool _isRecording = false;
  int _recordDuration = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final tempDir = await getTemporaryDirectory();
        final filePath = '${tempDir.path}/rec_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: filePath,
        );

        setState(() {
          _isRecording = true;
          _recordDuration = 0;
        });

        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted) {
            setState(() => _recordDuration++);
          }
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission required for voice notes')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting recording: $e')),
        );
      }
    }
  }

  Future<void> _stopAndSendRecording() async {
    _timer?.cancel();
    try {
      final path = await _audioRecorder.stop();
      final duration = _recordDuration;

      setState(() {
        _isRecording = false;
        _recordDuration = 0;
      });

      if (path != null && duration > 0) {
        final file = File(path);
        if (await file.exists()) {
          widget.onRecordingComplete(file, duration);
        }
      }
    } catch (e) {
      setState(() {
        _isRecording = false;
        _recordDuration = 0;
      });
    }
  }

  Future<void> _cancelRecording() async {
    _timer?.cancel();
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _recordDuration = 0;
      });
      if (path != null) {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (_) {
      setState(() {
        _isRecording = false;
        _recordDuration = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isRecording) {
      return CircleAvatar(
        radius: 23,
        backgroundColor: const Color(0xFF128C7E),
        child: IconButton(
          icon: const Icon(Icons.mic, color: Colors.white, size: 22),
          tooltip: 'Record Voice Note',
          onPressed: _startRecording,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Blinking Red Recording Dot
          Container(
            height: 10,
            width: 10,
            decoration: const BoxDecoration(
              color: Colors.redAccent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),

          // Duration
          Text(
            DateFormatter.formatDuration(_recordDuration),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(width: 12),

          // Cancel Trash Button
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
            tooltip: 'Cancel',
            onPressed: _cancelRecording,
          ),

          // Send Button
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF128C7E),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 16),
              tooltip: 'Send Voice Note',
              onPressed: _stopAndSendRecording,
            ),
          ),
        ],
      ),
    );
  }
}
