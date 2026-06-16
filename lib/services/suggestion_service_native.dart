import 'package:cloud_firestore/cloud_firestore.dart';
class SuggestionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addSuggestion({
    required String userId,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    String? note,
  }) async {
    await _firestore.collection('suggestions').add({
      'userId': userId,
      'name': name ?? '',
      'address': address ?? '',
      'latitude': latitude,
      'longitude': longitude,
      'note': note ?? '',
      'status': 'new',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getSuggestionsStream() {
    return _firestore
        .collection('suggestions')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> updateSuggestionStatus(String id, String status) async {
    await _firestore.collection('suggestions').doc(id).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
