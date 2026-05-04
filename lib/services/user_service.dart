import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;
// import 'package:path_provider/path_provider.dart';

import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const int _maxImageBytes = 10 * 1024 * 1024; // 10 MB

  Stream<UserModel> watchUser(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map(UserModel.fromFirestore);
  }

  Future<UserModel?> getUser(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Future<List<UserModel>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];
    final currentUid = _auth.currentUser?.uid;

    final snapshot = await _firestore
        .collection('users')
        .orderBy('name')
        .startAt([query])
        .endAt(['$query\uf8ff'])
        .limit(20)
        .get();

    return snapshot.docs
        .map(UserModel.fromFirestore)
        .where((u) => u.id != currentUid)
        .toList();
  }

  Future<void> updateProfile({String? name, String? imagePath}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final updates = <String, dynamic>{};

    if (name != null && name.trim().isNotEmpty) {
      updates['name'] = name.trim();
      await _auth.currentUser?.updateDisplayName(name.trim());
    }

    if (imagePath != null) {
      final url = await _uploadProfileImage(uid, imagePath);
      updates['profileImageUrl'] = url;
    }

    if (updates.isNotEmpty) {
      await _firestore.collection('users').doc(uid).update(updates);
    }
  }

  Future<String> _uploadProfileImage(String userId, String imagePath) async {
    final file = File(imagePath);
    final bytes = await file.readAsBytes();

    if (bytes.length > _maxImageBytes) {
      throw Exception('Image exceeds 10 MB limit');
    }

    final compressed = await _compressToWebp(bytes);
    final ref = _storage.ref().child('users/$userId/profile.webp');
    await ref.putData(compressed, SettableMetadata(contentType: 'image/webp'));
    return await ref.getDownloadURL();
  }

  Future<Uint8List> _compressToWebp(List<int> bytes) async {
    // final tmpDir = await getTemporaryDirectory();
    final decoded = img.decodeImage(Uint8List.fromList(bytes));
    if (decoded == null) throw Exception('Could not decode image');

    // Resize if larger than 400x400 for profile
    final resized = img.copyResize(decoded, width: 400, height: 400, maintainAspect: true);
    return img.encodeJpg(resized, quality: 80) ;
  }
}
