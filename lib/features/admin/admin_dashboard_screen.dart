import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'add_cafe_screen.dart';
import '../../services/admin_cafe_service.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  AdminCafeService get _adminService => AdminCafeService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navy,
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: AppTheme.navy,
      ),
      body: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kelola Cafe Finder',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            adminMenu(
              context,
              icon: Icons.add_business_rounded,
              title: 'Tambah Data Kafe',
              subtitle: 'Tambahkan data kafe baru ke aplikasi',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddCafeScreen(),
                  ),
                );
              },
            ),
            adminMenu(
              context,
              icon: Icons.auto_fix_high_rounded,
              title: 'Seed Sample Cafes',
              subtitle: 'Reset dan isi data demo default',
              onTap: () async {
                try {
                  await _adminService.seedDefaults();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sample cafes seeded')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal seed: $e')),
                    );
                  }
                }
              },
            ),
            adminMenu(
              context,
              icon: Icons.edit_location_alt_rounded,
              title: 'Edit Data Kafe',
              subtitle: 'Ubah informasi kafe yang sudah tersedia',
              onTap: () {},
            ),
            adminMenu(
              context,
              icon: Icons.rate_review_rounded,
              title: 'Kelola Review',
              subtitle: 'Pantau dan moderasi ulasan pengguna',
              onTap: () {},
            ),
            adminMenu(
              context,
              icon: Icons.report_rounded,
              title: 'Laporan Pengguna',
              subtitle: 'Tinjau laporan data salah atau review bermasalah',
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget adminMenu(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.gold, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.lightGray,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}
