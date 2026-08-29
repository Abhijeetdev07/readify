import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/sqlite_service.dart';
import '../../models/call_log_model.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/chat_utils.dart';
import '../../services/zego_call_service.dart';

class CallsTab extends StatefulWidget {
  const CallsTab({super.key});

  @override
  State<CallsTab> createState() => _CallsTabState();
}

class _CallsTabState extends State<CallsTab> {
  late Future<List<CallLogModel>> _callLogsFuture;

  @override
  void initState() {
    super.initState();
    _refreshCallLogs();
  }

  void _refreshCallLogs() {
    setState(() {
      _callLogsFuture = SqliteService.instance.getCallLogs();
    });
  }

  void _callBack(CallLogModel log) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final chatId = ChatUtils.getChatId(currentUser.uid, log.peerId);

    ZegoCallService.instance.startCall(
      context: context,
      currentUserId: currentUser.uid,
      currentUserName: currentUser.displayName ?? currentUser.email?.split('@').first ?? 'User',
      peerUserId: log.peerId,
      peerUserName: log.peerName,
      peerAvatar: log.peerAvatar,
      chatId: chatId,
      isVideo: log.callType == 'video',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<CallLogModel>>(
        future: _callLogsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF128C7E)));
          }

          final logs = snapshot.data ?? [];

          if (logs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.phone_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No recent calls',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Audio & video calls with your friends appear here.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: logs.length,
            separatorBuilder: (context, index) => const Divider(height: 1, indent: 72),
            itemBuilder: (context, index) {
              final log = logs[index];
              final isVideo = log.callType == 'video';
              final isMissed = log.direction == 'missed';

              return ListTile(
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: isMissed ? Colors.redAccent.shade100 : const Color(0xFF128C7E),
                  child: Text(
                    log.peerName.isNotEmpty ? log.peerName[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  log.peerName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isMissed ? Colors.redAccent : null,
                  ),
                ),
                subtitle: Row(
                  children: [
                    Icon(
                      log.direction == 'incoming'
                          ? Icons.call_received
                          : (log.direction == 'missed' ? Icons.call_missed : Icons.call_made),
                      size: 16,
                      color: isMissed ? Colors.redAccent : Colors.green,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormatter.formatChatListTime(log.timestamp),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(
                    isVideo ? Icons.videocam : Icons.call,
                    color: const Color(0xFF128C7E),
                  ),
                  tooltip: isVideo ? 'Video Call' : 'Audio Call',
                  onPressed: () => _callBack(log),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
