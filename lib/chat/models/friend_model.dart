class FriendModel {
  final String friendUid;
  final DateTime addedAt;

  FriendModel({
    required this.friendUid,
    required this.addedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'friendUid': friendUid,
      'addedAt': addedAt.millisecondsSinceEpoch,
    };
  }

  factory FriendModel.fromMap(Map<String, dynamic> map, String docId) {
    return FriendModel(
      friendUid: map['friendUid'] as String? ?? docId,
      addedAt: map['addedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['addedAt'] as int)
          : DateTime.now(),
    );
  }
}
