import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/cafe_model.dart';

class CafeService {
  FirebaseFirestore? _firestore;
  FirebaseFirestore get _instance => _firestore ??= FirebaseFirestore.instance;

  Stream<List<CafeModel>> getCafes() {
    return _instance
        .collection('cafes')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return CafeModel.fromFirestore(doc);
      }).toList();
    });
  }
}
