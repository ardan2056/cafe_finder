// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// app_theme not used here
import '../../services/suggestion_service_native.dart';
import '../../services/admin_cafe_service_native.dart';

class AdminSuggestionsScreen extends StatefulWidget {
  const AdminSuggestionsScreen({super.key});

  @override
  State<AdminSuggestionsScreen> createState() => _AdminSuggestionsScreenState();
}

class _AdminSuggestionsScreenState extends State<AdminSuggestionsScreen> {
  final SuggestionService _suggestionService = SuggestionService();
  final AdminCafeService _adminCafeService = AdminCafeService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saran Pengguna')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _suggestionService.getSuggestionsStream(),
        builder: (_, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('Belum ada saran'));
          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, idx) {
              final d = docs[idx];
              final data = d.data() as Map<String, dynamic>? ?? {};
              // status currently unused; keep in data for future UI
              return ListTile(
                title: Text(data['name'] ?? '(Tanpa nama)'),
                subtitle: Text(data['address'] ?? ''),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) async {
                    final localCtx = context;
                    if (v == 'accept') {
                      // create cafe with minimal data
                      try {
                        await _adminCafeService.addCafe(
                          name: data['name'] ?? 'Unnamed',
                          description: data['note'] ?? '',
                          address: data['address'] ?? '',
                          latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
                          longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
                          facilities: const [],
                          atmosphere: const [],
                          categories: const [],
                          priceRange: '',
                          images: const [],
                        );
                        await _suggestionService.updateSuggestionStatus(d.id, 'accepted');
                        if (!mounted) return;
                        ScaffoldMessenger.of(localCtx).showSnackBar(const SnackBar(content: Text('Saran diterima dan cafe dibuat')));
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(localCtx).showSnackBar(SnackBar(content: Text('Gagal membuat cafe: $e')));
                      }
                    } else if (v == 'reject') {
                      await _suggestionService.updateSuggestionStatus(d.id, 'rejected');
                    } else if (v == 'read') {
                      await _suggestionService.updateSuggestionStatus(d.id, 'read');
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'accept', child: Text('Terima & Buat Cafe')),
                    const PopupMenuItem(value: 'read', child: Text('Tandai dibaca')),
                    const PopupMenuItem(value: 'reject', child: Text('Tolak')),
                  ],
                ),
                onTap: () {
                  showDialog<void>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text(data['name'] ?? 'Saran'),
                      content: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Alamat: ${data['address'] ?? '-'}'),
                            const SizedBox(height: 8),
                            Text('Catatan: ${data['note'] ?? '-'}'),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup')),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
