import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../core/config.dart';
import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/firebase_status.dart' as fb_status;
// imports intentionally minimal; admin flow uses separate AdminLoginScreen

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final authService = AuthService();
  final userService = UserService();

  bool isLoading = false;
  bool isGoogleLoading = false;
  bool hidePassword = true;

  Future<void> loginUser() async {
    // Basic validation: require email and password
    final email = emailController.text.trim();
    final password = passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email dan password wajib diisi')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });
    try {
      await authService.login(email: email, password: password);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } on FirebaseAuthException catch (e, st) {
      developer.log('FirebaseAuthException during login',
          error: e, stackTrace: st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login gagal: [${e.code}] ${e.message}')),
        );
      }
    } catch (e, st) {
      developer.log('Unknown error during login', error: e, stackTrace: st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login gagal: $e')),
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

  Future<void> loginWithGoogle() async {
    setState(() {
      isGoogleLoading = true;
    });

    try {
      final identity = await authService.loginWithGoogle();
      await userService.createUserData(
        name: identity.name,
        email: identity.email,
      );

      if (!mounted) {
        return;
      }

      if (identity.email == 'google.demo@gmail.com') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Menggunakan Google Demo (OAuth Client ID tidak terkonfigurasi di web/index.html)'),
            duration: Duration(seconds: 4),
          ),
        );
      }

      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login Google gagal: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isGoogleLoading = false;
        });
      }
    }
  }

  Future<void> _loginAsGuest() async {
    final prefs = await SharedPreferences.getInstance();
    final isDemoForced = prefs.getBool('demo_mode') ?? false;

    if (!fb_status.isFirebaseReady || isDemoForced) {
      await _enterDemoGuest();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.home);
      return;
    }

    setState(() {
      isLoading = true;
    });
    try {
      await authService.signInAnonymously();
      // create minimal user data (native will write to Firestore, web stores demo data)
      await userService.createUserData(
          name: 'Tamu', email: '', phone: '', role: 'guest');
      if (!mounted) {
        return;
      }
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } catch (e) {
      // Fall back to local demo guest mode on any error (like JS interop issues or disabled anonymous login on web)
      developer.log('Anonymous sign in failed, falling back to demo mode', error: e);
      await _enterDemoGuest();
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masuk dalam Mode Demo (Firebase tidak tersedia)'),
          duration: Duration(seconds: 2),
        ),
      );
      
      Navigator.pushReplacementNamed(context, AppRoutes.home);
      return;
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _enterDemoGuest() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('demo_name', 'Tamu');
      await prefs.setString('demo_email', '');
      await prefs.setString('demo_phone', '');
      await prefs.setString('demo_role', 'guest');
      await prefs.setBool('demo_mode', true);
      await prefs.setStringList('demo_preferences', <String>[]);
    } catch (_) {}
  }

  Future<void> _toggleForceDemo() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final prefs = await SharedPreferences.getInstance();
      final cur = prefs.getBool('demo_mode') ?? false;
      await prefs.setBool('demo_mode', !cur);
      if (mounted) setState(() {});
      messenger.showSnackBar(SnackBar(
          content:
              Text(!cur ? 'Demo mode diaktifkan' : 'Demo mode dinonaktifkan')));
    } catch (e) {
      messenger
          .showSnackBar(SnackBar(content: Text('Gagal toggle demo mode: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/logo.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Selamat Datang',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Masuk untuk menemukan kafe terbaikmu',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textLight),
              ),
              const SizedBox(height: 36),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(color: AppTheme.text),
                decoration: inputDecoration(
                  label: 'Email',
                  icon: Icons.email_rounded,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: hidePassword,
                style: TextStyle(color: AppTheme.text),
                decoration: inputDecoration(
                  label: 'Password',
                  icon: Icons.lock_rounded,
                ).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      hidePassword
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: AppTheme.primary,
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
                  onPressed: isLoading ? null : loginUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Masuk',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 14),
              if (Config.allowAnonymousLogin)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: isLoading ? null : _loginAsGuest,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: const BorderSide(color: AppTheme.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    child: const Text(
                      'Masuk sebagai Tamu',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: isGoogleLoading ? null : loginWithGoogle,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    side: const BorderSide(color: AppTheme.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  icon: isGoogleLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppTheme.primary),
                        )
                      : const Icon(Icons.g_mobiledata_rounded, size: 28, color: AppTheme.primary),
                  label: const Text(
                    'Masuk dengan Google',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.register);
                },
                child: const Text(
                  'Belum punya akun? Daftar',
                  style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.adminLogin);
                },
                child: const Text(
                  'Login sebagai Admin',
                  style: TextStyle(color: AppTheme.textLight),
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
      labelStyle: const TextStyle(color: AppTheme.textLight),
      prefixIcon: Icon(icon, color: AppTheme.textLight),
      filled: true,
      fillColor: const Color(0xFFEEEEED),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: BorderSide.none,
      ),
    );
  }
}
