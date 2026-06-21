import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/firebase_status.dart' as fb_status;

class UserService {
  FirebaseFirestore? _firestore;
  FirebaseFirestore? get _instance {
    if (!fb_status.isFirebaseReady) return null;
    try {
      return _firestore ??= FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  FirebaseAuth? _auth;
  FirebaseAuth? get _authInstance {
    if (!fb_status.isFirebaseReady) return null;
    try {
      return _auth ??= FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  String get uid => _authInstance?.currentUser?.uid ?? '';

  Future<void> createUserData({
    required String name,
    required String email,
    String? phone,
    String role = 'user',
  }) async {
    final db = _instance;
    if (uid.isEmpty || db == null) {
      return;
    }

    await db.collection('users').doc(uid).set({
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
    final db = _instance;
    if (uid.isEmpty || db == null) {
      return Stream<DocumentSnapshot>.empty();
    }

    return db.collection('users').doc(uid).snapshots();
  }

  Future<void> updateName(String name) async {
    final db = _instance;
    if (uid.isEmpty || db == null) {
      return;
    }

    await db.collection('users').doc(uid).update({
      'name': name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updatePhone(String phone) async {
    final db = _instance;
    if (uid.isEmpty || db == null) return;
    await db.collection('users').doc(uid).update({
      'phone': phone,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updatePhoto(String photoUrl) async {
    final db = _instance;
    if (uid.isEmpty || db == null) return;
    await db.collection('users').doc(uid).update({
      'photoUrl': photoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updatePreferences(List<String> preferences) async {
    final db = _instance;
    if (uid.isEmpty || db == null) {
      return;
    }

    await db.collection('users').doc(uid).update({
      'preferences': preferences,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setRole(String role) async {
    final db = _instance;
    if (uid.isEmpty || db == null) return;
    await db.collection('users').doc(uid).update({
      'role': role,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String> getName() async {
    final db = _instance;
    if (uid.isEmpty || db == null) return '';
    final doc = await db.collection('users').doc(uid).get();
    final data = doc.data();
    return (data != null && data['name'] != null) ? data['name'] as String : '';
  }

  Future<String> getPhoto() async {
    final db = _instance;
    if (uid.isEmpty || db == null) return '';
    final doc = await db.collection('users').doc(uid).get();
    final data = doc.data();
    return (data != null && data['photoUrl'] != null) ? data['photoUrl'] as String : '';
  }

  Future<void> setName(String name) async {
    await updateName(name);
  }
}
