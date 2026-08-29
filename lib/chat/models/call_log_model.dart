class CallLogModel {
  final String id;
  final String peerId;
  final String peerName;
  final String peerAvatar;
  final String callType;  // 'audio' or 'video'
  final String direction; // 'incoming', 'outgoing', 'missed'
  final int duration;     // duration in seconds
  final DateTime timestamp;

  CallLogModel({
    required this.id,
    required this.peerId,
    required this.peerName,
    this.peerAvatar = '',
    required this.callType,
    required this.direction,
    this.duration = 0,
    required this.timestamp,
  });

  Map<String, dynamic> toSqlite() {
    return {
      'id': id,
      'peer_id': peerId,
      'peer_name': peerName,
      'peer_avatar': peerAvatar,
      'call_type': callType,
      'direction': direction,
      'duration': duration,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory CallLogModel.fromSqlite(Map<String, dynamic> map) {
    return CallLogModel(
      id: map['id'] as String? ?? '',
      peerId: map['peer_id'] as String? ?? '',
      peerName: map['peer_name'] as String? ?? '',
      peerAvatar: map['peer_avatar'] as String? ?? '',
      callType: map['call_type'] as String? ?? 'audio',
      direction: map['direction'] as String? ?? 'outgoing',
      duration: map['duration'] as int? ?? 0,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch),
    );
  }
}
