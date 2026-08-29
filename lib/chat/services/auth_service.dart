import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../core/constants/app_constants.dart';
import 'sqlite_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Reactive stream listening to both auth state and Firestore user profile doc
  Stream<UserModel?> get currentUserStream {
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) {
        return Stream.value(null);
      }
      return _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .snapshots()
          .map((doc) => doc.exists && doc.data() != null
              ? UserModel.fromMap(doc.data()!)
              : null);
    });
  }

  // Sign up with Email & Password
  Future<UserModel?> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;
    if (user != null) {
      final userModel = UserModel(
        uid: user.uid,
        name: name.trim(),
        email: email.trim(),
        isOnline: true,
        createdAt: DateTime.now(),
        lastSeen: DateTime.now(),
      );

      // Save to Cloud Firestore
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .set(userModel.toMap());

      // Cache to SQLite
      await SqliteService.instance.insertOrUpdateContact(userModel);

      return userModel;
    }
    return null;
  }

  // Sign in with Email & Password
  Future<UserModel?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;
    if (user != null) {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        final userModel = UserModel.fromMap(doc.data()!);
        await SqliteService.instance.insertOrUpdateContact(userModel);
        return userModel;
      } else {
        // Create Firestore document if user was added from console
        final defaultName = email.split('@').first;
        final userModel = UserModel(
          uid: user.uid,
          name: defaultName,
          email: email.trim().toLowerCase(),
          isOnline: true,
          createdAt: DateTime.now(),
          lastSeen: DateTime.now(),
        );
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(user.uid)
            .set(userModel.toMap());
        await SqliteService.instance.insertOrUpdateContact(userModel);
        return userModel;
      }
    }
    return null;
  }

  // Sign out
  Future<void> signOut() async {
    if (currentUser != null) {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(currentUser!.uid)
          .update({
        'onlineStatus': false,
        'lastSeen': DateTime.now().millisecondsSinceEpoch,
      });
    }
    await _auth.signOut();
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }
}
