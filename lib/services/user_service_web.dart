// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:convert';
import 'dart:html' as html;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Web user service: prefer writing real Firestore user documents when
/// Firebase Auth is available (even for anonymous users). If Firebase is
/// not initialized or no signed-in user exists, fall back to local demo
/// storage in SharedPreferences / localStorage.

class UserService {
  String get uid => FirebaseAuth.instance.currentUser?.uid ?? 'demo';

  Future<void> createUserData({
    required String name,
    required String email,
    String? phone,
    String role = 'user',
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Write to Firestore for real users (including anonymous users with uid)
      try {
        final doc =
            FirebaseFirestore.instance.collection('users').doc(user.uid);
        await doc.set({
          'uid': user.uid,
          'name': name,
          'email': email,
          'phone': phone ?? '',
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        return;
      } catch (_) {
        // fall through to local storage fallback
      }
    }

    // Fallback: local demo storage
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('demo_name', name);
      await prefs.setString('demo_email', email);
      await prefs.setString('demo_phone', phone ?? '');
      await prefs.setString('demo_role', role);
    } catch (e) {
      html.window.localStorage['demo_name'] = name;
      html.window.localStorage['demo_email'] = email;
      html.window.localStorage['demo_phone'] = phone ?? '';
      html.window.localStorage['demo_role'] = role;
    }
  }

  /// Web: store role locally in SharedPreferences
  Future<void> setRole(String role) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc =
            FirebaseFirestore.instance.collection('users').doc(user.uid);
        await doc.set({'role': role, 'updatedAt': FieldValue.serverTimestamp()},
            SetOptions(merge: true));
        return;
      } catch (_) {}
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('demo_role', role);
    } catch (e) {
      html.window.localStorage['demo_role'] = role;
    }
  }

  Future<String> getRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        return (doc.data()?['role'] as String?) ?? 'user';
      } catch (_) {}
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('demo_role') ?? 'user';
    } catch (e) {
      return html.window.localStorage['demo_role'] ?? 'user';
    }
  }

  /// Provide an empty DocumentSnapshot stream for web (used by profile UI).
  Stream<DocumentSnapshot> getUserData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots();
    }
    return Stream<DocumentSnapshot>.empty();
  }

  Future<void> updateName(String name) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
            {'name': name, 'updatedAt': FieldValue.serverTimestamp()},
            SetOptions(merge: true));
        return;
      } catch (_) {}
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('demo_name', name);
    } catch (e) {
      html.window.localStorage['demo_name'] = name;
    }
  }

  Future<void> updatePhone(String phone) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
            {'phone': phone, 'updatedAt': FieldValue.serverTimestamp()},
            SetOptions(merge: true));
        return;
      } catch (_) {}
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('demo_phone', phone);
    } catch (e) {
      html.window.localStorage['demo_phone'] = phone;
    }
  }

  Future<String?> getName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('demo_name');
    } catch (e) {
      return html.window.localStorage['demo_name'];
    }
  }

  Future<String?> getPhoto() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        return doc.data()?['photoUrl'] as String?;
      } catch (_) {}
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('demo_photo');
    } catch (e) {
      return html.window.localStorage['demo_photo'];
    }
  }

  Future<void> setName(String name) async {
    await updateName(name);
  }

  Future<void> updatePhoto(String photoUrl) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
            {'photoUrl': photoUrl, 'updatedAt': FieldValue.serverTimestamp()},
            SetOptions(merge: true));
        return;
      } catch (_) {}
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('demo_photo', photoUrl);
    } catch (e) {
      html.window.localStorage['demo_photo'] = photoUrl;
    }
  }

  Future<void> updatePreferences(List<String> preferences) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'preferences': preferences,
          'updatedAt': FieldValue.serverTimestamp()
        }, SetOptions(merge: true));
        return;
      } catch (_) {}
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('demo_preferences', preferences);
    } catch (e) {
      html.window.localStorage['demo_preferences'] = jsonEncode(preferences);
    }
  }
}
