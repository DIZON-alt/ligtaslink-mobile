import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfile {
  final String uid;
  final String name;
  final String email;
  final String address;
  final String phoneNumber;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    this.address = '',
    this.phoneNumber = '',
    this.createdAt,
    this.updatedAt,
  });

  factory UserProfile.fromDocument(DocumentSnapshot<Object?> document) {
    final data =
        document.data() as Map<String, dynamic>? ?? <String, dynamic>{};
    final createdAt = data['createdAt'] is Timestamp
        ? (data['createdAt'] as Timestamp).toDate()
        : null;
    final updatedAt = data['updatedAt'] is Timestamp
        ? (data['updatedAt'] as Timestamp).toDate()
        : null;

    return UserProfile(
      uid: data['uid']?.toString() ?? document.id,
      name: (data['name'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
      address: (data['address'] ?? '').toString(),
      phoneNumber: (data['phoneNumber'] ?? '').toString(),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uid': uid,
      'name': name,
      'email': email,
      'address': address,
      'phoneNumber': phoneNumber,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}

class ApiService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static bool get isSignedIn => _auth.currentUser != null;

  static Future<void> registerUser({
    required String name,
    required String email,
    required String password,
    required String address,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw Exception('Account creation failed.');
    }

    await saveProfile(
      uid: user.uid,
      name: name,
      email: user.email ?? email.trim(),
      address: address,
    );
  }

  static Future<void> saveProfile({
    String? uid,
    required String name,
    required String email,
    String address = '',
    String phoneNumber = '',
  }) async {
    final targetUid = uid ?? _auth.currentUser?.uid;
    if (targetUid == null) {
      throw Exception('No authenticated user found.');
    }

    final existing = await _db.collection('users').doc(targetUid).get();
    final data = <String, dynamic>{
      'uid': targetUid,
      'name': name.trim(),
      'email': email.trim(),
      'address': address.trim(),
      'phoneNumber': phoneNumber.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (!existing.exists) {
      data['createdAt'] = FieldValue.serverTimestamp();
    }

    await _db
        .collection('users')
        .doc(targetUid)
        .set(data, SetOptions(merge: true));

    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null && firebaseUser.displayName != name.trim()) {
      await firebaseUser.updateDisplayName(name.trim());
    }
  }

  static Future<Map<String, dynamic>?> getUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      return null;
    }

    final document = await _db.collection('users').doc(user.uid).get();
    return document.data();
  }

  static Future<UserProfile?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      return null;
    }

    final document = await _db.collection('users').doc(user.uid).get();
    if (!document.exists) {
      return null;
    }
    return UserProfile.fromDocument(document);
  }

}
