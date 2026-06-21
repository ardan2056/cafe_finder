import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/firebase_status.dart' as fb_status;

class ReviewService {
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

  Future<void> addReview({
    required String cafeId,
    required double rating,
    required String comment,
    required List<String> tags,
  }) async {
    final auth = _authInstance;
    final db = _instance;
    final user = auth?.currentUser;

    if (user == null || db == null) {
      throw Exception('User belum login atau Firebase belum siap');
    }

    await db.collection('reviews').add({
      'cafeId': cafeId,
      'userId': user.uid,
      'userName': user.displayName ?? 'Pengguna',
      'rating': rating,
      'comment': comment,
      'tags': tags,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getReviews(String cafeId) {
    final db = _instance;
    if (db == null) {
      return Stream<QuerySnapshot>.empty();
    }
    return db
        .collection('reviews')
        .where('cafeId', isEqualTo: cafeId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
