import 'package:firebase_auth/firebase_auth.dart';

import 'auth_service.dart';

class FirebaseAuthService implements AuthService {
  final FirebaseAuth _firebaseAuth;
  LocalUser? _currentUser;

  FirebaseAuthService._(this._firebaseAuth) {
    _currentUser = _toLocalUser(_firebaseAuth.currentUser);
  }

  static Future<FirebaseAuthService> create() async {
    return FirebaseAuthService._(FirebaseAuth.instance);
  }

  @override
  LocalUser? get currentUser => _currentUser;

  LocalUser? _toLocalUser(User? user) {
    if (user == null || user.email == null) return null;
    return LocalUser(
      name: user.displayName?.trim().isNotEmpty == true
          ? user.displayName!.trim()
          : user.email!.split('@').first,
      email: user.email!,
    );
  }

  String _message(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'An account with that email already exists.';
      case 'invalid-credential':
      case 'user-not-found':
      case 'wrong-password':
        return 'Incorrect email or password.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'weak-password':
        return 'Use a stronger password.';
      case 'network-request-failed':
        return 'Check your internet connection and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return error.message ?? 'Firebase authentication failed.';
    }
  }

  @override
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    required String recoveryPin,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      await credential.user?.updateDisplayName(name.trim());
      await credential.user?.reload();
      _currentUser = _toLocalUser(_firebaseAuth.currentUser);
      return AuthResult.success(_currentUser!);
    } on FirebaseAuthException catch (error) {
      return AuthResult.failure(_message(error));
    }
  }

  @override
  Future<AuthResult> signIn(String email, String password) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      _currentUser = _toLocalUser(_firebaseAuth.currentUser);
      return AuthResult.success(_currentUser!);
    } on FirebaseAuthException catch (error) {
      return AuthResult.failure(_message(error));
    }
  }

  @override
  Future<AuthResult> resetPassword({
    required String email,
    required String recoveryPin,
    required String newPassword,
  }) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(
        email: email.trim().toLowerCase(),
      );
      return AuthResult.success(
        LocalUser(name: '', email: email.trim().toLowerCase()),
      );
    } on FirebaseAuthException catch (error) {
      return AuthResult.failure(_message(error));
    }
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    _currentUser = null;
  }
}
