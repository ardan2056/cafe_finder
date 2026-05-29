import 'package:cloud_firestore/cloud_firestore.dart';
import 'image_uploader.dart';

class AdminCafeService {
  FirebaseFirestore? _firestore;
  FirebaseFirestore get _instance => _firestore ??= FirebaseFirestore.instance;

  Future<void> addCafe({
    required String name,
    required String description,
    required String address,
    required double latitude,
    required double longitude,
    required List<String> facilities,
    required List<String> atmosphere,
    required List<String> categories,
    required String priceRange,
    List<String>? images,
  }) async {
    // If there are images that are data URIs, attempt to upload them and replace with URLs.
    final imgs = images ?? <String>[];
    List<String> finalImages = imgs;
    try {
      finalImages = await uploadImagesIfNeeded(imgs, cafeId: DateTime.now().millisecondsSinceEpoch.toString());
    } catch (_) {
      // ignore and fall back to provided list
      finalImages = imgs;
    }

    await _instance.collection('cafes').add({
      'name': name,
      'description': description,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'facilities': facilities,
      'atmosphere': atmosphere,
      'categories': categories,
      'rating': 0.0,
      'priceRange': priceRange,
      'images': finalImages,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateCafe({
    required String cafeId,
    required Map<String, dynamic> data,
  }) async {
    await _instance.collection('cafes').doc(cafeId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setCafeActive({
    required String cafeId,
    required bool isActive,
  }) async {
    await _instance.collection('cafes').doc(cafeId).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
