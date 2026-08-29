import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/message_model.dart';
import '../models/friend_request_model.dart';
import '../core/constants/app_constants.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Search user by exact email
  Future<UserModel?> searchUserByEmail(String email) async {
    final query = await _firestore
        .collection(AppConstants.usersCollection)
        .where('email', isEqualTo: email.trim().toLowerCase())
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return UserModel.fromMap(query.docs.first.data());
    }
    return null;
  }

  // Get user by UID
  Future<UserModel?> getUserById(String uid) async {
    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .get();
    if (doc.exists && doc.data() != null) {
      return UserModel.fromMap(doc.data()!);
    }
    return null;
  }

  // Stream user profile
  Stream<UserModel?> streamUserProfile(String uid) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists && doc.data() != null ? UserModel.fromMap(doc.data()!) : null);
  }

  // Update online presence
  Future<void> updatePresence(String uid, bool isOnline) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({
      'onlineStatus': isOnline,
      'lastSeen': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // --- Friend Requests & Social Graph ---
  Future<void> sendFriendRequest({
    required UserModel fromUser,
    required String toUid,
  }) async {
    // Check if already friends
    final isFriendDoc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(fromUser.uid)
        .collection('friends')
        .doc(toUid)
        .get();
    if (isFriendDoc.exists) {
      throw Exception('User is already your friend');
    }

    // Check if pending request already exists
    final existingQuery = await _firestore
        .collection(AppConstants.friendRequestsCollection)
        .where('fromUid', isEqualTo: fromUser.uid)
        .where('toUid', isEqualTo: toUid)
        .where('status', isEqualTo: AppConstants.requestPending)
        .limit(1)
        .get();

    if (existingQuery.docs.isNotEmpty) {
      throw Exception('Friend request already sent');
    }

    final docRef = _firestore.collection(AppConstants.friendRequestsCollection).doc();
    final request = FriendRequestModel(
      id: docRef.id,
      fromUid: fromUser.uid,
      fromName: fromUser.name,
      fromEmail: fromUser.email,
      fromAvatar: fromUser.avatarUrl,
      toUid: toUid,
      status: AppConstants.requestPending,
      createdAt: DateTime.now(),
    );
    await docRef.set(request.toMap());
  }

  Stream<List<FriendRequestModel>> streamReceivedRequests(String myUid) {
    return _firestore
        .collection(AppConstants.friendRequestsCollection)
        .where('toUid', isEqualTo: myUid)
        .where('status', isEqualTo: AppConstants.requestPending)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FriendRequestModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<FriendRequestModel>> streamSentRequests(String myUid) {
    return _firestore
        .collection(AppConstants.friendRequestsCollection)
        .where('fromUid', isEqualTo: myUid)
        .where('status', isEqualTo: AppConstants.requestPending)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FriendRequestModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Atomic batch transaction adding bilateral friendship & marking request accepted
  Future<void> acceptFriendRequest({
    required String requestId,
    required String fromUid,
    required String toUid,
  }) async {
    final batch = _firestore.batch();
    final now = DateTime.now().millisecondsSinceEpoch;

    // 1. Update friend request status to accepted
    final requestRef = _firestore
        .collection(AppConstants.friendRequestsCollection)
        .doc(requestId);
    batch.update(requestRef, {'status': AppConstants.requestAccepted});

    // 2. Add to user A's friends subcollection
    final userAFriendRef = _firestore
        .collection(AppConstants.usersCollection)
        .doc(fromUid)
        .collection('friends')
        .doc(toUid);
    batch.set(userAFriendRef, {'friendUid': toUid, 'addedAt': now});

    // 3. Add to user B's friends subcollection
    final userBFriendRef = _firestore
        .collection(AppConstants.usersCollection)
        .doc(toUid)
        .collection('friends')
        .doc(fromUid);
    batch.set(userBFriendRef, {'friendUid': fromUid, 'addedAt': now});

    await batch.commit();
  }

  Future<void> rejectFriendRequest(String requestId) async {
    await _firestore
        .collection(AppConstants.friendRequestsCollection)
        .doc(requestId)
        .update({'status': AppConstants.requestRejected});
  }

  // Stream friend UIDs for a user
  Stream<List<String>> streamFriendsUids(String myUid) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(myUid)
        .collection('friends')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }

  // Stream full UserModel list of friends
  Stream<List<UserModel>> streamFriends(String myUid) {
    return streamFriendsUids(myUid).asyncMap((uids) async {
      if (uids.isEmpty) return <UserModel>[];
      final users = <UserModel>[];
      for (final uid in uids) {
        final doc = await _firestore.collection(AppConstants.usersCollection).doc(uid).get();
        if (doc.exists && doc.data() != null) {
          users.add(UserModel.fromMap(doc.data()!));
        }
      }
      return users;
    });
  }

  // --- Real-time Messages ---
  Stream<List<MessageModel>> streamMessages(String chatId) {
    return _firestore
        .collection(AppConstants.chatsCollection)
        .doc(chatId)
        .collection(AppConstants.messagesSubCollection)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromMap(doc.data()))
            .toList());
  }

  Future<void> sendMessageToFirestore(MessageModel message) async {
    await _firestore
        .collection(AppConstants.chatsCollection)
        .doc(message.chatId)
        .collection(AppConstants.messagesSubCollection)
        .doc(message.id)
        .set(message.toMap());

    // Update conversation meta in chats root
    await _firestore
        .collection(AppConstants.chatsCollection)
        .doc(message.chatId)
        .set({
      'chatId': message.chatId,
      'lastMessage': message.content,
      'lastMessageType': message.messageType,
      'lastMessageTime': message.timestamp.millisecondsSinceEpoch,
      'participants': [message.senderId, message.receiverId],
    }, SetOptions(merge: true));
  }

  Future<void> markMessageAsRead(String chatId, String messageId) async {
    await _firestore
        .collection(AppConstants.chatsCollection)
        .doc(chatId)
        .collection(AppConstants.messagesSubCollection)
        .doc(messageId)
        .update({'status': AppConstants.statusRead});
  }
}
