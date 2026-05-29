import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  FirebaseFirestore? _firestore;
  FirebaseFirestore get _instance => _firestore ??= FirebaseFirestore.instance;

  FirebaseAuth? _auth;
  FirebaseAuth get _authInstance => _auth ??= FirebaseAuth.instance;

  String get uid => _authInstance.currentUser?.uid ?? '';

  Future<void> createUserData({
    required String name,
    required String email,
    String? phone,
    String role = 'user',
  }) async {
    if (uid.isEmpty) {
      return;
    }

    await _instance.collection('users').doc(uid).set({
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone ?? '',
      'photoUrl': '',
      'preferences': [],
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<DocumentSnapshot> getUserData() {
    if (uid.isEmpty) {
      return Stream<DocumentSnapshot>.empty();
    }

    return _instance.collection('users').doc(uid).snapshots();
  }

  Future<void> updateName(String name) async {
    if (uid.isEmpty) {
      return;
    }

    await _instance.collection('users').doc(uid).update({
      'name': name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updatePhone(String phone) async {
    if (uid.isEmpty) return;
    await _instance.collection('users').doc(uid).update({
      'phone': phone,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updatePhoto(String photoUrl) async {
    if (uid.isEmpty) return;
    await _instance.collection('users').doc(uid).update({
      'photoUrl': photoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updatePreferences(List<String> preferences) async {
    if (uid.isEmpty) {
      return;
    }

    await _instance.collection('users').doc(uid).update({
      'preferences': preferences,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setRole(String role) async {
    if (uid.isEmpty) return;
    await _instance.collection('users').doc(uid).update({
      'role': role,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String> getName() async {
    if (uid.isEmpty) return '';
    final doc = await _instance.collection('users').doc(uid).get();
    final data = doc.data();
    return (data != null && data['name'] != null) ? data['name'] as String : '';
  }

  Future<String> getPhoto() async {
    if (uid.isEmpty) return '';
    final doc = await _instance.collection('users').doc(uid).get();
    final data = doc.data();
    return (data != null && data['photoUrl'] != null) ? data['photoUrl'] as String : '';
  }

  Future<void> setName(String name) async {
    await updateName(name);
  }
}
