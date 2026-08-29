import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _authService.currentUser != null;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _currentUser = await _authService.signInWithEmail(
        email: email,
        password: password,
      );
      _setLoading(false);
      return _currentUser != null;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getFriendlyErrorMessage(e);
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceAll(RegExp(r'\[.*?\]'), '').trim();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signUp(String email, String password, String name) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _currentUser = await _authService.signUpWithEmail(
        email: email,
        password: password,
        name: name,
      );
      _setLoading(false);
      return _currentUser != null;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getFriendlyErrorMessage(e);
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceAll(RegExp(r'\[.*?\]'), '').trim();
      _setLoading(false);
      return false;
    }
  }

  String _getFriendlyErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'network-request-failed':
        return 'Network connection error. Please check your phone internet/WiFi.';
      case 'email-already-in-use':
        return 'This email address is already in use. Please sign in instead.';
      case 'invalid-email':
        return 'The email address is badly formatted.';
      case 'weak-password':
        return 'The password is too weak. Use at least 6 characters.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password. Please try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _currentUser = null;
    notifyListeners();
  }
}
