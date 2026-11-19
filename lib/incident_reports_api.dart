import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class IncidentReportsApi {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  IncidentReportsApi({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  Future<String> createReport({
    required String service,
    required String area,
    required String location,
    required String details,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Sign in before submitting an incident report.');
    }

    final report = _firestore.collection('incident_reports').doc();
    await report.set({
      'reportId': report.id,
      'reporterUid': user.uid,
      'reporterName': user.displayName?.trim().isNotEmpty == true
          ? user.displayName!.trim()
          : user.email?.split('@').first ?? 'Member',
      'reporterEmail': user.email ?? '',
      'service': service,
      'area': area,
      'location': location,
      'details': details,
      'status': 'Pending verification',
      'submittedAt': FieldValue.serverTimestamp(),
    });
    return report.id;
  }

  Future<List<Map<String, dynamic>>> getMyReports() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Sign in to view your incident reports.');
    }

    final snapshot = await _firestore
        .collection('incident_reports')
        .where('reporterUid', isEqualTo: user.uid)
        .orderBy('submittedAt', descending: true)
        .get();
    return snapshot.docs
        .map((document) => <String, dynamic>{
              'id': document.id,
              ...document.data(),
            })
        .toList();
  }
}
