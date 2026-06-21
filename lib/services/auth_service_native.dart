import 'package:firebase_auth/firebase_auth.dart';
import '../core/firebase_status.dart' as fb_status;
// NOTE: google_sign_in tidak compatible untuk Windows di repo ini.
// Untuk Android/iOS, plugin harus ditambahkan & dikonfigurasi.
// Agar build tetap jalan, Google login di Windows dibuat fallback.
// import 'package:google_sign_in/google_sign_in.dart';

import 'auth_identity.dart';

class AuthService {
  FirebaseAuth? _auth;

  FirebaseAuth? get _instance {
    if (!fb_status.isFirebaseReady) return null;
    try {
      return _auth ??= FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final auth = _instance;
    if (auth == null) {
      throw Exception('Firebase belum siap / tidak terhubung.');
    }
    await auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  Future<void> register({
    required String email,
    required String password,
  }) async {
    final auth = _instance;
    if (auth == null) {
      throw Exception('Firebase belum siap / tidak terhubung.');
    }
    await auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  Future<void> logout() async {
    final auth = _instance;
    if (auth != null) {
      await auth.signOut();
    }
  }

  User? get currentUser {
    final auth = _instance;
    return auth?.currentUser;
  }

  Future<AuthIdentity> loginWithGoogle() async {
    // Untuk saat ini, login Google di Windows belum bisa karena plugin
    // google_sign_in tidak terkonfigurasi / tidak kompatibel di build ini.
    // Supaya app bisa jalan, tampilkan error yang jelas.
    throw Exception(
        'Login Google belum tersedia di platform ini. Gunakan Android/iOS.');
  }

  Future<void> signInAnonymously() async {
    final auth = _instance;
    if (auth == null) {
      throw Exception('Firebase belum siap / tidak terhubung.');
    }
    await auth.signInAnonymously();
  }

  /// If current user is anonymous, link the anonymous account to an email/password
  /// credential so data (like Firestore docs) remain associated with the same uid.
  Future<void> upgradeAnonymousWithEmail({
    required String email,
    required String password,
  }) async {
    final auth = _instance;
    if (auth == null) {
      throw Exception('Firebase belum siap / tidak terhubung.');
    }
    final user = auth.currentUser;
    final cred = EmailAuthProvider.credential(
      email: email.trim(),
      password: password.trim(),
    );

    if (user == null) {
      // No active user — create a new account instead
      await createUserWithEmail(email: email, password: password);
      return;
    }

    if (user.isAnonymous) {
      await user.linkWithCredential(cred);
    } else {
      // Not anonymous — create a new account
      await createUserWithEmail(email: email, password: password);
    }
  }

  Future<void> createUserWithEmail(
      {required String email, required String password}) async {
    final auth = _instance;
    if (auth == null) {
      throw Exception('Firebase belum siap / tidak terhubung.');
    }
    await auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }
}
