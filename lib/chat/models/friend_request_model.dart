class FriendRequestModel {
  final String id;
  final String fromUid;
  final String fromName;
  final String fromEmail;
  final String fromAvatar;
  final String toUid;
  final String status; // pending, accepted, rejected
  final DateTime createdAt;

  FriendRequestModel({
    required this.id,
    required this.fromUid,
    required this.fromName,
    required this.fromEmail,
    this.fromAvatar = '',
    required this.toUid,
    this.status = 'pending',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fromUid': fromUid,
      'fromName': fromName,
      'fromEmail': fromEmail,
      'fromAvatar': fromAvatar,
      'toUid': toUid,
      'status': status,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory FriendRequestModel.fromMap(Map<String, dynamic> map, String docId) {
    return FriendRequestModel(
      id: docId,
      fromUid: map['fromUid'] as String? ?? '',
      fromName: map['fromName'] as String? ?? '',
      fromEmail: map['fromEmail'] as String? ?? '',
      fromAvatar: map['fromAvatar'] as String? ?? '',
      toUid: map['toUid'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
          : DateTime.now(),
    );
  }
}
