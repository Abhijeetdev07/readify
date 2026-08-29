import '../models/call_log_model.dart';
import 'sqlite_service.dart';

class CallService {
  Future<void> logCall({
    required String peerId,
    required String peerName,
    String peerAvatar = '',
    required String callType,  // audio / video
    required String direction, // incoming / outgoing / missed
    int duration = 0,
  }) async {
    final callLog = CallLogModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      peerId: peerId,
      peerName: peerName,
      peerAvatar: peerAvatar,
      callType: callType,
      direction: direction,
      duration: duration,
      timestamp: DateTime.now(),
    );

    await SqliteService.instance.insertCallLog(callLog);
  }

  Future<List<CallLogModel>> getCallHistory() async {
    return await SqliteService.instance.getCallLogs();
  }
}
