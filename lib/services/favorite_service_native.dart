import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoriteService {
  FirebaseFirestore? _firestore;
  FirebaseFirestore get _instance => _firestore ??= FirebaseFirestore.instance;

  FirebaseAuth? _auth;
  FirebaseAuth get _authInstance => _auth ??= FirebaseAuth.instance;

  String get userId => _authInstance.currentUser?.uid ?? '';

  Future<void> addFavorite(String cafeId) async {
    if (userId.isEmpty) {
      return;
    }

    await _instance.collection('favorites').add({
      'userId': userId,
      'cafeId': cafeId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeFavorite(String cafeId) async {
    if (userId.isEmpty) {
      return;
    }

    final snapshot = await _instance
        .collection('favorites')
        .where('userId', isEqualTo: userId)
        .where('cafeId', isEqualTo: cafeId)
        .get();

    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  Stream<bool> isFavorite(String cafeId) {
    if (userId.isEmpty) {
      return Stream<bool>.value(false);
    }

    return _instance
        .collection('favorites')
        .where('userId', isEqualTo: userId)
        .where('cafeId', isEqualTo: cafeId)
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty);
  }

  Stream<List<String>> favoriteIds() {
    if (userId.isEmpty) {
      return Stream<List<String>>.value(<String>[]);
    }

    return _instance
        .collection('favorites')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => (doc.data()['cafeId'] as String?) ?? '')
            .where((id) => id.isNotEmpty)
            .toList());
  }
}
