import 'package:cloud_firestore/cloud_firestore.dart';

class PaginationService {
  PaginationService._();
  static final instance = PaginationService._();

  /// Fetch a page of documents from [collection] ordered by [orderByField].
  Future<QuerySnapshot> fetchPage({
    required String collection,
    required String orderByField,
    DocumentSnapshot? startAfter,
    int limit = 20,
  }) async {
    var q = FirebaseFirestore.instance
        .collection(collection)
        .orderBy(orderByField, descending: true)
        .limit(limit);
    if (startAfter != null) {
      q = q.startAfterDocument(startAfter);
    }
    return q.get();
  }
}
