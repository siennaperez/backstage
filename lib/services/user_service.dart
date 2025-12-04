import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppUser {
  final String id;
  final String? displayName;
  final String? username;
  final String? email;
  final String? profileImageUrl;
  final List<String> attending;

  AppUser({
    required this.id,
    this.displayName,
    this.username,
    this.email,
    this.profileImageUrl,
    required this.attending,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return AppUser(
      id: doc.id,
      displayName: data['displayName'],
      username: data['username'],
      email: data['email'],
      profileImageUrl: data['profileImageUrl'],
      attending: List<String>.from(data['attending'] ?? []),
    );
  }

  String get displayNameOrUsername => displayName ?? username ?? 'Unknown User';
}

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  Stream<List<AppUser>> getAllUsers() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .where((doc) => doc.id != currentUserId)
          .map((doc) => AppUser.fromFirestore(doc))
          .toList();
    });
  }

  Future<List<AppUser>> searchUsers(String query) async {
    if (currentUserId == null) return [];

    final usersSnapshot = await _firestore.collection('users').get();
    final q = query.toLowerCase();

    return usersSnapshot.docs
        .where((d) => d.id != currentUserId)
        .map((doc) => AppUser.fromFirestore(doc))
        .where((u) {
          final uname = u.username?.toLowerCase() ?? '';
          final dname = u.displayName?.toLowerCase() ?? '';
          return uname.contains(q) || dname.contains(q);
        })
        .toList();
  }

  Future<AppUser?> getUserById(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) return null;
    return AppUser.fromFirestore(doc);
  }

  Stream<List<String>> streamUserAttending(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((doc) {
      final data = doc.data() ?? {};
      return List<String>.from(data['attending'] ?? []);
    });
  }
}
