import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserModel> signUp({
    required String email,
    required String password,
    required String name,
    String? profileImagePath,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user!;

    String? profileImageUrl;
    if (profileImagePath != null) {
      profileImageUrl = await _uploadProfileImage(user.uid, profileImagePath);
    }

    final userModel = UserModel(
      id: user.uid,
      name: name,
      email: email,
      profileImageUrl: profileImageUrl,
      lastSeen: DateTime.now(),
      isOnline: true,
      createdAt: DateTime.now(),
    );

    await _firestore.collection('users').doc(user.uid).set(userModel.toFirestore());
    await user.updateDisplayName(name);

    return userModel;
  }

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user!;

    await _firestore.collection('users').doc(user.uid).update({
      'isOnline': true,
      'lastSeen': Timestamp.fromDate(DateTime.now()),
    });

    final doc = await _firestore.collection('users').doc(user.uid).get();
    return UserModel.fromFirestore(doc);
  }

  Future<void> signOut() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await _firestore.collection('users').doc(uid).update({
        'isOnline': false,
        'lastSeen': Timestamp.fromDate(DateTime.now()),
      });
    }
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<UserModel?> getCurrentUserModel() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Future<String> _uploadProfileImage(String userId, String imagePath) async {
    final ref = _storage.ref().child('users/$userId/profile.webp');
    await ref.putString(imagePath);
    return await ref.getDownloadURL();
  }

  Future<void> updateOnlineStatus(bool isOnline) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _firestore.collection('users').doc(uid).update({
      'isOnline': isOnline,
      'lastSeen': Timestamp.fromDate(DateTime.now()),
    });
  }
}
