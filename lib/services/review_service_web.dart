import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewService {
  Future<void> addReview({
    required String cafeId,
    required double rating,
    required String comment,
    required List<String> tags,
  }) async {}

  Stream<QuerySnapshot> getReviews(String cafeId) {
    return Stream<QuerySnapshot>.empty();
  }
}
