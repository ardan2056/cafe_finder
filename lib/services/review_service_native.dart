import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReviewService {
  FirebaseFirestore? _firestore;
  FirebaseFirestore get _instance => _firestore ??= FirebaseFirestore.instance;

  FirebaseAuth? _auth;
  FirebaseAuth get _authInstance => _auth ??= FirebaseAuth.instance;

  Future<void> addReview({
    required String cafeId,
    required double rating,
    required String comment,
    required List<String> tags,
  }) async {
    final user = _authInstance.currentUser;

    if (user == null) {
      throw Exception('User belum login');
    }

    await _instance.collection('reviews').add({
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
    return _instance
        .collection('reviews')
        .where('cafeId', isEqualTo: cafeId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
