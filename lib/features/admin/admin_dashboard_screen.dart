import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'admin_cafe_manager_screen.dart';
import 'add_cafe_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  Stream<int> _countStream(String collection) {
    return FirebaseFirestore.instance
        .collection(collection)
        .snapshots()
        .map((s) => s.size);
  }

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
            const SizedBox(height: 18),
            // Overview cards
            Row(
              children: [
                Expanded(
                  child: StreamBuilder<int>(
                    stream: _countStream('cafes'),
                    builder: (context, snap) =>
                        _statCard('Cafes', (snap.data ?? 0).toString()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StreamBuilder<int>(
                    stream: _countStream('users'),
                    builder: (context, snap) =>
                        _statCard('Users', (snap.data ?? 0).toString()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StreamBuilder<int>(
                    stream: _countStream('feedback'),
                    builder: (context, snap) =>
                        _statCard('Feedback', (snap.data ?? 0).toString()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            adminMenu(
              context,
              icon: Icons.add_business_rounded,
              title: 'Tambah Data Kafe',
              subtitle: 'Tambahkan data kafe baru ke aplikasi',
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AddCafeScreen()));
              },
            ),
            adminMenu(
              context,
              icon: Icons.edit_location_alt_rounded,
              title: 'Edit Data Kafe',
              subtitle: 'Ubah, aktif/nonaktifkan, dan kelola semua kafe',
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AdminCafeManagerScreen()));
              },
            ),
            adminMenu(
              context,
              icon: Icons.rate_review_rounded,
              title: 'Kelola Review',
              subtitle: 'Pantau dan moderasi ulasan pengguna',
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.lightGray)),
          const SizedBox(height: 8),
          Text(value,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
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
            Semantics(
              label: title,
              child: Icon(icon, color: AppTheme.gold, size: 32),
            ),
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
