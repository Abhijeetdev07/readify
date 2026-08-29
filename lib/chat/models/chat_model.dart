class ChatModel {
  final String chatId;
  final String peerId;
  final String peerName;
  final String peerAvatar;
  final String lastMessage;
  final DateTime lastMessageTime;
  final String lastMessageType;
  final int unreadCount;

  ChatModel({
    required this.chatId,
    required this.peerId,
    required this.peerName,
    this.peerAvatar = '',
    required this.lastMessage,
    required this.lastMessageTime,
    this.lastMessageType = 'text',
    this.unreadCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'peerId': peerId,
      'peerName': peerName,
      'peerAvatar': peerAvatar,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime.millisecondsSinceEpoch,
      'lastMessageType': lastMessageType,
      'unreadCount': unreadCount,
    };
  }

  factory ChatModel.fromMap(Map<String, dynamic> map) {
    return ChatModel(
      chatId: map['chatId'] as String? ?? '',
      peerId: map['peerId'] as String? ?? '',
      peerName: map['peerName'] as String? ?? '',
      peerAvatar: map['peerAvatar'] as String? ?? '',
      lastMessage: map['lastMessage'] as String? ?? '',
      lastMessageTime: DateTime.fromMillisecondsSinceEpoch(map['lastMessageTime'] as int? ?? DateTime.now().millisecondsSinceEpoch),
      lastMessageType: map['lastMessageType'] as String? ?? 'text',
      unreadCount: map['unreadCount'] as int? ?? 0,
    );
  }

  // SQLite Mapping
  Map<String, dynamic> toSqlite() {
    return {
      'chat_id': chatId,
      'peer_id': peerId,
      'peer_name': peerName,
      'peer_avatar': peerAvatar,
      'last_message': lastMessage,
      'last_message_time': lastMessageTime.millisecondsSinceEpoch,
      'last_message_type': lastMessageType,
      'unread_count': unreadCount,
    };
  }

  factory ChatModel.fromSqlite(Map<String, dynamic> map) {
    return ChatModel(
      chatId: map['chat_id'] as String? ?? '',
      peerId: map['peer_id'] as String? ?? '',
      peerName: map['peer_name'] as String? ?? '',
      peerAvatar: map['peer_avatar'] as String? ?? '',
      lastMessage: map['last_message'] as String? ?? '',
      lastMessageTime: DateTime.fromMillisecondsSinceEpoch(map['last_message_time'] as int? ?? DateTime.now().millisecondsSinceEpoch),
      lastMessageType: map['last_message_type'] as String? ?? 'text',
      unreadCount: map['unread_count'] as int? ?? 0,
    );
  }
}
