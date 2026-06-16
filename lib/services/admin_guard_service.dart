import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminGuardService {
  const AdminGuardService._();

  static Future<bool> isCurrentUserAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = doc.data();
      final role = (data?['role'] as String?)?.trim().toLowerCase();
      return role == 'admin';
    } catch (_) {
      return false;
    }
  }
}
