// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:convert';
import 'dart:html' as html;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  String get uid => 'demo';

  Future<void> createUserData({
    required String name,
    required String email,
  }) async {}

  Future<void> createOrUpdateUserData({
    required String name,
    required String email,
    String? photoUrl,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('demo_name', name);
      await prefs.setString('demo_email', email);
      if (photoUrl != null) {
        await prefs.setString('demo_photo', photoUrl);
      }
    } catch (e) {
      html.window.localStorage['demo_name'] = name;
      html.window.localStorage['demo_email'] = email;
      if (photoUrl != null) {
        html.window.localStorage['demo_photo'] = photoUrl;
      }
    }
  }

  /// Web: store role locally in SharedPreferences
  Future<void> setRole(String role) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('demo_role', role);
    } catch (e) {
      // fallback to localStorage on web when plugin missing
      html.window.localStorage['demo_role'] = role;
    }
  }

  Future<String> getRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('demo_role') ?? 'user';
    } catch (e) {
      return html.window.localStorage['demo_role'] ?? 'user';
    }
  }

  /// Provide an empty DocumentSnapshot stream for web (used by profile UI).
  Stream<DocumentSnapshot> getUserData() {
    return Stream<DocumentSnapshot>.empty();
  }

  Future<void> updateName(String name) async {}

  Future<String?> getName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('demo_name');
    } catch (e) {
      return html.window.localStorage['demo_name'];
    }
  }

  Future<String?> getPhoto() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('demo_photo');
    } catch (e) {
      return html.window.localStorage['demo_photo'];
    }
  }

  Future<void> setName(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('demo_name', name);
    } catch (e) {
      html.window.localStorage['demo_name'] = name;
    }
  }

  Future<void> updatePhoto(String photoUrl) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('demo_photo', photoUrl);
    } catch (e) {
      html.window.localStorage['demo_photo'] = photoUrl;
    }
  }

  Future<void> updatePreferences(List<String> preferences) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('demo_preferences', preferences);
    } catch (e) {
      html.window.localStorage['demo_preferences'] = jsonEncode(preferences);
    }
  }
}
