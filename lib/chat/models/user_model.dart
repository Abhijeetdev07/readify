class UserModel {
  final String uid;
  final String name;
  final String email;
  final String avatarUrl;
  final String about;
  final bool isOnline;
  final DateTime? lastSeen;
  final DateTime? createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.avatarUrl = '',
    this.about = 'Hey there! I am using Readify Chat.',
    this.isOnline = false,
    this.lastSeen,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'about': about,
      'onlineStatus': isOnline,
      'lastSeen': lastSeen?.millisecondsSinceEpoch,
      'createdAt': createdAt?.millisecondsSinceEpoch,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String? ?? '',
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      avatarUrl: map['avatarUrl'] as String? ?? '',
      about: map['about'] as String? ?? 'Hey there! I am using Readify Chat.',
      isOnline: (map['onlineStatus'] ?? map['isOnline']) as bool? ?? false,
      lastSeen: map['lastSeen'] != null ? DateTime.fromMillisecondsSinceEpoch(map['lastSeen'] as int) : null,
      createdAt: map['createdAt'] != null ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int) : null,
    );
  }

  // SQLite Mapping
  Map<String, dynamic> toSqlite() {
    return {
      'id': uid,
      'name': name,
      'email': email,
      'avatar_url': avatarUrl,
      'about': about,
      'last_seen': lastSeen?.millisecondsSinceEpoch,
    };
  }

  factory UserModel.fromSqlite(Map<String, dynamic> map) {
    return UserModel(
      uid: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      avatarUrl: map['avatar_url'] as String? ?? '',
      about: map['about'] as String? ?? '',
      lastSeen: map['last_seen'] != null ? DateTime.fromMillisecondsSinceEpoch(map['last_seen'] as int) : null,
    );
  }
}
