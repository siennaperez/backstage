import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserMigrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> ensureCurrentUserDocument() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userDoc = await _firestore.collection('users').doc(user.uid).get();

    if (!userDoc.exists) {
      await _firestore.collection('users').doc(user.uid).set({
        'displayName': user.displayName ?? 'User',
        'username':
            user.email?.split('@')[0] ?? 'user_${user.uid.substring(0, 8)}',
        'email': user.email ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('Created Firestore document for user: ${user.uid}');
    }
  }

  Future<void> migrateAllAuthUsers() async {
    print('User migration should be done through the app signup flow');
  }
}
