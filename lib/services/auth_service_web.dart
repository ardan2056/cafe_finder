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

  Object? get currentUser => null;
}
