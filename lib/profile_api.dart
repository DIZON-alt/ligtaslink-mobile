
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ApiService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db =
      FirebaseFirestore.instance;

  // Register a user and save their profile
  static Future<void> registerUser({
    required String name,
    required String email,
    required String password,
    required String address,
  }) async {
    final credential =
        await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;

    if (user == null) {
      throw Exception('Account creation failed.');
    }

    await _db.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'name': name.trim(),
      'email': email.trim(),
      'address': address.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Get the currently logged-in user's profile
  static Future<Map<String, dynamic>?> getUserProfile() async {
    final user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    final document =
        await _db.collection('users').doc(user.uid).get();

    return document.data();
  }
}
