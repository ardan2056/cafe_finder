import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/firebase_status.dart' as fb_status;

class FavoriteService {
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

  String get userId => _authInstance?.currentUser?.uid ?? '';

  Future<void> addFavorite(String cafeId) async {
    final db = _instance;
    if (userId.isEmpty || db == null) {
      return;
    }

    await db.collection('favorites').add({
      'userId': userId,
      'cafeId': cafeId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeFavorite(String cafeId) async {
    final db = _instance;
    if (userId.isEmpty || db == null) {
      return;
    }

    final snapshot = await db
        .collection('favorites')
        .where('userId', isEqualTo: userId)
        .where('cafeId', isEqualTo: cafeId)
        .get();

    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  Stream<bool> isFavorite(String cafeId) {
    final db = _instance;
    if (userId.isEmpty || db == null) {
      return Stream<bool>.value(false);
    }

    return db
        .collection('favorites')
        .where('userId', isEqualTo: userId)
        .where('cafeId', isEqualTo: cafeId)
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty);
  }

  Stream<List<String>> favoriteIds() {
    final db = _instance;
    if (userId.isEmpty || db == null) {
      return Stream<List<String>>.value(<String>[]);
    }

    return db
        .collection('favorites')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => (doc.data()['cafeId'] as String?) ?? '')
            .where((id) => id.isNotEmpty)
            .toList());
  }
}
