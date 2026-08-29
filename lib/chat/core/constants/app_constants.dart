class AppConstants {
  static const String appName = 'ChatsUp';
  
  // Collections in Firestore
  static const String usersCollection = 'users';
  static const String friendsSubCollection = 'friends';
  static const String chatsCollection = 'chats';
  static const String messagesSubCollection = 'messages';
  static const String friendRequestsCollection = 'friend_requests';
  static const String callLogsCollection = 'call_logs';

  // Message Types
  static const String typeText = 'text';
  static const String typeImage = 'image';
  static const String typeAudio = 'audio';
  static const String typeVideo = 'video';

  // Message Status
  static const String statusPending = 'pending';
  static const String statusSent = 'sent';
  static const String statusDelivered = 'delivered';
  static const String statusRead = 'read';

  // Friend Request Status
  static const String requestPending = 'pending';
  static const String requestAccepted = 'accepted';
  static const String requestRejected = 'rejected';
}
