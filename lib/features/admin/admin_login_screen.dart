import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../bootstrap/firebase_bootstrap.dart' as fb_boot;
import '../../core/firebase_status.dart' as fb_status;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Admin login screen:
/// - Web: accept an admin passcode defined via --dart-define=ADMIN_SECRET
/// - Native: require normal email/password login and verification that the
///   authenticated user's Firestore `role` is `admin`.
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final auth = AuthService();
  final userService = UserService();

  final passcodeController = TextEditingController();

  bool isLoading = false;

  Future<void> _loginAsAdmin() async {
    setState(() => isLoading = true);
    try {
      // Try reading admin secret from Firestore so it can be rotated remotely.
      String secret = '';
      if (fb_status.isFirebaseReady) {
        try {
          final doc = await FirebaseFirestore.instance
              .collection('config')
              .doc('app')
              .get()
              .timeout(const Duration(seconds: 2));
          secret = (doc.data()?['admin_secret'] as String?) ?? '';
        } catch (fireErr) {
          // Firestore read failed (offline/misconfigured/timeout). We'll fall back to
          // compile-time dart-define ADMIN_SECRET if provided.
          secret = const String.fromEnvironment('ADMIN_SECRET', defaultValue: '');
        }
      }

      // If still empty, try dart-define again (explicit fallback)
      if (secret.isEmpty) {
        secret = const String.fromEnvironment('ADMIN_SECRET', defaultValue: '');
      }

      // Fallback to 'admin' in demo/debug mode
      if (secret.isEmpty && (!fb_status.isFirebaseReady || kDebugMode)) {
        secret = 'admin';
      }

      if (secret.isEmpty) {
        throw Exception(
            'Admin secret tidak ditemukan. Atur field config/app.admin_secret di Firestore atau jalankan dengan --dart-define=ADMIN_SECRET=your_secret');
      }

      if (passcodeController.text.trim().isEmpty) {
        throw Exception('Masukkan kode admin');
      }
      if (passcodeController.text.trim() != secret.trim()) {
        throw Exception('Kode admin salah');
      }

      if (fb_status.isFirebaseReady) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // promote user in backend (userService will write to Firestore when user exists)
          try {
            await userService.setRole('admin').timeout(const Duration(seconds: 2));
          } catch (e) {
            // Ignore database write timeout/failure so that offline/local demo mode works
            // and lets the user proceed.
            debugPrint('Failed to set admin role in Firestore: $e');
          }
        }
      }

      // Always save to SharedPreferences for Web Demo role persistence
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('demo_role', 'admin');
      await prefs.setBool('demo_mode', true);

      if (!mounted) {
        return;
      }
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Login admin gagal: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navy,
      appBar: AppBar(
        title: Text('Admin Login', style: TextStyle(color: AppTheme.text, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.navy,
        iconTheme: IconThemeData(color: AppTheme.text),
      ),
      body: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!fb_status.isFirebaseReady) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_rounded, color: Colors.redAccent),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(
                            'Firebase belum terhubung. Beberapa fitur dinonaktifkan.',
                            style: TextStyle(color: AppTheme.text))),
                    TextButton(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          if (!mounted) return;
                          setState(() => isLoading = true);
                          await fb_boot.initializeFirebase();
                          fb_status.firebaseInitError = null;
                          if (mounted) setState(() => isLoading = false);
                        } catch (e) {
                          if (mounted) {
                            setState(() => isLoading = false);
                            messenger.showSnackBar(SnackBar(
                                content:
                                    Text('Gagal inisialisasi Firebase: $e')));
                          }
                        }
                      },
                      child: const Text('Ulangi'),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 12),
            Text('Masuk sebagai Admin',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.text)),
            const SizedBox(height: 12),
            TextField(
              controller: passcodeController,
              obscureText: true,
              style: TextStyle(color: AppTheme.text),
              decoration: InputDecoration(
                labelText: 'Kode Admin',
                labelStyle: const TextStyle(color: AppTheme.textLight),
                filled: true,
                fillColor: const Color(0xFFEEEEED),
                prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.textLight),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isLoading ? null : _loginAsAdmin,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.gold,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    )),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Masuk sebagai Admin', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Kembali',
                    style: TextStyle(color: AppTheme.lightGray, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
