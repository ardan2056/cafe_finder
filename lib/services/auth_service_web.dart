import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'auth_identity.dart';

class AuthService {
  Future<void> login({
    required String email,
    required String password,
  }) async {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  Future<void> register({
    required String email,
    required String password,
  }) async {
    await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  Future<void> logout() async {
    final googleSignIn = GoogleSignIn();
    await Future.wait([
      FirebaseAuth.instance.signOut(),
      googleSignIn.signOut(),
    ]);
  }

  Future<void> signInAnonymously() async {
    await FirebaseAuth.instance.signInAnonymously();
  }

  Future<void> upgradeAnonymousWithEmail({
    required String email,
    required String password,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    final cred = EmailAuthProvider.credential(
      email: email.trim(),
      password: password.trim(),
    );

    if (user == null) {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return;
    }

    if (user.isAnonymous) {
      await user.linkWithCredential(cred);
    } else {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
    }
  }

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

    final result = await FirebaseAuth.instance.signInWithCredential(credential);
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

  User? get currentUser => FirebaseAuth.instance.currentUser;
}
