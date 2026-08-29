import 'package:flutter/material.dart';
import '../core/constants/zego_config.dart';
import '../screens/call/call_page.dart';

class ZegoCallService {
  static final ZegoCallService instance = ZegoCallService._init();
  ZegoCallService._init();

  /// Launch 1-on-1 Audio or Video Call Screen using CallPage.
  /// Call logging (duration, direction, timestamp) is handled inside CallPage.
  void startCall({
    required BuildContext context,
    required String currentUserId,
    required String currentUserName,
    required String peerUserId,
    required String peerUserName,
    String peerAvatar = '',
    required String chatId,
    required bool isVideo,
  }) {
    if (ZegoConfig.appId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please configure your ZegoCloud AppID in zego_config.dart'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CallPage(
          callID: chatId,
          userID: currentUserId,
          userName: currentUserName,
          isVideo: isVideo,
          peerId: peerUserId,
          peerName: peerUserName,
          peerAvatar: peerAvatar,
          direction: 'outgoing',
        ),
      ),
    );
  }
}
