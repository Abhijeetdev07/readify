class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String receiverId;
  final String messageType; // text, image, audio, video
  final String content;     // text body or cloud storage URL
  final String? localPath;  // path on local device filesystem
  final String status;      // pending, sent, delivered, read
  final DateTime timestamp;
  final int duration;       // audio duration in seconds
  final int fileSize;       // file size in bytes

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.receiverId,
    required this.messageType,
    required this.content,
    this.localPath,
    this.status = 'pending',
    required this.timestamp,
    this.duration = 0,
    this.fileSize = 0,
  });

  MessageModel copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? receiverId,
    String? messageType,
    String? content,
    String? localPath,
    String? status,
    DateTime? timestamp,
    int? duration,
    int? fileSize,
  }) {
    return MessageModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      messageType: messageType ?? this.messageType,
      content: content ?? this.content,
      localPath: localPath ?? this.localPath,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      duration: duration ?? this.duration,
      fileSize: fileSize ?? this.fileSize,
    );
  }

  // Firestore Mapping
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'receiverId': receiverId,
      'messageType': messageType,
      'content': content,
      'status': status,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'duration': duration,
      'fileSize': fileSize,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'] as String? ?? '',
      chatId: map['chatId'] as String? ?? '',
      senderId: map['senderId'] as String? ?? '',
      receiverId: map['receiverId'] as String? ?? '',
      messageType: map['messageType'] as String? ?? 'text',
      content: map['content'] as String? ?? '',
      localPath: map['localPath'] as String?,
      status: map['status'] as String? ?? 'sent',
      timestamp: map['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int)
          : DateTime.now(),
      duration: map['duration'] as int? ?? 0,
      fileSize: map['fileSize'] as int? ?? 0,
    );
  }

  // SQLite Mapping
  Map<String, dynamic> toSqlite() {
    return {
      'id': id,
      'chat_id': chatId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'message_type': messageType,
      'content': content,
      'local_path': localPath,
      'status': status,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'duration': duration,
      'file_size': fileSize,
    };
  }

  factory MessageModel.fromSqlite(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'] as String? ?? '',
      chatId: map['chat_id'] as String? ?? '',
      senderId: map['sender_id'] as String? ?? '',
      receiverId: map['receiver_id'] as String? ?? '',
      messageType: map['message_type'] as String? ?? 'text',
      content: map['content'] as String? ?? '',
      localPath: map['local_path'] as String?,
      status: map['status'] as String? ?? 'sent',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch),
      duration: map['duration'] as int? ?? 0,
      fileSize: map['file_size'] as int? ?? 0,
    );
  }
}
