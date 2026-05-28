import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'image_uploader.dart';
import 'admin_image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class CafeImageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Opens image picker, uploads selected images to Storage (if needed),
  /// and appends the resulting download URLs to `cafes/{cafeId}.images`.
  Future<List<String>> pickAndUploadImages(String cafeId) async {
    // Only admins can upload images
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('AUTH_REQUIRED');
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final role = userDoc.data()?['role'] as String? ?? 'user';
    if (role != 'admin') throw Exception('NOT_ADMIN');

    // Let platform-specific picker return local paths or data: URIs
    final picked = await pickImages();
    if (picked.isEmpty) return <String>[];

    // Upload images if needed (native/web implementations handle data: URIs or local files)
    final uploaded = await uploadImagesIfNeeded(picked, cafeId: cafeId);

    if (uploaded.isNotEmpty) {
      final doc = _firestore.collection('cafes').doc(cafeId);
      await doc.update({
        'images': FieldValue.arrayUnion(uploaded),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    return uploaded;
  }

  /// Delete an image by its download URL from Storage (if possible) and
  /// remove it from the Firestore `images` array for the cafe.
  Future<void> deleteImage(String cafeId, String imageUrl) async {
    final storage = FirebaseStorage.instance;
    try {
      // Try to delete from storage if it's a Firebase Storage URL
      if (imageUrl.startsWith('https://')) {
        final ref = storage.refFromURL(imageUrl);
        await ref.delete();
      }
    } catch (_) {
      // ignore storage deletion failures
    }

    // Remove from Firestore array
    final doc = _firestore.collection('cafes').doc(cafeId);
    await doc.update({
      'images': FieldValue.arrayRemove([imageUrl]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
