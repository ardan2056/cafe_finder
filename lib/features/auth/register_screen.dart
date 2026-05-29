import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../bootstrap/firebase_bootstrap.dart' as fb_boot;
import '../../core/firebase_status.dart' as fb_status;
import 'complete_profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final authService = AuthService();
  final userService = UserService();

  bool isLoading = false;
  bool hidePassword = true;

  Future<void> registerUser() async {
    final messenger = ScaffoldMessenger.of(context);

    if (!fb_status.isFirebaseReady) {
      final retry = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Firebase belum siap'),
          content: const Text(
              'Aplikasi belum terhubung ke Firebase. Coba ulangi inisialisasi?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Ulangi')),
          ],
        ),
      );

      if (!mounted) return;

      if (retry == true) {
        if (!mounted) return;
        setState(() => isLoading = true);
        try {
          await fb_boot.initializeFirebase();
          fb_status.firebaseInitError = null;
        } catch (e) {
          fb_status.firebaseInitError = e.toString();
          if (mounted) {
            messenger.showSnackBar(
                SnackBar(content: Text('Gagal menghubungkan Firebase: $e')));
          }
          if (mounted) setState(() => isLoading = false);
          return;
        }
        if (mounted) setState(() => isLoading = false);
      } else {
        return;
      }
    }

    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final phone = phoneController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty || phone.isEmpty) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Semua data wajib diisi')));
      return;
    }

    // basic email format check
    final emailRegex = RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+$");
    if (!emailRegex.hasMatch(email)) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Format email tidak valid')));
      return;
    }

    // password strength: minimum 6 chars (Firebase requirement)
    if (password.length < 6) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Password minimal 6 karakter')));
      return;
    }

    setState(() => isLoading = true);

    try {
      final before = FirebaseAuth.instance.currentUser?.uid ?? '<none>';
      await authService.register(
        email: emailController.text,
        password: passwordController.text,
      );

      // After creating the Firebase user, check and show UID to aid debugging.
      final user = FirebaseAuth.instance.currentUser;
      final uid = user?.uid ?? '';
      developer.log('Registered user uid: $uid (before: $before)');
      // If demo_mode was active, migrate local demo data into Firestore
      try {
        final prefs = await SharedPreferences.getInstance();
        final isDemo = prefs.getBool('demo_mode') ?? false;
        if (isDemo && uid.isNotEmpty) {
          final nameVal = prefs.getString('demo_name') ?? name;
          final phoneVal = prefs.getString('demo_phone') ?? phone;
          final photoVal = prefs.getString('demo_photo') ?? '';
          final demoPrefs = prefs.getStringList('demo_preferences') ?? [];

          await FirebaseFirestore.instance.collection('users').doc(uid).set({
            'uid': uid,
            'name': nameVal,
            'email': email,
            'phone': phoneVal,
            'photoUrl': photoVal,
            'preferences': demoPrefs,
            'role': 'user',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          // clear demo keys
          await prefs.remove('demo_mode');
          await prefs.remove('demo_name');
          await prefs.remove('demo_email');
          await prefs.remove('demo_phone');
          await prefs.remove('demo_role');
          await prefs.remove('demo_photo');
          await prefs.remove('demo_preferences');
        }
      } catch (e) {
        developer.log('Failed migrating demo data: $e');
      }
      if (mounted) {
        messenger.showSnackBar(SnackBar(
            content: Text(uid.isNotEmpty
                ? 'Daftar berhasil (uid: $uid)'
                : 'Daftar berhasil, tapi UID kosong.')));
      }

      // After creating the Firebase user, let them complete their profile.
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CompleteProfileScreen(
            initialName: nameController.text,
            initialEmail: emailController.text,
            initialPhone: phoneController.text,
          ),
        ),
      );
    } on FirebaseAuthException catch (e, st) {
      developer.log('FirebaseAuthException during register',
          error: e, stackTrace: st);
      if (mounted) {
        messenger.showSnackBar(
            SnackBar(content: Text('Daftar gagal: [${e.code}] ${e.message}')));
      }
    } catch (e, st) {
      developer.log('Unknown error during register', error: e, stackTrace: st);
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text('Daftar gagal: $e')));
      }
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navy,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Buat Akun',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Daftar untuk mulai mencari kafe favoritmu',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.lightGray),
              ),
              const SizedBox(height: 36),
              TextField(
                controller: nameController,
                decoration: inputDecoration(
                  label: 'Nama',
                  icon: Icons.person_rounded,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: inputDecoration(
                  label: 'No. Telepon',
                  icon: Icons.phone_rounded,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: inputDecoration(
                  label: 'Email',
                  icon: Icons.email_rounded,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: hidePassword,
                decoration: inputDecoration(
                  label: 'Password',
                  icon: Icons.lock_rounded,
                ).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      hidePassword
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                    ),
                    onPressed: () {
                      setState(() => hidePassword = !hidePassword);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isLoading ? null : registerUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.gold,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text(
                          'Daftar',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 18),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  'Sudah punya akun? Masuk',
                  style: TextStyle(color: AppTheme.gold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.08),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: BorderSide.none,
      ),
    );
  }
}
