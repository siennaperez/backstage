import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get userChanges => _auth.authStateChanges();

  Future<UserCredential> register(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> signup(
    String displayName,
    String username,
    String email,
    String password,
  ) async {
    UserCredential userCredential = await register(email, password);
    final user = userCredential.user;

    if (user == null) {
      throw Exception('Failed to create user account');
    }

    try {
      await user.updateDisplayName(displayName);
      print(' Updated display name in Firebase Auth');

      print('  Creating user document in Firestore...');
      print('   UID: ${user.uid}');
      print('   displayName: $displayName');
      print('   username: $username');
      print('   email: $email');

      await _firestore.collection('users').doc(user.uid).set({
        'displayName': displayName,
        'username': username,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('Document set() completed, verifying...');

      dynamic lastError;
      DocumentSnapshot? doc;

      for (int i = 0; i < 3; i++) {
        try {
          doc = await _firestore.collection('users').doc(user.uid).get();
          if (doc.exists) {
            break; // Success
          }
          if (i < 2) {
            print('⏳ Document not found yet, retrying... (attempt ${i + 1}/3)');
            await Future.delayed(Duration(seconds: 1));
          }
        } catch (e) {
          lastError = e;
          if (i < 2) {
            print(
              '⏳ Error verifying document, retrying... (attempt ${i + 1}/3): $e',
            );
            await Future.delayed(Duration(seconds: 1));
          }
        }
      }

      if (doc == null || !doc.exists) {
        print('⚠️ Could not verify document creation immediately');
        if (lastError != null) {
          print('⚠️ Last error: $lastError');
          final errorStr = lastError.toString();
          if (errorStr.contains('unavailable') ||
              errorStr.contains('offline')) {
            print(
              '⚠️ Firestore appears to be offline - document will be created when connection is restored',
            );
            print(
              '⚠️ The user can still use the app, and the document will sync when online',
            );
            print('⚠️ Make sure Firestore is enabled in Firebase Console!');
          }
        }
      } else {
        print('User document created and verified in Firestore: ${user.uid}');
        print('Document data: ${doc.data()}');
      }
    } catch (e) {
      print('ERROR: Failed to create Firestore document: $e');
      print('Error type: ${e.runtimeType}');
      if (e.toString().contains('permission') ||
          e.toString().contains('PERMISSION_DENIED')) {
        print('This is a Firestore permissions issue!');
        print('Check your Firestore security rules in Firebase Console');
      }
    }

    return userCredential;
  }

  Future<UserCredential> login(String email, String password) async {
    final userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = userCredential.user;
    if (user != null) {
      try {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (!doc.exists) {
          print(
            'User logged in but no Firestore document found, creating one...',
          );
          print('   UID: ${user.uid}');
          print('   Email: ${user.email}');
          print('   DisplayName: ${user.displayName}');

          await _firestore.collection('users').doc(user.uid).set({
            'displayName': user.displayName ?? 'User',
            'username':
                user.email?.split('@')[0] ?? 'user_${user.uid.substring(0, 8)}',
            'email': user.email ?? '',
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          print('Firestore document created for logged-in user: ${user.uid}');
        } else {
          print('User already has Firestore document');
        }
      } catch (e) {
        print('Could not check/create Firestore document on login: $e');
      }
    }

    return userCredential;
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
