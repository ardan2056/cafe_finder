import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../services/admin_image_picker.dart';
import '../../services/user_image_uploader.dart';
import '../../services/diagnostic_report_service.dart';
import '../../core/firebase_status.dart' as fb_status;
import '../../core/config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/gleap_service.dart';
import '../admin/admin_dashboard_screen.dart';
import '../../services/favorite_service.dart';
import '../../services/cafe_service.dart';
import '../../models/cafe_model.dart';

class ProfileScreen extends StatefulWidget {
  final bool isActive;
  const ProfileScreen({super.key, this.isActive = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final userService = UserService();
  final authService = AuthService();
  final String demoName = 'Demo User';
  final String demoEmail = 'demo@cafe-finder.local';

  final List<String> allPreferences = [
    'Belajar',
    'Kerja',
    'Nongkrong',
    'Meeting',
    'Kreatif',
    'Healing',
    'Tenang',
    'Wi-Fi',
    'Colokan',
    'Outdoor',
  ];

  List<String> selectedPreferences = [];
  String webRole = 'user';
  bool isUploadingAvatar = false;
  String? webName;
  String? webPhoto;
  String? webEmail;
  bool? _simpleProfileOverride;

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void initState() {
    super.initState();
    _loadSimpleOverride();
    if (kIsWeb) {
      _loadWebPreferences();
      _loadWebProfile();
    }
    _loadFeaturePrefs();
    _loadDemoMode();
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      setState(() {});
    }
  }

  Future<void> _loadFeaturePrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _gleapEnabled = prefs.getBool('gleap_enabled') ?? false;
      _crashlyticsEnabled = prefs.getBool('crashlytics_enabled') ?? false;
      if (mounted) setState(() {});
      // Initialize Gleap wrapper (no-op if SDK not available)
      await GleapService.instance.initialize();
    } catch (_) {}
  }

  Future<void> _setGleapEnabled(bool v) async {
    try {
      await GleapService.instance.setEnabled(v);
      _gleapEnabled = v;
      if (mounted) setState(() {});
      _showSnack(v ? 'Feedback diaktifkan' : 'Feedback dinonaktifkan');
    } catch (e) {
      _showSnack('Gagal menyimpan: $e');
    }
  }

  Future<void> _setCrashlyticsEnabled(bool v) async {
    try {
      await DiagnosticReportService.instance.setEnabled(v);
      _crashlyticsEnabled = v;
      if (mounted) setState(() {});
      _showSnack(v ? 'Crashlytics diaktifkan' : 'Crashlytics dinonaktifkan');
    } catch (e) {
      _showSnack('Gagal menyimpan: $e');
    }
  }

  Future<void> _showFeedbackDialog() async {
    // Delegate to GleapService which will either open Gleap or fallback
    await GleapService.instance.showFeedback(context);
  }

  Future<void> _showDiagnosticsDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final queued = prefs.getStringList('queued_feedback') ?? [];
    final queuedCrash = prefs.getStringList('queued_crash_reports') ?? [];
    final buffer = StringBuffer();
    buffer.writeln('Firebase ready: ${fb_status.isFirebaseReady}');
    buffer.writeln('Demo mode: ${prefs.getBool('demo_mode') ?? false}');
    buffer.writeln('Gleap enabled: ${prefs.getBool('gleap_enabled') ?? false}');
    buffer.writeln('Crashlytics enabled: ${prefs.getBool('crashlytics_enabled') ?? false}');
    buffer.writeln('Queued feedback: ${queued.length}');
    buffer.writeln('Queued crash reports: ${queuedCrash.length}');

    if (!mounted) return;
    _showDiagnosticsDialogBody(buffer.toString());
  }

  void _showDiagnosticsDialogBody(String details) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Diagnostics'),
        content: SingleChildScrollView(child: Text(details)),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup'))],
      ),
    );
  }

  bool _demoMode = false;
  bool _gleapEnabled = false;
  bool _crashlyticsEnabled = false;

  Future<void> _loadDemoMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _demoMode = prefs.getBool('demo_mode') ?? false;
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _loadSimpleOverride() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey('simple_profile_mode_override')) {
        _simpleProfileOverride = prefs.getBool('simple_profile_mode_override');
      }
    } catch (_) {}
  }

  bool get _isSimpleProfile => _simpleProfileOverride ?? Config.simpleProfileMode;

  Future<void> _setSimpleOverride(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('simple_profile_mode_override', value);
      _simpleProfileOverride = value;
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _loadWebProfile() async {
    final name = await userService.getName();
    final photo = await userService.getPhoto();
    if (!mounted) {
      return;
    }
    webName = name;
    webPhoto = photo;
    webEmail = demoEmail;
    setState(() {});
  }

  Future<void> _loadWebPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList('demo_preferences') ?? [];
    final role = prefs.getString('demo_role') ?? 'user';
    if (!mounted) {
      return;
    }
    setState(() {
      selectedPreferences = List<String>.from(stored);
      webRole = role;
    });
  }

  Future<void> _showUpgradeDialogWeb() async {
    final emailController = TextEditingController();
    final passController = TextEditingController();

    final ok = await showDialog<bool?>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Upgrade Akun'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: passController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal')),
            ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Upgrade')),
          ],
        );
      },
    );

    if (ok != true) return;

    try {
      await authService.upgradeAnonymousWithEmail(
        email: emailController.text,
        password: passController.text,
      );
      final prefs = await SharedPreferences.getInstance();
      // copy local demo data into Firestore for the newly linked user
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final name = prefs.getString('demo_name') ?? 'Pengguna';
        final phone = prefs.getString('demo_phone') ?? '';
        final photo = prefs.getString('demo_photo') ?? '';
        final demoPrefs = prefs.getStringList('demo_preferences') ?? [];

        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': name,
          'email': emailController.text,
          'phone': phone,
          'photoUrl': photo,
          'preferences': demoPrefs,
          'role': 'user',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // clear demo local storage keys
        await prefs.remove('demo_name');
        await prefs.remove('demo_email');
        await prefs.remove('demo_phone');
        await prefs.remove('demo_role');
        await prefs.remove('demo_photo');
        await prefs.remove('demo_preferences');
      }

      await prefs.setString('demo_role', 'user');
      if (!mounted) {
        return;
      }
      setState(() {
        webRole = 'user';
      });
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Akun berhasil di-upgrade')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal upgrade: $e')));
      }
    }
  }


  Future<void> logout() async {
    bool shouldNavigate = false;
    final navigator = Navigator.of(context);
    try {
      await authService.logout();
    } catch (e) {
      // If logout fails, still continue to navigate back to login
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal saat logout: $e')));
      }
    } finally {
      shouldNavigate = mounted;
    }

    if (!shouldNavigate) return;

    // Clear demo-mode preferences if present
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('demo_mode') == true) {
        await prefs.remove('demo_mode');
        await prefs.remove('demo_name');
        await prefs.remove('demo_email');
        await prefs.remove('demo_phone');
        await prefs.remove('demo_role');
        await prefs.remove('demo_photo');
        await prefs.remove('demo_preferences');
      }
    } catch (_) {}

    navigator.pushNamedAndRemoveUntil(
      AppRoutes.login,
      (route) => false,
    );
  }

  Future<void> savePreferences() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('demo_preferences', selectedPreferences);
    } else {
      await userService.updatePreferences(selectedPreferences);
    }

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preferensi berhasil disimpan')),
    );
  }

  String _displayRole(String? role) {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'moderator':
        return 'Moderator';
      default:
        return 'Pengguna';
    }
  }

  Widget _roleBadge(String role) {
    final isAdmin = role == 'admin';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isAdmin ? AppTheme.gold : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _displayRole(role),
        style: TextStyle(
          color: isAdmin ? Colors.black : Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Future<void> _onPickAvatar() async {
    setState(() => isUploadingAvatar = true);
    try {
      final picked = await pickImages();
      if (picked.isEmpty) return;
      final id = userService.uid.isEmpty
          ? DateTime.now().millisecondsSinceEpoch.toString()
          : userService.uid;
      final uploaded = await uploadUserImageFiles(picked, uid: id);
      if (uploaded.isEmpty) return;
      final url = uploaded.first;
      // Update backend/storage and local UI state
      await userService.updatePhoto(url);
      if (kIsWeb) {
        webPhoto = url;
      }
      if (!mounted) {
        return;
      }
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto profil diperbarui')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal upload avatar: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => isUploadingAvatar = false);
      }
    }
  }

  Widget _avatar({
    required String? imageUrl,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.gold,
        ),
        child: ClipOval(
          child: Semantics(
            label: 'Foto profil',
            button: true,
            child: (imageUrl == null || imageUrl.isEmpty)
                ? const Icon(
                    Icons.person_rounded,
                    color: Colors.black,
                    size: 38,
                  )
                : Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.person_rounded,
                      color: Colors.black,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _profileCard({
    required String name,
    required String email,
    required String role,
    required String? photoUrl,
    required VoidCallback onAvatarTap,
    VoidCallback? onEditNameTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          _avatar(imageUrl: photoUrl, onTap: onAvatarTap),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: role == 'admin'
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AdminDashboardScreen(),
                                ),
                              );
                            }
                          : null,
                      child: _roleBadge(role),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  email,
                  style: const TextStyle(color: AppTheme.lightGray),
                ),
              ],
            ),
          ),
          if (onEditNameTap != null)
            IconButton(
              onPressed: onEditNameTap,
              icon: const Icon(Icons.edit_rounded),
            ),
        ],
      ),
    );
  }

  Widget buildWebProfile() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profil',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Spacer(),
              const Text('Mode Sederhana', style: TextStyle(color: AppTheme.lightGray)),
              const SizedBox(width: 8),
              Switch.adaptive(
                value: _isSimpleProfile,
                onChanged: (v) async {
                  await _setSimpleOverride(v);
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _profileCard(
            name: webName ?? demoName,
            email: webEmail ?? demoEmail,
            role: webRole,
            photoUrl: webPhoto,
            onAvatarTap: webRole == 'guest'
                ? () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content:
                            Text('Upgrade akun untuk mengunggah foto profil')));
                  }
                : () {
                    if (!fb_status.isFirebaseReady) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text(
                              'Firebase belum siap. Periksa konfigurasi atau jalankan dengan --dart-define=ADMIN_SECRET untuk demo.')));
                      return;
                    }
                    _onPickAvatar();
                  },
          ),
          if (webRole == 'guest') const SizedBox(height: 18),
          if (webRole == 'guest')
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(18),
              ),
              child: ListTile(
                leading: const Icon(Icons.upgrade_rounded, color: AppTheme.gold),
                title: const Text('Upgrade ke Akun'),
                subtitle: const Text('Ubah akun tamu menjadi akun terdaftar'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _showUpgradeDialogWeb,
              ),
            ),
          const SizedBox(height: 30),
          const Text(
            'Preferensi Kafe',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: allPreferences.map((item) {
              final selected = selectedPreferences.contains(item);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    selected
                        ? selectedPreferences.remove(item)
                        : selectedPreferences.add(item);
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.gold
                        : Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    item,
                    style: TextStyle(
                      color: selected ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: savePreferences,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.gold,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'Simpan Preferensi',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.feedback_rounded, color: AppTheme.gold),
                  title: const Text('Kirim Feedback'),
                  subtitle: const Text('Laporkan bug atau kirim masukan'),
                  onTap: _showFeedbackDialog,
                ),
                SwitchListTile.adaptive(
                  title: const Text('Aktifkan Feedback (Gleap)'),
                  value: _gleapEnabled,
                  onChanged: (v) => _setGleapEnabled(v),
                  secondary: const Icon(Icons.bug_report_rounded, color: AppTheme.gold),
                ),
                SwitchListTile.adaptive(
                  title: const Text('Aktifkan Crashlytics'),
                  value: _crashlyticsEnabled,
                  onChanged: (v) => _setCrashlyticsEnabled(v),
                  secondary: const Icon(Icons.warning_rounded, color: AppTheme.gold),
                ),
                ListTile(
                  leading: const Icon(Icons.build_rounded, color: AppTheme.gold),
                  title: const Text('Diagnostics'),
                  subtitle: const Text('Tampilkan status aplikasi & antrian feedback'),
                  onTap: _showDiagnosticsDialog,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (webRole == 'admin')
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(24),
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: AppTheme.gold,
                ),
                title: const Text('Admin Panel'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminDashboardScreen(),
                    ),
                  );
                },
              ),
            ),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: logout,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: AppTheme.gold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Logout'),
            ),
            ),
        ],
      ),
    );
  }

  Widget buildWebProfileSimple() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profil',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Spacer(),
              const Text('Mode Sederhana', style: TextStyle(color: AppTheme.lightGray)),
              const SizedBox(width: 8),
              Switch.adaptive(
                value: _isSimpleProfile,
                onChanged: (v) async {
                  await _setSimpleOverride(v);
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _profileCard(
            name: webName ?? demoName,
            email: webEmail ?? demoEmail,
            role: webRole,
            photoUrl: webPhoto,
            onAvatarTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Fitur unggah foto nonaktif di mode sederhana')));
            },
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: logout,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Keluar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.gold,
                side: const BorderSide(color: AppTheme.gold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void showEditNameDialog(String currentName) {
    final controller = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: const Color(0xFF111827),
          title: const Text('Edit Nama'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Nama baru',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (kIsWeb) {
                  await userService.setName(controller.text);
                } else {
                  await userService.updateName(controller.text);
                }
                if (!mounted) {
                  return;
                }
                Navigator.pop(context);
                setState(() {});
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  Widget menuItem(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.gold),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    // If demo_mode is active (or Firestore isn't ready/logged in), load from SharedPreferences.
    if (_demoMode || !fb_status.isFirebaseReady || FirebaseAuth.instance.currentUser == null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: FutureBuilder<SharedPreferences>(
          future: SharedPreferences.getInstance(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
            }
            final prefs = snapshot.data!;
            final name = prefs.getString('demo_name') ?? 'Julian Aris';
            final email = prefs.getString('demo_email') ?? 'julian.aris@brewquest.local';
            final photoUrl = prefs.getString('demo_photo') ?? '';
            final role = prefs.getString('demo_role') ?? 'guest';

            // Load dynamic local visits
            var localVisitsStr = prefs.getStringList('local_visits');
            List<Map<String, dynamic>> localVisits = [];
            if (localVisitsStr == null) {
              final defaultVisits = [
                '{"cafeId":"c1","cafeName":"The Roasted Bean","cafeImage":"https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=150&auto=format&fit=crop&q=80","createdAt":"2023-10-24T12:00:00Z"}',
                '{"cafeId":"c2","cafeName":"Minimalist Espresso","cafeImage":"https://images.unsplash.com/photo-1498804103079-a6351b050096?w=150&auto=format&fit=crop&q=80","createdAt":"2023-10-21T12:00:00Z"}',
                '{"cafeId":"c3","cafeName":"Urban Brew Labs","cafeImage":"https://images.unsplash.com/photo-1445116572660-236099ec97a0?w=150&auto=format&fit=crop&q=80","createdAt":"2023-10-18T12:00:00Z"}',
                '{"cafeId":"c4","cafeName":"Velvet Sips","cafeImage":"https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=150&auto=format&fit=crop&q=80","createdAt":"2023-10-12T12:00:00Z"}',
              ];
              for (int i = 5; i <= 24; i++) {
                defaultVisits.add('{"cafeId":"mock_$i","cafeName":"Mock Cafe $i","cafeImage":"","createdAt":"2023-10-01T12:00:00Z"}');
              }
              prefs.setStringList('local_visits', defaultVisits);
              localVisits = defaultVisits.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
            } else {
              localVisits = localVisitsStr.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
            }

            return _buildProfileBody(name, email, photoUrl, role, isDemo: true, localVisits: localVisits);
          },
        ),
      );
    }

    // Otherwise, query Firestore for logged-in user
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: StreamBuilder<DocumentSnapshot>(
        stream: userService.getUserData(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }
          final doc = snapshot.data!;
          if (!doc.exists) {
            return _buildProfileBody('Pengguna Baru', '', '', 'user', isDemo: false);
          }
          final data = doc.data() as Map<String, dynamic>? ?? {};
          final name = data['name'] ?? 'Julian Aris';
          final email = data['email'] ?? '';
          final photoUrl = data['photoUrl'] ?? '';
          final role = data['role'] ?? 'user';
          return _buildProfileBody(name, email, photoUrl, role, isDemo: false);
        },
      ),
    );
  }

  Widget _buildProfileBody(String name, String email, String photoUrl, String role, {required bool isDemo, List<Map<String, dynamic>> localVisits = const []}) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top App Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/logo.png',
                        width: 28,
                        height: 28,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'BrewQuest',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () {
                    // Open settings sheet
                    _showSettingsSheet(role);
                  },
                  icon: const Icon(Icons.settings_rounded, color: AppTheme.primary),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Profile Header & Badge Section
            Center(
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomCenter,
                    clipBehavior: Clip.none,
                    children: [
                      // Avatar
                      GestureDetector(
                        onTap: () {
                          if (isDemo) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                content: Text('Ubah foto profil hanya tersedia untuk pengguna terdaftar')));
                          } else {
                            if (!fb_status.isFirebaseReady) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                  content: Text('Firebase belum siap')));
                              return;
                            }
                            _onPickAvatar();
                          }
                        },
                        child: Container(
                          width: 120,
                          height: 120,
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [AppTheme.primary, AppTheme.secondary],
                            ),
                          ),
                          child: ClipOval(
                            child: isUploadingAvatar
                                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                                : (photoUrl.isNotEmpty
                                    ? Image.network(photoUrl, fit: BoxFit.cover)
                                    : Image.network(
                                        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=300&auto=format&fit=crop&q=80',
                                        fit: BoxFit.cover,
                                      )),
                          ),
                        ),
                      ),
                      // Badge
                      Positioned(
                        bottom: -10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.secondary,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.military_tech_rounded, color: Colors.white, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                role == 'admin' ? 'Admin' : 'Urban Explorer',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          if (isDemo) {
                            _showEditDemoNameDialog(name);
                          } else {
                            showEditNameDialog(name);
                          }
                        },
                        child: const Icon(
                          Icons.edit_rounded,
                          size: 18,
                          color: AppTheme.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Exploring the world one bean at a time.',
                    style: TextStyle(color: AppTheme.textLight, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Stats Bento Grid
            Row(
              children: [
                StreamBuilder<QuerySnapshot>(
                  stream: fb_status.isFirebaseReady && !isDemo
                      ? FirebaseFirestore.instance
                          .collection('visits')
                          .where('userId', isEqualTo: userService.uid)
                          .snapshots()
                      : const Stream<QuerySnapshot>.empty(),
                  builder: (context, snapshot) {
                    final count = isDemo ? localVisits.length : (snapshot.data?.docs.length ?? 0);
                    final docs = snapshot.data?.docs ?? [];
                    return _buildStatItem(
                      count: '$count',
                      label: 'Total Kunjungan',
                      onTap: () => _showVisitsBottomSheet(docs, isDemo, localVisits: localVisits),
                    );
                  },
                ),
                const SizedBox(width: 14),
                StreamBuilder<QuerySnapshot>(
                  stream: fb_status.isFirebaseReady && !isDemo
                      ? FirebaseFirestore.instance
                          .collection('reviews')
                          .where('userId', isEqualTo: userService.uid)
                          .snapshots()
                      : const Stream<QuerySnapshot>.empty(),
                  builder: (context, snapshot) {
                    final count = isDemo ? 12 : (snapshot.data?.docs.length ?? 0);
                    final docs = snapshot.data?.docs ?? [];
                    return _buildStatItem(
                      count: '$count',
                      label: 'Total Review',
                      onTap: () => _showReviewsBottomSheet(docs, isDemo),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Achievements Card
            StreamBuilder<QuerySnapshot>(
              stream: fb_status.isFirebaseReady && !isDemo
                  ? FirebaseFirestore.instance
                      .collection('visits')
                      .where('userId', isEqualTo: userService.uid)
                      .snapshots()
                  : const Stream<QuerySnapshot>.empty(),
              builder: (context, snapshot) {
                final visitsCount = isDemo ? localVisits.length : (snapshot.data?.docs.length ?? 0);
                
                String currentLevel = 'Novice';
                String nextLevel = 'Explorer';
                int targetVisits = 5;
                int needed = 5;
                double progress = 0.0;
                
                if (visitsCount < 5) {
                  currentLevel = 'Novice';
                  nextLevel = 'Explorer';
                  targetVisits = 5;
                  needed = 5 - visitsCount;
                  progress = visitsCount / 5.0;
                } else if (visitsCount < 10) {
                  currentLevel = 'Explorer';
                  nextLevel = 'Connoisseur';
                  targetVisits = 10;
                  needed = 10 - visitsCount;
                  progress = visitsCount / 10.0;
                } else if (visitsCount < 20) {
                  currentLevel = 'Connoisseur';
                  nextLevel = 'Legend';
                  targetVisits = 20;
                  needed = 20 - visitsCount;
                  progress = visitsCount / 20.0;
                } else {
                  currentLevel = 'Legend';
                  nextLevel = '';
                  targetVisits = 20;
                  needed = 0;
                  progress = 1.0;
                }

                String milestoneText = needed > 0 
                    ? '$needed kunjungan lagi untuk level \'$nextLevel\'' 
                    : 'Level Maksimum Tercapai!';

                return GestureDetector(
                  onTap: () => _showMilestoneDialog(currentLevel, visitsCount),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryContainer.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.secondary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.military_tech_outlined, color: AppTheme.secondary, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Next Milestone (Level: $currentLevel)',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primary),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    milestoneText,
                                    style: const TextStyle(fontSize: 12, color: AppTheme.textLight),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            backgroundColor: Colors.white,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.secondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 28),

            // Saved Cafes (Cafe Favorit) Section
            const Text(
              'Cafe Favorit',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary),
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<String>>(
              stream: FavoriteService().favoriteIds(),
              builder: (context, favSnap) {
                final favIds = favSnap.data ?? [];
                if (favIds.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    alignment: Alignment.center,
                    child: const Text('Belum ada cafe favorit yang disimpan.', style: TextStyle(color: AppTheme.textLight)),
                  );
                }

                return StreamBuilder<List<CafeModel>>(
                  stream: CafeService().getCafes(),
                  builder: (context, cafeSnap) {
                    if (!cafeSnap.hasData) {
                      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
                    }
                    final savedCafes = cafeSnap.data!.where((c) => favIds.contains(c.id)).toList();
                    if (savedCafes.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        alignment: Alignment.center,
                        child: const Text('Belum ada cafe favorit yang disimpan.', style: TextStyle(color: AppTheme.textLight)),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: savedCafes.length,
                      itemBuilder: (context, index) {
                        final cafe = savedCafes[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFD4C3BA).withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: 64,
                                  height: 64,
                                  color: AppTheme.secondaryContainer.withValues(alpha: 0.4),
                                  child: cafe.images.isNotEmpty
                                      ? Image.network(cafe.images.first, fit: BoxFit.cover)
                                      : const Icon(Icons.local_cafe_rounded, color: AppTheme.primary),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cafe.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 15),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      cafe.categories.join(' • '),
                                      style: const TextStyle(color: AppTheme.textLight, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () async {
                                  await FavoriteService().removeFavorite(cafe.id);
                                },
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 24),
            _buildJoinedCommunitiesSection(),
            _buildJoinedEventsSection(),

            // Visit History Section
            const Text(
              'Visit History',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary),
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: fb_status.isFirebaseReady && !isDemo
                  ? FirebaseFirestore.instance
                      .collection('visits')
                      .where('userId', isEqualTo: userService.uid)
                      .orderBy('createdAt', descending: true)
                      .limit(5)
                      .snapshots()
                  : const Stream<QuerySnapshot>.empty(),
              builder: (context, snapshot) {
                if (isDemo) {
                  if (localVisits.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      alignment: Alignment.center,
                      child: const Text('Belum ada riwayat kunjungan.', style: TextStyle(color: AppTheme.textLight)),
                    );
                  }
                  // Sort visits descending by date
                  final sortedVisits = List<Map<String, dynamic>>.from(localVisits);
                  sortedVisits.sort((a, b) {
                    final da = DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime.now();
                    final db = DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime.now();
                    return db.compareTo(da);
                  });
                  final displayVisits = sortedVisits.take(5).toList();
                  return Column(
                    children: displayVisits.map((item) {
                      final cafeName = item['cafeName'] ?? 'Kafe';
                      final cafeImage = item['cafeImage'] ?? '';
                      final cafeId = item['cafeId'] ?? '';
                      final createdAtStr = item['createdAt'] ?? '';
                      
                      DateTime date = DateTime.tryParse(createdAtStr) ?? DateTime.now();
                      final dateStr = '${date.day}/${date.month}/${date.year}';
                      return _buildHistoryItem(cafeName, dateStr, cafeImage, cafeId);
                    }).toList(),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
                }

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    alignment: Alignment.center,
                    child: const Text('Belum ada riwayat kunjungan.', style: TextStyle(color: AppTheme.textLight)),
                  );
                }

                return Column(
                  children: docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final cafeName = data['cafeName'] ?? 'Kafe';
                    final cafeImage = data['cafeImage'] ?? '';
                    final cafeId = data['cafeId'] ?? '';
                    
                    DateTime date = DateTime.now();
                    if (data['createdAt'] is Timestamp) {
                      date = (data['createdAt'] as Timestamp).toDate();
                    }
                    final dateStr = '${date.day}/${date.month}/${date.year}';

                    return _buildHistoryItem(cafeName, dateStr, cafeImage, cafeId);
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  IconData _getCommunityIcon(dynamic iconData) {
    if (iconData is IconData) return iconData;
    switch (iconData) {
      case 'code': return Icons.code_rounded;
      case 'brush': return Icons.brush_rounded;
      case 'local_fire_department': return Icons.local_fire_department_rounded;
      case 'menu_book': return Icons.menu_book_rounded;
      case 'laptop_mac': return Icons.laptop_mac_rounded;
      case 'coffee':
      default: return Icons.coffee_rounded;
    }
  }

  Color _getCommunityColor(dynamic colorData) {
    if (colorData is Color) return colorData;
    switch (colorData) {
      case 'primary': return AppTheme.primary;
      case 'secondary': return AppTheme.secondary;
      case 'orange': return Colors.orange.shade700;
      case 'teal': return Colors.teal.shade700;
      case 'purple': return Colors.purple.shade700;
      case 'blue': return Colors.blue.shade700;
      default: return AppTheme.primary;
    }
  }

  Widget _buildJoinedCommunitiesSection() {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final prefs = snapshot.data!;
        final joinedIds = prefs.getStringList('joined_communities') ?? [];

        if (_useFirestore) {
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('communities')
                .where('members', arrayContains: userService.uid)
                .snapshots(),
            builder: (context, streamSnap) {
              if (!streamSnap.hasData) return const SizedBox();
              final docs = streamSnap.data!.docs;
              if (docs.isEmpty) return const SizedBox();
              return _buildJoinedCommunitiesList(docs.map((d) {
                final c = d.data() as Map<String, dynamic>;
                return {
                  'id': d.id,
                  'title': c['title'] ?? '',
                  'desc': c['desc'] ?? '',
                  'icon': c['icon'] ?? 'coffee',
                  'color': c['color'] ?? 'primary',
                  'memberCount': c['memberCount'] ?? 0,
                  'members': List<String>.from(c['members'] ?? []),
                };
              }).toList());
            },
          );
        } else {
          // Local mode
          if (joinedIds.isEmpty) return const SizedBox();
          final joinedList = [
            {
              'id': 'c1',
              'title': 'Programmer Coffee Club',
              'desc': 'Coding, caffeine, and collaborations.',
              'icon': Icons.code_rounded,
              'color': AppTheme.primary,
              'memberCount': 128,
            },
            {
              'id': 'c2',
              'title': 'UI/UX Designers Jkt',
              'desc': 'Connecting pixels and people in Jakarta.',
              'icon': Icons.brush_rounded,
              'color': AppTheme.secondary,
              'memberCount': 42,
            },
            {
              'id': 'c3',
              'title': 'Coffee Roasters Indo',
              'desc': 'Share and learn roasting profiles.',
              'icon': Icons.local_fire_department_rounded,
              'color': Colors.orange.shade700,
              'memberCount': 57,
            },
            {
              'id': 'c4',
              'title': 'Book Worms & Beans',
              'desc': 'Weekly reading circles in quiet cafes.',
              'icon': Icons.menu_book_rounded,
              'color': Colors.teal.shade700,
              'memberCount': 31,
            },
          ].where((c) => joinedIds.contains(c['id'])).toList();

          if (joinedList.isEmpty) return const SizedBox();
          return _buildJoinedCommunitiesList(joinedList);
        }
      },
    );
  }

  Widget _buildJoinedCommunitiesList(List<Map<String, dynamic>> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Komunitas Saya',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final c = items[index];
            final id = c['id'] as String;
            final icon = _getCommunityIcon(c['icon']);
            final color = _getCommunityColor(c['color']);
            
            return GestureDetector(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.communityDetail,
                  arguments: {
                    'type': 'community',
                    'id': id,
                    'title': c['title'],
                    'desc': c['desc'],
                    'icon': icon,
                    'color': color,
                    'memberCount': c['memberCount'],
                    'members': c['members'] ?? <String>[],
                  },
                ).then((_) => setState(() {}));
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFD4C3BA).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c['title'] as String,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            c['desc'] as String,
                            style: const TextStyle(color: AppTheme.textLight, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppTheme.secondary),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildJoinedEventsSection() {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final prefs = snapshot.data!;
        final joinedIds = prefs.getStringList('joined_events') ?? [];

        if (_useFirestore) {
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('events')
                .where('goingUsers', arrayContains: userService.uid)
                .snapshots(),
            builder: (context, streamSnap) {
              if (!streamSnap.hasData) return const SizedBox();
              final docs = streamSnap.data!.docs;
              if (docs.isEmpty) return const SizedBox();
              return _buildJoinedEventsList(docs.map((d) {
                final ev = d.data() as Map<String, dynamic>;
                return {
                  'id': d.id,
                  'title': ev['title'] ?? '',
                  'location': ev['location'] ?? '',
                  'month': ev['month'] ?? 'OCT',
                  'day': ev['day'] ?? '01',
                  'time': ev['time'] ?? '',
                  'going': ev['going'] ?? 0,
                  'imageUrl': ev['imageUrl'] ?? '',
                  'goingUsers': List<String>.from(ev['goingUsers'] ?? []),
                };
              }).toList());
            },
          );
        } else {
          // Local mode
          if (joinedIds.isEmpty) return const SizedBox();
          final joinedList = [
            {
              'id': 'e1',
              'title': 'Startup Networking Event',
              'location': 'The Espresso Lab, Jakarta',
              'month': 'OCT',
              'day': '24',
              'time': '18:00 - 20:00',
              'going': '45 Going',
              'imageUrl': 'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=600&auto=format&fit=crop&q=80',
            },
            {
              'id': 'e2',
              'title': 'Latte Art Workshop',
              'location': 'Roast & Co. Menteng',
              'month': 'OCT',
              'day': '28',
              'time': '14:00 - 16:00',
              'going': '12 Going',
              'imageUrl': 'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?w=600&auto=format&fit=crop&q=80',
            },
            {
              'id': 'e3',
              'title': 'Indie Writers Meetup',
              'location': 'Navy Brew Space, Balikpapan',
              'month': 'NOV',
              'day': '02',
              'time': '15:00 - 17:00',
              'going': '18 Going',
              'imageUrl': 'https://images.unsplash.com/photo-1499750310107-5fef28a66643?w=600&auto=format&fit=crop&q=80',
            },
          ].where((e) => joinedIds.contains(e['id'])).toList();

          if (joinedList.isEmpty) return const SizedBox();
          return _buildJoinedEventsList(joinedList);
        }
      },
    );
  }

  Widget _buildJoinedEventsList(List<Map<String, dynamic>> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Event Saya',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final ev = items[index];
            final id = ev['id'] as String;
            final imageUrl = ev['imageUrl'] as String;
            
            return GestureDetector(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.communityDetail,
                  arguments: {
                    'type': 'event',
                    'id': id,
                    'title': ev['title'],
                    'desc': 'Ikuti event menarik ini untuk memperluas jaringan Anda dan mempelajari hal baru.',
                    'location': ev['location'],
                    'month': ev['month'],
                    'day': ev['day'],
                    'time': ev['time'],
                    'goingCount': ev['going'] is String ? 45 : (ev['going'] ?? 0),
                    'imageUrl': imageUrl,
                    'goingUsers': ev['goingUsers'] ?? <String>[],
                  },
                ).then((_) => setState(() {}));
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFD4C3BA).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 48,
                        height: 48,
                        color: AppTheme.secondaryContainer.withValues(alpha: 0.4),
                        child: imageUrl.isNotEmpty
                            ? Image.network(imageUrl, fit: BoxFit.cover)
                            : const Icon(Icons.event_note_rounded, color: AppTheme.primary),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ev['title'] as String,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${ev['day']} ${ev['month']} • ${ev['location']}',
                            style: const TextStyle(color: AppTheme.textLight, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppTheme.secondary),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  bool get _useFirestore => fb_status.isFirebaseReady &&
      FirebaseAuth.instance.currentUser != null &&
      !FirebaseAuth.instance.currentUser!.isAnonymous;
  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  Widget _buildStatItem({
    required String count,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFD4C3BA).withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Text(
                count,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(color: AppTheme.textLight, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDemoNameDialog(String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: const Color(0xFF111827),
          title: const Text('Edit Nama (Demo Mode)', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Nama baru',
              hintStyle: TextStyle(color: Colors.grey),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('demo_name', controller.text);
                if (!mounted) return;
                Navigator.pop(context);
                setState(() {});
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void _showMilestoneDialog(String currentLevel, int visitsCount) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: const Color(0xFF111827),
          title: const Text('Milestone Level', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Level Anda Saat Ini: $currentLevel', style: const TextStyle(color: AppTheme.gold, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Total Kunjungan Riil: $visitsCount', style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 16),
              const Divider(color: Colors.grey),
              const SizedBox(height: 8),
              const Text('Panduan Level BrewQuest:', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text('• Novice: < 5 Kunjungan', style: TextStyle(color: Colors.white70)),
              const Text('• Explorer: 5 - 9 Kunjungan', style: TextStyle(color: Colors.white70)),
              const Text('• Connoisseur: 10 - 19 Kunjungan', style: TextStyle(color: Colors.white70)),
              const Text('• Legend: >= 20 Kunjungan', style: TextStyle(color: Colors.white70)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup', style: TextStyle(color: AppTheme.gold)),
            ),
          ],
        );
      },
    );
  }

  void _showVisitsBottomSheet(List<DocumentSnapshot> docs, bool isDemo, {List<Map<String, dynamic>> localVisits = const []}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Daftar Kunjungan Anda',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: isDemo 
                    ? (localVisits.isEmpty 
                        ? const Center(child: Text('Belum ada riwayat kunjungan.', style: TextStyle(color: AppTheme.textLight)))
                        : ListView.builder(
                            itemCount: localVisits.length,
                            itemBuilder: (context, index) {
                              final data = localVisits[index];
                              final cafeName = data['cafeName'] ?? 'Kafe';
                              final cafeImage = data['cafeImage'] ?? '';
                              final cafeId = data['cafeId'] ?? '';
                              final createdAtStr = data['createdAt'] ?? '';
                              
                              DateTime date = DateTime.tryParse(createdAtStr) ?? DateTime.now();
                              final dateStr = '${date.day}/${date.month}/${date.year}';

                              return ListTile(
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: cafeImage.isNotEmpty && cafeImage.startsWith('http')
                                      ? Image.network(cafeImage, width: 40, height: 40, fit: BoxFit.cover)
                                      : const Icon(Icons.coffee_rounded, color: AppTheme.primary),
                                ),
                                title: Text(cafeName, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                                subtitle: Text('Dikunjungi pada $dateStr'),
                                trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.secondary),
                                onTap: () {
                                  Navigator.pop(context);
                                  final dummyCafe = CafeModel(
                                    id: cafeId,
                                    name: cafeName,
                                    description: '',
                                    address: '',
                                    latitude: 0,
                                    longitude: 0,
                                    facilities: [],
                                    atmosphere: [],
                                    categories: [],
                                    rating: 0,
                                    priceRange: '',
                                    images: cafeImage.isNotEmpty ? [cafeImage] : [],
                                    isActive: true,
                                  );
                                  Navigator.pushNamed(context, AppRoutes.cafeDetail, arguments: dummyCafe);
                                },
                              );
                            },
                          ))
                    : docs.isEmpty
                        ? const Center(child: Text('Belum ada riwayat kunjungan.', style: TextStyle(color: AppTheme.textLight)))
                        : ListView.builder(
                            itemCount: docs.length,
                            itemBuilder: (context, index) {
                              final data = docs[index].data() as Map<String, dynamic>;
                              final cafeName = data['cafeName'] ?? 'Kafe';
                              final cafeImage = data['cafeImage'] ?? '';
                              final cafeId = data['cafeId'] ?? '';
                              
                              DateTime date = DateTime.now();
                              if (data['createdAt'] is Timestamp) {
                                date = (data['createdAt'] as Timestamp).toDate();
                              }
                              final dateStr = '${date.day}/${date.month}/${date.year}';

                              return ListTile(
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: cafeImage.isNotEmpty
                                      ? Image.network(cafeImage, width: 40, height: 40, fit: BoxFit.cover)
                                      : const Icon(Icons.coffee_rounded, color: AppTheme.primary),
                                ),
                                title: Text(cafeName, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                                subtitle: Text('Dikunjungi pada $dateStr'),
                                trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.secondary),
                                onTap: () {
                                  Navigator.pop(context);
                                  final dummyCafe = CafeModel(
                                    id: cafeId,
                                    name: cafeName,
                                    description: '',
                                    address: '',
                                    latitude: 0,
                                    longitude: 0,
                                    facilities: [],
                                    atmosphere: [],
                                    categories: [],
                                    rating: 0,
                                    priceRange: '',
                                    images: cafeImage.isNotEmpty ? [cafeImage] : [],
                                    isActive: true,
                                  );
                                  Navigator.pushNamed(context, AppRoutes.cafeDetail, arguments: dummyCafe);
                                },
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showReviewsBottomSheet(List<DocumentSnapshot> docs, bool isDemo) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Daftar Review Anda',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: isDemo 
                    ? const Center(child: Text('Demo Mode: Review Anda adalah 12 kali.', style: TextStyle(color: AppTheme.textLight)))
                    : docs.isEmpty
                        ? const Center(child: Text('Belum ada review yang dibuat.', style: TextStyle(color: AppTheme.textLight)))
                        : ListView.builder(
                            itemCount: docs.length,
                            itemBuilder: (context, index) {
                              final data = docs[index].data() as Map<String, dynamic>;
                              final comment = data['comment'] ?? '';
                              final rating = (data['rating'] ?? 0.0).toDouble();
                              final cafeId = data['cafeId'] ?? '';
                              
                              return ListTile(
                                title: Row(
                                  children: [
                                    const Icon(Icons.star_rounded, color: AppTheme.secondary, size: 16),
                                    const SizedBox(width: 4),
                                    Text('$rating', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                subtitle: Text(comment, maxLines: 2, overflow: TextOverflow.ellipsis),
                                trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.secondary),
                                onTap: () {
                                  Navigator.pop(context);
                                  final dummyCafe = CafeModel(
                                    id: cafeId,
                                    name: 'Lihat Detail Kafe',
                                    description: '',
                                    address: '',
                                    latitude: 0,
                                    longitude: 0,
                                    facilities: [],
                                    atmosphere: [],
                                    categories: [],
                                    rating: 0,
                                    priceRange: '',
                                    images: [],
                                    isActive: true,
                                  );
                                  Navigator.pushNamed(context, AppRoutes.cafeDetail, arguments: dummyCafe);
                                },
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHistoryItem(String name, String date, String imageUrl, String cafeId) {
    return GestureDetector(
      onTap: () {
        final dummyCafe = CafeModel(
          id: cafeId,
          name: name,
          description: '',
          address: '',
          latitude: 0,
          longitude: 0,
          facilities: [],
          atmosphere: [],
          categories: [],
          rating: 0,
          priceRange: '',
          images: imageUrl.isNotEmpty ? [imageUrl] : [],
          isActive: true,
        );
        Navigator.pushNamed(
          context,
          AppRoutes.cafeDetail,
          arguments: dummyCafe,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD4C3BA).withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imageUrl.isNotEmpty && imageUrl.startsWith('http')
                  ? Image.network(
                      imageUrl,
                      width: 58,
                      height: 58,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 58,
                        height: 58,
                        color: AppTheme.secondaryContainer.withValues(alpha: 0.4),
                        child: const Icon(Icons.coffee_rounded, color: AppTheme.primary),
                      ),
                    )
                  : Container(
                      width: 58,
                      height: 58,
                      color: AppTheme.secondaryContainer.withValues(alpha: 0.4),
                      child: const Icon(Icons.coffee_rounded, color: AppTheme.primary),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 12, color: AppTheme.secondary),
                      const SizedBox(width: 6),
                      Text(
                        date,
                        style: const TextStyle(color: AppTheme.textLight, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.secondary),
          ],
        ),
      ),
    );
  }

  void _showSettingsSheet(String role) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (context) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: AppTheme.themeModeNotifier,
          builder: (context, themeMode, _) {
            final isDark = themeMode == ThemeMode.dark;
            return Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppTheme.textLight.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Pengaturan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.text,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile.adaptive(
                    title: Text(
                      'Mode Sederhana',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.text),
                    ),
                    value: _isSimpleProfile,
                    activeTrackColor: AppTheme.primary,
                    onChanged: (v) async {
                      final navigator = Navigator.of(context);
                      await _setSimpleOverride(v);
                      navigator.pop();
                    },
                  ),
                  SwitchListTile.adaptive(
                    title: Text(
                      'Mode Gelap',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.text),
                    ),
                    value: isDark,
                    activeTrackColor: AppTheme.primary,
                    onChanged: (v) async {
                      await AppTheme.setThemeMode(v ? ThemeMode.dark : ThemeMode.light);
                    },
                  ),
                  if (role == 'admin')
                    ListTile(
                      leading: const Icon(Icons.admin_panel_settings_rounded, color: AppTheme.primary),
                      title: Text(
                        'Admin Panel',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.text),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                        );
                      },
                    ),
                  ListTile(
                    leading: const Icon(Icons.feedback_rounded, color: AppTheme.primary),
                    title: Text(
                      'Diagnostics & Feedback',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.text),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _showDiagnosticsDialog();
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                    title: const Text(
                      'Logout / Keluar',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      logout();
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
