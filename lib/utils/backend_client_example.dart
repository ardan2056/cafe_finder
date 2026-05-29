import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

/// Example: call backend admin/promote endpoint with current user's ID token
Future<void> promoteUser(
    String backendUrl, String targetUid, String role) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) throw Exception('Not signed in');
  final idToken = await user.getIdToken();
  final resp = await http.post(
    Uri.parse('$backendUrl/admin/promote'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $idToken',
    },
    body: jsonEncode({'uid': targetUid, 'role': role}),
  );
  if (resp.statusCode != 200) {
    throw Exception('Failed to promote: ${resp.statusCode} ${resp.body}');
  }
}
