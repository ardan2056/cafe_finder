import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final passcodeController = TextEditingController();

  bool isLoading = false;

  Future<void> _loginAsAdminNative() async {
    setState(() => isLoading = true);
    try {
      final email = emailController.text.trim();
      final password = passwordController.text;
      if (email.isEmpty || password.isEmpty) {
        throw Exception('Email dan password wajib diisi');
      }

      await auth.login(email: email, password: password);

      // verify role from user document
      final snapshot = await userService.getUserData().first;
      final data = snapshot.data() as Map<String, dynamic>? ?? {};
      final role = data['role'] as String? ?? 'user';
      if (role != 'admin') {
        throw Exception('Akun bukan admin');
      }

      if (!mounted) {
        return;
      }
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login admin gagal: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _loginAsAdminWeb() async {
    setState(() => isLoading = true);
    try {
      // Try reading admin secret from Firestore so it can be rotated remotely.
      String secret = '';
      try {
        final doc = await FirebaseFirestore.instance
            .collection('config')
            .doc('app')
            .get();
        secret = (doc.data()?['admin_secret'] as String?) ?? '';
      } catch (fireErr) {
        // Firestore read failed (offline/misconfigured). We'll fall back to
        // compile-time dart-define ADMIN_SECRET if provided.
        secret = const String.fromEnvironment('ADMIN_SECRET', defaultValue: '');
      }

      // If still empty, try dart-define again (explicit fallback)
      if (secret.isEmpty) {
        secret = const String.fromEnvironment('ADMIN_SECRET', defaultValue: '');
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

      // Only promote if there's an authenticated user. Otherwise ask them to
      // register/login first so we can persist the admin role to users/{uid}.
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Silakan login/daftar dengan email terlebih dahulu sebelum mengaktifkan akses admin')));
        return;
      }

      // promote user in backend (userService will write to Firestore when user exists)
      await userService.setRole('admin');

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
        title: const Text('Admin Login'),
        backgroundColor: AppTheme.navy,
      ),
      body: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            if (kIsWeb) ...[
              const Text('Masuk sebagai Admin (Web demo)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: passcodeController,
                decoration: InputDecoration(
                  labelText: 'Kode Admin',
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.04),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _loginAsAdminWeb,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.gold,
                      foregroundColor: Colors.black),
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Masuk sebagai Admin'),
                ),
              ),
            ] else ...[
              const Text('Masuk Admin (Native)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.04),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.04),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _loginAsAdminNative,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.gold,
                      foregroundColor: Colors.black),
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Masuk sebagai Admin'),
                ),
              ),
            ],
            const SizedBox(height: 18),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Kembali',
                    style: TextStyle(color: AppTheme.lightGray)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
