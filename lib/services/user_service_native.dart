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
  }) async {
    await createOrUpdateUserData(
      name: name,
      email: email,
      photoUrl: '',
    );
  }

  Future<void> createOrUpdateUserData({
    required String name,
    required String email,
    String? photoUrl,
  }) async {
    if (uid.isEmpty) {
      return;
    }

    await _instance.collection('users').doc(uid).set({
      'uid': uid,
      'name': name,
      'email': email,
      'photoUrl': photoUrl ?? '',
      'preferences': [],
      'role': 'user',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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

  Future<void> setName(String name) async {
    await updateName(name);
  }

  Future<String?> getName() async {
    if (uid.isEmpty) return null;
    final doc = await _instance.collection('users').doc(uid).get();
    final data = doc.data();
    return data == null ? null : data['name'] as String?;
  }

  Future<String?> getPhoto() async {
    if (uid.isEmpty) return null;
    final doc = await _instance.collection('users').doc(uid).get();
    final data = doc.data();
    return data == null ? null : data['photoUrl'] as String?;
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
}
