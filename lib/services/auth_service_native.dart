import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'auth_identity.dart';

class AuthService {
  FirebaseAuth? _auth;

  FirebaseAuth get _instance => _auth ??= FirebaseAuth.instance;

  Future<void> login({
    required String email,
    required String password,
  }) async {
    await _instance.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  Future<void> register({
    required String email,
    required String password,
  }) async {
    await _instance.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  Future<void> logout() async {
    final googleSignIn = GoogleSignIn();
    await Future.wait([
      _instance.signOut(),
      googleSignIn.signOut(),
    ]);
  }

  User? get currentUser => _instance.currentUser;

  Future<AuthIdentity> loginWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      throw Exception('Login Google dibatalkan');
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final result = await _instance.signInWithCredential(credential);
    final user = result.user;
    if (user == null) {
      throw Exception('Gagal masuk dengan Google');
    }

    return AuthIdentity(
      email: user.email ?? googleUser.email,
      name: user.displayName ?? googleUser.displayName ?? 'Pengguna',
      photoUrl: user.photoURL ?? googleUser.photoUrl,
    );
  }

  Future<void> signInAnonymously() async {
    await _instance.signInAnonymously();
  }

  /// If current user is anonymous, link the anonymous account to an email/password
  /// credential so data (like Firestore docs) remain associated with the same uid.
  Future<void> upgradeAnonymousWithEmail({
    required String email,
    required String password,
  }) async {
    final user = _instance.currentUser;
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
    await _instance.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }
}
