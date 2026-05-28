class AuthIdentity {
  const AuthIdentity({
    required this.email,
    required this.name,
    this.photoUrl,
  });

  final String email;
  final String name;
  final String? photoUrl;
}
