import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../services/admin_image_picker.dart';
import '../../services/image_uploader.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    if (!mounted) return;
    webName = name;
    webPhoto = photo;
    webEmail = demoEmail;
    setState(() {});
  }

  Future<void> _loadWebPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList('demo_preferences') ?? [];
    final role = prefs.getString('demo_role') ?? 'user';
    if (!mounted) return;
    setState(() {
      selectedPreferences = List<String>.from(stored);
      webRole = role;
    });
  }

  Future<void> logout() async {
    await authService.logout();

    if (!mounted) return;
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

    if (!mounted) return;
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preferensi berhasil disimpan')),
    );
  }

  Future<void> _promoteToAdmin() async {
    try {
      await userService.setRole('admin');
      if (kIsWeb) {
        webRole = 'admin';
      }
      if (!mounted) return;
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Akun dipromosikan menjadi admin (dev)')),
      );
    } catch (e) {
      if (!mounted) return;
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mempromosikan: $e')),
      );
    }
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
      final uploaded = await uploadImagesIfNeeded(picked, cafeId: id);
      if (uploaded.isEmpty) return;
      final url = uploaded.first;
      // Update backend/storage and local UI state
      await userService.updatePhoto(url);
      if (kIsWeb) {
        webPhoto = url;
      }
      if (!mounted) return;
        setState(() {});
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto profil diperbarui')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal upload avatar: $e')));
      }
    } finally {
      if (mounted) setState(() => isUploadingAvatar = false);
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
            onAvatarTap: _onPickAvatar,
          ),
          if (kIsWeb)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _promoteToAdmin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                child: const Text('Promote to Admin (dev)'),
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
                    onAvatarTap: _onPickAvatar,
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
