import 'package:firebase_auth/firebase_auth.dart';

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
    await _instance.signOut();
  }

  User? get currentUser => _instance.currentUser;
}
