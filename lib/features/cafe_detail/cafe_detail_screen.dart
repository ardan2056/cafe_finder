// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/theme/app_theme.dart';
import '../../core/firebase_status.dart' as fb_status;
import '../../models/cafe_model.dart';
import '../../services/favorite_service.dart';
import '../../services/review_service.dart';
import '../../services/cafe_image_service.dart';
import '../review/review_screen.dart';

class CafeDetailScreen extends StatefulWidget {
  const CafeDetailScreen({super.key});

  @override
  State<CafeDetailScreen> createState() => _CafeDetailScreenState();
}

class _CafeDetailScreenState extends State<CafeDetailScreen> {
  final FavoriteService favoriteService = FavoriteService();

  Future<void> _openMaps(CafeModel cafe) async {
    final url =
        'https://www.google.com/maps/search/?api=1&query=${cafe.latitude},${cafe.longitude}';
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _checkIn(CafeModel cafe) async {
    try {
      final isDemo = !fb_status.isFirebaseReady ||
          FirebaseAuth.instance.currentUser == null ||
          FirebaseAuth.instance.currentUser!.isAnonymous;

      if (isDemo) {
        final prefs = await SharedPreferences.getInstance();
        var localVisitsStr = prefs.getStringList('local_visits');
        List<String> visitsList = [];
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
          visitsList = defaultVisits;
        } else {
          visitsList = List<String>.from(localVisitsStr);
        }

        final checkInTime = DateTime.now().toIso8601String();
        final newVisitJson = '{"cafeId":"${cafe.id}","cafeName":"${cafe.name}","cafeImage":"${cafe.images.isNotEmpty ? cafe.images.first : ''}","createdAt":"$checkInTime"}';
        visitsList.add(newVisitJson);
        await prefs.setStringList('local_visits', visitsList);
      } else {
        await FirebaseFirestore.instance.collection('visits').add({
          'userId': FirebaseAuth.instance.currentUser!.uid,
          'cafeId': cafe.id,
          'cafeName': cafe.name,
          'cafeImage': cafe.images.isNotEmpty ? cafe.images.first : '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Berhasil check-in di ${cafe.name}!'),
            backgroundColor: AppTheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal check-in: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final initialCafe = ModalRoute.of(context)!.settings.arguments as CafeModel;

    return Scaffold(
      backgroundColor: AppTheme.navy,
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('cafes')
              .doc(initialCafe.id)
              .snapshots(),
          builder: (_, snapshot) {
            final cafe = snapshot.hasData
                ? CafeModel.fromFirestore(snapshot.data!)
                : initialCafe;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 220,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: cafe.images.isEmpty
                          ? LinearGradient(
                              colors: [
                                AppTheme.gold.withValues(alpha: 0.75),
                                AppTheme.blue.withValues(alpha: 0.75),
                              ],
                            )
                          : null,
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: cafe.images.isNotEmpty
                        ? Image.network(
                            cafe.images.first,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(
                                Icons.local_cafe_rounded,
                                size: 80,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.local_cafe_rounded,
                              size: 80,
                              color: Colors.white,
                            ),
                          ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    cafe.name,
                    style: const TextStyle(
                        fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: AppTheme.gold),
                      const SizedBox(width: 6),
                      Text(cafe.rating.toString()),
                      const SizedBox(width: 16),
                      const Icon(Icons.location_on_rounded,
                          color: AppTheme.blue),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          cafe.address,
                          style: const TextStyle(color: AppTheme.lightGray),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    cafe.description,
                    style:
                        const TextStyle(color: AppTheme.lightGray, height: 1.6),
                  ),
                  const SizedBox(height: 28),
                  _sectionTitle('Kategori'),
                  _chipWrap(cafe.categories),
                  const SizedBox(height: 24),
                  _sectionTitle('Fasilitas'),
                  _chipWrap(cafe.facilities),
                  const SizedBox(height: 24),
                  _sectionTitle('Suasana'),
                  _chipWrap(cafe.atmosphere),
                  const SizedBox(height: 24),
                  _sectionTitle('Range Harga'),
                  Text(cafe.priceRange,
                      style: const TextStyle(color: AppTheme.lightGray)),
                  const SizedBox(height: 34),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () => _openMaps(cafe),
                      icon: const Icon(Icons.map_rounded),
                      label: const Text('Buka Google Maps'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.gold,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => ReviewScreen(cafeId: cafe.id)),
                        );
                      },
                      icon: const Icon(Icons.rate_review_rounded),
                      label: const Text('Tulis Review'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.gold,
                        side: const BorderSide(color: AppTheme.gold),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await _checkIn(cafe);
                      },
                      icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                      label: const Text('Check-in Kunjungan', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Image gallery
                  if (cafe.images.isNotEmpty) ...[
                    _sectionTitle('Foto Kafe'),
                    SizedBox(
                      height: 120,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (itemCtx, index) {
                          final url = cafe.images[index];
                          return Stack(
                            children: [
                              Container(
                                width: 160,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  image: DecorationImage(
                                      image: NetworkImage(url),
                                      fit: BoxFit.cover),
                                ),
                              ),
                              Positioned(
                                top: 6,
                                right: 6,
                                child: GestureDetector(
                                  onTap: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (dialogCtx) => AlertDialog(
                                        title: const Text('Hapus gambar?'),
                                        content: const Text(
                                            'Gambar akan dihapus permanen.'),
                                        actions: [
                                          TextButton(
                                              onPressed: () => Navigator.pop(
                                                  dialogCtx, false),
                                              child: const Text('Batal')),
                                          TextButton(
                                              onPressed: () => Navigator.pop(
                                                  dialogCtx, true),
                                              child: const Text('Hapus')),
                                        ],
                                      ),
                                    );

                                    if (!mounted) {
                                      return;
                                    }

                                    if (confirm == true) {
                                      showDialog(
                                          context: context,
                                          barrierDismissible: false,
                                          builder: (_) => const Center(
                                              child:
                                                  CircularProgressIndicator()));
                                      try {
                                        await CafeImageService()
                                            .deleteImage(cafe.id, url);
                                        if (!mounted) {
                                          return;
                                        }
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                                content:
                                                    Text('Gambar dihapus')));
                                      } catch (e) {
                                        if (!mounted) {
                                          return;
                                        }
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                                content: Text(
                                                    'Gagal menghapus gambar')));
                                      }
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                        color: Colors.black45,
                                        shape: BoxShape.circle),
                                    padding: const EdgeInsets.all(6),
                                    child: const Icon(Icons.delete,
                                        color: Colors.white, size: 18),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemCount: cafe.images.length,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        if (!fb_status.isFirebaseReady) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text(
                                  'Firebase belum siap — upload dinonaktifkan.')));
                          return;
                        }

                        showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => const Center(
                                child: CircularProgressIndicator()));
                        try {
                          final uploaded = await CafeImageService()
                              .pickAndUploadImages(cafe.id);
                          if (!mounted) {
                            return;
                          }

                          if (uploaded.isEmpty) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Tidak ada gambar yang diupload')),
                            );
                            return;
                          }

                          // Refresh dari server supaya foto baru langsung muncul.
                          await FirebaseFirestore.instance
                              .collection('cafes')
                              .doc(cafe.id)
                              .get(GetOptions(source: Source.server));

                          if (!mounted) return;

                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'Berhasil mengupload ${uploaded.length} gambar')),
                          );
                        } catch (e) {
                          if (!mounted) {
                            return;
                          }
                          Navigator.pop(context);
                          if (e.toString().contains('NOT_ADMIN')) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Hanya admin yang bisa mengupload gambar')),
                            );
                          } else if (e.toString().contains('AUTH_REQUIRED')) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Silakan login terlebih dahulu')),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Gagal mengupload gambar')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.photo_camera_rounded),
                      label: const Text('Tambah Foto'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.blue,
                        side: const BorderSide(color: AppTheme.blue),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 34),
                  _sectionTitle('Ulasan Pengguna'),
                  StreamBuilder(
                    stream: ReviewService().getReviews(cafe.id),
                    builder: (_, snap) {
                      if (!snap.hasData) {
                        return const Text('Belum ada ulasan',
                            style: TextStyle(color: AppTheme.lightGray));
                      }

                      final reviews = snap.data!.docs;
                      if (reviews.isEmpty) {
                        return const Text('Belum ada ulasan',
                            style: TextStyle(color: AppTheme.lightGray));
                      }

                      return Column(
                        children: reviews.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(data['userName'] ?? 'Pengguna',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                Text('⭐ ${data['rating']}'),
                                const SizedBox(height: 6),
                                Text(data['comment'] ?? '',
                                    style: const TextStyle(
                                        color: AppTheme.lightGray)),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),

                  const SizedBox(height: 14),
                  StreamBuilder<bool>(
                    stream: favoriteService.isFavorite(cafe.id),
                    builder: (_, favSnap) {
                      final isFavorite = favSnap.data ?? false;

                      return SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            if (isFavorite) {
                              await favoriteService.removeFavorite(cafe.id);
                            } else {
                              await favoriteService.addFavorite(cafe.id);
                            }
                          },
                          icon: Icon(isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded),
                          label: Text(isFavorite
                              ? 'Hapus dari Favorit'
                              : 'Simpan Favorit'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
    );
  }

  Widget _chipWrap(List<String> items) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items.map((item) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.gold.withValues(alpha: 0.3)),
          ),
          child: Text(item),
        );
      }).toList(),
    );
  }
}
