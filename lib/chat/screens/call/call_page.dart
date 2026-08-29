import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import '../../core/constants/zego_config.dart';
import '../../services/sqlite_service.dart';
import '../../models/call_log_model.dart';
import 'package:uuid/uuid.dart';

class CallPage extends StatefulWidget {
  final String callID;
  final String userID;
  final String userName;
  final bool isVideo;

  /// Peer info for call log recording
  final String peerId;
  final String peerName;
  final String peerAvatar;
  final String direction; // 'outgoing' | 'incoming'

  const CallPage({
    super.key,
    required this.callID,
    required this.userID,
    required this.userName,
    required this.isVideo,
    required this.peerId,
    required this.peerName,
    this.peerAvatar = '',
    this.direction = 'outgoing',
  });

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  late DateTime _callStartTime;
  bool _callConnected = false;

  @override
  void initState() {
    super.initState();
    _callStartTime = DateTime.now();
  }

  /// Calculates duration and writes the call log to SQLite.
  void _persistCallLog() {
    final duration = _callConnected
        ? DateTime.now().difference(_callStartTime).inSeconds
        : 0;

    final callLog = CallLogModel(
      id: const Uuid().v4(),
      peerId: widget.peerId,
      peerName: widget.peerName,
      peerAvatar: widget.peerAvatar,
      callType: widget.isVideo ? 'video' : 'audio',
      direction: _callConnected ? widget.direction : 'missed',
      timestamp: _callStartTime,
      duration: duration,
    );

    SqliteService.instance.insertCallLog(callLog);
  }

  @override
  Widget build(BuildContext context) {
    return ZegoUIKitPrebuiltCall(
      appID: ZegoConfig.appId,
      appSign: ZegoConfig.appSign,
      userID: widget.userID,
      userName: widget.userName,
      callID: widget.callID,
      config: widget.isVideo
          ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
          : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall(),
      events: ZegoUIKitPrebuiltCallEvents(
        // Track when the remote peer joins → call is connected
        user: ZegoCallUserEvents(
          onEnter: (user) {
            _callConnected = true;
            _callStartTime = DateTime.now(); // Start timer from actual connection
          },
        ),
        // Record call log on call end with accurate duration
        onCallEnd: (event, defaultAction) {
          _persistCallLog();
          defaultAction.call(); // Navigate back
        },
      ),
    );
  }
}
