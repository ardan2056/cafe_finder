import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'auth_identity.dart';

class AuthService {
  Future<void> login({
    required String email,
    required String password,
  }) async {}

  Future<void> register({
    required String email,
    required String password,
  }) async {}

  Future<void> logout() async {}

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

  Object? get currentUser => null;
}
