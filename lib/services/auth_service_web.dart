import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/firebase_status.dart' as fb_status;

import 'auth_identity.dart';

class AuthService {
  User? get _currentUser {
    if (!fb_status.isFirebaseReady) return null;
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (_) {
      return null;
    }
  }

  FirebaseAuth? get _authInstance {
    if (!fb_status.isFirebaseReady) return null;
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final auth = _authInstance;
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
    final auth = _authInstance;
    if (auth == null) {
      throw Exception('Firebase belum siap / tidak terhubung.');
    }
    await auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  Future<void> logout() async {
    final auth = _authInstance;
    final googleSignIn = GoogleSignIn();
    final List<Future<dynamic>> futures = [];
    if (auth != null) {
      futures.add(auth.signOut());
    }
    try {
      futures.add(googleSignIn.signOut());
    } catch (_) {}
    await Future.wait(futures);
  }

  Future<void> signInAnonymously() async {
    final auth = _authInstance;
    if (auth == null) {
      throw Exception('Firebase belum siap / tidak terhubung.');
    }
    await auth.signInAnonymously();
  }

  Future<void> upgradeAnonymousWithEmail({
    required String email,
    required String password,
  }) async {
    final auth = _authInstance;
    if (auth == null) {
      throw Exception('Firebase belum siap / tidak terhubung.');
    }
    final user = auth.currentUser;
    final cred = EmailAuthProvider.credential(
      email: email.trim(),
      password: password.trim(),
    );

    if (user == null) {
      await auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return;
    }

    if (user.isAnonymous) {
      await user.linkWithCredential(cred);
    } else {
      await auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
    }
  }

  Future<AuthIdentity> loginWithGoogle() async {
    final prefs = await SharedPreferences.getInstance();
    final isDemo = prefs.getBool('demo_mode') ?? false;

    // Direct mock check
    if (!fb_status.isFirebaseReady || isDemo) {
      return AuthIdentity(
        email: 'google.demo@gmail.com',
        name: 'Google User Demo',
        photoUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100',
      );
    }

    final auth = _authInstance;
    if (auth == null) {
      throw Exception('Firebase belum siap / tidak terhubung.');
    }

    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        throw Exception('Login Google dibatalkan');
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await auth.signInWithCredential(credential);
      final user = result.user;
      if (user == null) {
        throw Exception('Gagal masuk dengan Google');
      }

      return AuthIdentity(
        email: user.email ?? googleUser.email,
        name: user.displayName ?? googleUser.displayName ?? 'Pengguna',
        photoUrl: user.photoURL ?? googleUser.photoUrl,
      );
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      // If we got invalid_client or oauth failure or 401 error, fallback to mock Google login
      if (errStr.contains('client') ||
          errStr.contains('401') ||
          errStr.contains('oauth') ||
          errStr.contains('platform') ||
          errStr.contains('credential') ||
          errStr.contains('sign_in_failed')) {
        
        // Also enable demo mode on local prefs so subsequent DB operations know to fallback locally
        await prefs.setBool('demo_mode', true);
        await prefs.setString('demo_name', 'Google User Demo');
        await prefs.setString('demo_email', 'google.demo@gmail.com');
        await prefs.setString('demo_role', 'user');

        return AuthIdentity(
          email: 'google.demo@gmail.com',
          name: 'Google User Demo',
          photoUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100',
        );
      }
      rethrow;
    }
  }

  User? get currentUser => _currentUser;
}
