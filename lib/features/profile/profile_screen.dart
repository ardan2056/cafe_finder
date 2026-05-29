import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../services/admin_image_picker.dart';
// image_uploader not used here anymore (we use user_image_uploader)
// import '../../services/image_uploader.dart';
import '../../services/user_image_uploader.dart';
import '../../core/firebase_status.dart' as fb_status;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../admin/admin_dashboard_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

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

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _loadWebPreferences();
      _loadWebProfile();
    }
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

  Future<void> _showUpgradeDialogNative() async {
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
      // Ensure role updated in backend
      await userService.setRole('user');
      // Copy any demo/local preferences into Firestore if present
      try {
        final prefs = await SharedPreferences.getInstance();
        final demoPrefs = prefs.getStringList('demo_preferences') ?? [];
        final name = prefs.getString('demo_name');
        final phone = prefs.getString('demo_phone');
        final photo = prefs.getString('demo_photo');

        if (name != null) {
          await userService.updateName(name);
        }
        if (phone != null) {
          await userService.updatePhone(phone);
        }
        if (photo != null) {
          await userService.updatePhoto(photo);
        }
        if (demoPrefs.isNotEmpty) {
          await userService.updatePreferences(demoPrefs);
        }
      } catch (_) {}
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Akun berhasil di-upgrade')));
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal upgrade: $e')));
      }
    }
  }

  Future<void> logout() async {
    await authService.logout();

    if (!mounted) {
      return;
    }
    Navigator.pushNamedAndRemoveUntil(
      context,
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
                    _roleBadge(role),
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
                leading:
                    const Icon(Icons.upgrade_rounded, color: AppTheme.gold),
                title: const Text('Upgrade ke Akun'),
                subtitle: const Text('Ubah akun tamu menjadi akun terdaftar'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _showUpgradeDialogWeb,
              ),
            ),
          // Developer-only promote button removed — admin management is handled elsewhere.
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
    if (kIsWeb) {
      return Scaffold(
        backgroundColor: AppTheme.navy,
        body: SafeArea(child: buildWebProfile()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.navy,
      body: SafeArea(
        child: StreamBuilder(
          stream: userService.getUserData(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.gold),
              );
            }

            final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
            final name = data['name'] ?? 'Pengguna';
            final email = data['email'] ?? '';
            final photoUrl = data['photoUrl'] ?? '';
            final role = data['role'] ?? 'user';
            final preferences = List<String>.from(data['preferences'] ?? []);

            if (selectedPreferences.isEmpty && preferences.isNotEmpty) {
              selectedPreferences = preferences;
            }

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
                  const SizedBox(height: 24),
                  _profileCard(
                    name: name,
                    email: email,
                    role: role,
                    photoUrl: photoUrl,
                    onAvatarTap: role == 'guest'
                        ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Upgrade akun untuk mengunggah foto profil')));
                          }
                        : () {
                            if (!fb_status.isFirebaseReady) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Firebase belum siap. Upload dinonaktifkan sementara.')));
                              return;
                            }
                            _onPickAvatar();
                          },
                    onEditNameTap: () => showEditNameDialog(name),
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
                  const SizedBox(height: 28),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        if (data['role'] == 'admin')
                          ListTile(
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
                        if (data['role'] == 'guest')
                          ListTile(
                            leading: const Icon(Icons.upgrade_rounded,
                                color: AppTheme.gold),
                            title: const Text('Upgrade ke Akun'),
                            subtitle: const Text(
                                'Ubah akun tamu menjadi akun terdaftar'),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: _showUpgradeDialogNative,
                          ),
                        menuItem(Icons.notifications_rounded, 'Notifikasi'),
                        menuItem(Icons.dark_mode_rounded, 'Dark Mode'),
                        menuItem(
                            Icons.privacy_tip_rounded, 'Kebijakan Privasi'),
                        menuItem(Icons.help_rounded, 'Bantuan'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
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
          },
        ),
      ),
    );
  }
}
